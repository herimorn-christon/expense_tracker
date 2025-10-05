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
        Schema::create('financial_goals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('name');
            $table->text('description')->nullable();
            $table->enum('type', ['savings', 'debt_payoff', 'investment', 'purchase', 'emergency_fund'])->default('savings');
            $table->decimal('target_amount', 15, 2);
            $table->decimal('current_amount', 15, 2)->default(0);
            $table->date('target_date');
            $table->date('start_date')->default(now());
            $table->enum('priority', ['low', 'medium', 'high'])->default('medium');
            $table->boolean('is_achieved')->default(false);
            $table->boolean('is_active')->default(true);
            $table->decimal('monthly_contribution', 15, 2)->default(0);
            $table->json('metadata')->nullable(); // For AI suggestions and progress tracking
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('financial_goals');
    }
};
