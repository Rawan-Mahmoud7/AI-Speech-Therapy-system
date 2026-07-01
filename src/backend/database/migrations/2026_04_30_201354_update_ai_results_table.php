<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('ai_results', function (Blueprint $table) {

            // =====================
            // AI CORE METRICS
            // =====================
            $table->boolean('is_correct')->nullable()->after('result');
            $table->float('confidence')->nullable()->after('is_correct');
            $table->float('score')->nullable()->after('confidence');

            // =====================
            // PHONEME DATA
            // =====================
            $table->string('target_phoneme')->nullable()->after('score');
            $table->string('predicted_phoneme')->nullable()->after('target_phoneme');
            $table->integer('therapy_level')->nullable()->after('predicted_phoneme');

            // =====================
            // VOICE ANALYSIS (VAD)
            // =====================
            $table->integer('speech_start_ms')->nullable()->after('therapy_level');
            $table->integer('speech_end_ms')->nullable()->after('speech_start_ms');
            $table->integer('speech_duration_ms')->nullable()->after('speech_end_ms');

            // =====================
            // PERFORMANCE
            // =====================
            $table->integer('processing_time_ms')->nullable()->after('speech_duration_ms');

            // =====================
            // ADVANCED AI DATA
            // =====================
            $table->json('top_predictions')->nullable()->after('processing_time_ms');
            $table->json('raw_response')->nullable()->after('top_predictions');
        });
    }

    public function down(): void
    {
        Schema::table('ai_results', function (Blueprint $table) {

            $table->dropColumn([
                'is_correct',
                'confidence',
                'score',
                'target_phoneme',
                'predicted_phoneme',
                'therapy_level',
                'speech_start_ms',
                'speech_end_ms',
                'speech_duration_ms',
                'processing_time_ms',
                'top_predictions',
                'raw_response'
            ]);
        });
    }
};