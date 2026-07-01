<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
{
    Schema::create('patients', function (Blueprint $table) {
        $table->id();

        // 👤 user account
        $table->foreignId('user_id')
            ->constrained()
            ->cascadeOnDelete();

        // 👨‍⚕️ doctor owner
        $table->foreignId('doctor_id')
            ->constrained()
            ->cascadeOnDelete();

        $table->string('first_name');
        $table->string('last_name');
        $table->integer('age');
        $table->enum('gender', ['male', 'female']);

        // speech info
        $table->string('speech_disorder')->nullable();
        $table->string('severity')->nullable();

        // progress
        $table->integer('level')->default(1);
        $table->date('started_at')->nullable();
        $table->enum('status', ['active', 'inactive'])->default('active');

        $table->timestamps();
    });
}

    public function down(): void
    {
        Schema::dropIfExists('patients');
    }
};