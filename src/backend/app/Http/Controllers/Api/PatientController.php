<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Patient;
use Illuminate\Http\Request;

class PatientController extends Controller
{
    
    //  GET ALL PATIENTS
    public function index()
    {
        $patients = Patient::with([
            'user:id,name,email',
            'doctor.user:id,name,email'
        ])->get();

        return response()->json([
            'status' => true,
            'message' => 'Patients fetched successfully',
            'data' => $patients->map(function ($p) {

                return [
                    'id' => $p->id,
                    'name' => $p->user->name ?? null,
                    'email' => $p->user->email ?? null,

                    'age' => $p->age,
                    'gender' => $p->gender,

                    // speech issue
                    'speech_disorder' => $p->speech_disorder ?? 'N/A',

                    // doctor info
                    'doctor' => [
                        'id' => $p->doctor->id ?? null,
                        'name' => $p->doctor->user->name ?? null
                    ]
                ];
            })
        ]);
    }

    
    //PATIENT PROFILE 
   
    public function profile(Request $request)
    {
        $user = $request->user();

        $patient = Patient::with([
            'user:id,name,email',
            'doctor.user:id,name,email'
        ])->where('user_id', $user->id)->first();

        if (!$patient) {
            return response()->json([
                'status' => false,
                'message' => 'Patient not found'
            ], 404);
        }

        return response()->json([
            'status' => true,
            'message' => 'Patient profile fetched successfully',
            'data' => [
                'id' => $patient->id,
                'user_id' => $patient->user_id,

                'name' => $patient->user->name,
                'email' => $patient->user->email,

                'age' => $patient->age,
                'gender' => $patient->gender,

                'speech_disorder' => $patient->speech_disorder,

                'doctor' => $patient->doctor ? [
                    'id' => $patient->doctor->id,
                    'name' => $patient->doctor->user->name ?? null
                ] : null
            ]
        ]);
    }

    // UPDATE PATIENT PROFILE
   
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $patient = Patient::where('user_id', $user->id)->first();

        if (!$patient) {
            return response()->json([
                'status' => false,
                'message' => 'Patient not found'
            ], 404);
        }

        $request->validate([
            'age' => 'nullable|integer',
            'gender' => 'nullable|in:male,female',
            'speech_disorder' => 'nullable|string',
        ]);

        $patient->update([
            'age' => $request->age ?? $patient->age,
            'gender' => $request->gender ?? $patient->gender,
            'speech_disorder' => $request->speech_disorder ?? $patient->speech_disorder,
        ]);

        return response()->json([
            'status' => true,
            'message' => 'Patient profile updated successfully',
            'data' => $patient
        ]);
    }

    //  BASIC INFO
   
    public function basicInfo(Request $request)
    {
        $user = $request->user();

        $patient = Patient::with('user:id,name,email')
            ->where('user_id', $user->id)
            ->first();

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
            ]
        ]);
    }
}