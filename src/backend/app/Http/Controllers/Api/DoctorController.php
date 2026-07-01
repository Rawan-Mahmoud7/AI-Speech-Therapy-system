<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Doctor;
use Illuminate\Http\Request;

class DoctorController extends Controller
{
    // GET ALL DOCTORS (PUBLIC)
    
    public function index()
    {
        $doctors = Doctor::with('user:id,name,email')
            ->get([
                'id',
                'user_id',
                'specialization',
                'experience_years',
                'age'
            ]);

        return response()->json([
            'status' => true,
            'message' => 'Doctors fetched successfully',
            'data' => $doctors
        ]);
    }

    
    // GET SINGLE DOCTOR (PUBLIC)
    
    public function show($id)
    {
        $doctor = Doctor::with('user:id,name,email')
            ->find($id);

        if (!$doctor) {
            return response()->json([
                'status' => false,
                'message' => 'Doctor not found'
            ], 404);
        }

        return response()->json([
            'status' => true,
            'message' => 'Doctor fetched successfully',
            'data' => $doctor
        ]);
    }

    
    // GET DOCTOR PROFILE (AUTH USER)
    
    public function profile(Request $request)
    {
        $user = $request->user();

        $doctor = Doctor::with('user:id,name,email')
            ->where('user_id', $user->id)
            ->first();

        if (!$doctor) {
            return response()->json([
                'status' => false,
                'message' => 'Doctor not found'
            ], 404);
        }

        return response()->json([
            'status' => true,
            'message' => 'Doctor profile fetched successfully',
            'data' => [
                'id' => $doctor->id,
                'user_id' => $doctor->user_id,
                'name' => $doctor->user->name,
                'email' => $doctor->user->email,
                'age' => $doctor->age,
                'specialization' => $doctor->specialization,
                'experience_years' => $doctor->experience_years
            ]
        ]);
    }

   
    // UPDATE DOCTOR PROFILE 
    
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $doctor = Doctor::where('user_id', $user->id)->first();

        if (!$doctor) {
            return response()->json([
                'status' => false,
                'message' => 'Doctor not found'
            ], 404);
        }

        $request->validate([
            'age' => 'nullable|integer',
            'specialization' => 'nullable|string',
            'experience_years' => 'nullable|integer',
        ]);

        $doctor->update([
            'age' => $request->age ?? $doctor->age,
            'specialization' => $request->specialization ?? $doctor->specialization,
            'experience_years' => $request->experience_years ?? $doctor->experience_years,
        ]);

        return response()->json([
            'status' => true,
            'message' => 'Profile updated successfully',
            'data' => $doctor
        ]);
    }
}