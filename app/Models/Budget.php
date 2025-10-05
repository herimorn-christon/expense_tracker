<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Carbon\Carbon;

class Budget extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'category_id',
        'amount',
        'period',
        'start_date',
        'end_date',
        'description',
        'is_active',
        'auto_adjust',
        'alert_threshold',
        'metadata'
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'start_date' => 'date',
        'end_date' => 'date',
        'is_active' => 'boolean',
        'auto_adjust' => 'boolean',
        'alert_threshold' => 'decimal:2',
        'metadata' => 'array'
    ];

    /**
     * Get the user that owns the budget.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the category for this budget.
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    /**
     * Get expenses for this budget period.
     */
    public function getExpensesForPeriod()
    {
        return Expense::forUser($this->user_id)
            ->when($this->category_id, function ($query) {
                return $query->where('category_id', $this->category_id);
            })
            ->whereBetween('expense_date', [$this->start_date, $this->end_date])
            ->sum('amount');
    }

    /**
     * Calculate budget utilization percentage.
     */
    public function getUtilizationPercentage(): float
    {
        $spent = $this->getExpensesForPeriod();
        return $this->amount > 0 ? ($spent / $this->amount) * 100 : 0;
    }

    /**
     * Check if budget alert should be triggered.
     */
    public function shouldAlert(): bool
    {
        $utilization = $this->getUtilizationPercentage();
        return $utilization >= $this->alert_threshold;
    }

    /**
     * Get remaining budget amount.
     */
    public function getRemainingAmount(): float
    {
        return max(0, $this->amount - $this->getExpensesForPeriod());
    }

    /**
     * Get budget status.
     */
    public function getStatus(): string
    {
        $utilization = $this->getUtilizationPercentage();

        if ($utilization >= 100) return 'exceeded';
        if ($utilization >= $this->alert_threshold) return 'warning';
        if ($utilization > 0) return 'active';

        return 'unused';
    }

    /**
     * Scope for active budgets.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true)
                    ->where('start_date', '<=', now())
                    ->where('end_date', '>=', now());
    }

    /**
     * Scope for current period budgets.
     */
    public function scopeCurrentPeriod($query)
    {
        return $query->where('start_date', '<=', now())
                    ->where('end_date', '>=', now());
    }
}
