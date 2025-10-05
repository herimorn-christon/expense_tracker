<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use App\Models\Category;
use App\Models\Budget;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * @group Savings & Analytics
 *
 * APIs for identifying savings opportunities, expense categorization, and subscription analysis
 */
class SavingsOpportunityController extends Controller
{
    /**
     * Get savings opportunities for the user.
     *
     * Analyze user expenses to identify potential savings opportunities and cost reduction suggestions.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @queryParam months integer Number of months of historical data to analyze (default: 6). Example: 12
     *
     * @response 200 {
     *   "success": true,
     *   "data": {
     *     "opportunities": [
     *       {
     *         "type": "high_spending_category",
     *         "category": "Food & Dining",
     *         "current_spending": 150000,
     *         "potential_savings": 22500,
     *         "suggestion": "Consider reducing Food & Dining expenses by 15% to save Tsh 22,500 monthly",
     *         "confidence": "high"
     *       }
     *     ],
     *     "total_potential_savings": 22500,
     *     "analysis_period": "6 months",
     *     "categories_analyzed": 8
     *   }
     * }
     *
     * @response 200 {
     *   "success": true,
     *   "message": "Need more expense data to identify savings opportunities",
     *   "data": []
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to analyze savings opportunities"
     * }
     */
    public function getSavingsOpportunities(Request $request): JsonResponse
    {
        try {
            $userId = Auth::id();
            $months = $request->get('months', 6);

            // Get user's expense data
            $expenses = Expense::where('user_id', $userId)
                ->where('expense_date', '>=', now()->subMonths($months))
                ->with('category')
                ->get();

            if ($expenses->isEmpty()) {
                return response()->json([
                    'success' => true,
                    'message' => 'Need more expense data to identify savings opportunities',
                    'data' => []
                ]);
            }

            $opportunities = $this->analyzeSavingsOpportunities($expenses);

            return response()->json([
                'success' => true,
                'data' => [
                    'opportunities' => $opportunities,
                    'total_potential_savings' => array_sum(array_column($opportunities, 'potential_savings')),
                    'analysis_period' => "{$months} months",
                    'categories_analyzed' => $expenses->groupBy('category_id')->count()
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Savings opportunities error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to analyze savings opportunities'
            ], 500);
        }
    }

    /**
     * Get automated expense categorization suggestions.
     *
     * Generate AI-powered suggestions for categorizing uncategorized expenses based on description and amount analysis.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @response 200 {
     *   "success": true,
     *   "data": {
     *     "suggestions": [
     *       {
     *         "expense_id": 1,
     *         "expense_description": "Lunch at restaurant",
     *         "expense_amount": 15000,
     *         "suggested_category": "Food & Dining",
     *         "confidence": 85,
     *         "reasoning": "Food-related keywords detected"
     *       }
     *     ],
     *     "total_uncategorized": 5,
     *     "categories_available": 12
     *   }
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to generate categorization suggestions"
     * }
     */
    public function getCategorizationSuggestions(Request $request): JsonResponse
    {
        try {
            $userId = Auth::id();

            // Get uncategorized or recently added expenses
            $uncategorizedExpenses = Expense::where('user_id', $userId)
                ->whereNull('category_id')
                ->where('expense_date', '>=', now()->subDays(30))
                ->limit(50)
                ->get();

            $suggestions = [];

            foreach ($uncategorizedExpenses as $expense) {
                $suggestion = $this->suggestCategory($expense);
                if ($suggestion) {
                    $suggestions[] = [
                        'expense_id' => $expense->id,
                        'expense_description' => $expense->title,
                        'expense_amount' => $expense->amount,
                        'suggested_category' => $suggestion['category'],
                        'confidence' => $suggestion['confidence'],
                        'reasoning' => $suggestion['reasoning']
                    ];
                }
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'suggestions' => $suggestions,
                    'total_uncategorized' => $uncategorizedExpenses->count(),
                    'categories_available' => Category::where('user_id', $userId)->count()
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Categorization suggestions error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to generate categorization suggestions'
            ], 500);
        }
    }

