<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\DB;

/**
 * @group Expense Management
 *
 * APIs for managing user expenses with full CRUD operations and analytics
 */
class ExpenseController extends Controller
{
    /**
     * Display a listing of expenses.
     *
     * Get all expenses for the authenticated user with optional filtering and pagination.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @queryParam category_id integer Filter by category ID. Example: 1
     * @queryParam start_date string Filter expenses from this date (YYYY-MM-DD). Example: 2025-01-01
     * @queryParam end_date string Filter expenses until this date (YYYY-MM-DD). Example: 2025-12-31
     * @queryParam current_month boolean Filter for current month only. Example: true
     * @queryParam search string Search in title and description. Example: grocery
     * @queryParam page integer Page number for pagination. Example: 1
     * @queryParam per_page integer Items per page (max 100). Example: 15
     *
     * @response 200 {
     *   "success": true,
     *   "data": {
     *     "current_page": 1,
     *     "data": [
     *       {
     *         "id": 1,
     *         "user_id": 1,
     *         "category_id": 1,
     *         "title": "Grocery Shopping",
     *         "description": "Weekly groceries",
     *         "amount": "85.50",
     *         "expense_date": "2025-09-10",
     *         "payment_method": "card",
     *         "location": "SuperMart",
     *         "tags": ["food", "essentials"],
     *         "is_recurring": false,
     *         "recurrence_type": null,
     *         "created_at": "2025-10-04T10:37:03.000000Z",
     *         "updated_at": "2025-10-04T10:37:03.000000Z",
     *         "category": {
     *           "id": 1,
     *           "name": "Food & Dining",
     *           "color": "#EF4444"
     *         }
     *       }
     *     ],
     *     "first_page_url": "http://localhost:8000/api/expenses?page=1",
     *     "from": 1,
     *     "last_page": 5,
     *     "last_page_url": "http://localhost:8000/api/expenses?page=5",
     *     "links": [...],
     *     "next_page_url": "http://localhost:8000/api/expenses?page=2",
     *     "path": "http://localhost:8000/api/expenses",
     *     "per_page": 15,
     *     "prev_page_url": null,
     *     "to": 15,
     *     "total": 67
     *   }
     * }
     *
     * @response 401 {
     *   "message": "Unauthenticated."
     * }
     */
    public function index(Request $request): JsonResponse
    {
        $query = Expense::forUser(Auth::id())->with('category');

        // Filter by category
        if ($request->has('category_id')) {
            $query->byCategory($request->category_id);
        }

        // Filter by date range
        if ($request->has('start_date') && $request->has('end_date')) {
            $query->dateRange($request->start_date, $request->end_date);
        }

        // Filter by current month
        if ($request->has('current_month') && $request->current_month) {
            $query->currentMonth();
        }

        // Search by title or description
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        $expenses = $query->orderBy('expense_date', 'desc')
                         ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $expenses
        ]);
    }

    /**
     * Store a newly created expense.
     *
     * Create a new expense for the authenticated user.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @bodyParam category_id integer required The category ID for this expense. Must be owned by the user. Example: 1
     * @bodyParam title string required The expense title/description. Example: Grocery Shopping
     * @bodyParam description string The detailed description of the expense. Example: Weekly groceries from SuperMart
     * @bodyParam amount numeric required The expense amount. Example: 85.50
     * @bodyParam expense_date string required The date when the expense occurred (YYYY-MM-DD). Example: 2025-09-10
     * @bodyParam payment_method string required The payment method used. Options: cash, card, bank_transfer, mobile_money, other. Example: card
     * @bodyParam location string The location where the expense occurred. Example: SuperMart Downtown
     * @bodyParam tags array An array of tags for categorizing the expense. Example: ["food", "essentials"]
     * @bodyParam is_recurring boolean Whether this is a recurring expense. Example: false
     * @bodyParam recurrence_type string required_if The frequency of recurrence. Options: daily, weekly, monthly, yearly. Example: monthly
     *
     * @response 201 {
     *   "success": true,
     *   "message": "Expense created successfully",
     *   "data": {
     *     "id": 1,
     *     "user_id": 1,
     *     "category_id": 1,
     *     "title": "Grocery Shopping",
     *     "description": "Weekly groceries",
     *     "amount": "85.50",
     *     "expense_date": "2025-09-10",
     *     "payment_method": "card",
     *     "location": "SuperMart",
     *     "tags": ["food", "essentials"],
     *     "is_recurring": false,
     *     "recurrence_type": null,
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
     * @response 404 {
     *   "success": false,
     *   "message": "Category not found"
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Validation failed",
     *   "errors": {
     *     "category_id": ["The selected category_id is invalid."],
     *     "amount": ["The amount must be a number."]
     *   }
     * }
     */
    public function store(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'category_id' => 'required|exists:categories,id',
                'title' => 'required|string|max:255',
                'description' => 'nullable|string',
                'amount' => 'required|numeric|min:0',
                'expense_date' => 'required|date',
                'payment_method' => 'required|in:cash,card,bank_transfer,mobile_money,other',
                'location' => 'nullable|string|max:255',
                'tags' => 'nullable|array',
                'is_recurring' => 'boolean',
                'recurrence_type' => 'required_if:is_recurring,true|in:daily,weekly,monthly,yearly'
            ]);

            // Ensure user can only create expenses in their own categories
            $category = Category::where('id', $validated['category_id'])
                               ->where('user_id', Auth::id())
                               ->first();

            if (!$category) {
                return response()->json([
                    'success' => false,
                    'message' => 'Category not found'
                ], 404);
            }

            $expense = Expense::create([
                'user_id' => Auth::id(),
                'category_id' => $validated['category_id'],
                'title' => $validated['title'],
                'description' => $validated['description'] ?? null,
                'amount' => $validated['amount'],
                'expense_date' => $validated['expense_date'],
                'payment_method' => $validated['payment_method'],
                'location' => $validated['location'] ?? null,
                'tags' => $validated['tags'] ?? null,
                'is_recurring' => $validated['is_recurring'] ?? false,
                'recurrence_type' => $validated['recurrence_type'] ?? null,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Expense created successfully',
                'data' => $expense->load('category')
            ], 201);

        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        }
    }

    /**
     * Display the specified expense.
     *
     * Get detailed information about a specific expense including its category.
     *
     * @authenticated
     * @security bearerAuth
     * @urlParam id integer required The expense ID. Example: 1
     *
     * @response 200 {
     *   "success": true,
     *   "data": {
     *     "id": 1,
     *     "user_id": 1,
     *     "category_id": 1,
     *     "title": "Grocery Shopping",
     *     "description": "Weekly groceries",
     *     "amount": "85.50",
     *     "expense_date": "2025-09-10",
     *     "payment_method": "card",
     *     "location": "SuperMart",
     *     "tags": ["food", "essentials"],
     *     "is_recurring": false,
     *     "recurrence_type": null,
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
     * @response 404 {
     *   "success": false,
     *   "message": "Expense not found"
     * }
     */
    public function show(Expense $expense): JsonResponse
    {
        // Ensure user can only view their own expenses
        if ($expense->user_id !== Auth::id()) {
            return response()->json([
                'success' => false,
                'message' => 'Expense not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $expense->load('category')
        ]);
    }

    /**
     * Update the specified expense.
     *
     * Update an existing expense's information.
     *
     * @authenticated
     * @security bearerAuth
     * @urlParam id integer required The expense ID. Example: 1
     *
     * @bodyParam category_id integer The category ID for this expense. Must be owned by the user. Example: 1
     * @bodyParam title string The expense title/description. Example: Grocery Shopping
     * @bodyParam description string The detailed description of the expense. Example: Weekly groceries from SuperMart
     * @bodyParam amount numeric The expense amount. Example: 85.50
     * @bodyParam expense_date string The date when the expense occurred (YYYY-MM-DD). Example: 2025-09-10
     * @bodyParam payment_method string The payment method used. Options: cash, card, bank_transfer, mobile_money, other. Example: card
     * @bodyParam location string The location where the expense occurred. Example: SuperMart Downtown
     * @bodyParam tags array An array of tags for categorizing the expense. Example: ["food", "essentials"]
     * @bodyParam is_recurring boolean Whether this is a recurring expense. Example: false
     * @bodyParam recurrence_type string The frequency of recurrence. Options: daily, weekly, monthly, yearly. Example: monthly
     *
     * @response 200 {
     *   "success": true,
     *   "message": "Expense updated successfully",
     *   "data": {
     *     "id": 1,
     *     "user_id": 1,
     *     "category_id": 1,
     *     "title": "Grocery Shopping",
     *     "description": "Weekly groceries",
     *     "amount": "85.50",
     *     "expense_date": "2025-09-10",
     *     "payment_method": "card",
     *     "location": "SuperMart",
     *     "tags": ["food", "essentials"],
     *     "is_recurring": false,
     *     "recurrence_type": null,
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
     * @response 404 {
     *   "success": false,
     *   "message": "Expense not found"
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Validation failed",
     *   "errors": {
     *     "category_id": ["The selected category_id is invalid."],
     *     "amount": ["The amount must be a number."]
     *   }
     * }
     */
    public function update(Request $request, Expense $expense): JsonResponse
    {
        // Ensure user can only update their own expenses
        if ($expense->user_id !== Auth::id()) {
            return response()->json([
                'success' => false,
                'message' => 'Expense not found'
            ], 404);
        }

        try {
            $validated = $request->validate([
                'category_id' => 'sometimes|required|exists:categories,id',
                'title' => 'sometimes|required|string|max:255',
                'description' => 'nullable|string',
                'amount' => 'sometimes|required|numeric|min:0',
                'expense_date' => 'sometimes|required|date',
                'payment_method' => 'sometimes|required|in:cash,card,bank_transfer,mobile_money,other',
                'location' => 'nullable|string|max:255',
                'tags' => 'nullable|array',
                'is_recurring' => 'boolean',
                'recurrence_type' => 'required_if:is_recurring,true|in:daily,weekly,monthly,yearly'
            ]);

            // If category is being updated, ensure user owns it
            if (isset($validated['category_id'])) {
                $category = Category::where('id', $validated['category_id'])
                                   ->where('user_id', Auth::id())
                                   ->first();

                if (!$category) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Category not found'
                    ], 404);
                }
            }

            $expense->update($validated);

            return response()->json([
                'success' => true,
                'message' => 'Expense updated successfully',
                'data' => $expense->load('category')
            ]);

        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        }
    }

    /**
     * Remove the specified expense.
     *
     * Delete an existing expense permanently.
     *
     * @authenticated
     * @security bearerAuth
     * @urlParam id integer required The expense ID. Example: 1
     *
     * @response 200 {
     *   "success": true,
     *   "message": "Expense deleted successfully"
     * }
     *
     * @response 404 {
     *   "success": false,
     *   "message": "Expense not found"
     * }
     */
    public function destroy(Expense $expense): JsonResponse
    {
        // Ensure user can only delete their own expenses
        if ($expense->user_id !== Auth::id()) {
            return response()->json([
                'success' => false,
                'message' => 'Expense not found'
            ], 404);
        }

        $expense->delete();

        return response()->json([
            'success' => true,
            'message' => 'Expense deleted successfully'
        ]);
    }

    /**
     * Get expense statistics for dashboard.
     *
     * Retrieve comprehensive expense analytics including totals, category breakdowns, and monthly trends.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @queryParam start_date string Start date for statistics (YYYY-MM-DD). Defaults to 3 months ago. Example: 2025-01-01
     * @queryParam end_date string End date for statistics (YYYY-MM-DD). Defaults to current month end. Example: 2025-12-31
     *
     * @response 200 {
     *   "success": true,
     *   "data": {
     *     "total_expenses": 1250.75,
     *     "expense_count": 45,
     *     "expenses_by_category": [
     *       {
     *         "category": {
     *           "id": 1,
     *           "name": "Food & Dining",
     *           "color": "#EF4444"
     *         },
     *         "total": 450.25
     *       }
     *     ],
     *     "monthly_trend": [
     *       {
     *         "month": "2025-07",
     *         "total": 380.50
     *       },
     *       {
     *         "month": "2025-08",
     *         "total": 420.75
     *       }
     *     ],
     *     "date_range": {
     *       "start": "2025-07-01",
     *       "end": "2025-09-30"
     *     }
     *   }
     * }
     *
     * @response 401 {
     *   "message": "Unauthenticated."
     * }
     */
    public function statistics(Request $request): JsonResponse
    {
        $userId = Auth::id();

        // Date range filter - default to last 3 months to show seeded data
        $startDate = $request->get('start_date', now()->subMonths(3)->startOfMonth()->format('Y-m-d'));
        $endDate = $request->get('end_date', now()->endOfMonth()->format('Y-m-d'));

        // Total expenses in date range
        $totalExpenses = Expense::forUser($userId)
            ->dateRange($startDate, $endDate)
            ->sum('amount');

        // Total expense count in date range
        $expenseCount = Expense::forUser($userId)
            ->dateRange($startDate, $endDate)
            ->count();

        // Expenses by category
        $expensesByCategory = Expense::where('expenses.user_id', $userId)
            ->dateRange($startDate, $endDate)
            ->join('categories', function($join) use ($userId) {
                $join->on('expenses.category_id', '=', 'categories.id')
                     ->where('categories.user_id', '=', $userId);
            })
            ->select('categories.id', 'categories.name', 'categories.color', DB::raw('SUM(expenses.amount) as total'))
            ->groupBy('categories.id', 'categories.name', 'categories.color')
            ->get()
            ->map(function($expense) {
                return [
                    'category' => [
                        'id' => $expense->id,
                        'name' => $expense->name,
                        'color' => $expense->color
                    ],
                    'total' => $expense->total
                ];
            });

        // Monthly trend (last 6 months) - PostgreSQL compatible
        $monthlyTrend = Expense::forUser($userId)
            ->where('expense_date', '>=', now()->subMonths(6)->startOfMonth())
            ->select(
                DB::raw("TO_CHAR(expense_date, 'YYYY-MM') as month"),
                DB::raw('SUM(amount) as total')
            )
            ->groupBy('month')
            ->orderBy('month')
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'total_expenses' => $totalExpenses,
                'expense_count' => $expenseCount,
                'expenses_by_category' => $expensesByCategory,
                'monthly_trend' => $monthlyTrend,
                'date_range' => [
                    'start' => $startDate,
                    'end' => $endDate
                ]
            ]
        ]);
    }
}
