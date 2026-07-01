<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('patient_sessions', function (Blueprint $table) {
            $table->id();

            // 👤 مرتبط بالمريض مباشرة
            $table->foreignId('patient_id')
                ->constrained()
                ->cascadeOnDelete();

            $table->integer('level')->default(1);

            $table->integer('success_count')->default(0);
            $table->integer('fail_count')->default(0);

            $table->text('doctor_feedback')->nullable();

            $table->string('status')->default('active');
            // active - completed

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('patient_sessions');
    }
};