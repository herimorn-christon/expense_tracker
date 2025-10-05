<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use App\Models\CashFlow;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

/**
 * @group Cash Flow Management
 *
 * APIs for tracking and analyzing cash flow patterns and trends
 */
class CashFlowController extends Controller
{
    /**
     * Display a listing of cash flow entries.
     *
     * Get all cash flow entries for the authenticated user with optional filtering.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @queryParam start_date string Filter from this date (YYYY-MM-DD). Example: 2025-01-01
     * @queryParam end_date string Filter until this date (YYYY-MM-DD). Example: 2025-12-31
     * @queryParam type string Filter by cash flow type. Options: income, expense. Example: expense
     *
     * @response 200 {
     *   "success": true,
     *   "data": [
     *     {
     *       "id": 1,
     *       "user_id": 1,
     *       "amount": 500.00,
     *       "type": "expense",
     *       "description": "Monthly groceries",
     *       "date": "2025-09-15",
     *       "category": "Food & Dining",
     *       "created_at": "2025-10-04T10:37:03.000000Z",
     *       "updated_at": "2025-10-04T10:37:03.000000Z"
     *     }
     *   ]
     * }
     *
     * @response 401 {
     *   "message": "Unauthenticated."
     * }
     */
    public function index(Request $request): JsonResponse
    {
        $userId = Auth::id();
        $query = CashFlow::where('user_id', $userId);

        // Apply filters
        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereBetween('date', [$request->start_date, $request->end_date]);
        }

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        $cashFlow = $query->orderBy('date', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $cashFlow
        ]);
    }

    /**
     * Store a newly created cash flow entry.
     *
     * Create a new cash flow entry for the authenticated user.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @bodyParam amount numeric required The cash flow amount. Example: 500.00
     * @bodyParam type string required The cash flow type. Options: income, expense. Example: expense
     * @bodyParam description string required The cash flow description. Example: Monthly groceries
     * @bodyParam date string required The cash flow date (YYYY-MM-DD). Example: 2025-09-15
     * @bodyParam category string The cash flow category. Example: Food & Dining
     *
     * @response 201 {
     *   "success": true,
     *   "message": "Cash flow entry created successfully",
     *   "data": {
     *     "id": 1,
     *     "user_id": 1,
     *     "amount": 500.00,
     *     "type": "expense",
     *     "description": "Monthly groceries",
     *     "date": "2025-09-15",
     *     "category": "Food & Dining",
     *     "created_at": "2025-10-04T10:37:03.000000Z",
     *     "updated_at": "2025-10-04T10:37:03.000000Z"
     *   }
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Validation failed",
     *   "errors": {
     *     "amount": ["The amount field is required."],
     *     "type": ["The type must be either income or expense."]
     *   }
     * }
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount' => 'required|numeric|min:0',
            'type' => 'required|in:income,expense',
            'description' => 'required|string|max:255',
            'date' => 'required|date',
            'category' => 'nullable|string|max:255'
        ]);

        $cashFlow = CashFlow::create([
            'user_id' => Auth::id(),
            ...$validated
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Cash flow entry created successfully',
            'data' => $cashFlow
        ], 201);
    }

    /**
     * Display the specified cash flow entry.
     *
     * Get detailed information about a specific cash flow entry.
     *
     * @authenticated
     * @security bearerAuth
     * @urlParam id integer required The cash flow entry ID. Example: 1
     *
     * @response 200 {
     *   "success": true,
     *   "data": {
     *     "id": 1,
     *     "user_id": 1,
     *     "amount": 500.00,
     *     "type": "expense",
     *     "description": "Monthly groceries",
     *     "date": "2025-09-15",
     *     "category": "Food & Dining",
     *     "created_at": "2025-10-04T10:37:03.000000Z",
     *     "updated_at": "2025-10-04T10:37:03.000000Z"
     *   }
     * }
     *
     * @response 404 {
     *   "success": false,
     *   "message": "Cash flow entry not found"
     * }
     */
    public function show(string $id): JsonResponse
    {
        $cashFlow = CashFlow::where('user_id', Auth::id())
            ->where('id', $id)
            ->first();

        if (!$cashFlow) {
            return response()->json([
                'success' => false,
                'message' => 'Cash flow entry not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $cashFlow
        ]);
    }

    /**
     * Update the specified cash flow entry.
     *
     * Update an existing cash flow entry's information.
     *
     * @authenticated
     * @security bearerAuth
     * @urlParam id integer required The cash flow entry ID. Example: 1
     *
     * @bodyParam amount numeric The cash flow amount. Example: 550.00
     * @bodyParam type string The cash flow type. Options: income, expense. Example: expense
     * @bodyParam description string The cash flow description. Example: Updated monthly groceries
     * @bodyParam date string The cash flow date (YYYY-MM-DD). Example: 2025-09-15
     * @bodyParam category string The cash flow category. Example: Food & Dining
     *
     * @response 200 {
     *   "success": true,
     *   "message": "Cash flow entry updated successfully",
     *   "data": {
     *     "id": 1,
     *     "user_id": 1,
     *     "amount": 550.00,
     *     "type": "expense",
     *     "description": "Updated monthly groceries",
     *     "date": "2025-09-15",
     *     "category": "Food & Dining",
     *     "created_at": "2025-10-04T10:37:03.000000Z",
     *     "updated_at": "2025-10-04T10:37:03.000000Z"
     *   }
     * }
     *
     * @response 404 {
     *   "success": false,
     *   "message": "Cash flow entry not found"
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Validation failed",
     *   "errors": {
     *     "amount": ["The amount must be a number."],
     *     "type": ["The type must be either income or expense."]
     *   }
     * }
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $cashFlow = CashFlow::where('user_id', Auth::id())
            ->where('id', $id)
            ->first();

        if (!$cashFlow) {
            return response()->json([
                'success' => false,
                'message' => 'Cash flow entry not found'
            ], 404);
        }

        $validated = $request->validate([
            'amount' => 'sometimes|required|numeric|min:0',
            'type' => 'sometimes|required|in:income,expense',
            'description' => 'sometimes|required|string|max:255',
            'date' => 'sometimes|required|date',
            'category' => 'nullable|string|max:255'
        ]);

        $cashFlow->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Cash flow entry updated successfully',
            'data' => $cashFlow
        ]);
    }

    /**
     * Remove the specified cash flow entry.
     *
     * Delete an existing cash flow entry permanently.
     *
     * @authenticated
     * @security bearerAuth
     * @urlParam id integer required The cash flow entry ID. Example: 1
     *
     * @response 200 {
     *   "success": true,
     *   "message": "Cash flow entry deleted successfully"
     * }
     *
     * @response 404 {
     *   "success": false,
     *   "message": "Cash flow entry not found"
     * }
     */
    public function destroy(string $id): JsonResponse
    {
        $cashFlow = CashFlow::where('user_id', Auth::id())
            ->where('id', $id)
            ->first();

        if (!$cashFlow) {
            return response()->json([
                'success' => false,
                'message' => 'Cash flow entry not found'
            ], 404);
        }

        $cashFlow->delete();

        return response()->json([
            'success' => true,
            'message' => 'Cash flow entry deleted successfully'
        ]);
    }

    /**
     * Get monthly cash flow trend.
     *
     * Retrieve cash flow trends aggregated by month for the authenticated user.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @queryParam months integer Number of months to analyze (default: 12). Example: 6
     *
     * @response 200 {
     *   "success": true,
     *   "data": [
     *     {
     *       "month": "2025-09",
     *       "income": 5000.00,
     *       "expenses": 3500.00,
     *       "net_flow": 1500.00
     *     },
     *     {
     *       "month": "2025-08",
     *       "income": 4800.00,
     *       "expenses": 3200.00,
     *       "net_flow": 1600.00
     *     }
     *   ]
     * }
     *
     * @response 401 {
     *   "message": "Unauthenticated."
     * }
     */
    public function monthlyTrend(Request $request): JsonResponse
    {
        $userId = Auth::id();
        $months = $request->get('months', 12);

        $trends = CashFlow::where('user_id', $userId)
            ->where('date', '>=', now()->subMonths($months)->startOfMonth())
            ->selectRaw("
                DATE_FORMAT(date, '%Y-%m') as month,
                SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as income,
                SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as expenses,
                SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END) as net_flow
            ")
            ->groupBy('month')
            ->orderBy('month', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $trends
        ]);
    }

    /**
     * Get cash flow balance for date range.
     *
     * Calculate the net cash flow balance between two dates.
     *
     * @authenticated
     * @security bearerAuth
     * @urlParam startDate string required The start date (YYYY-MM-DD). Example: 2025-01-01
     * @urlParam endDate string required The end date (YYYY-MM-DD). Example: 2025-12-31
     *
     * @response 200 {
     *   "success": true,
     *   "data": {
     *     "start_date": "2025-01-01",
     *     "end_date": "2025-12-31",
     *     "total_income": 50000.00,
     *     "total_expenses": 35000.00,
     *     "net_balance": 15000.00,
     *     "transaction_count": 245
     *   }
     * }
     *
     * @response 401 {
     *   "message": "Unauthenticated."
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Invalid date format"
     * }
     */
    public function getBalance(string $startDate, string $endDate): JsonResponse
    {
        try {
            $start = \Carbon\Carbon::parse($startDate);
            $end = \Carbon\Carbon::parse($endDate);

            if ($start->after($end)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Start date must be before end date'
                ], 422);
            }
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid date format'
            ], 422);
        }

        $userId = Auth::id();

        $balance = CashFlow::where('user_id', $userId)
            ->whereBetween('date', [$startDate, $endDate])
            ->selectRaw("
                SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as total_income,
                SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as total_expenses,
                SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END) as net_balance,
                COUNT(*) as transaction_count
            ")
            ->first();

        return response()->json([
            'success' => true,
            'data' => [
                'start_date' => $startDate,
                'end_date' => $endDate,
                'total_income' => $balance->total_income ?? 0,
                'total_expenses' => $balance->total_expenses ?? 0,
                'net_balance' => $balance->net_balance ?? 0,
                'transaction_count' => $balance->transaction_count ?? 0
            ]
        ]);
    }
}
