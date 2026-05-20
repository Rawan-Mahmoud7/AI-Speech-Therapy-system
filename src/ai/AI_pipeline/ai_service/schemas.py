from pydantic import BaseModel
from typing import List, Optional, Any

# ==========================================
# Common AI Response Schemas
# ==========================================

class VadDetails(BaseModel):
    speech_detected: bool
    speech_start_ms: float
    speech_end_ms: float
    speech_duration_ms: float

class TopPrediction(BaseModel):
    phoneme: str
    confidence: float

class ClassificationDetails(BaseModel):
    predicted_phoneme: str
    confidence: float
    top_predictions: List[TopPrediction]

class TargetPhonemeOccurrence(BaseModel):
    ipa_label: str
    position_in_word: str
    start_ms: float
    end_ms: float
    confidence: float
    is_estimated: bool
    is_correct: bool

class AlignedPhoneme(BaseModel):
    ipa_label: str
    start_ms: float
    end_ms: float
    confidence: float

class AlignmentDetails(BaseModel):
    expected_text: str
    phoneme_count: int
    target_phoneme_occurrences: List[TargetPhonemeOccurrence]
    all_phonemes: List[AlignedPhoneme]
    coverage_ratio: float
    bad_confidence: bool

class ErrorAnalysis(BaseModel):
    error_type: str
    expected_phoneme: str
    produced_phoneme: str
    is_common_error: bool
    clinical_category: Optional[str]
    description: str

class ProcessingDetails(BaseModel):
    vad: Optional[VadDetails] = None
    classification: Optional[ClassificationDetails] = None
    alignment: Optional[AlignmentDetails] = None
    processing_time_ms: float

class EvaluationResponse(BaseModel):
    is_correct: bool
    confidence: float
    predicted_phoneme: str
    target_phoneme: str
    therapy_level: int
    details: ProcessingDetails
    error_analysis: Optional[ErrorAnalysis] = None
