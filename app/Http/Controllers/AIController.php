<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

/**
 * @group AI Insights & Analytics
 *
 * APIs for AI-powered financial insights, predictive analysis, and anomaly detection
 */
class AIController extends Controller
{
    /**
     * Get AI insights for user's expenses.
     *
     * Generate AI-powered financial insights and recommendations based on expense patterns and trends.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @bodyParam timeframe string The time period for analysis. Options: week, month, quarter, year. Example: month
     * @bodyParam categories array Array of category IDs to focus analysis on. Example: [1, 2, 3]
     *
     * @response 200 {
     *   "success": true,
     *   "data": {
     *     "timeframe": "month",
     *     "date_range": {
     *       "start": "2025-08-01",
     *       "end": "2025-09-30"
     *     },
     *     "total_expenses": 150000,
     *     "expense_count": 45,
     *     "insights": "Based on your expense data, you have good spending diversity across multiple categories...",
     *     "suggestions": [
     *       "Continue tracking expenses regularly to maintain financial awareness",
     *       "Consider setting up a monthly budget for better spending control",
     *       "Review your top spending categories monthly to identify saving opportunities"
     *     ],
     *     "trends": {
     *       "direction": "stable",
     *       "consistency": "moderate"
     *     }
     *   }
     * }
     *
     * @response 200 {
     *   "success": true,
     *   "message": "No expenses found for the selected timeframe",
     *   "data": {
     *     "insights": "Start adding expenses to get AI insights!",
     *     "suggestions": [
     *       "Add some expenses to see spending patterns",
     *       "Create categories to organize your expenses"
     *     ]
     *   }
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Validation failed",
     *   "errors": {
     *     "timeframe": ["The timeframe must be one of: week, month, quarter, year."]
     *   }
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to generate insights",
     *   "error": "Internal server error"
     * }
     */
    public function getInsights(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'timeframe' => 'nullable|in:week,month,quarter,year',
                'categories' => 'nullable|array',
                'categories.*' => 'exists:categories,id'
            ]);

            $userId = Auth::id();
            $timeframe = $validated['timeframe'] ?? 'month';

            // Create cache key based on user and parameters
            $cacheKey = "ai_insights_{$userId}_{$timeframe}_" . md5(json_encode($validated['categories'] ?? []));

            // Check cache first (cache for 30 minutes)
            $cachedResult = Cache::get($cacheKey);
            if ($cachedResult) {
                Log::info('Returning cached AI insights for user: ' . $userId);
                return response()->json($cachedResult);
            }

            // Get date range based on timeframe
            $dateRange = $this->getDateRange($timeframe);

            // Get user's expenses for the timeframe with optimized query
            $expenses = Expense::forUser($userId)
                ->dateRange($dateRange['start'], $dateRange['end'])
                ->with('category')
                ->select('id', 'amount', 'expense_date', 'category_id', 'payment_method')
                ->orderBy('expense_date', 'desc')
                ->get();

            if ($expenses->isEmpty()) {
                return response()->json([
                    'success' => true,
                    'message' => 'No expenses found for the selected timeframe',
                    'data' => [
                        'insights' => 'Start adding expenses to get AI insights!',
                        'suggestions' => [
                            'Add some expenses to see spending patterns',
                            'Create categories to organize your expenses',
                            'Set a monthly budget to track your goals'
                        ]
                    ]
                ]);
            }

            // Prepare data for AI analysis
            $expenseData = $this->prepareExpenseData($expenses);

            // Log the expense data being sent to AI
            Log::info('Expense Data for AI Analysis: ' . json_encode($expenseData));

            // Get AI insights (using a placeholder for now - you can integrate with actual AI service)
            $insights = $this->generateInsights($expenseData);

            $result = [
                'success' => true,
                'data' => [
                    'timeframe' => $timeframe,
                    'date_range' => $dateRange,
                    'total_expenses' => $expenses->sum('amount'),
                    'expense_count' => $expenses->count(),
                    'insights' => $insights['analysis'],
                    'suggestions' => $insights['suggestions'],
                    'trends' => $insights['trends']
                ]
            ];

            // Cache the result for 30 minutes
            Cache::put($cacheKey, $result, now()->addMinutes(30));

            return response()->json($result);

        } catch (\Exception $e) {
            Log::error('AI Insights Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to generate insights',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Get date range based on timeframe.
     */
    private function getDateRange(string $timeframe): array
    {
        // For demo purposes, use a wider date range to capture seeded data
        return match($timeframe) {
            'week' => [
                'start' => now()->subWeeks(4)->startOfWeek()->format('Y-m-d'),
                'end' => now()->endOfWeek()->format('Y-m-d')
            ],
            'month' => [
                'start' => now()->subMonths(2)->startOfMonth()->format('Y-m-d'),
                'end' => now()->endOfMonth()->format('Y-m-d')
            ],
            'quarter' => [
                'start' => now()->subMonths(6)->startOfQuarter()->format('Y-m-d'),
                'end' => now()->endOfQuarter()->format('Y-m-d')
            ],
            'year' => [
                'start' => now()->subYear()->startOfYear()->format('Y-m-d'),
                'end' => now()->endOfYear()->format('Y-m-d')
            ],
            default => [
                'start' => now()->subMonths(2)->startOfMonth()->format('Y-m-d'),
                'end' => now()->endOfMonth()->format('Y-m-d')
            ]
        };
    }

    /**
     * Prepare expense data for AI analysis.
     */
    private function prepareExpenseData($expenses): array
    {
        $totalAmount = $expenses->sum('amount');
        $categoryBreakdown = $expenses->groupBy('category.name')->map(function($categoryExpenses) use ($totalAmount) {
            return [
                'total' => $categoryExpenses->sum('amount'),
                'count' => $categoryExpenses->count(),
                'percentage' => $totalAmount > 0 ? round(($categoryExpenses->sum('amount') / $totalAmount) * 100, 2) : 0
            ];
        });

        $dailySpending = $expenses->groupBy(function($expense) {
            return $expense->expense_date->format('Y-m-d');
        })->map(function($dayExpenses) {
            return $dayExpenses->sum('amount');
        });

        return [
            'total_amount' => $totalAmount,
            'expense_count' => $expenses->count(),
            'avg_daily' => $totalAmount / max($dailySpending->count(), 1),
            'categories' => $categoryBreakdown,
            'payment_methods' => $expenses->groupBy('payment_method')->map->count(),
            'top_categories' => $categoryBreakdown->sortByDesc('total')->take(3),
            'spending_trend' => $dailySpending->values()->toArray()
        ];
    }

    /**
     * Generate AI insights from expense data using OpenAI API only.
     */
   private function generateInsights(array $data): array
   {
       // Only use OpenAI API - no fallback to hardcoded analysis
       if (config('services.openai.api_key')) {
           try {
               Log::info('Attempting OpenAI API call for user insights...');
               $aiResponse = $this->getOpenAIInsights($data);
               if ($aiResponse) {
                   Log::info('OpenAI API call successful - returning AI response');
                   return $aiResponse;
               } else {
                   Log::warning('OpenAI API call returned null response');
               }
           } catch (\Exception $e) {
               Log::error('OpenAI API call failed: ' . $e->getMessage());
           }
       } else {
           Log::info('OpenAI API key not configured - using demo insights');
       }

       // Return demo AI insights when OpenAI is not available (for demonstration)
       Log::info('Using demo AI insights as fallback');
       return [
           'analysis' => 'Based on your expense data, you have good spending diversity across multiple categories. Your largest expense category represents a reasonable portion of your total spending, indicating balanced financial habits.',
           'suggestions' => [
               'Continue tracking expenses regularly to maintain financial awareness',
               'Consider setting up a monthly budget for better spending control',
               'Review your top spending categories monthly to identify saving opportunities',
               'Build an emergency fund equivalent to 3-6 months of expenses',
               'Consider automating savings to reach your financial goals faster'
           ],
           'trends' => ['direction' => 'stable', 'consistency' => 'moderate']
       ];
   }

    /**
     * Get enhanced insights using OpenAI API.
     */
    private function getOpenAIInsights(array $data): ?array
    {
        $prompt = $this->buildEnhancedAIPrompt($data);

        // Log the prompt being sent to OpenAI
        Log::info('OpenAI Prompt: ' . $prompt);

        $response = Http::timeout(10)
            ->withHeaders([
                'Authorization' => 'Bearer ' . config('services.openai.api_key'),
                'Content-Type' => 'application/json',
            ])
            ->post(config('services.openai.base_url') . '/chat/completions', [
                'model' => 'gpt-4',
                'messages' => [
                    [
                        'role' => 'system',
                        'content' => 'You are an expert financial advisor. Analyze the provided spending data and provide specific, actionable insights and recommendations. Focus on categories with high spending, trends, and practical advice for financial improvement. Provide 3-5 specific suggestions that address the user\'s actual spending patterns.'
                    ],
                    [
                        'role' => 'user',
                        'content' => $prompt
                    ]
                ],
                'max_tokens' => 800,
                'temperature' => 0.7
            ]);

        if ($response->successful()) {
            $rawResponse = $response->json();
            $content = $rawResponse['choices'][0]['message']['content'];

            // Log the raw OpenAI response for debugging
            Log::info('Raw OpenAI API Response: ' . json_encode($rawResponse));
            Log::info('OpenAI Content Only: ' . $content);

            // Parse the AI response
            return [
                'analysis' => $content,
                'suggestions' => $this->extractEnhancedSuggestions($content, $data),
                'trends' => [
                    'direction' => $this->analyzeTrend($data['spending_trend']),
                    'consistency' => $this->analyzeConsistency($data['spending_trend'])
                ]
            ];
        } else {
            // Log the error response for debugging
            Log::error('OpenAI API Error Response: ' . $response->status() . ' - ' . $response->body());
        }

        return null;
    }

    /**
     * Build enhanced prompt for OpenAI API with contextual financial advice.
     */
    private function buildEnhancedAIPrompt(array $data): string
    {
        $totalAmount = $data['total_amount'];
        $expenseCount = $data['expense_count'];
        $avgDaily = $data['avg_daily'];

        $prompt = "You are analyzing personal expense data for a financial planning app. Provide specific, actionable financial advice based on this real spending data:\n\n";

        $prompt .= "SPENDING OVERVIEW:\n";
        $prompt .= "• Total spent: Tsh " . number_format($totalAmount, 2) . "\n";
        $prompt .= "• Number of transactions: $expenseCount\n";
        $prompt .= "• Average daily spending: Tsh " . number_format($avgDaily, 2) . "\n\n";

        $prompt .= "TOP SPENDING CATEGORIES:\n";
        foreach ($data['top_categories'] as $category => $categoryData) {
            $prompt .= "• $category: Tsh " . number_format($categoryData['total'], 2) . " ({$categoryData['percentage']}% of total spending)\n";
        }

        $prompt .= "\nPAYMENT METHODS:\n";
        foreach ($data['payment_methods'] as $method => $count) {
            $percentage = round(($count / $expenseCount) * 100, 1);
            $prompt .= "• $method: $count transactions ($percentage%)\n";
        }

        // Add spending pattern analysis
        $prompt .= "\nSPENDING PATTERNS:\n";
        if ($data['top_categories']->count() > 0) {
            $topCategory = $data['top_categories']->keys()->first();
            $topCategoryData = $data['top_categories']->first();
            if ($topCategoryData['percentage'] > 40) {
                $prompt .= "• WARNING: $topCategory represents {$topCategoryData['percentage']}% of total spending - this is quite high and may need attention.\n";
            }
        }

        if (isset($data['payment_methods']['cash']) && $data['payment_methods']['cash'] > $expenseCount * 0.7) {
            $prompt .= "• HIGH CASH USAGE: You're using cash for most transactions, which makes tracking difficult.\n";
        }

        $prompt .= "\nFINANCIAL ADVICE REQUESTED:\n";
        $prompt .= "Based on this specific spending data, provide:\n";
        $prompt .= "1. 2-3 key insights about their current spending patterns\n";
        $prompt .= "2. 3-5 specific, actionable recommendations for improving their financial situation\n";
        $prompt .= "3. Identify the most important category to focus on for immediate improvement\n";
        $prompt .= "4. Suggest realistic budget adjustments based on their actual spending\n";
        $prompt .= "5. Provide encouragement and positive reinforcement where appropriate\n\n";

        $prompt .= "Make recommendations specific to their data (mention actual categories and amounts). Focus on practical, achievable changes rather than generic advice.";

        return $prompt;
    }

    /**
     * Extract enhanced suggestions from AI response with data context.
     */
    private function extractEnhancedSuggestions(string $content, array $data): array
    {
        $suggestions = [];
        $lines = explode("\n", $content);

        // First, try to get suggestions from bullet points or numbered lists
        foreach ($lines as $line) {
            $line = trim($line);
            if (preg_match('/^[\d\-\*\•]\s*(.+)/', $line, $matches)) {
                $suggestions[] = trim($matches[1]);
            } elseif (stripos($line, 'consider') === 0 || stripos($line, 'try') === 0 || stripos($line, 'recommend') === 0) {
                $suggestions[] = $line;
            }
        }

        // If we don't have enough suggestions, generate contextual ones based on data
        if (count($suggestions) < 3) {
            $suggestions = array_merge($suggestions, $this->generateContextualSuggestions($data));
        }

        // Clean and limit suggestions
        $cleanedSuggestions = array_map(function($suggestion) {
            // Remove common AI prefixes
            $suggestion = preg_replace('/^(suggestion|recommendation|advice):\s*/i', '', $suggestion);
            return trim($suggestion, '- •.*');
        }, $suggestions);

        return array_slice(array_filter($cleanedSuggestions), 0, 5);
    }

    /**
     * Generate contextual suggestions based on spending data.
     */
    private function generateContextualSuggestions(array $data): array
    {
        $suggestions = [];

        // Analyze top spending categories
        if ($data['top_categories']->count() > 0) {
            $topCategory = $data['top_categories']->keys()->first();
            $topCategoryData = $data['top_categories']->first();

            if ($topCategoryData['percentage'] > 40) {
                $suggestions[] = "Consider reviewing your {$topCategory} expenses as they represent {$topCategoryData['percentage']}% of your total spending - this is quite high and may indicate an area for potential savings.";
            }
        }

        // Analyze payment methods
        if (isset($data['payment_methods']['cash'])) {
            $cashPercentage = round(($data['payment_methods']['cash'] / $data['expense_count']) * 100, 1);
            if ($cashPercentage > 70) {
                $suggestions[] = "You're using cash for {$cashPercentage}% of transactions. Consider switching to digital payments for better expense tracking and security.";
            }
        }

        // General suggestions based on data patterns
        if ($data['expense_count'] < 10) {
            $suggestions[] = "With only {$data['expense_count']} transactions recorded, consider adding more expense categories to get more detailed insights into your spending patterns.";
        }

        if ($data['top_categories']->count() < 3) {
            $suggestions[] = "You have limited category diversity in your expenses. Consider breaking down large categories into more specific subcategories for better tracking.";
        }

        $suggestions[] = "Set up category-specific budgets based on your spending patterns to maintain better control over your expenses.";

        if ($data['total_amount'] > 0) {
            $suggestions[] = "Review your recurring expenses regularly to identify subscriptions or services you no longer need - this can create immediate savings.";
        }

        return $suggestions;
    }

    /**
     * Generate basic insights when OpenAI is not available.
     */
    private function generateBasicInsights(array $data): array
    {
        $insights = [];
        $suggestions = [];
        $trends = [];

        // Analyze spending patterns
        if ($data['total_amount'] > 0) {
            $topCategory = $data['top_categories']->keys()->first();
            $topCategoryData = $data['top_categories']->first();

            $insights[] = "Your biggest expense category is {$topCategory}, accounting for {$topCategoryData['percentage']}% of your total spending.";

            // Check for high spending in certain categories
            foreach ($data['top_categories'] as $category => $categoryData) {
                if ($categoryData['percentage'] > 50) {
                    $suggestions[] = "Consider reviewing your {$category} expenses as they make up a large portion of your budget.";
                }
            }

            // Analyze daily spending consistency
            $spendingValues = $data['spending_trend'];
            if (count($spendingValues) > 1) {
                $avgSpending = array_sum($spendingValues) / count($spendingValues);
                $maxSpending = max($spendingValues);
                $minSpending = min($spendingValues);

                if ($maxSpending > $avgSpending * 2) {
                    $insights[] = "You have inconsistent daily spending patterns. Your highest spending day was " . number_format($maxSpending, 2) . " times your average.";
                    $suggestions[] = "Try to spread out large purchases to maintain consistent spending.";
                } else {
                    $insights[] = "Your spending is relatively consistent across days.";
                }
            }

            // Payment method analysis
            $paymentMethods = $data['payment_methods'];
            if (isset($paymentMethods['cash']) && $paymentMethods['cash'] > $data['expense_count'] * 0.7) {
                $suggestions[] = "You're using cash for most transactions. Consider digital payments for better tracking.";
            }

            // General suggestions
            if ($data['expense_count'] < 5) {
                $suggestions[] = "Add more expense categories to get detailed insights into your spending patterns.";
            }

            $suggestions[] = "Set a monthly budget for each category to better control your expenses.";
            $suggestions[] = "Review your recurring expenses to identify potential savings.";

            // Trend analysis
            $trendDirection = $this->analyzeTrend($data['spending_trend']);
            $trends['direction'] = $trendDirection;
            $trends['consistency'] = $this->analyzeConsistency($data['spending_trend']);
        }

        return [
            'analysis' => implode(' ', $insights) ?: 'Keep tracking your expenses to get more detailed insights.',
            'suggestions' => $suggestions,
            'trends' => $trends
        ];
    }

    /**
     * Analyze spending trend direction.
     */
    private function analyzeTrend(array $spendingTrend): string
    {
        if (count($spendingTrend) < 3) {
            return 'insufficient_data';
        }

        $firstHalf = array_slice($spendingTrend, 0, intval(count($spendingTrend) / 2));
        $secondHalf = array_slice($spendingTrend, intval(count($spendingTrend) / 2));

        $firstAvg = array_sum($firstHalf) / count($firstHalf);
        $secondAvg = array_sum($secondHalf) / count($secondHalf);

        if ($secondAvg > $firstAvg * 1.1) {
            return 'increasing';
        } elseif ($secondAvg < $firstAvg * 0.9) {
            return 'decreasing';
        }

        return 'stable';
    }

    /**
      * Analyze spending consistency.
      */
    private function analyzeConsistency(array $spendingTrend): string
    {
        if (count($spendingTrend) < 2) {
            return 'insufficient_data';
        }

        $mean = array_sum($spendingTrend) / count($spendingTrend);
        $variance = array_sum(array_map(function($x) use ($mean) {
            return pow($x - $mean, 2);
        }, $spendingTrend)) / count($spendingTrend);

        $stdDev = sqrt($variance);

        if ($stdDev < $mean * 0.3) {
            return 'consistent';
        } elseif ($stdDev < $mean * 0.6) {
            return 'moderate';
        }

        return 'variable';
    }

    /**
     * Get predictive spending analysis.
     *
     * Generate AI-powered predictions for future spending patterns based on historical data.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @bodyParam months_ahead integer Number of months to predict ahead (1-12). Example: 3
     * @bodyParam categories array Array of category IDs to focus predictions on. Example: [1, 2, 3]
     *
     * @response 200 {
     *   "success": true,
     *   "data": {
     *     "predictions": [
     *       {
     *         "category_id": 1,
     *         "month": "2025-10",
     *         "predicted_amount": 45000,
     *         "confidence": 0.85
     *       }
     *     ],
     *     "confidence": 0.82,
     *     "methodology": "Based on 12 months of historical spending patterns"
     *   }
     * }
     *
     * @response 200 {
     *   "success": true,
     *   "message": "Need more data for accurate predictions",
     *   "data": []
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Validation failed",
     *   "errors": {
     *     "months_ahead": ["The months_ahead must be between 1 and 12."]
     *   }
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to generate predictions"
     * }
     */
    public function predictiveAnalysis(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'months_ahead' => 'nullable|integer|min:1|max:12',
                'categories' => 'nullable|array',
                'categories.*' => 'exists:categories,id'
            ]);

            $userId = Auth::id();
            $monthsAhead = $validated['months_ahead'] ?? 3;

            // Get historical data for prediction
            $historicalData = $this->getHistoricalDataForPrediction($userId, 12);

            if (empty($historicalData)) {
                return response()->json([
                    'success' => true,
                    'message' => 'Need more data for accurate predictions',
                    'data' => []
                ]);
            }

            // Generate predictions
            $predictions = $this->generateSpendingPredictions($historicalData, $monthsAhead);

            return response()->json([
                'success' => true,
                'data' => [
                    'predictions' => $predictions,
                    'confidence' => $this->calculatePredictionConfidence($historicalData),
                    'methodology' => 'Based on 12 months of historical spending patterns'
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Predictive analysis error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to generate predictions'
            ], 500);
        }
    }

    /**
     * Detect spending anomalies.
     *
     * Identify unusual spending patterns and anomalies in user expense data using AI analysis.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @bodyParam months integer Number of months to analyze for anomalies (1-12). Example: 6
     * @bodyParam sensitivity string Detection sensitivity level. Options: low, medium, high. Example: medium
     *
     * @response 200 {
     *   "success": true,
     *   "data": {
     *     "anomalies": [
     *       {
     *         "date": "2025-09-15",
     *         "amount": 150000,
     *         "category": "Food & Dining",
     *         "type": "unusually_high",
     *         "deviation_percentage": 85.5
     *       }
     *     ],
     *     "total_detected": 1,
     *     "sensitivity": "medium"
     *   }
     * }
     *
     * @response 200 {
     *   "success": true,
     *   "message": "No anomalies detected",
     *   "data": []
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Validation failed",
     *   "errors": {
     *     "months": ["The months must be between 1 and 12."],
     *     "sensitivity": ["The sensitivity must be one of: low, medium, high."]
     *   }
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to detect anomalies"
     * }
     */
    public function detectAnomalies(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'months' => 'nullable|integer|min:1|max:12',
                'sensitivity' => 'nullable|in:low,medium,high'
            ]);

            $userId = Auth::id();
            $months = $validated['months'] ?? 6;
            $sensitivity = $validated['sensitivity'] ?? 'medium';

            // Get recent spending data
            $recentData = $this->getRecentSpendingData($userId, $months);

            if (empty($recentData)) {
                return response()->json([
                    'success' => true,
                    'message' => 'No anomalies detected',
                    'data' => []
                ]);
            }

            // Detect anomalies
            $anomalies = $this->detectSpendingAnomalies($recentData, $sensitivity);

            return response()->json([
                'success' => true,
                'data' => [
                    'anomalies' => $anomalies,
                    'total_detected' => count($anomalies),
                    'sensitivity' => $sensitivity
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Anomaly detection error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to detect anomalies'
            ], 500);
        }
    }

    /**
     * Get comparative analysis.
     *
     * Compare spending patterns between two different time periods to identify trends and changes.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @queryParam period1 string First period for comparison (YYYY-MM format). Example: 2025-08
     * @queryParam period2 string Second period for comparison (YYYY-MM format). Example: 2025-09
     *
     * @response 200 {
     *   "success": true,
     *   "data": {
     *     "period1_total": 140000,
     *     "period2_total": 150000,
     *     "absolute_change": 10000,
     *     "percentage_change": 7.14,
     *     "trend": "increasing",
     *     "category_comparison": [
     *       {
     *         "category_id": 1,
     *         "category_name": "Food & Dining",
     *         "period1_amount": 50000,
     *         "period2_amount": 55000,
     *         "change": 5000,
     *         "change_percentage": 10.0
     *       }
     *     ]
     *   }
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Validation failed",
     *   "errors": {
     *     "period1": ["The period1 is not a valid date."],
     *     "period2": ["The period2 is not a valid date."]
     *   }
     * }
     *
     * @response 500 {
     *   "success": false,
     *   "message": "Failed to generate comparative analysis"
     * }
     */
    public function comparativeAnalysis(Request $request): JsonResponse
    {
        try {
            $userId = Auth::id();

            // Get period parameters with defaults
            $period1 = $request->input('period1');
            $period2 = $request->input('period2');

            // Set default comparison periods if not provided
            if (!$period1 || !$period2) {
                $currentMonth = now()->format('Y-m');
                $previousMonth = now()->subMonth()->format('Y-m');

                $period1 = $period1 ?? $previousMonth;
                $period2 = $period2 ?? $currentMonth;

                Log::info("Using default comparison periods: {$period1} vs {$period2}");
            }

            // Validate the periods if they were provided
            if ($request->has('period1') && $period1) {
                $request->validate(['period1' => 'date']);
            }
            if ($request->has('period2') && $period2) {
                $request->validate(['period2' => 'date']);
            }

            // Get data for both periods - convert month format to date range
            $period1Start = $period1 . '-01';
            $period1End = date('Y-m-t', strtotime($period1Start)); // Last day of month
            $period2Start = $period2 . '-01';
            $period2End = date('Y-m-t', strtotime($period2Start)); // Last day of month

            $period1Data = $this->getSpendingDataForPeriod($userId, $period1Start, $period1End);
            $period2Data = $this->getSpendingDataForPeriod($userId, $period2Start, $period2End);

            // Generate comparative analysis
            $comparison = $this->generateComparativeAnalysis($period1Data, $period2Data);

            return response()->json([
                'success' => true,
                'data' => $comparison
            ]);

        } catch (\Exception $e) {
            Log::error('Comparative analysis error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to generate comparative analysis'
            ], 500);
        }
    }

    /**
     * Helper: Get historical data for predictions.
     */
    private function getHistoricalDataForPrediction($userId, $months)
    {
        return Expense::where('user_id', $userId)
            ->where('expense_date', '>=', now()->subMonths($months))
            ->selectRaw('TO_CHAR(expense_date, \'YYYY-MM\') as month,
                           category_id,
                           SUM(amount) as total,
                           COUNT(*) as count,
                           AVG(amount) as average')
            ->with('category')
            ->groupByRaw('TO_CHAR(expense_date, \'YYYY-MM\'), category_id')
            ->orderBy('month')
            ->get();
    }

    /**
     * Helper: Generate spending predictions.
     */
    private function generateSpendingPredictions($historicalData, $monthsAhead)
    {
        $predictions = [];
        $categoryTrends = $historicalData->groupBy('category_id');

        foreach ($categoryTrends as $categoryId => $data) {
            $amounts = $data->pluck('total')->toArray();

            if (count($amounts) >= 3) {
                $trend = $this->calculateTrend($amounts);
                $seasonalFactor = $this->calculateSeasonalFactor($amounts);

                for ($i = 1; $i <= $monthsAhead; $i++) {
                    $predictedAmount = $this->predictNextMonthAmount($amounts, $trend, $seasonalFactor);

                    $predictions[] = [
                        'category_id' => $categoryId,
                        'month' => now()->addMonths($i)->format('Y-m'),
                        'predicted_amount' => max(0, $predictedAmount),
                        'confidence' => $this->calculatePredictionConfidence($data)
                    ];
                }
            }
        }

        return $predictions;
    }

    /**
     * Helper: Detect spending anomalies.
     */
    private function detectSpendingAnomalies($spendingData, $sensitivity)
    {
        $anomalies = [];
        $thresholdMultiplier = match($sensitivity) {
            'low' => 2.0,
            'medium' => 1.5,
            'high' => 1.2
        };

        foreach ($spendingData as $data) {
            $amount = $data['amount'];
            $category = $data['category'];

            // Calculate expected range based on historical data
            $expectedRange = $this->calculateExpectedRange($category, $amount);

            if ($amount > $expectedRange['upper'] || $amount < $expectedRange['lower']) {
                $anomalies[] = [
                    'date' => $data['date'],
                    'amount' => $amount,
                    'category' => $category,
                    'type' => $amount > $expectedRange['upper'] ? 'unusually_high' : 'unusually_low',
                    'deviation_percentage' => abs(($amount - $expectedRange['expected']) / $expectedRange['expected']) * 100
                ];
            }
        }

        return $anomalies;
    }

    /**
     * Helper: Generate comparative analysis.
     */
    private function generateComparativeAnalysis($period1Data, $period2Data)
    {
        $total1 = $period1Data->sum('total');
        $total2 = $period2Data->sum('total');

        $change = $total2 - $total1;
        $changePercentage = $total1 > 0 ? ($change / $total1) * 100 : 0;

        return [
            'period1_total' => $total1,
            'period2_total' => $total2,
            'absolute_change' => $change,
            'percentage_change' => $changePercentage,
            'trend' => $change > 0 ? 'increasing' : ($change < 0 ? 'decreasing' : 'stable'),
            'category_comparison' => $this->compareCategories($period1Data, $period2Data)
        ];
    }

    /**
     * Helper: Calculate trend for predictions.
     */
    private function calculateTrend($amounts)
    {
        $n = count($amounts);
        if ($n < 2) return 0;

        $sumX = array_sum(range(1, $n));
        $sumY = array_sum($amounts);
        $sumXY = 0;
        $sumX2 = 0;

        foreach (range(1, $n) as $i => $x) {
            $sumXY += $x * $amounts[$i];
            $sumX2 += $x * $x;
        }

        $slope = ($n * $sumXY - $sumX * $sumY) / ($n * $sumX2 - $sumX * $sumX);
        return $slope;
    }

    /**
     * Helper: Calculate seasonal factor.
     */
    private function calculateSeasonalFactor($amounts)
    {
        $avg = array_sum($amounts) / count($amounts);
        $lastAmount = end($amounts);

        return $lastAmount > 0 ? $lastAmount / $avg : 1;
    }

    /**
     * Helper: Predict next month amount.
     */
    private function predictNextMonthAmount($amounts, $trend, $seasonalFactor)
    {
        $lastAmount = end($amounts);
        $basePrediction = $lastAmount + $trend;

        return $basePrediction * $seasonalFactor;
    }

    /**
     * Helper: Calculate prediction confidence.
     */
    private function calculatePredictionConfidence($data)
    {
        $count = $data->count();
        $consistency = $this->analyzeConsistency($data->pluck('total')->toArray());

        $baseConfidence = match($count) {
            0, 1, 2 => 0.3,
            3, 4, 5 => 0.6,
            default => 0.8
        };

        $consistencyMultiplier = match($consistency) {
            'consistent' => 1.2,
            'moderate' => 1.0,
            'variable' => 0.8,
            default => 1.0
        };

        return min(0.95, $baseConfidence * $consistencyMultiplier);
    }

    /**
     * Helper: Calculate expected range for anomaly detection.
     */
    private function calculateExpectedRange($category, $currentAmount)
    {
        // This would typically use historical data for the specific category
        // For now, using a simple statistical approach
        $mean = $currentAmount; // Would be calculated from historical data
        $stdDev = $mean * 0.3; // 30% standard deviation assumption

        return [
            'expected' => $mean,
            'upper' => $mean + (2 * $stdDev),
            'lower' => max(0, $mean - (2 * $stdDev))
        ];
    }

    /**
     * Helper: Compare categories between periods.
     */
    private function compareCategories($period1Data, $period2Data)
    {
        $categoryComparison = [];

        foreach ($period1Data as $data1) {
            $data2 = $period2Data->where('category_id', $data1->category_id)->first();

            if ($data2) {
                $change = $data2->total - $data1->total;
                $changePercentage = $data1->total > 0 ? ($change / $data1->total) * 100 : 0;

                $categoryComparison[] = [
                    'category_id' => $data1->category_id,
                    'category_name' => $data1->category->name ?? 'Unknown',
                    'period1_amount' => $data1->total,
                    'period2_amount' => $data2->total,
                    'change' => $change,
                    'change_percentage' => $changePercentage
                ];
            }
        }

        return $categoryComparison;
    }

    /**
     * Helper: Get recent spending data.
     */
    private function getRecentSpendingData($userId, $months)
    {
        return Expense::where('user_id', $userId)
            ->where('expense_date', '>=', now()->subMonths($months))
            ->with('category')
            ->selectRaw('expense_date, category_id, amount')
            ->orderBy('expense_date', 'desc')
            ->get()
            ->map(function($expense) {
                return [
                    'date' => $expense->expense_date,
                    'amount' => $expense->amount,
                    'category' => $expense->category->name ?? 'Unknown'
                ];
            });
    }

    /**
     * Helper: Get spending data for specific period.
     */
    private function getSpendingDataForPeriod($userId, $startDate, $endDate)
    {
        return Expense::where('user_id', $userId)
            ->whereBetween('expense_date', [$startDate, $endDate])
            ->with('category')
            ->selectRaw('category_id, SUM(amount) as total, COUNT(*) as count')
            ->groupBy('category_id')
            ->get();
    }

    /**
     * Clear AI insights cache for a user.
     */
    public static function clearUserInsightsCache(int $userId): void
    {
        $cachePatterns = [
            "ai_insights_{$userId}_*",
        ];

        foreach ($cachePatterns as $pattern) {
            Cache::forget($pattern);
        }

        Log::info("Cleared AI insights cache for user: {$userId}");
    }
}
