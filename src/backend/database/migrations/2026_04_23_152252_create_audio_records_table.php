<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('audio_records', function (Blueprint $table) {
            $table->id();

            // 🔗 مرتبط بالـ session فقط (مش patient مباشرة)
            $table->foreignId('session_id')
                ->constrained('patient_sessions')
                ->cascadeOnDelete();

            // 🎧 ملف الصوت
            $table->string('file_path');

            // ⏱ مدة التسجيل (اختياري)
            $table->integer('duration')->nullable();

            // 🧠 النص المتوقع والناتج من AI
            $table->text('expected_text');
            $table->text('recognized_text')->nullable();

            // 📊 نتيجة الـ AI
            $table->float('accuracy_score')->nullable();

            // 🤖 حالة التحليل
            $table->enum('ai_status', ['pending', 'success', 'fail'])
                ->default('pending');

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('audio_records');
    }
};