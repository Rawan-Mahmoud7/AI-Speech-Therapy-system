<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Doctor extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'specialization',
        'experience_years',
        'age',
    ];

    //  user
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // patients
    public function patients()
    {
        return $this->hasMany(Patient::class);
    }
}