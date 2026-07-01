<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use App\Models\AudioRecord;
use App\Models\PatientSession;

class AudioRecordController extends Controller
{
    
    // UPLOAD ONLY (NO AI)
    
    public function store(Request $request)
    {
        try {

        
            // VALIDATION
           
            $request->validate([
                'session_id' => 'required|exists:patient_sessions,id',
                'audio' => 'required|file',

               
                'expected_text' => 'nullable|string',
                'target_phoneme' => 'nullable|string',
            ]);

            Log::info("UPLOAD HIT", [
                'session_id' => $request->session_id
            ]);

        
            // GET SESSION
            $session = PatientSession::find($request->session_id);

            if (!$session) {
                return response()->json([
                    'status' => false,
                    'message' => 'Session not found'
                ], 404);
            }

            $level = (int) $session->level;

            // LEVEL VALIDATION
            // levels 1-2 => phoneme required
            if ($level <= 2 && !$request->target_phoneme) {

                return response()->json([
                    'status' => false,
                    'message' => 'target_phoneme is required for levels 1 and 2'
                ], 422);
            }

            // levels 3-4 => expected_text required
            if ($level >= 3 && !$request->expected_text) {

                return response()->json([
                    'status' => false,
                    'message' => 'expected_text is required for levels 3 and 4'
                ], 422);
            }
            // CHECK FILE
            if (!$request->hasFile('audio')) {

                return response()->json([
                    'status' => false,
                    'message' => 'No audio file received'
                ], 400);
            }

            $file = $request->file('audio');
            // STORE FILE
            
            $path = $file->storeAs(
                'audio_files/' . $session->id,
                $session->id . '_' . time() . '.' . $file->getClientOriginalExtension(),
                'public'
            );

            // SAVE RECORD
          
            $audio = AudioRecord::create([
                'session_id' => $session->id,

                'file_path' => $path,

                // level 3-4
                'expected_text' => $request->expected_text,

                // level 1-2
                'target_phoneme' => $request->target_phoneme,

                'ai_status' => 'pending',
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Audio uploaded successfully',

                'data' => $audio,

                'file_url' => url('storage/' . $path),
            ]);

        } catch (\Exception $e) {

            Log::error("UPLOAD ERROR: " . $e->getMessage());

            return response()->json([
                'status' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    
    // GET AUDIO BY SESSION
    
    public function index($sessionId)
    {
        $audios = AudioRecord::where('session_id', $sessionId)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => true,
            'data' => $audios
        ]);
    }
}