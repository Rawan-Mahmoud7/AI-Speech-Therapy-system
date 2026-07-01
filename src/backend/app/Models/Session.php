<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\AudioRecord;
use App\Models\User;

class Session extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'session_date',
        'notes',
    ];

    // Session belongs to User (NOT Patient)
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // Session has many AudioRecords
    public function audioRecords()
    {
        return $this->hasMany(AudioRecord::class);
    }
}