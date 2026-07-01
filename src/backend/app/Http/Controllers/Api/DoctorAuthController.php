<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class DoctorAuthController extends Controller
{
    
    // REGISTER DOCTOR
 
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:6'
        ]);

        $doctor = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => 'doctor'
        ]);

        $token = $doctor->createToken('doctor-token')->plainTextToken;

        return response()->json([
            'status' => true,
            'message' => 'Doctor registered successfully',
            'doctor' => $doctor,
            'token' => $token
        ]);
    }

    
    // LOGIN DOCTOR
    
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required'
        ]);

        $doctor = User::where('email', $request->email)
                      ->where('role', 'doctor')
                      ->first();

        if (!$doctor || !Hash::check($request->password, $doctor->password)) {
            return response()->json([
                'status' => false,
                'message' => 'Invalid email or password'
            ], 401);
        }

        $token = $doctor->createToken('doctor-token')->plainTextToken;

        return response()->json([
            'status' => true,
            'message' => 'Login successful',
            'doctor' => $doctor,
            'token' => $token
        ]);
    }

    
    //LOGOUT
   
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'status' => true,
            'message' => 'Logged out successfully'
        ]);
    }
}