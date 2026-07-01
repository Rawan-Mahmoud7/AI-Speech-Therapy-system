<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_feedback', function (Blueprint $table) {
            $table->id();

            $table->foreignId('audio_record_id')
                ->constrained()
                ->cascadeOnDelete();

            $table->foreignId('patient_id')
                ->constrained()
                ->cascadeOnDelete();

            $table->text('patient_comment'); 
            // الجملة اللي المريض كتبها أو قالها

            $table->enum('ai_rating', ['correct', 'wrong']);
            // تقييم المريض للـ AI

            $table->text('correct_sentence')->nullable();
            // الجملة الصحيحة لو في تصحيح

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_feedback');
    }
};
