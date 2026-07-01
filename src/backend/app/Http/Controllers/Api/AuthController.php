<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Doctor;
use App\Models\Patient;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class AuthController extends Controller
{
    
    // REGISTER
    
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:6|confirmed',
            'role' => 'required|in:doctor,patient',
            'doctor_id' => 'nullable|exists:doctors,id',
        ]);

        DB::beginTransaction();

        try {

            // create user
            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'role' => $request->role,
            ]);

            $doctor = null;
            $patientId = null;

            // doctor
            if ($request->role === 'doctor') {
                $doctor = Doctor::create([
                    'user_id' => $user->id,
                    'name' => $request->name,
                ]);
            }

            // patient
            if ($request->role === 'patient') {
                $patient = Patient::create([
                    'user_id' => $user->id,
                    'doctor_id' => $request->doctor_id ?? null,
                    'name' => $request->name,
                ]);

                $patientId = $patient->id; // 👈 إضافة جديدة
            }

            DB::commit();

            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'message' => 'User registered successfully',
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'role' => $user->role
                ],
                'doctor_id' => $doctor?->id,
                'patient_id' => $patientId, 
                'token' => $token
            ]);

        } catch (\Exception $e) {

            DB::rollBack();

            return response()->json([
                'message' => 'Error in registration',
                'error' => $e->getMessage()
            ], 500);
        }
    }


    // LOGIN
    
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required'
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Invalid email or password'
            ], 401);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        // doctor id
        $doctorId = null;

        if ($user->role === 'doctor') {
            $doctorId = Doctor::where('user_id', $user->id)->value('id');
        }

        // patient id
        $patientId = null;

        if ($user->role === 'patient') {
            $patientId = Patient::where('user_id', $user->id)->value('id');
        }

        return response()->json([
            'message' => 'Login successful',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'role' => $user->role
            ],
            'doctor_id' => $doctorId,
            'patient_id' => $patientId, 
            'token' => $token
        ]);
    }
}