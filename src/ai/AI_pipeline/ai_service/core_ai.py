import os
import time
import torch
import torchaudio
import soundfile as sf
import numpy as np
import logging

# Monkey-patch torchaudio.load to bypass torchcodec (ffmpeg) completely on Windows
def _custom_torchaudio_load(filepath, *args, **kwargs):
    wav, sr = sf.read(filepath, dtype='float32')
    if wav.ndim == 1:
        wav = wav[:, np.newaxis]
    wav = wav.T # channels first
    return torch.from_numpy(wav), sr

torchaudio.load = _custom_torchaudio_load

from transformers import AutoModelForAudioClassification, AutoFeatureExtractor

logger = logging.getLogger("ai_service.core_ai")

# ---------------------------------------------------------
# Constants & Phoneme Mapping
# ---------------------------------------------------------
TARGET_PHONEMES = ["ث", "ر", "س", "ش", "ل", "و", "ي"]
ID2LABEL = {i: label for i, label in enumerate(TARGET_PHONEMES)}
LABEL2ID = {label: i for i, label in enumerate(TARGET_PHONEMES)}

PHONEME_MAP = {
    "ث": {"ipa": "θ"}, "ر": {"ipa": "r"}, "س": {"ipa": "s"},
    "ش": {"ipa": "ʃ"}, "ل": {"ipa": "l"}, "و": {"ipa": "w"}, "ي": {"ipa": "j"},
}

COMMON_SUBSTITUTIONS = {
    ("ر", "ل"): {"category": "lateral_substitution_for_rhotic", "desc": "Lateral /l/ produced instead of trill /r/."},
    ("ر", "و"): {"category": "glide_substitution_for_rhotic", "desc": "Glide /w/ produced instead of trill /r/."},
    ("س", "ش"): {"category": "retraction_of_sibilant", "desc": "Postalveolar /ʃ/ produced instead of alveolar /s/."},
    ("ش", "س"): {"category": "fronting_of_sibilant", "desc": "Alveolar /s/ produced instead of postalveolar /ʃ/."},
    ("ث", "س"): {"category": "stopping_or_fronting_of_dental", "desc": "Alveolar /s/ produced instead of dental /θ/."},
    ("ث", "ت"): {"category": "stopping_of_dental_fricative", "desc": "Stop /t/ produced instead of fricative /θ/."},
}

# ---------------------------------------------------------
# Voice Activity Detection (Silero VAD)
# ---------------------------------------------------------
class SileroVAD:
    def __init__(self):
        logger.info("Loading Silero VAD...")
        self.model, utils = torch.hub.load(repo_or_dir='snakers4/silero-vad', model='silero_vad', force_reload=False)
        self.get_speech_timestamps = utils[0]

    def process(self, audio_array: np.ndarray, sample_rate: int = 16000):
        tensor_audio = torch.FloatTensor(audio_array)
        # Suppress prints from silero
        timestamps = self.get_speech_timestamps(tensor_audio, self.model, sampling_rate=sample_rate)
        
        if not timestamps:
            return None
            
        start_sample = timestamps[0]['start']
        end_sample = timestamps[-1]['end']
        
        start_ms = (start_sample / sample_rate) * 1000
        end_ms = (end_sample / sample_rate) * 1000
        duration_ms = end_ms - start_ms
        
        # Trim audio
        trimmed_audio = audio_array[start_sample:end_sample]
        
        return {
            "trimmed_audio": trimmed_audio,
            "start_ms": start_ms,
            "end_ms": end_ms,
            "duration_ms": duration_ms
        }

