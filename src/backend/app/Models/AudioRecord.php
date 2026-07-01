<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AudioRecord extends Model
{
    use HasFactory;

    protected $fillable = [
        'session_id',
        'file_path',
        'duration',
        'expected_text',      // ✅ لازم تضيفيها
        'recognized_text',
        'accuracy_score',
        'ai_status',
        'target_phoneme',
    ];

   
    //  Relationships
    

    public function session()
    {
        return $this->belongsTo(PatientSession::class, 'session_id');
    }

    public function aiResult()
    {
        return $this->hasOne(AiResult::class);
    }

    
    

    // =========================
    // 🔥 Helpers
    // =========================

    public function isAnalyzed()
    {
        return $this->ai_status !== 'pending';
    }

    public function isSuccess()
    {
        return $this->ai_status === 'success';
    }

    public function isFail()
    {
        return $this->ai_status === 'fail';
    }
}