<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('audio_records', function (Blueprint $table) {

            $table->string('target_phoneme')
                  ->nullable()
                  ->after('expected_text');

        });
    }

    public function down(): void
    {
        Schema::table('audio_records', function (Blueprint $table) {

            $table->dropColumn('target_phoneme');

        });
    }
};