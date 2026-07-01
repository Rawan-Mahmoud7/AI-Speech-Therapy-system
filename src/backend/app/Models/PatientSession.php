<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PatientSession extends Model
{
    use HasFactory;

    protected $fillable = [
        'patient_id',
        'level',
        'success_count',
        'fail_count',
        'doctor_feedback',
        'status',
    ];

    // AUTO APPENDED ATTRIBUTES
    protected $appends = [
        'success_rate'
    ];

    // RELATIONS

    public function patient()
    {
        return $this->belongsTo(Patient::class);
    }

    public function audioRecords()
    {
        return $this->hasMany(AudioRecord::class, 'session_id');
    }

    public function doctor()
    {
        return $this->hasOneThrough(
            Doctor::class,
            Patient::class,
            'id',         // patients.id
            'id',         // doctors.id
            'patient_id', // sessions.patient_id
            'doctor_id'   // patients.doctor_id
        );
    }

    
    // ACCESSORS
    

    public function getSuccessRateAttribute()
    {
        $total = $this->success_count + $this->fail_count;

        return $total > 0
            ? round(($this->success_count / $total) * 100, 2)
            : 0;
    }

    
    // BUSINESS LOGIC
   

    public function shouldLevelUp(): bool
    {
        return $this->success_rate >= 80;
    }
}