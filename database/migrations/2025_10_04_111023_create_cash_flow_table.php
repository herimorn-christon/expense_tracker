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
        Schema::create('cash_flow', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->enum('type', ['income', 'expense', 'transfer'])->default('expense');
            $table->string('source')->nullable(); // Bank account, cash, etc.
            $table->decimal('amount', 15, 2);
            $table->date('flow_date');
            $table->text('description')->nullable();
            $table->string('category')->nullable(); // For income categorization
            $table->boolean('is_recurring')->default(false);
            $table->enum('frequency', ['daily', 'weekly', 'bi-weekly', 'monthly', 'quarterly', 'yearly'])->nullable();
            $table->json('metadata')->nullable(); // For additional data and AI analysis
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('cash_flow');
    }
};