    /**
     * Apply automated categorization to expenses.
     *
     * Apply a specific category to multiple uncategorized expenses in bulk.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @bodyParam expense_ids array required Array of expense IDs to categorize. Example: [1, 2, 3]
     * @bodyParam category_id integer required The category ID to apply to the expenses. Example: 1
     *
     * @response 200 {
     *   "success": true,
     *   "message": "Successfully categorized 3 expenses",
     *   "data": {
     *     "updated_count": 3,
     *     "category_name": "Food & Dining"
     *   }
     * }
     *
     * @response 404 {
     *   "success": false,
     *   "message": "Category not found or access denied"
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Validation failed",
     *   "errors": {
     *     "expense_ids": ["The expense_ids field is required."],
     *     "category_id": ["The selected category_id is invalid."]
     *   }
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to apply categorization"
     * }
     */
    public function applyCategorization(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'expense_ids' => 'required|array',
                'expense_ids.*' => 'exists:expenses,id',
                'category_id' => 'required|exists:categories,id'
            ]);

            $userId = Auth::id();
            $category = Category::where('id', $validated['category_id'])
                              ->where('user_id', $userId)
                              ->first();

            if (!$category) {
                return response()->json([
                    'success' => false,
                    'message' => 'Category not found or access denied'
                ], 404);
            }

            $updated = Expense::where('user_id', $userId)
                ->whereIn('id', $validated['expense_ids'])
                ->update(['category_id' => $validated['category_id']]);

            return response()->json([
                'success' => true,
                'message' => "Successfully categorized {$updated} expenses",
                'data' => [
                    'updated_count' => $updated,
                    'category_name' => $category->name
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Apply categorization error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to apply categorization'
            ], 500);
        }
    }

    /**
     * Get subscription and recurring expense analysis.
     *
     * Analyze expense patterns to identify potential subscriptions and recurring payments with optimization suggestions.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @queryParam months integer Number of months of historical data to analyze (default: 12). Example: 6
     *
     * @response 200 {
     *   "success": true,
     *   "data": {
     *     "recurring_patterns": [
     *       {
     *         "amount": 25000,
     *         "frequency": 30,
     *         "monthly_amount": 25000,
     *         "occurrence_count": 6,
     *         "category": "Utilities",
     *         "confidence": "high"
     *       }
     *     ],
     *     "potential_subscriptions": [
     *       {
     *         "name": "Potential Monthly Subscription",
     *         "amount": 25000,
     *         "category": "Utilities",
     *         "confidence": "high",
     *         "annual_cost": 300000,
     *         "suggestion": "This appears to be a monthly subscription costing Tsh 25,000. Consider if you still need this service."
     *       }
     *     ],
     *     "monthly_recurring_total": 25000,
     *     "analysis_period": "12 months"
     *   }
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to analyze subscriptions"
     * }
     */
    public function getSubscriptionAnalysis(Request $request): JsonResponse
    {
        try {
            $userId = Auth::id();
            $months = $request->get('months', 12);

            // Get potential recurring expenses (similar amounts, regular intervals)
            $expenses = Expense::where('user_id', $userId)
                ->where('expense_date', '>=', now()->subMonths($months))
                ->with('category')
                ->get();

            $recurringPatterns = $this->identifyRecurringPatterns($expenses);

            return response()->json([
                'success' => true,
                'data' => [
                    'recurring_patterns' => $recurringPatterns,
                    'potential_subscriptions' => $this->identifySubscriptions($expenses),
                    'monthly_recurring_total' => array_sum(array_column($recurringPatterns, 'monthly_amount')),
                    'analysis_period' => "{$months} months"
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Subscription analysis error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to analyze subscriptions'
            ], 500);
        }
    }

    /**
     * Analyze expenses for savings opportunities.
     */
    private function analyzeSavingsOpportunities($expenses): array
    {
        $opportunities = [];

        // Group expenses by category
        $categoryTotals = $expenses->groupBy('category_id')->map(function ($categoryExpenses) {
            return [
                'total' => $categoryExpenses->sum('amount'),
                'count' => $categoryExpenses->count(),
                'avg' => $categoryExpenses->avg('amount'),
                'category' => $categoryExpenses->first()->category
            ];
        });

        // Identify high-spending categories
        foreach ($categoryTotals as $categoryData) {
            if ($categoryData['total'] > 100000) { // High spending threshold
                $potentialSavings = $categoryData['total'] * 0.15; // 15% potential savings
                $categoryName = $categoryData['category']->name ?? 'Uncategorized';
                $opportunities[] = [
                    'type' => 'high_spending_category',
                    'category' => $categoryName,
                    'current_spending' => $categoryData['total'],
                    'potential_savings' => $potentialSavings,
                    'suggestion' => "Consider reducing {$categoryName} expenses by 15% to save Tsh " . number_format($potentialSavings, 0) . " monthly",
                    'confidence' => 'high'
                ];
            }
        }

        // Identify frequent small expenses that could be reduced
        $frequentSmallExpenses = $expenses->where('amount', '<', 10000)
                                         ->where('amount', '>', 1000)
                                         ->count();

        if ($frequentSmallExpenses > 20) {
            $potentialSavings = $frequentSmallExpenses * 2000; // Assume Tsh 2,000 savings per small expense
            $opportunities[] = [
                'type' => 'frequent_small_expenses',
                'description' => 'Many small frequent expenses detected',
                'current_count' => $frequentSmallExpenses,
                'potential_savings' => $potentialSavings,
                'suggestion' => "You have {$frequentSmallExpenses} small expenses. Consider reducing by 10 to save Tsh " . number_format($potentialSavings, 0) . " monthly",
                'confidence' => 'medium'
            ];
        }

        // Identify potential subscription services
        $subscriptionOpportunities = $this->identifySubscriptionOpportunities($expenses);
        $opportunities = array_merge($opportunities, $subscriptionOpportunities);

        return $opportunities;
    }

    /**
     * Suggest category for an expense based on description and amount.
     */
    private function suggestCategory(Expense $expense): ?array
    {
        $description = strtolower($expense->title . ' ' . $expense->description);
        $amount = $expense->amount;

        // Get user's categories for matching
        $categories = Category::where('user_id', $expense->user_id)->get();

        $suggestions = [];

        foreach ($categories as $category) {
            $confidence = 0;
            $reasoning = [];

            // Keyword matching
            $categoryKeywords = strtolower($category->name . ' ' . ($category->description ?? ''));

            if (stripos($description, 'food') !== false || stripos($description, 'restaurant') !== false || stripos($description, 'lunch') !== false) {
                if (stripos($categoryKeywords, 'food') !== false || stripos($categoryKeywords, 'dining') !== false) {
                    $confidence += 80;
                    $reasoning[] = 'Food-related keywords detected';
                }
            }

            if (stripos($description, 'transport') !== false || stripos($description, 'fuel') !== false || stripos($description, 'bus') !== false) {
                if (stripos($categoryKeywords, 'transport') !== false) {
                    $confidence += 80;
                    $reasoning[] = 'Transportation-related keywords detected';
                }
            }

            if (stripos($description, 'entertainment') !== false || stripos($description, 'movie') !== false || stripos($description, 'game') !== false) {
                if (stripos($categoryKeywords, 'entertainment') !== false) {
                    $confidence += 75;
                    $reasoning[] = 'Entertainment-related keywords detected';
                }
            }

            // Amount-based suggestions
            if ($amount > 50000 && $amount < 200000) {
                if (stripos($categoryKeywords, 'shopping') !== false || stripos($categoryKeywords, 'personal') !== false) {
                    $confidence += 60;
                    $reasoning[] = 'Amount range suggests shopping or personal expense';
                }
            }

            if ($amount < 5000) {
                if (stripos($categoryKeywords, 'misc') !== false || stripos($categoryKeywords, 'other') !== false) {
                    $confidence += 40;
                    $reasoning[] = 'Small amount suggests miscellaneous expense';
                }
            }

            if ($confidence >= 60) {
                $suggestions[] = [
                    'category' => $category,
                    'confidence' => $confidence,
                    'reasoning' => implode(', ', $reasoning)
                ];
            }
        }

        // Return best suggestion
        if (!empty($suggestions)) {
            usort($suggestions, function($a, $b) {
                return $b['confidence'] <=> $a['confidence'];
            });

            return [
                'category' => $suggestions[0]['category']->name,
                'category_id' => $suggestions[0]['category']->id,
                'confidence' => $suggestions[0]['confidence'],
                'reasoning' => $suggestions[0]['reasoning']
            ];
        }

        return null;
    }

    /**
     * Identify recurring expense patterns.
     */
    private function identifyRecurringPatterns($expenses): array
    {
        $patterns = [];

        // Group by amount (potential recurring payments)
        $amountGroups = $expenses->groupBy(function($expense) {
            return round($expense->amount / 1000) * 1000; // Round to nearest 1000
        });

        foreach ($amountGroups as $amount => $expenseGroup) {
            if ($expenseGroup->count() >= 3) { // At least 3 occurrences
                $dates = $expenseGroup->pluck('expense_date')->sort()->values();

                // Check for regular intervals
                $intervals = [];
                for ($i = 1; $i < $dates->count(); $i++) {
                    $days = $dates[$i]->diffInDays($dates[$i-1]);
                    $intervals[] = $days;
                }

                $avgInterval = array_sum($intervals) / count($intervals);

                // If intervals are consistent (within 5 days variance)
                $intervalVariance = array_sum(array_map(function($interval) use ($avgInterval) {
                    return abs($interval - $avgInterval);
                }, $intervals)) / count($intervals);

                if ($intervalVariance <= 5) {
                    $patterns[] = [
                        'amount' => $amount,
                        'frequency' => round($avgInterval),
                        'monthly_amount' => $amount * (30 / round($avgInterval)),
                        'occurrence_count' => $expenseGroup->count(),
                        'category' => $expenseGroup->first()->category->name ?? 'Uncategorized',
                        'confidence' => $intervalVariance <= 2 ? 'high' : 'medium'
                    ];
                }
            }
        }

        return $patterns;
    }

    /**
     * Identify potential subscription services.
     */
    private function identifySubscriptions($expenses): array
    {
        $subscriptions = [];

        // Look for expenses with similar amounts occurring regularly
        $recurringPatterns = $this->identifyRecurringPatterns($expenses);

        foreach ($recurringPatterns as $pattern) {
            if ($pattern['frequency'] >= 25 && $pattern['frequency'] <= 35) { // Monthly pattern
                $subscriptions[] = [
                    'name' => 'Potential Monthly Subscription',
                    'amount' => $pattern['amount'],
                    'category' => $pattern['category'],
                    'confidence' => $pattern['confidence'],
                    'annual_cost' => $pattern['amount'] * 12,
                    'suggestion' => "This appears to be a monthly subscription costing Tsh " . number_format($pattern['amount'], 0) . ". Consider if you still need this service."
                ];
            }
        }

        return $subscriptions;
    }

    /**
     * Identify subscription cancellation opportunities.
     */
    private function identifySubscriptionOpportunities($expenses): array
    {
        $opportunities = [];

        $subscriptions = $this->identifySubscriptions($expenses);

        foreach ($subscriptions as $subscription) {
            $opportunities[] = [
                'type' => 'subscription_optimization',
                'description' => $subscription['name'] . ' - ' . $subscription['category'],
                'current_cost' => $subscription['amount'],
                'potential_savings' => $subscription['amount'],
                'suggestion' => $subscription['suggestion'],
                'confidence' => $subscription['confidence'],
                'frequency' => 'monthly'
            ];
        }

        return $opportunities;
    }
}
