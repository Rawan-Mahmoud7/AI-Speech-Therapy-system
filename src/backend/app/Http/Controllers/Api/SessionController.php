<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\PatientSession;
use App\Models\Patient;

class SessionController extends Controller
{
    // CREATE SESSION
    public function store(Request $request)
    {
        $request->validate([
            'level' => 'nullable|integer|in:1,2,3,4'
        ]);

        $user = auth()->user();

        if (!$user) {
            return response()->json([
                'status' => false,
                'message' => 'Unauthenticated'
            ], 401);
        }

        $patient = Patient::where('user_id', $user->id)->first();

        if (!$patient) {
            return response()->json([
                'status' => false,
                'message' => 'Patient profile not found'
            ], 404);
        }

        $session = PatientSession::create([
            'patient_id' => $patient->id,
            'level' => $request->level ?? 1,
            'success_count' => 0,
            'fail_count' => 0,
            'status' => 'active',
        ]);

        return response()->json([
            'status' => true,
            'message' => 'Session created successfully',
            'data' => $session
        ]);
    }

    // GET ALL SESSIONS FOR PATIENT
    
    public function index()
    {
        $user = auth()->user();

        if (!$user) {
            return response()->json([
                'status' => false,
                'message' => 'Unauthenticated'
            ], 401);
        }

        $patient = Patient::where('user_id', $user->id)->first();

        if (!$patient) {
            return response()->json([
                'status' => false,
                'message' => 'Patient not found'
            ], 404);
        }

        $sessions = PatientSession::with('audioRecords')
            ->where('patient_id', $patient->id)
            ->latest()
            ->get();

        $data = $sessions->map(function ($session) {

            $total = $session->success_count + $session->fail_count;

            return [
                'session' => [
                    'id' => $session->id,
                    'level' => $session->level,
                    'status' => $session->status,
                    'created_at' => $session->created_at->toDateTimeString(),
                ],

                'stats' => [
                    'total_attempts' => $total,
                    'success_count' => $session->success_count,
                    'fail_count' => $session->fail_count,
                    'success_rate' => $total > 0
                        ? round(($session->success_count / $total) * 100, 2)
                        : 0,

                    'doctor_feedback' => $session->doctor_feedback ?? null,
                ],

                'records' => $session->audioRecords->map(function ($audio) {
                    return [
                        'id' => $audio->id,
                        'expected_text' => $audio->expected_text,
                        'target_phoneme' => $audio->target_phoneme,
                        'recognized_text' => $audio->recognized_text,
                        'accuracy_score' => $audio->accuracy_score,
                        'ai_status' => $audio->ai_status,
                        'is_correct' => $audio->accuracy_score >= 70,
                        'file_url' => url('storage/' . $audio->file_path),
                        'created_at' => $audio->created_at->format('H:i'),
                    ];
                }),
            ];
        });

        return response()->json([
            'status' => true,
            'data' => $data
        ]);
    }

    // GET SINGLE SESSION
    
    public function show($id)
    {
        $user = auth()->user();

        if (!$user) {
            return response()->json([
                'status' => false,
                'message' => 'Unauthenticated'
            ], 401);
        }

        $patient = Patient::where('user_id', $user->id)->first();

        if (!$patient) {
            return response()->json([
                'status' => false,
                'message' => 'Patient not found'
            ], 404);
        }

        $session = PatientSession::with('audioRecords')
            ->where('id', $id)
            ->where('patient_id', $patient->id)
            ->first();

        if (!$session) {
            return response()->json([
                'status' => false,
                'message' => 'Session not found'
            ], 404);
        }

        $total = $session->success_count + $session->fail_count;

        return response()->json([
            'status' => true,
            'data' => [

                'session' => [
                    'id' => $session->id,
                    'level' => $session->level,
                    'status' => $session->status,
                    'created_at' => $session->created_at->toDateTimeString(),
                ],

                'stats' => [
                    'total_attempts' => $total,
                    'success_count' => $session->success_count,
                    'fail_count' => $session->fail_count,
                    'success_rate' => $total > 0
                        ? round(($session->success_count / $total) * 100, 2)
                        : 0,

                    'doctor_feedback' => $session->doctor_feedback ?? null,
                ],

                'records' => $session->audioRecords->map(function ($audio) {
                    return [
                        'id' => $audio->id,
                        'expected_text' => $audio->expected_text,
                        'target_phoneme' => $audio->target_phoneme,
                        'recognized_text' => $audio->recognized_text,
                        'accuracy_score' => $audio->accuracy_score,
                        'is_correct' => $audio->accuracy_score >= 70,
                        'file_url' => url('storage/' . $audio->file_path),
                        'created_at' => $audio->created_at->format('H:i'),
                    ];
                }),
            ]
        ]);
    }

   
    // UPDATE DOCTOR FEEDBACK
    
    public function updateDoctorFeedback(Request $request, $id)
    {
        $request->validate([
            'doctor_feedback' => 'required|string|max:2000'
        ]);

        $user = auth()->user();

        if (!$user || $user->role !== 'doctor') {
            return response()->json([
                'status' => false,
                'message' => 'Unauthorized'
            ], 403);
        }

        $session = PatientSession::find($id);

        if (!$session) {
            return response()->json([
                'status' => false,
                'message' => 'Session not found'
            ], 404);
        }

        $session->update([
            'doctor_feedback' => $request->doctor_feedback
        ]);

        return response()->json([
            'status' => true,
            'message' => 'Doctor feedback updated successfully',
            'data' => $session
        ]);
    }

    
    // GET DOCTOR FEEDBACK
   
    public function getDoctorFeedback($session_id)
    {
        $session = PatientSession::find($session_id);

        if (!$session) {
            return response()->json([
                'status' => false,
                'message' => 'Session not found'
            ], 404);
        }

        return response()->json([
            'status' => true,
            'data' => [
                'doctor_feedback' => $session->doctor_feedback
            ]
        ]);
    }
}