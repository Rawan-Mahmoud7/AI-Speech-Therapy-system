<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AudioRecord;
use App\Models\AiResult;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AIController extends Controller
{
    public function analyze($audio_id)
    {
        DB::beginTransaction();

        try {

            // GET AUDIO + SESSION
            $audio = AudioRecord::with('session')->find($audio_id);

            if (!$audio || !$audio->session) {

                DB::rollBack();

                return response()->json([
                    'status' => false,
                    'message' => 'Audio or Session not found'
                ], 404);
            }

            $session = $audio->session;
            
            $level = (int) $session->level;

        
            // CHECK AUDIO FILE
    
            $audioPath = storage_path(
                'app/public/' . ltrim($audio->file_path, '/')
            );

            if (!file_exists($audioPath)) {

                DB::rollBack();

                return response()->json([
                    'status' => false,
                    'message' => 'Audio file not found',
                ], 404);
            }

        
            // GET DATA FROM DB
            
            $expectedText = trim($audio->expected_text ?? '');

            $targetPhoneme = trim($audio->target_phoneme ?? '');

            // VALIDATION
            // levels 1-2
            if ($level <= 2 && !$targetPhoneme) {

                DB::rollBack();

                return response()->json([
                    'status' => false,
                    'message' => 'target_phoneme is required for levels 1 and 2'
                ], 422);
            }

            // levels 3-4
            if ($level >= 3 && !$expectedText) {

                DB::rollBack();

                return response()->json([
                    'status' => false,
                    'message' => 'expected_text is required for levels 3 and 4'
                ], 422);
            }

            // BUILD AI REQUEST
            $data = [
                'therapy_level' => $level,
                'target_phoneme' => $targetPhoneme,
            ];

            // expected_text only for levels 3-4
            if ($level >= 3) {

                $data['expected_text'] = $expectedText;
            }

            Log::info('SENDING TO AI', $data);
            // CALL AI
            $response = Http::timeout(120)
                ->attach(
                    'audio_file',
                    file_get_contents($audioPath),
                    basename($audioPath)
                )
                ->post(
                    'https://rawan7-nutqi-ai-service.hf.space/evaluate',
                    $data
                );

            Log::info('AI STATUS', [
                'status' => $response->status()
            ]);

            Log::info('AI BODY', [
                'body' => $response->body()
            ]);

            // CHECK RESPONSE STATUS
            if (!$response->successful()) {

                DB::rollBack();

                return response()->json([
                    'status' => false,
                    'message' => 'AI service failed',
                    'ai_response' => $response->body()
                ], 500);
            }

            // PARSE RESPONSE
            $aiData = $response->json();

            if (!is_array($aiData)) {

                DB::rollBack();

                return response()->json([
                    'status' => false,
                    'message' => 'Invalid AI response',
                    'raw_response' => $response->body()
                ], 500);
            }

        
            // HANDLE AI ERRORS
            if (isset($aiData['detail'])) {

                DB::rollBack();

                return response()->json([
                    'status' => false,
                    'message' => $aiData['detail']['message'] ?? 'AI error',
                    'error' => $aiData['detail']
                ], 400);
            }

            // PROCESS AI RESULT
            $isCorrect = $aiData['is_correct'] ?? false;

            $confidence = (float) ($aiData['confidence'] ?? 0);

            $score = round($confidence * 100, 2);

            $predicted = $aiData['predicted_phoneme'] ?? null;

            $result = $isCorrect ? 'success' : 'fail';
            // SAVE AI RESULT
            $resultModel = AiResult::create([

                'audio_record_id' => $audio->id,

                'result' => $result,

                'is_correct' => $isCorrect,

                'confidence' => $confidence,

                'score' => $score,

                'feedback' => $isCorrect
                    ? 'Great pronunciation 🎉'
                    : 'Try again and focus on pronunciation',

                'target_text' => $expectedText,

                'predicted_phoneme' => $predicted,

                'therapy_level' => $level,

                // VAD DETAILS
                'speech_start_ms' =>
                    $aiData['details']['vad']['speech_start_ms'] ?? null,

                'speech_end_ms' =>
                    $aiData['details']['vad']['speech_end_ms'] ?? null,

                'speech_duration_ms' =>
                    $aiData['details']['vad']['speech_duration_ms'] ?? null,

                // PROCESSING TIME
        
                'processing_time_ms' =>
                    $aiData['details']['processing_time_ms'] ?? null,

                // CLASSIFICATION
                'top_predictions' =>
                    isset($aiData['details']['classification']['top_predictions'])
                    ? json_encode(
                        $aiData['details']['classification']['top_predictions']
                    )
                    : null,

                
                'raw_response' => json_encode($aiData),
            ]);

        
            // UPDATE AUDIO
            $audio->update([
                'ai_status' => 'success',
                'accuracy_score' => $score,
                'recognized_text' => $predicted,
            ]);

            DB::commit();

            // SUCCESS RESPONSE
        
            return response()->json([
                'status' => true,
                'message' => 'AI processed successfully',

                'data' => [
                    'audio_id' => $audio->id,

                    'session_id' => $session->id,

                    'therapy_level' => $level,

                    'target_phoneme' => $targetPhoneme,

                    'expected_text' => $expectedText,

                    'is_correct' => $isCorrect,

                    'result' => $result,

                    'score' => $score,

                    'confidence' => $confidence,

                    'predicted_phoneme' => $predicted,

                    'ai_result_id' => $resultModel->id,
                ]
            ]);

        } catch (\Exception $e) {

            DB::rollBack();

            Log::error('AI PROCESS ERROR', [
                'message' => $e->getMessage(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'status' => false,
                'message' => 'AI processing failed',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}