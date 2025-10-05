<?php

namespace App\Http\Controllers;

use App\Models\FinancialGoal;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

/**
 * @group Financial Goals Management
 *
 * APIs for managing user financial goals with progress tracking and analytics
 */
class FinancialGoalController extends Controller
{
    /**
     * Display a listing of the user's financial goals.
     *
     * Get all financial goals for the authenticated user with progress tracking and analytics.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @response 200 {
     *   "success": true,
     *   "data": [
     *     {
     *       "id": 1,
     *       "user_id": 1,
     *       "name": "Emergency Fund",
     *       "description": "Build a 6-month emergency fund",
     *       "type": "emergency_fund",
     *       "target_amount": 15000.00,
     *       "current_amount": 8500.00,
     *       "target_date": "2025-12-31",
     *       "start_date": "2025-01-01",
     *       "priority": "high",
     *       "monthly_contribution": 1000.00,
     *       "is_active": true,
     *       "is_achieved": false,
     *       "progress_percentage": 56.67,
     *       "days_remaining": 88,
     *       "required_monthly_contribution": 850.00,
     *       "is_on_track": true,
     *       "status": "on_track",
     *       "created_at": "2025-10-04T10:37:03.000000Z",
     *       "updated_at": "2025-10-04T10:37:03.000000Z"
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
     *   "message": "Failed to retrieve financial goals",
     *   "error": "Internal server error"
     * }
     */
    public function index(): JsonResponse
    {
        try {
            $userId = Auth::id();

            $goals = FinancialGoal::where('user_id', $userId)
                ->orderBy('created_at', 'desc')
                ->get();

            // Add computed attributes to each goal
            $goals->transform(function ($goal) {
                $goal->progress_percentage = $goal->getProgressPercentage();
                $goal->days_remaining = $goal->getDaysRemaining();
                $goal->required_monthly_contribution = $goal->getRequiredMonthlyContribution();
                $goal->is_on_track = $goal->isOnTrack();
                $goal->status = $goal->getStatus();
                return $goal;
            });

            return response()->json([
                'success' => true,
                'data' => $goals
            ]);

        } catch (\Exception $e) {
            Log::error('Financial Goals Index Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve financial goals',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Store a newly created financial goal.
     *
     * Create a new financial goal for the authenticated user with progress tracking.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @bodyParam name string required The goal name. Example: Emergency Fund
     * @bodyParam description string The goal description. Example: Build a 6-month emergency fund
     * @bodyParam type string required The goal type. Options: savings, debt_payoff, investment, purchase, emergency_fund, other. Example: emergency_fund
     * @bodyParam target_amount numeric required The target amount to achieve. Example: 15000.00
     * @bodyParam current_amount numeric The current amount saved (defaults to 0). Example: 8500.00
     * @bodyParam target_date string required The target achievement date (YYYY-MM-DD). Example: 2025-12-31
     * @bodyParam start_date string The start date (defaults to today). Example: 2025-01-01
     * @bodyParam priority string The goal priority. Options: low, medium, high. Example: high
     * @bodyParam monthly_contribution numeric The planned monthly contribution. Example: 1000.00
     * @bodyParam metadata array Additional metadata for the goal. Example: {"category": "savings"}
     *
     * @response 201 {
     *   "success": true,
     *   "message": "Financial goal created successfully",
     *   "data": {
     *     "id": 1,
     *     "user_id": 1,
     *     "name": "Emergency Fund",
     *     "description": "Build a 6-month emergency fund",
     *     "type": "emergency_fund",
     *     "target_amount": 15000.00,
     *     "current_amount": 8500.00,
     *     "target_date": "2025-12-31",
     *     "start_date": "2025-01-01",
     *     "priority": "high",
     *     "monthly_contribution": 1000.00,
     *     "is_active": true,
     *     "is_achieved": false,
     *     "progress_percentage": 56.67,
     *     "days_remaining": 88,
     *     "required_monthly_contribution": 850.00,
     *     "is_on_track": true,
     *     "status": "on_track",
     *     "created_at": "2025-10-04T10:37:03.000000Z",
     *     "updated_at": "2025-10-04T10:37:03.000000Z"
     *   }
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Validation failed",
     *   "errors": {
     *     "name": ["The name field is required."],
     *     "target_amount": ["The target amount must be at least 0.01."]
     *   }
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to create financial goal",
     *   "error": "Internal server error"
     * }
     */
    public function store(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'description' => 'nullable|string',
                'type' => 'required|in:savings,debt_payoff,investment,purchase,emergency_fund,other',
                'target_amount' => 'required|numeric|min:0.01',
                'current_amount' => 'nullable|numeric|min:0',
                'target_date' => 'required|date|after_or_equal:today',
                'start_date' => 'nullable|date|before_or_equal:target_date',
                'priority' => 'nullable|in:low,medium,high',
                'monthly_contribution' => 'nullable|numeric|min:0',
                'metadata' => 'nullable|array'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $userId = Auth::id();

            // Set default start date if not provided
            $startDate = $request->start_date ?? now()->format('Y-m-d');

            $goal = FinancialGoal::create([
                'user_id' => $userId,
                'name' => $request->name,
                'description' => $request->description,
                'type' => $request->type,
                'target_amount' => $request->target_amount,
                'current_amount' => $request->current_amount ?? 0,
                'target_date' => $request->target_date,
                'start_date' => $startDate,
                'priority' => $request->priority ?? 'medium',
                'monthly_contribution' => $request->monthly_contribution,
                'is_active' => true,
                'is_achieved' => false,
                'metadata' => $request->metadata ?? []
            ]);

            // Add computed attributes
            $goal->progress_percentage = $goal->getProgressPercentage();
            $goal->days_remaining = $goal->getDaysRemaining();
            $goal->required_monthly_contribution = $goal->getRequiredMonthlyContribution();
            $goal->is_on_track = $goal->isOnTrack();
            $goal->status = $goal->getStatus();

            return response()->json([
                'success' => true,
                'message' => 'Financial goal created successfully',
                'data' => $goal
            ], 201);

        } catch (\Exception $e) {
            Log::error('Financial Goal Creation Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to create financial goal',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Display the specified financial goal.
     *
     * Get detailed information about a specific financial goal including progress analytics.
     *
     * @authenticated
     * @security bearerAuth
     * @urlParam id integer required The financial goal ID. Example: 1
     *
     * @response 200 {
     *   "success": true,
     *   "data": {
     *     "id": 1,
     *     "user_id": 1,
     *     "name": "Emergency Fund",
     *     "description": "Build a 6-month emergency fund",
     *     "type": "emergency_fund",
     *     "target_amount": 15000.00,
     *     "current_amount": 8500.00,
     *     "target_date": "2025-12-31",
     *     "start_date": "2025-01-01",
     *     "priority": "high",
     *     "monthly_contribution": 1000.00,
     *     "is_active": true,
     *     "is_achieved": false,
     *     "progress_percentage": 56.67,
     *     "days_remaining": 88,
     *     "required_monthly_contribution": 850.00,
     *     "is_on_track": true,
     *     "status": "on_track",
     *     "created_at": "2025-10-04T10:37:03.000000Z",
     *     "updated_at": "2025-10-04T10:37:03.000000Z"
     *   }
     * }
     *
     * @response 404 {
     *   "success": false,
     *   "message": "Financial goal not found"
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to retrieve financial goal",
     *   "error": "Internal server error"
     * }
     */
    public function show(string $id): JsonResponse
    {
        try {
            $userId = Auth::id();

            $goal = FinancialGoal::where('user_id', $userId)
                ->where('id', $id)
                ->first();

            if (!$goal) {
                return response()->json([
                    'success' => false,
                    'message' => 'Financial goal not found'
                ], 404);
            }

            // Add computed attributes
            $goal->progress_percentage = $goal->getProgressPercentage();
            $goal->days_remaining = $goal->getDaysRemaining();
            $goal->required_monthly_contribution = $goal->getRequiredMonthlyContribution();
            $goal->is_on_track = $goal->isOnTrack();
            $goal->status = $goal->getStatus();

            return response()->json([
                'success' => true,
                'data' => $goal
            ]);

        } catch (\Exception $e) {
            Log::error('Financial Goal Show Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve financial goal',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Update the specified financial goal.
     *
     * Update an existing financial goal's information and settings.
     *
     * @authenticated
     * @security bearerAuth
     * @urlParam id integer required The financial goal ID. Example: 1
     *
     * @bodyParam name string The goal name. Example: Emergency Fund
     * @bodyParam description string The goal description. Example: Build a 6-month emergency fund
     * @bodyParam type string The goal type. Options: savings, debt_payoff, investment, purchase, emergency_fund, other. Example: emergency_fund
     * @bodyParam target_amount numeric The target amount to achieve. Example: 15000.00
     * @bodyParam current_amount numeric The current amount saved. Example: 8500.00
     * @bodyParam target_date string The target achievement date (YYYY-MM-DD). Example: 2025-12-31
     * @bodyParam start_date string The start date. Example: 2025-01-01
     * @bodyParam priority string The goal priority. Options: low, medium, high. Example: high
     * @bodyParam monthly_contribution numeric The planned monthly contribution. Example: 1000.00
     * @bodyParam is_active boolean Whether the goal is active. Example: true
     * @bodyParam is_achieved boolean Whether the goal is achieved. Example: false
     * @bodyParam metadata array Additional metadata for the goal. Example: {"category": "savings"}
     *
     * @response 200 {
     *   "success": true,
     *   "message": "Financial goal updated successfully",
     *   "data": {
     *     "id": 1,
     *     "user_id": 1,
     *     "name": "Emergency Fund",
     *     "description": "Build a 6-month emergency fund",
     *     "type": "emergency_fund",
     *     "target_amount": 15000.00,
     *     "current_amount": 8500.00,
     *     "target_date": "2025-12-31",
     *     "start_date": "2025-01-01",
     *     "priority": "high",
     *     "monthly_contribution": 1000.00,
     *     "is_active": true,
     *     "is_achieved": false,
     *     "progress_percentage": 56.67,
     *     "days_remaining": 88,
     *     "required_monthly_contribution": 850.00,
     *     "is_on_track": true,
     *     "status": "on_track",
     *     "created_at": "2025-10-04T10:37:03.000000Z",
     *     "updated_at": "2025-10-04T10:37:03.000000Z"
     *   }
     * }
     *
     * @response 404 {
     *   "success": false,
     *   "message": "Financial goal not found"
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Validation failed",
     *   "errors": {
     *     "name": ["The name field is required when updating."],
     *     "target_amount": ["The target amount must be at least 0.01."]
     *   }
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to update financial goal",
     *   "error": "Internal server error"
     * }
     */
    public function update(Request $request, string $id): JsonResponse
    {
        try {
            $userId = Auth::id();

            $goal = FinancialGoal::where('user_id', $userId)
                ->where('id', $id)
                ->first();

            if (!$goal) {
                return response()->json([
                    'success' => false,
                    'message' => 'Financial goal not found'
                ], 404);
            }

            $validator = Validator::make($request->all(), [
                'name' => 'sometimes|required|string|max:255',
                'description' => 'nullable|string',
                'type' => 'sometimes|required|in:savings,debt_payoff,investment,purchase,emergency_fund,other',
                'target_amount' => 'sometimes|required|numeric|min:0.01',
                'current_amount' => 'nullable|numeric|min:0',
                'target_date' => 'sometimes|required|date|after_or_equal:today',
                'start_date' => 'nullable|date|before_or_equal:target_date',
                'priority' => 'nullable|in:low,medium,high',
                'monthly_contribution' => 'nullable|numeric|min:0',
                'is_active' => 'boolean',
                'is_achieved' => 'boolean',
                'metadata' => 'nullable|array'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Update the goal
            $goal->update($request->only([
                'name', 'description', 'type', 'target_amount', 'current_amount',
                'target_date', 'start_date', 'priority', 'monthly_contribution',
                'is_active', 'is_achieved', 'metadata'
            ]));

            // Check if goal is achieved
            if ($goal->current_amount >= $goal->target_amount && !$goal->is_achieved) {
                $goal->is_achieved = true;
                $goal->save();
            }

            // Add computed attributes
            $goal->progress_percentage = $goal->getProgressPercentage();
            $goal->days_remaining = $goal->getDaysRemaining();
            $goal->required_monthly_contribution = $goal->getRequiredMonthlyContribution();
            $goal->is_on_track = $goal->isOnTrack();
            $goal->status = $goal->getStatus();

            return response()->json([
                'success' => true,
                'message' => 'Financial goal updated successfully',
                'data' => $goal
            ]);

        } catch (\Exception $e) {
            Log::error('Financial Goal Update Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to update financial goal',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Remove the specified financial goal.
     *
     * Delete an existing financial goal permanently.
     *
     * @authenticated
     * @security bearerAuth
     * @urlParam id integer required The financial goal ID. Example: 1
     *
     * @response 200 {
     *   "success": true,
     *   "message": "Financial goal deleted successfully"
     * }
     *
     * @response 404 {
     *   "success": false,
     *   "message": "Financial goal not found"
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to delete financial goal",
     *   "error": "Internal server error"
     * }
     */
    public function destroy(string $id): JsonResponse
    {
        try {
            $userId = Auth::id();

            $goal = FinancialGoal::where('user_id', $userId)
                ->where('id', $id)
                ->first();

            if (!$goal) {
                return response()->json([
                    'success' => false,
                    'message' => 'Financial goal not found'
                ], 404);
            }

            $goal->delete();

            return response()->json([
                'success' => true,
                'message' => 'Financial goal deleted successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Financial Goal Delete Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to delete financial goal',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Add progress to a financial goal.
     *
     * Add a contribution amount to a financial goal's current progress.
     *
     * @authenticated
     * @security bearerAuth
     * @urlParam id integer required The financial goal ID. Example: 1
     *
     * @bodyParam amount numeric required The amount to add to the goal. Example: 500.00
     *
     * @response 200 {
     *   "success": true,
     *   "message": "Progress added successfully",
     *   "data": {
     *     "previous_amount": 8500.00,
     *     "added_amount": 500.00,
     *     "current_amount": 9000.00,
     *     "is_achieved": false,
     *     "progress_percentage": 60.00
     *   }
     * }
     *
     * @response 404 {
     *   "success": false,
     *   "message": "Financial goal not found"
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Validation failed",
     *   "errors": {
     *     "amount": ["The amount must be at least 0.01."]
     *   }
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to add progress",
     *   "error": "Internal server error"
     * }
     */
    public function addProgress(Request $request, string $id): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'amount' => 'required|numeric|min:0.01'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $userId = Auth::id();

            $goal = FinancialGoal::where('user_id', $userId)
                ->where('id', $id)
                ->first();

            if (!$goal) {
                return response()->json([
                    'success' => false,
                    'message' => 'Financial goal not found'
                ], 404);
            }

            $oldAmount = $goal->current_amount;
            $goal->addProgress($request->amount);

            return response()->json([
                'success' => true,
                'message' => 'Progress added successfully',
                'data' => [
                    'previous_amount' => $oldAmount,
                    'added_amount' => $request->amount,
                    'current_amount' => $goal->current_amount,
                    'is_achieved' => $goal->is_achieved,
                    'progress_percentage' => $goal->getProgressPercentage()
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Financial Goal Progress Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to add progress',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }
}
