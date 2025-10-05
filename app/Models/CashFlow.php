<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Carbon\Carbon;

class CashFlow extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type',
        'source',
        'amount',
        'flow_date',
        'description',
        'category',
        'is_recurring',
        'frequency',
        'metadata'
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'flow_date' => 'date',
        'is_recurring' => 'boolean',
        'metadata' => 'array'
    ];

    /**
     * Get the user that owns the cash flow record.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Scope for income records.
     */
    public function scopeIncome($query)
    {
        return $query->where('type', 'income');
    }

    /**
     * Scope for expense records.
     */
    public function scopeExpenses($query)
    {
        return $query->where('type', 'expense');
    }

    /**
     * Scope for transfer records.
     */
    public function scopeTransfers($query)
    {
        return $query->where('type', 'transfer');
    }

    /**
     * Scope for recurring items.
     */
    public function scopeRecurring($query)
    {
        return $query->where('is_recurring', true);
    }

    /**
     * Scope for date range.
     */
    public function scopeDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('flow_date', [$startDate, $endDate]);
    }

    /**
     * Get cash flow balance for a period.
     */
    public static function getBalanceForPeriod($userId, $startDate, $endDate)
    {
        $income = static::where('user_id', $userId)
            ->income()
            ->dateRange($startDate, $endDate)
            ->sum('amount');

        $expenses = static::where('user_id', $userId)
            ->expenses()
            ->dateRange($startDate, $endDate)
            ->sum('amount');

        return $income - $expenses;
    }

    /**
     * Get monthly cash flow trend.
     */
    public static function getMonthlyTrend($userId, $months = 12)
    {
        $endDate = now();
        $startDate = now()->subMonths($months);

        return static::where('user_id', $userId)
            ->where('flow_date', '>=', $startDate)
            ->where('flow_date', '<=', $endDate)
            ->selectRaw('DATE_FORMAT(flow_date, "%Y-%m") as month,
                           SUM(CASE WHEN type = "income" THEN amount ELSE 0 END) as income,
                           SUM(CASE WHEN type = "expense" THEN amount ELSE 0 END) as expenses,
                           SUM(CASE WHEN type = "income" THEN amount ELSE -amount END) as net_flow')
            ->groupBy('month')
            ->orderBy('month')
            ->get();
    }

    /**
     * Get cash flow by category.
     */
    public static function getByCategory($userId, $startDate, $endDate, $type = 'expense')
    {
        return static::where('user_id', $userId)
            ->where('type', $type)
            ->dateRange($startDate, $endDate)
            ->whereNotNull('category')
            ->selectRaw('category, SUM(amount) as total, COUNT(*) as count')
            ->groupBy('category')
            ->orderByDesc('total')
            ->get();
    }

    /**
     * Get average monthly income.
     */
    public static function getAverageMonthlyIncome($userId, $months = 6)
    {
        $totalIncome = static::where('user_id', $userId)
            ->income()
            ->where('flow_date', '>=', now()->subMonths($months))
            ->sum('amount');

        return $totalIncome / $months;
    }

    /**
     * Get average monthly expenses.
     */
    public static function getAverageMonthlyExpenses($userId, $months = 6)
    {
        $totalExpenses = static::where('user_id', $userId)
            ->expenses()
            ->where('flow_date', '>=', now()->subMonths($months))
            ->sum('amount');

        return $totalExpenses / $months;
    }
}
