<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

use App\Models\PatientSession;
use App\Models\AudioRecord;
use App\Models\AiResult;

class Patient extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'doctor_id',
        'name',
        'age',
        'gender',
        'speech_disorder',
        'severity',
        'level',
        'started_at',
        'status',
    ];

    
    // User
    
    public function user()
    {
        return $this->belongsTo(User::class);
    }
    public function doctor()
{
    return $this->belongsTo(Doctor::class);
}

    
    // Sessions
   
    public function sessions()
    {
        return $this->hasMany(PatientSession::class);
    }

    
    //  Audio
    
    public function audioRecords()
    {
        return $this->hasManyThrough(
            AudioRecord::class,
            PatientSession::class,
            'patient_id',
            'session_id'
        );
    }

    
    // AI results (through audio)
    
    public function aiResults()
    {
        return $this->hasManyThrough(
            AiResult::class,
            AudioRecord::class,
            'session_id',
            'audio_record_id'
        );
 
       }
       public function basicInfo($id)
{
    $patient = Patient::with('user:id,name,email')
        ->find($id);

    if (!$patient) {
        return response()->json([
            'status' => false,
            'message' => 'Patient not found'
        ], 404);
    }

    return response()->json([
        'status' => true,
        'message' => 'Patient basic info fetched successfully',
        'data' => [
            'id' => $patient->id,
            'name' => $patient->user->name,
            'email' => $patient->user->email,

            //  المطلوب
            'age' => $patient->age,
            'gender' => $patient->gender,
            'speech_disorder_type' => $patient->speech_disorder_type,
        ]
    ]);
}
}