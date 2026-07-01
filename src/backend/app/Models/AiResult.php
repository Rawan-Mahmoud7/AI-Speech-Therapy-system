<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AiResult extends Model
{
    use HasFactory;

    protected $fillable = [
        'audio_record_id',
    'result',
    'feedback',
    'is_correct',
    'confidence',
    'score',
    'target_phoneme',
    'predicted_phoneme',
    'therapy_level',
    'speech_start_ms',
    'speech_end_ms',
    'speech_duration_ms',
    'processing_time_ms',
    'top_predictions',
    'raw_response'
    ];

    // Relationships
    

    public function audioRecord()
    {
        return $this->belongsTo(AudioRecord::class);
    }

    public function patient()
    {
        return $this->hasOneThrough(
            Patient::class,
            AudioRecord::class,
            'id',
            'id',
            'audio_record_id',
            'session_id'
        );
    }

    
    // Helpers
    

    public function isSuccess()
    {
        return $this->result === 'success';
    }

    public function isFail()
    {
        return $this->result === 'fail';
    }
}