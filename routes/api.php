<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\ExpenseController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Public routes
Route::post('/register', [App\Http\Controllers\AuthController::class, 'register']);
Route::post('/login', [App\Http\Controllers\AuthController::class, 'login']);

// Protected routes
Route::middleware('auth.jwt')->group(function () {
    // User info
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    // Categories management
    Route::apiResource('categories', CategoryController::class);

    // Expenses management
    Route::apiResource('expenses', ExpenseController::class);

    // Expense statistics
    Route::get('/expenses/statistics/dashboard', [ExpenseController::class, 'statistics']);

    // Budget management
    Route::apiResource('budgets', App\Http\Controllers\BudgetController::class);
    Route::get('/budgets/statistics/dashboard', [App\Http\Controllers\BudgetController::class, 'statistics']);
    Route::post('/budgets/ai-suggestions', [App\Http\Controllers\BudgetController::class, 'getAISuggestions']);
    Route::post('/budgets/auto-adjust', [App\Http\Controllers\BudgetController::class, 'autoAdjust']);
    Route::get('/budgets/analytics/overview', [App\Http\Controllers\BudgetController::class, 'analytics']);

    // Financial goals management
    Route::apiResource('financial-goals', App\Http\Controllers\FinancialGoalController::class);

    // Cash flow tracking
    Route::apiResource('cash-flow', App\Http\Controllers\CashFlowController::class);
    Route::get('/cash-flow/monthly-trend', [App\Http\Controllers\CashFlowController::class, 'monthlyTrend']);
    Route::get('/cash-flow/balance/{startDate}/{endDate}', [App\Http\Controllers\CashFlowController::class, 'getBalance']);

    // Savings opportunities and categorization
    Route::get('/savings-opportunities', [App\Http\Controllers\SavingsOpportunityController::class, 'getSavingsOpportunities']);
    Route::get('/categorization-suggestions', [App\Http\Controllers\SavingsOpportunityController::class, 'getCategorizationSuggestions']);
    Route::post('/apply-categorization', [App\Http\Controllers\SavingsOpportunityController::class, 'applyCategorization']);
    Route::get('/subscription-analysis', [App\Http\Controllers\SavingsOpportunityController::class, 'getSubscriptionAnalysis']);

    // AI Insights endpoint (will be implemented next)
    Route::post('/ai/insights', [App\Http\Controllers\AIController::class, 'getInsights']);
    Route::post('/ai/predictive-analysis', [App\Http\Controllers\AIController::class, 'predictiveAnalysis']);
    Route::post('/ai/anomaly-detection', [App\Http\Controllers\AIController::class, 'detectAnomalies']);
    Route::get('/ai/comparative-analysis', [App\Http\Controllers\AIController::class, 'comparativeAnalysis']);

    // Logout
    Route::post('/logout', [App\Http\Controllers\AuthController::class, 'logout']);
});
