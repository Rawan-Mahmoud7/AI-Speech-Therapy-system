import time
import os
import librosa
import numpy as np
import tempfile
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import logging

os.environ["PHONEMIZER_ESPEAK_LIBRARY"] = r"C:\Users\pc\OneDrive\Desktop\Grad-project-implement\espeak-ng\eSpeak NG\libespeak-ng.dll"
os.environ["PHONEMIZER_ESPEAK_PATH"] = r"C:\Users\pc\OneDrive\Desktop\Grad-project-implement\espeak-ng\eSpeak NG"
os.environ["ESPEAK_DATA_PATH"] = r"C:\Users\pc\OneDrive\Desktop\Grad-project-implement\espeak-ng\eSpeak NG"
from schemas import (
    EvaluationResponse, ProcessingDetails, VadDetails, 
    ClassificationDetails, TopPrediction, AlignmentDetails, 
    TargetPhonemeOccurrence, AlignedPhoneme, ErrorAnalysis
)
from core_ai import (
    SileroVAD, PhonemeClassifier, ForcedAligner, 
    PHONEME_MAP, generate_error_analysis, TARGET_PHONEMES
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ai_service.main")

app = FastAPI(title="AI Inference Service", description="AI endpoints for Pronunciation Evaluation")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# Initialize Models globally
vad_model = None
classifier_model = None
aligner_model = None

@app.on_event("startup")
async def startup_event():
    global vad_model, classifier_model, aligner_model
    vad_model = SileroVAD()
    
    # Check if a model path is supplied for the classifier
    model_path = os.getenv("MODEL_PATH", r"C:\Users\pc\OneDrive\Desktop\Grad-project-implement\best_model")
    classifier_model = PhonemeClassifier(model_path=model_path)
    aligner_model = ForcedAligner()
    logger.info("All AI models loaded.")

@app.post("/evaluate", response_model=EvaluationResponse)
async def evaluate(
    audio_file: UploadFile = File(...),
    therapy_level: int = Form(...),
    target_phoneme: str = Form(...),
    expected_text: str = Form(default=None)
):
    start_time = time.perf_counter()
    logger.info(f"THERAPY LEVEL INPUT = {therapy_level}")
    # 1. Validations
    if therapy_level not in {1, 2, 3, 4}:
        raise HTTPException(400, detail={"code": "INVALID_THERAPY_LEVEL", "message": "Therapy level must be 1, 2, 3, or 4."})
    
    if target_phoneme not in TARGET_PHONEMES:
        raise HTTPException(400, detail={"code": "INVALID_PHONEME", "message": f"Target phoneme must be one of: {TARGET_PHONEMES}"})
        
    if therapy_level in {3, 4} and not expected_text:
        raise HTTPException(400, detail={"code": "MISSING_EXPECTED_TEXT", "message": "expected_text is required for levels 3 and 4."})
        
    # 2. Load and Resample Audio
    try:
        audio_bytes = await audio_file.read()
        suffix = os.path.splitext(audio_file.filename or "")[1] or ".wav"
        with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
            tmp.write(audio_bytes)
            tmp_path = tmp.name
        
        # Resample to 16kHz Mono
        audio_array, sr = librosa.load(tmp_path, sr=16000, mono=True)
        os.unlink(tmp_path)
        
        # Peak Normalize
        if len(audio_array) > 0 and np.max(np.abs(audio_array)) > 0:
            audio_array = audio_array / np.max(np.abs(audio_array))
            
    except Exception as e:
        raise HTTPException(400, detail={"code": "INVALID_AUDIO_FORMAT", "message": str(e)})

    # 3. Voice Activity Detection (VAD)
    if therapy_level in {1, 2}:
        # Bypass VAD for levels 1 and 2
        trimmed_audio = audio_array
        duration_ms = float(len(audio_array)) / 16000.0 * 1000.0
        vad_details = VadDetails(
            speech_detected=True,
            speech_start_ms=0.0,
            speech_end_ms=duration_ms,
            speech_duration_ms=duration_ms
        )
    else:
        vad_result = vad_model.process(audio_array, sample_rate=16000)
        if not vad_result:
            raise HTTPException(422, detail={"code": "NO_SPEECH_DETECTED", "message": "No speech found in audio."})
            
        if vad_result["duration_ms"] < 100:
            raise HTTPException(422, detail={"code": "AUDIO_TOO_SHORT", "message": "Speech segment is shorter than 100 ms."})
            
        vad_details = VadDetails(
            speech_detected=True,
            speech_start_ms=vad_result["start_ms"],
            speech_end_ms=vad_result["end_ms"],
            speech_duration_ms=vad_result["duration_ms"]
        )
        
        # Trimmed audio for classification
        trimmed_audio = vad_result["trimmed_audio"]
    
    response_data = {
        "target_phoneme": target_phoneme,
        "therapy_level": therapy_level,
        "details": ProcessingDetails(vad=vad_details, processing_time_ms=0.0)
    }

    # 4. Pipeline Routing
    if therapy_level in {1, 2}:
        # Wav2Vec2 Classification
        if classifier_model.model is None:
            raise HTTPException(503, detail={"code": "MODEL_NOT_LOADED", "message": "Classifier model failed to load."})
            
        preds = classifier_model.predict(trimmed_audio)
        predicted_phoneme = preds["predicted_phoneme"]
        confidence = preds["confidence"]
        is_correct = (predicted_phoneme == target_phoneme)
        
        class_details = ClassificationDetails(
            predicted_phoneme=predicted_phoneme,
            confidence=confidence,
            top_predictions=[TopPrediction(**p) for p in preds["top_predictions"]]
        )
        
        response_data.update({
            "is_correct": is_correct,
            "confidence": confidence,
            "predicted_phoneme": predicted_phoneme,
        })
        response_data["details"].classification = class_details
        
        if not is_correct:
            response_data["error_analysis"] = ErrorAnalysis(**generate_error_analysis(target_phoneme, predicted_phoneme))

    else:
        # Levels 3-4: Forced Alignment
        align_res = aligner_model.align(audio_array, expected_text)
        
        target_ipa = PHONEME_MAP.get(target_phoneme, {}).get("ipa", target_phoneme)
        
        # Parse alignment result
        segments = align_res.get("segments", [])
        if not segments:
            raise HTTPException(422, detail={"code": "ALIGNMENT_FAILED", "message": "Could not align text to audio."})
            
        main_seg = segments[0]
        pts = main_seg.get("phoneme_ts", [])
        
        all_phonemes = []
        occurrences = []
        
        total_pts = len(pts)
        for i, pt in enumerate(pts):
            ipa_lbl = pt.get("ipa_label", "").lower()
            orig_lbl = pt.get("phoneme_label", "").lower()
            
            ap = AlignedPhoneme(
                ipa_label=ipa_lbl, start_ms=pt["start_ms"], 
                end_ms=pt["end_ms"], confidence=pt.get("confidence", 0.0)
            )
            all_phonemes.append(ap)
            
            if ipa_lbl == target_ipa or orig_lbl == target_ipa:
                pos = "medial"
                if i == 0: pos = "initial"
                elif i == total_pts - 1: pos = "final"
                
                is_est = pt.get("is_estimated", False)
                conf = pt.get("confidence", 0.0)
                is_corr = (conf >= 0.5) and not is_est
                
                occurrences.append(TargetPhonemeOccurrence(
                    ipa_label=ipa_lbl, position_in_word=pos,
                    start_ms=pt["start_ms"], end_ms=pt["end_ms"],
                    confidence=conf, is_estimated=is_est, is_correct=is_corr
                ))
        
        cov = main_seg.get("coverage_analysis", {})
        
        alignment_details = AlignmentDetails(
            expected_text=expected_text,
            phoneme_count=cov.get("target_count", len(pts)),
            target_phoneme_occurrences=occurrences,
            all_phonemes=all_phonemes,
            coverage_ratio=cov.get("coverage_ratio", 1.0),
            bad_confidence=cov.get("bad_confidence", False)
        )
        
        response_data["details"].alignment = alignment_details
        
        # Evaluate correctness from occurrences
        if not occurrences:
            # Phoneme was completely omitted/unrecognized
            response_data.update({
                "is_correct": False,
                "confidence": 0.0,
                "predicted_phoneme": "[omitted]",
                "error_analysis": ErrorAnalysis(
                    error_type="omission", expected_phoneme=target_phoneme,
                    produced_phoneme="[omitted]", is_common_error=False,
                    clinical_category=None, description=f"The target phoneme {target_phoneme} was omitted or not detected."
                )
            })
        else:
            # Check if all occurrences are correct
            all_correct = all(o.is_correct for o in occurrences)
            avg_conf = sum(o.confidence for o in occurrences) / len(occurrences)
            
            response_data.update({
                "is_correct": all_correct,
                "confidence": avg_conf,
                "predicted_phoneme": target_phoneme if all_correct else "[mispronounced]",
            })
            
            if not all_correct:
                response_data["error_analysis"] = ErrorAnalysis(
                    error_type="distortion", expected_phoneme=target_phoneme,
                    produced_phoneme="[distortion]", is_common_error=False,
                    clinical_category=None, description="The target phoneme was aligned but with low confidence or high distortion."
                )

    # Compute Total Time
    response_data["details"].processing_time_ms = round((time.perf_counter() - start_time) * 1000, 2)
    logger.info(f"THERAPY LEVEL RESPONSE = {response_data['therapy_level']}")
    return EvaluationResponse(**response_data)

@app.get("/health")
async def health():
    return {
        "status": "ready",
        "models": {
            "silero_vad": {"loaded": vad_model is not None},
            "wav2vec2_classifier": {
                "loaded": classifier_model.model is not None if classifier_model else False,
                "device": classifier_model.device if classifier_model else "none",
            },
            "bournemouth_aligner": {"loaded": aligner_model.aligner is not None if aligner_model else False, "preset": "ar"}
        },
        "gpu_available": torch.cuda.is_available()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)
