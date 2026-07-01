<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Patient;
use App\Models\Doctor;
use App\Models\AudioRecord;
use App\Models\AiFeedback;
use Illuminate\Support\Carbon;

class DoctorDashboardController extends Controller
{
    
    // DASHBOARD OVERVIEW
   
    public function overview()
    {
        $totalPatients = Patient::count();
        $totalAudios = AudioRecord::count();

        $successAudios = AudioRecord::where('attempt_result', 'success')->count();
        $failAudios = AudioRecord::where('attempt_result', 'fail')->count();

        $successRate = $totalAudios > 0
            ? round(($successAudios / $totalAudios) * 100, 2)
            : 0;

        return response()->json([
            'status' => true,
            'message' => 'Dashboard overview fetched successfully',
            'data' => [
                'total_patients' => $totalPatients,
                'total_audio_records' => $totalAudios,
                'success_rate' => $successRate,
                'success_count' => $successAudios,
                'fail_count' => $failAudios
            ]
        ]);
    }


    // ALL PATIENTS
    
    public function patients()
    {
        $patients = Patient::with('user:id,name,email')->get();

        return response()->json([
            'status' => true,
            'data' => $patients
        ]);
    }

    
    // PATIENTS OVERVIEW
   
    public function patientsOverview($doctor_id)
    {
        $patients = Patient::where('doctor_id', $doctor_id)
            ->with(['user', 'sessions.audioRecords.aiResult'])
            ->get()
            ->map(function ($patient) {

                $lastSession = $patient->sessions
                    ->sortByDesc('created_at')
                    ->first();

                return [
                    'patient_id' => $patient->id,
                    'name' => $patient->user->name ?? 'N/A',
                    'age' => $patient->age ?? null,
                    'speech_disorder' => $patient->speech_disorder ?? 'N/A',
                    'level' => $lastSession?->level ?? 1,
                    'last_session_date' => $lastSession
                        ? $lastSession->created_at->format('Y-m-d')
                        : null,
                    'progress' => $lastSession
                        ? (($lastSession->success_count + $lastSession->fail_count) > 0
                            ? round(
                                ($lastSession->success_count /
                                ($lastSession->success_count + $lastSession->fail_count)) * 100,
                                2
                            )
                            : 0)
                        : 0,
                ];
            });

        return response()->json([
            'status' => true,
            'data' => $patients
        ]);
    }

    
    // SINGLE PATIENT DETAILS
    
    public function patientDetails($id)
    {
        $patient = Patient::with([
            'user:id,name,email',
            'audioRecords',
            'progress'
        ])->find($id);

        if (!$patient) {
            return response()->json([
                'status' => false,
                'message' => 'Patient not found'
            ], 404);
        }

        $totalAudio = $patient->audioRecords->count();
        $success = $patient->audioRecords->where('attempt_result', 'success')->count();
        $fail = $patient->audioRecords->where('attempt_result', 'fail')->count();

        $rate = $totalAudio > 0
            ? round(($success / $totalAudio) * 100, 2)
            : 0;

        return response()->json([
            'status' => true,
            'data' => [
                'patient' => $patient,
                'stats' => [
                    'total_audio' => $totalAudio,
                    'success' => $success,
                    'fail' => $fail,
                    'success_rate' => $rate
                ]
            ]
        ]);
    }

    
    // PATIENT SESSIONS
    
    public function patientSessions($id)
    {
        $user = auth()->user();

        if (!$user || $user->role !== 'doctor') {
            return response()->json([
                'status' => false,
                'message' => 'Unauthorized'
            ], 403);
        }

        $doctor = Doctor::where('user_id', $user->id)->first();

        if (!$doctor) {
            return response()->json([
                'status' => false,
                'message' => 'Doctor profile not found'
            ], 404);
        }

        $patient = Patient::where('id', $id)
            ->where('doctor_id', $doctor->id)
            ->first();

        if (!$patient) {
            return response()->json([
                'status' => false,
                'message' => 'Patient not found'
            ], 404);
        }

        $sessions = $patient->sessions()
            ->with(['audioRecords'])
            ->latest()
            ->get()
            ->map(function ($session) {

                $total = $session->success_count + $session->fail_count;

                return [
                    'id' => $session->id,
                    'level' => $session->level,
                    'status' => $session->status,
                    'created_at' => $session->created_at->toDateTimeString(),

                    'stats' => [
                        'success_count' => $session->success_count,
                        'fail_count' => $session->fail_count,
                        'total' => $total,
                        'success_rate' => $total > 0
                            ? round(($session->success_count / $total) * 100, 2)
                            : 0,
                    ],

                    'records' => $session->audioRecords->map(function ($audio) {
                        return [
                            'id' => $audio->id,
                            'expected_text' => $audio->expected_text,
                            'recognized_text' => $audio->recognized_text,
                            'accuracy_score' => $audio->accuracy_score,
                            'is_correct' => $audio->accuracy_score >= 70,
                            'file_url' => secure_url('storage/' . $audio->file_path),
                            'created_at' => $audio->created_at->format('H:i'),
                        ];
                    }),
                ];
            });

        return response()->json([
            'status' => true,
            'patient' => [
                'id' => $patient->id,
                'name' => $patient->user->name ?? 'N/A',
                'age' => $patient->age,
                'speech_disorder' => $patient->speech_disorder,
            ],
            'data' => $sessions
        ]);
    }

   
    // FEEDBACK
    
    public function addFeedback(Request $request)
    {
        return response()->json([
            'status' => true,
            'message' => 'Feedback feature not active yet'
        ]);
    }
}