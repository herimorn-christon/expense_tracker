<?php

namespace App\Http\Controllers;

use App\Models\Budget;
use App\Models\Expense;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

/**
 * @group Budget Management
 *
 * APIs for managing user budgets with AI-powered suggestions and analytics
 */
class BudgetController extends Controller
{
    /**
     * Display a listing of user's budgets.
     *
     * Get all budgets for the authenticated user with optional filtering by period.
     *
     * @authenticated
     * @security bearerAuth
     * @security bearerAuth
     *
     * @queryParam period string Filter budgets by period. Options: current, active. Example: current
     *
     * @response 200 {
     *   "success": true,
     *   "data": [
     *     {
     *       "id": 1,
     *       "amount": 500.00,
     *       "spent": 350.75,
     *       "remaining": 149.25,
     *       "utilization_percentage": 70.15,
     *       "status": "on_track",
     *       "period": "monthly",
     *       "start_date": "2025-09-01",
     *       "end_date": "2025-09-30",
     *       "category": {
     *         "id": 1,
     *         "name": "Food & Dining",
     *         "color": "#EF4444"
     *       },
     *       "should_alert": false,
     *       "is_active": true
     *     }
     *   ]
     * }
     *
     * @response 401 {
     *   "message": "Unauthenticated."
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to fetch budgets"
     * }
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $userId = Auth::id();
            $period = $request->get('period', 'current');

            $query = Budget::where('user_id', $userId)
                ->with('category')
                ->when($period === 'current', function ($q) {
                    return $q->currentPeriod();
                })
                ->when($period === 'active', function ($q) {
                    return $q->active();
                });

            $budgets = $query->get()->map(function ($budget) {
                return [
                    'id' => $budget->id,
                    'user_id' => $budget->user_id,
                    'category_id' => $budget->category_id,
                    'amount' => $budget->amount,
                    'spent' => $budget->getExpensesForPeriod(),
                    'remaining' => $budget->getRemainingAmount(),
                    'utilization_percentage' => $budget->getUtilizationPercentage(),
                    'status' => $budget->getStatus(),
                    'period' => $budget->period,
                    'start_date' => $budget->start_date,
                    'end_date' => $budget->end_date,
                    'description' => $budget->description,
                    'alert_threshold' => $budget->alert_threshold,
                    'auto_adjust' => $budget->auto_adjust,
                    'is_active' => $budget->is_active,
                    'created_at' => $budget->created_at,
                    'updated_at' => $budget->updated_at,
                    'category' => $budget->category,
                    'should_alert' => $budget->shouldAlert(),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $budgets
            ]);

        } catch (\Exception $e) {
            Log::error('Budget index error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch budgets'
            ], 500);
        }
    }

    /**
     * Store a newly created budget.
     *
     * Create a new budget for the authenticated user with optional AI-powered suggestions.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @bodyParam amount numeric required The budget amount. Example: 500.00
     * @bodyParam category_id integer required The category ID for this budget. Must be owned by the user. Example: 1
     * @bodyParam period string required The budget period. Options: weekly, monthly, quarterly, yearly. Example: monthly
     * @bodyParam start_date string required The budget start date (YYYY-MM-DD). Example: 2025-09-01
     * @bodyParam end_date string The budget end date (YYYY-MM-DD). If not provided, calculated from period. Example: 2025-09-30
     * @bodyParam description string The budget description. Example: Monthly food budget
     * @bodyParam alert_threshold numeric Alert threshold percentage (0-100). Example: 80
     * @bodyParam auto_adjust boolean Whether to auto-adjust this budget based on AI analysis. Example: true
     *
     * @response 201 {
     *   "success": true,
     *   "message": "Budget created successfully",
     *   "data": {
     *     "id": 1,
     *     "user_id": 1,
     *     "amount": 500.00,
     *     "category_id": 1,
     *     "period": "monthly",
     *     "start_date": "2025-09-01",
     *     "end_date": "2025-09-30",
     *     "description": "Monthly food budget",
     *     "alert_threshold": 80,
     *     "auto_adjust": true,
     *     "is_active": true,
     *     "created_at": "2025-10-04T10:37:03.000000Z",
     *     "updated_at": "2025-10-04T10:37:03.000000Z",
     *     "category": {
     *       "id": 1,
     *       "name": "Food & Dining",
     *       "color": "#EF4444"
     *     }
     *   }
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Failed to create budget",
     *   "error": "Validation error message"
     * }
     */
    public function store(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'amount' => 'required|numeric|min:0',
                'category_id' => 'required|exists:categories,id',
                'period' => 'required|in:weekly,monthly,quarterly,yearly',
                'start_date' => 'required|date',
                'end_date' => 'required|date|after:start_date',
                'description' => 'nullable|string',
                'alert_threshold' => 'numeric|min:0|max:100',
                'auto_adjust' => 'boolean'
            ]);

            $validated['user_id'] = Auth::id();

            // Calculate end_date based on period if not provided
            if (!$request->has('end_date')) {
                $validated['end_date'] = $this->calculateEndDate(
                    $validated['start_date'],
                    $validated['period']
                );
            }

            $budget = Budget::create($validated);

            return response()->json([
                'success' => true,
                'message' => 'Budget created successfully',
                'data' => $budget->load('category')
            ], 201);

        } catch (\Exception $e) {
            Log::error('Budget creation error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to create budget',
                'error' => $e->getMessage()
            ], 422);
        }
    }

    /**
     * Display the specified budget with details.
     *
     * Get detailed information about a specific budget including spending analytics.
     *
     * @authenticated
     * @security bearerAuth
     * @urlParam id integer required The budget ID. Example: 1
     *
     * @response 200 {
     *   "success": true,
     *   "data": {
     *     "id": 1,
     *     "amount": 500.00,
     *     "spent": 350.75,
     *     "remaining": 149.25,
     *     "utilization_percentage": 70.15,
     *     "status": "on_track",
     *     "period": "monthly",
     *     "start_date": "2025-09-01",
     *     "end_date": "2025-09-30",
     *     "category": {
     *       "id": 1,
     *       "name": "Food & Dining",
     *       "color": "#EF4444"
     *     },
     *     "should_alert": false,
     *     "is_active": true,
     *     "description": "Monthly food budget",
     *     "alert_threshold": 80,
     *     "auto_adjust": true,
     *     "created_at": "2025-10-04T10:37:03.000000Z",
     *     "updated_at": "2025-10-04T10:37:03.000000Z"
     *   }
     * }
     *
     * @response 403 {
     *   "message": "This action is unauthorized."
     * }
     *
     * @response 404 {
     *   "success": false,
     *   "message": "Budget not found"
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to fetch budget details"
     * }
     */
    public function show(Budget $budget): JsonResponse
    {
        try {
            // Ensure user can only view their own budgets
            if ($budget->user_id !== Auth::id()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Budget not found'
                ], 404);
            }

            $budget->load('category');

            $data = [
                'id' => $budget->id,
                'amount' => $budget->amount,
                'spent' => $budget->getExpensesForPeriod(),
                'remaining' => $budget->getRemainingAmount(),
                'utilization_percentage' => $budget->getUtilizationPercentage(),
                'status' => $budget->getStatus(),
                'period' => $budget->period,
                'start_date' => $budget->start_date,
                'end_date' => $budget->end_date,
                'category' => $budget->category,
                'should_alert' => $budget->shouldAlert(),
                'is_active' => $budget->is_active,
                'description' => $budget->description,
                'alert_threshold' => $budget->alert_threshold,
                'auto_adjust' => $budget->auto_adjust,
                'created_at' => $budget->created_at,
                'updated_at' => $budget->updated_at
            ];

            return response()->json([
                'success' => true,
                'data' => $data
            ]);

        } catch (\Exception $e) {
            Log::error('Budget show error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch budget details'
            ], 500);
        }
    }

    /**
     * Update the specified budget.
     *
     * Update an existing budget's information and settings.
     *
     * @authenticated
     * @security bearerAuth
     * @urlParam id integer required The budget ID. Example: 1
     *
     * @bodyParam amount numeric The budget amount. Example: 600.00
     * @bodyParam category_id integer The category ID for this budget. Must be owned by the user. Example: 1
     * @bodyParam period string The budget period. Options: weekly, monthly, quarterly, yearly. Example: monthly
     * @bodyParam start_date string The budget start date (YYYY-MM-DD). Example: 2025-09-01
     * @bodyParam end_date string The budget end date (YYYY-MM-DD). Example: 2025-09-30
     * @bodyParam description string The budget description. Example: Updated monthly food budget
     * @bodyParam alert_threshold numeric Alert threshold percentage (0-100). Example: 85
     * @bodyParam auto_adjust boolean Whether to auto-adjust this budget based on AI analysis. Example: true
     * @bodyParam is_active boolean Whether the budget is active. Example: true
     *
     * @response 200 {
     *   "success": true,
     *   "message": "Budget updated successfully",
     *   "data": {
     *     "id": 1,
     *     "user_id": 1,
     *     "amount": 600.00,
     *     "category_id": 1,
     *     "period": "monthly",
     *     "start_date": "2025-09-01",
     *     "end_date": "2025-09-30",
     *     "description": "Updated monthly food budget",
     *     "alert_threshold": 85,
     *     "auto_adjust": true,
     *     "is_active": true,
     *     "created_at": "2025-10-04T10:37:03.000000Z",
     *     "updated_at": "2025-10-04T10:37:03.000000Z",
     *     "category": {
     *       "id": 1,
     *       "name": "Food & Dining",
     *       "color": "#EF4444"
     *     }
     *   }
     * }
     *
     * @response 403 {
     *   "message": "This action is unauthorized."
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Failed to update budget",
     *   "error": "Validation error message"
     * }
     */
    public function update(Request $request, Budget $budget): JsonResponse
    {
        try {
            // Ensure user can only update their own budgets
            if ($budget->user_id !== Auth::id()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Budget not found'
                ], 404);
            }

            $validated = $request->validate([
                'amount' => 'sometimes|required|numeric|min:0',
                'category_id' => 'sometimes|required|exists:categories,id',
                'period' => 'sometimes|required|in:weekly,monthly,quarterly,yearly',
                'start_date' => 'sometimes|required|date',
                'end_date' => 'sometimes|required|date|after:start_date',
                'description' => 'nullable|string',
                'alert_threshold' => 'sometimes|numeric|min:0|max:100',
                'auto_adjust' => 'sometimes|boolean',
                'is_active' => 'sometimes|boolean'
            ]);

            $budget->update($validated);

            return response()->json([
                'success' => true,
                'message' => 'Budget updated successfully',
                'data' => $budget->load('category')
            ]);

        } catch (\Exception $e) {
            Log::error('Budget update error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to update budget',
                'error' => $e->getMessage()
            ], 422);
        }
    }

    /**
     * Remove the specified budget.
     *
     * Delete an existing budget permanently.
     *
     * @authenticated
     * @security bearerAuth
     * @urlParam id integer required The budget ID. Example: 1
     *
     * @response 200 {
     *   "success": true,
     *   "message": "Budget deleted successfully"
     * }
     *
     * @response 403 {
     *   "message": "This action is unauthorized."
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to delete budget"
     * }
     */
    public function destroy(Budget $budget): JsonResponse
    {
        try {
            // Ensure user can only delete their own budgets
            if ($budget->user_id !== Auth::id()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Budget not found'
                ], 404);
            }
            $budget->delete();

            return response()->json([
                'success' => true,
                'message' => 'Budget deleted successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Budget deletion error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete budget'
            ], 500);
        }
    }

    /**
     * Get AI-powered budget suggestions.
     *
     * Generate intelligent budget suggestions based on historical spending patterns and AI analysis.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @queryParam months integer Number of months of historical data to analyze. Default: 6. Example: 12
     *
     * @response 200 {
     *   "success": true,
     *   "data": [
     *     {
     *       "category_id": 1,
     *       "suggested_amount": 550.00,
     *       "confidence": "high",
     *       "reasoning": "Based on 6 months of spending data"
     *     }
     *   ]
     * }
     *
     * @response 200 {
     *   "success": true,
     *   "message": "Need more expense data for AI suggestions",
     *   "data": []
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to generate budget suggestions"
     * }
     */
    public function getAISuggestions(Request $request): JsonResponse
    {
        try {
            $userId = Auth::id();
            $months = $request->get('months', 6);

            // Get historical spending data
            $spendingData = $this->getHistoricalSpendingData($userId, $months);

            if (empty($spendingData)) {
                return response()->json([
                    'success' => true,
                    'message' => 'Need more expense data for AI suggestions',
                    'data' => []
                ]);
            }

            // Generate AI-powered budget suggestions
            $suggestions = $this->generateBudgetSuggestions($spendingData);

            return response()->json([
                'success' => true,
                'data' => $suggestions
            ]);

        } catch (\Exception $e) {
            Log::error('Budget AI suggestions error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to generate budget suggestions'
            ], 500);
        }
    }

    /**
     * Auto-adjust budgets based on AI analysis.
     *
     * Automatically adjust budget amounts for budgets with auto_adjust enabled based on AI analysis of spending patterns.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @response 200 {
     *   "success": true,
     *   "message": "Adjusted 3 budgets",
     *   "data": [
     *     {
     *       "id": 1,
     *       "amount": 550.00,
     *       "category": {
     *         "id": 1,
     *         "name": "Food & Dining"
     *       }
     *     }
     *   ]
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to auto-adjust budgets"
     * }
     */
    public function autoAdjust(Request $request): JsonResponse
    {
        try {
            $userId = Auth::id();

            $budgets = Budget::where('user_id', $userId)
                ->active()
                ->where('auto_adjust', true)
                ->get();

            $adjusted = [];

            foreach ($budgets as $budget) {
                $newAmount = $this->calculateOptimalBudgetAmount($budget);
                if ($newAmount !== $budget->amount) {
                    $budget->update([
                        'amount' => $newAmount,
                        'metadata' => array_merge($budget->metadata ?? [], [
                            'auto_adjusted_at' => now(),
                            'previous_amount' => $budget->amount
                        ])
                    ]);
                    $adjusted[] = $budget;
                }
            }

            return response()->json([
                'success' => true,
                'message' => "Adjusted " . count($adjusted) . " budgets",
                'data' => $adjusted
            ]);

        } catch (\Exception $e) {
            Log::error('Budget auto-adjust error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to auto-adjust budgets'
            ], 500);
        }
    }

    /**
     * Get budget statistics for dashboard.
     *
     * Retrieve key budget statistics for dashboard display including totals and utilization metrics.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @response 200 {
     *   "success": true,
     *   "data": {
     *     "total_budgets": 8,
     *     "active_budgets": 6,
     *     "over_budget": 1,
     *     "avg_utilization_percentage": 75.5,
     *     "total_budgeted": 3500.00,
     *     "total_spent": 2850.75
     *   }
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to fetch budget statistics"
     * }
     */
    public function statistics(Request $request): JsonResponse
    {
        try {
            $userId = Auth::id();

            $budgets = Budget::where('user_id', $userId)
                ->active()
                ->get();

            $totalBudgets = $budgets->count();
            $activeBudgets = $budgets->where('is_active', true)->count();
            $overBudget = $budgets->where('status', 'exceeded')->count();

            $totalBudgeted = $budgets->sum('amount');
            $totalSpent = $budgets->sum(function($budget) {
                return $budget->getExpensesForPeriod();
            });

            $avgUtilization = $totalBudgets > 0
                ? $budgets->avg(function($budget) {
                    return $budget->getUtilizationPercentage();
                })
                : 0;

            $statistics = [
                'total_budgets' => $totalBudgets,
                'active_budgets' => $activeBudgets,
                'over_budget' => $overBudget,
                'avg_utilization_percentage' => round($avgUtilization, 1),
                'total_budgeted' => $totalBudgeted,
                'total_spent' => $totalSpent
            ];

            return response()->json([
                'success' => true,
                'data' => $statistics
            ]);

        } catch (\Exception $e) {
            Log::error('Budget statistics error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch budget statistics'
            ], 500);
        }
    }

    /**
     * Get budget performance analytics.
     *
     * Retrieve comprehensive budget performance analytics including utilization, trends, and category breakdowns.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @queryParam months integer Number of months to analyze. Default: 6. Example: 12
     *
     * @response 200 {
     *   "success": true,
     *   "data": {
     *     "total_budgets": 8,
     *     "active_budgets": 6,
     *     "over_budget": 1,
     *     "on_track": 4,
     *     "warning": 1,
     *     "total_budgeted": 3500.00,
     *     "total_spent": 2850.75,
     *     "budgets_by_status": {
     *       "on_track": 4,
     *       "warning": 1,
     *       "exceeded": 1
     *     },
     *     "category_breakdown": {
     *       "Food & Dining": {
     *         "total_budgeted": 800.00,
     *         "total_spent": 650.50,
     *         "budget_count": 1,
     *         "avg_utilization": 81.31
     *       }
     *     }
     *   }
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to fetch budget analytics"
     * }
     */
    public function analytics(Request $request): JsonResponse
    {
        try {
            $userId = Auth::id();
            $months = $request->get('months', 6);

            $budgets = Budget::where('user_id', $userId)
                ->with('category')
                ->where('created_at', '>=', now()->subMonths($months))
                ->get();

            $analytics = [
                'total_budgets' => $budgets->count(),
                'active_budgets' => $budgets->where('is_active', true)->count(),
                'over_budget' => $budgets->where('status', 'exceeded')->count(),
                'on_track' => $budgets->where('status', 'on_track')->count(),
                'warning' => $budgets->where('status', 'warning')->count(),
                'total_budgeted' => $budgets->sum('amount'),
                'total_spent' => $budgets->sum(function($budget) {
                    return $budget->getExpensesForPeriod();
                }),
                'budgets_by_status' => $budgets->groupBy('status')->map->count(),
                'category_breakdown' => $this->getBudgetCategoryAnalytics($budgets)
            ];

            return response()->json([
                'success' => true,
                'data' => $analytics
            ]);

        } catch (\Exception $e) {
            Log::error('Budget analytics error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch budget analytics'
            ], 500);
        }
    }

    /**
     * Helper: Get historical spending data for AI analysis.
     */
    private function getHistoricalSpendingData($userId, $months)
    {
        return Expense::where('user_id', $userId)
            ->where('expense_date', '>=', now()->subMonths($months))
            ->with('category')
            ->selectRaw('DATE_FORMAT(expense_date, "%Y-%m") as month, category_id, SUM(amount) as total')
            ->groupBy('month', 'category_id')
            ->get();
    }

    /**
     * Helper: Generate AI-powered budget suggestions.
     */
    private function generateBudgetSuggestions($spendingData)
    {
        $suggestions = [];
        $categoryTotals = $spendingData->groupBy('category_id');

        foreach ($categoryTotals as $categoryId => $expenses) {
            $total = $expenses->sum('total');
            $avg = $total / $expenses->count();

            $suggestions[] = [
                'category_id' => $categoryId,
                'suggested_amount' => $avg * 1.1, // 10% buffer
                'confidence' => $expenses->count() >= 3 ? 'high' : 'medium',
                'reasoning' => "Based on {$expenses->count()} months of spending data"
            ];
        }

        return $suggestions;
    }

    /**
     * Helper: Calculate optimal budget amount.
     */
    private function calculateOptimalBudgetAmount(Budget $budget)
    {
        $expenses = $budget->getExpensesForPeriod();
        $months = Carbon::parse($budget->start_date)->diffInMonths($budget->end_date);

        if ($months > 0) {
            $monthlyAverage = $expenses / $months;
            return $monthlyAverage * 1.15; // 15% buffer for safety
        }

        return $budget->amount;
    }

    /**
     * Helper: Calculate end date based on period.
     */
    private function calculateEndDate($startDate, $period)
    {
        $start = Carbon::parse($startDate);

        return match($period) {
            'weekly' => $start->addWeek()->format('Y-m-d'),
            'monthly' => $start->addMonth()->format('Y-m-d'),
            'quarterly' => $start->addMonths(3)->format('Y-m-d'),
            'yearly' => $start->addYear()->format('Y-m-d'),
            default => $start->addMonth()->format('Y-m-d')
        };
    }

    /**
     * Helper: Get budget analytics by category.
     */
    private function getBudgetCategoryAnalytics($budgets)
    {
        return $budgets->groupBy('category.name')->map(function ($categoryBudgets) {
            return [
                'total_budgeted' => $categoryBudgets->sum('amount'),
                'total_spent' => $categoryBudgets->sum(function($budget) {
                    return $budget->getExpensesForPeriod();
                }),
                'budget_count' => $categoryBudgets->count(),
                'avg_utilization' => $categoryBudgets->avg('utilization_percentage')
            ];
        });
    }
}