# ---------------------------------------------------------
# Phoneme Classifier (Wav2Vec2)
# ---------------------------------------------------------
class PhonemeClassifier:
    def __init__(self, model_path: str = r"C:\Users\pc\OneDrive\Desktop\Grad-project-implement\ai_service\best_model"):
        self.device = "cuda:0" if torch.cuda.is_available() else "cpu"
        logger.info(f"Loading Wav2Vec2 Classifier on {self.device}...")
        try:
            self.feature_extractor = AutoFeatureExtractor.from_pretrained(model_path)
            # ignore_mismatched_sizes handles loading our fine-tuned weights properly
            self.model = AutoModelForAudioClassification.from_pretrained(
                model_path, num_labels=len(TARGET_PHONEMES), ignore_mismatched_sizes=True
            ).eval().to(self.device)
            if self.device.startswith("cuda"):
                self.model = self.model.half()
        except Exception as e:
            logger.error(f"Failed to load classifier from {model_path}: {e}")
            self.model = None

    @torch.no_grad()
    def predict(self, audio: np.ndarray, sample_rate: int = 16000):
        if self.model is None:
            raise RuntimeError("Classifier model not loaded.")
            
        inputs = self.feature_extractor(
            audio, sampling_rate=sample_rate, max_length=sample_rate,
            truncation=True, padding="max_length", return_tensors="pt"
        )
        iv = inputs.input_values.to(self.device)
        if self.device.startswith("cuda"):
            iv = iv.half()
            
        logits = self.model(iv).logits
        probs = torch.nn.functional.softmax(logits.float(), dim=-1).squeeze().cpu().numpy()
        
        pid = int(probs.argmax())
        top_ids = probs.argsort()[::-1][:3]
        
        return {
            "predicted_phoneme": ID2LABEL[pid],
            "confidence": round(float(probs[pid]), 4),
            "top_predictions": [
                {"phoneme": ID2LABEL[int(i)], "confidence": round(float(probs[i]), 4)}
                for i in top_ids
            ]
        }

# ---------------------------------------------------------
# Forced Aligner (Bournemouth)
# ---------------------------------------------------------
class ForcedAligner:
    def __init__(self):
        logger.info("Loading Bournemouth Forced Aligner...")
        try:
            from bournemouth_aligner import PhonemeTimestampAligner
            self.aligner = PhonemeTimestampAligner(preset="ar")
        except ImportError:
            logger.warning("bournemouth_aligner not installed. Falling back to mock aligner.")
            self.aligner = None

    def align(self, audio_array: np.ndarray, expected_text: str, sample_rate: int = 16000):
        if self.aligner is None:
            return self._mock_align(expected_text)
            
        # Aligner expects a specific format or path. 
        # BFA can take a path or raw audio (if supported, assuming it takes raw audio).
        # We will write to a temp file since BFA load_audio handles paths best in the standard API.
        import tempfile
        import soundfile as sf
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            sf.write(tmp.name, audio_array, sample_rate)
            tmp_path = tmp.name
            
        try:
            audio_obj = self.aligner.load_audio(tmp_path)
            result = self.aligner.process_sentence(expected_text, audio_obj)
            return result
        finally:
            os.unlink(tmp_path)
            
    def _mock_align(self, text: str):
        # Fallback if BFA is missing locally
        chars = list(text.replace(" ", ""))
        return {
            "segments": [{
                "text": text,
                "phoneme_ts": [
                    {
                        "phoneme_label": c, "ipa_label": c, 
                        "start_ms": i*100.0, "end_ms": (i+1)*100.0,
                        "confidence": 0.88, "is_estimated": False
                    } for i, c in enumerate(chars)
                ],
                "coverage_analysis": {
                    "target_count": len(chars), "aligned_count": len(chars),
                    "coverage_ratio": 1.0, "bad_confidence": False
                }
            }]
        }

# ---------------------------------------------------------
# Analysis Utilities
# ---------------------------------------------------------
def generate_error_analysis(expected: str, predicted: str):
    sub = COMMON_SUBSTITUTIONS.get((expected, predicted))
    if sub:
        return {
            "error_type": "substitution",
            "expected_phoneme": expected,
            "produced_phoneme": predicted,
            "is_common_error": True,
            "clinical_category": sub["category"],
            "description": sub["desc"]
        }
    return {
        "error_type": "substitution",
        "expected_phoneme": expected,
        "produced_phoneme": predicted,
        "is_common_error": False,
        "clinical_category": None,
        "description": f"Target /{PHONEME_MAP.get(expected, {}).get('ipa', expected)}/ produced as /{PHONEME_MAP.get(predicted, {}).get('ipa', predicted)}/."
    }
