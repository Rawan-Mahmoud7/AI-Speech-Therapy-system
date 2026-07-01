<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use Carbon\Carbon;

class ForgotPasswordController extends Controller
{
    //SEND OTP
    public function sendOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email|exists:users,email'
        ]);

        try {

            $otp = rand(100000, 999999);

            DB::table('password_otps')->updateOrInsert(
                ['email' => $request->email],
                [
                    'otp' => $otp,
                    'expires_at' => Carbon::now()->addMinutes(30),
                    'updated_at' => now()
                ]
            );

            return response()->json([
                'status' => true,
                'message' => 'OTP sent successfully',
                'otp' => $otp,
                'expires_in_minutes' => 30
            ]);

        } catch (\Exception $e) {

            return response()->json([
                'status' => false,
                'message' => 'Failed to send OTP',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    
    // VERIFY OTP
    public function verifyOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required'
        ]);

        $record = DB::table('password_otps')
            ->where('email', $request->email)
            ->first();

        if (!$record) {
            return response()->json([
                'status' => false,
                'message' => 'OTP not found'
            ], 404);
        }

        
        if (Carbon::now()->gt($record->expires_at)) {
            return response()->json([
                'status' => false,
                'message' => 'OTP expired'
            ], 400);
        }

        if ($record->otp != $request->otp) {
            return response()->json([
                'status' => false,
                'message' => 'Invalid OTP'
            ], 400);
        }

        return response()->json([
            'status' => true,
            'message' => 'OTP verified successfully'
        ]);
    }
    // RESET PASSWORD
    
    public function resetWithOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email|exists:users,email',
            'otp' => 'required',
            'password' => 'required|min:6|confirmed'
        ]);

        try {

            $record = DB::table('password_otps')
                ->where('email', $request->email)
                ->first();

            if (!$record) {
                return response()->json([
                    'status' => false,
                    'message' => 'OTP not found'
                ], 404);
            }

            
            if (Carbon::now()->gt($record->expires_at)) {
                return response()->json([
                    'status' => false,
                    'message' => 'OTP expired'
                ], 400);
            }

            if ($record->otp != $request->otp) {
                return response()->json([
                    'status' => false,
                    'message' => 'Invalid OTP'
                ], 400);
            }

            $user = User::where('email', $request->email)->first();

            if (!$user) {
                return response()->json([
                    'status' => false,
                    'message' => 'User not found'
                ], 404);
            }

            $user->update([
                'password' => Hash::make($request->password)
            ]);

            //delete OTP after success
            DB::table('password_otps')
                ->where('email', $request->email)
                ->delete();

            return response()->json([
                'status' => true,
                'message' => 'Password reset successful'
            ]);

        } catch (\Exception $e) {

            return response()->json([
                'status' => false,
                'message' => 'Reset failed',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}