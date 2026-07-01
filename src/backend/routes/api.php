<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\PatientController;
use App\Http\Controllers\Api\SessionController;
use App\Http\Controllers\Api\AudioRecordController;
use App\Http\Controllers\Api\AIController;
use App\Http\Controllers\Api\DoctorDashboardController;
use App\Http\Controllers\Api\ForgotPasswordController;
use App\Http\Controllers\Api\DoctorController;

// AUTH
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// DOCTORS (PUBLIC)
Route::get('/doctors', [DoctorController::class, 'index']);
Route::get('/doctors/{id}', [DoctorController::class, 'show']);

// FORGOT PASSWORD
Route::post('/send-otp', [ForgotPasswordController::class, 'sendOtp']);
Route::post('/verify-otp', [ForgotPasswordController::class, 'verifyOtp']);
Route::post('/reset-password', [ForgotPasswordController::class, 'resetWithOtp']);


// AI 
Route::post('/ai/analyze/{audio_id}', [AIController::class, 'analyze']);



Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return response()->json([
            'status' => true,
            'user' => $request->user()
        ]);
    });


    Route::prefix('doctor')->group(function () {

        Route::get('/profile', [DoctorController::class, 'profile']);
        Route::put('/profile', [DoctorController::class, 'updateProfile']);

        Route::get('/patients', [DoctorDashboardController::class, 'patients']);
        Route::get('/patients/{id}', [DoctorDashboardController::class, 'patientDetails']);
        Route::get('/patients/{id}/sessions', [DoctorDashboardController::class, 'patientSessions']);
        
    });

    Route::get('/doctor/{doctor_id}/patients-overview',
        [DoctorDashboardController::class, 'patientsOverview']
    );

    
    Route::prefix('patient')->group(function () {

        // profile
        Route::get('/profile', [PatientController::class, 'profile']);
        Route::put('/profile', [PatientController::class, 'updateProfile']);
        Route::get('/basic-info', [PatientController::class, 'basicInfo']);

        // get all sessions 
        Route::get('/sessions', [SessionController::class, 'index']);

        // get single session
        Route::get('/sessions/{id}', [SessionController::class, 'show']);
    });
    Route::post('/sessions', [SessionController::class, 'store']);

    //  doctor feedback
    Route::put('/sessions/{id}/doctor-feedback', [SessionController::class, 'updateDoctorFeedback']);
    Route::get('/sessions/{id}/doctor-feedback', [SessionController::class, 'getDoctorFeedback']);
    Route::post('/audio/upload', [AudioRecordController::class, 'store']);
    Route::get('/audio/{sessionId}', [AudioRecordController::class, 'index']);


    
   
});