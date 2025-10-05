<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Carbon\Carbon;

class FinancialGoal extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'description',
        'type',
        'target_amount',
        'current_amount',
        'target_date',
        'start_date',
        'priority',
        'is_achieved',
        'is_active',
        'monthly_contribution',
        'metadata'
    ];

    protected $casts = [
        'target_amount' => 'decimal:2',
        'current_amount' => 'decimal:2',
        'target_date' => 'date',
        'start_date' => 'date',
        'is_achieved' => 'boolean',
        'is_active' => 'boolean',
        'monthly_contribution' => 'decimal:2',
        'metadata' => 'array'
    ];

    /**
     * Get the user that owns the goal.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Calculate goal progress percentage.
     */
    public function getProgressPercentage(): float
    {
        return $this->target_amount > 0 ? ($this->current_amount / $this->target_amount) * 100 : 0;
    }

    /**
     * Calculate days remaining to achieve goal.
     */
    public function getDaysRemaining(): int
    {
        return max(0, Carbon::now()->diffInDays($this->target_date, false));
    }

    /**
     * Calculate required monthly contribution to achieve goal.
     */
    public function getRequiredMonthlyContribution(): float
    {
        $remaining = $this->target_amount - $this->current_amount;

        // If goal is already achieved or target amount is reached
        if ($remaining <= 0) {
            return 0;
        }

        $monthsRemaining = Carbon::now()->diffInMonths($this->target_date);

        // Handle same-day goals or when target date is in the past
        if ($monthsRemaining <= 0) {
            return $remaining; // Require full remaining amount immediately
        }

        return $remaining / $monthsRemaining;
    }

    /**
     * Check if goal is on track.
     */
    public function isOnTrack(): bool
    {
        $progress = $this->getProgressPercentage();
        $daysElapsed = Carbon::now()->diffInDays($this->start_date);
        $totalDays = Carbon::parse($this->start_date)->diffInDays($this->target_date);

        // Prevent division by zero when start and target dates are the same
        if ($totalDays === 0) {
            return $progress >= 100; // If it's a same-day goal, check if it's completed
        }

        $expectedProgress = ($daysElapsed / $totalDays) * 100;

        return $progress >= $expectedProgress * 0.9; // Within 90% of expected progress
    }

    /**
     * Get goal status.
     */
    public function getStatus(): string
    {
        if ($this->is_achieved) return 'achieved';
        if (!$this->is_active) return 'inactive';
        if ($this->target_date < now()) return 'overdue';

        return $this->isOnTrack() ? 'on_track' : 'behind';
    }

    /**
     * Update current amount (for savings goals).
     */
    public function addProgress(float $amount): void
    {
        $this->current_amount += $amount;
        if ($this->current_amount >= $this->target_amount) {
            $this->is_achieved = true;
        }
        $this->save();
    }

    /**
     * Scope for active goals.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope for achieved goals.
     */
    public function scopeAchieved($query)
    {
        return $query->where('is_achieved', true);
    }

    /**
     * Scope for overdue goals.
     */
    public function scopeOverdue($query)
    {
        return $query->where('target_date', '<', now())
                    ->where('is_achieved', false);
    }
}
