<?php

namespace App\Http\Controllers;

use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

/**
 * @group Category Management
 *
 * APIs for managing expense categories
 */
class CategoryController extends Controller
{
    /**
     * Display a listing of categories.
     *
     * Get all active categories for the authenticated user.
     *
     * @authenticated
     *
     * @response 200 {
     *   "success": true,
     *   "data": [
     *     {
     *       "id": 1,
     *       "user_id": 1,
     *       "name": "Food & Dining",
     *       "description": "Restaurants, groceries, and food delivery",
     *       "color": "#EF4444",
     *       "is_active": true,
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
    public function index(): JsonResponse
    {
        $categories = Category::forUser(Auth::id())
            ->active()
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $categories
        ]);
    }

    /**
     * Store a newly created category.
     *
     * Create a new expense category for the authenticated user.
     *
     * @authenticated
     *
     * @bodyParam name string required The category name. Example: Food & Dining
     * @bodyParam description string The category description. Example: Restaurants, groceries, and food delivery
     * @bodyParam color string The category color in hex format. Example: #EF4444
     * @bodyParam is_active boolean Whether the category is active. Example: true
     *
     * @response 201 {
     *   "success": true,
     *   "message": "Category created successfully",
     *   "data": {
     *     "id": 1,
     *     "user_id": 1,
     *     "name": "Food & Dining",
     *     "description": "Restaurants, groceries, and food delivery",
     *     "color": "#EF4444",
     *     "is_active": true,
     *     "created_at": "2025-10-04T10:37:22.000000Z",
     *     "updated_at": "2025-10-04T10:37:22.000000Z"
     *   }
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Validation failed",
     *   "errors": {
     *     "name": ["The name field is required."],
     *     "color": ["The color format is invalid."]
     *   }
     * }
     */
    public function store(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'description' => 'nullable|string',
                'color' => 'nullable|string|regex:/^#[0-9A-F]{6}$/i',
                'is_active' => 'boolean'
            ]);

            $category = Category::create([
                'user_id' => Auth::id(),
                'name' => $validated['name'],
                'description' => $validated['description'] ?? null,
                'color' => $validated['color'] ?? '#6B7280',
                'is_active' => $validated['is_active'] ?? true,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Category created successfully',
                'data' => $category
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
     * Display the specified category.
     *
     * Get detailed information about a specific category including associated expenses.
     *
     * @authenticated
     * @urlParam id integer required The category ID. Example: 1
     *
     * @response 200 {
     *   "success": true,
     *   "data": {
     *     "id": 1,
     *     "user_id": 1,
     *     "name": "Food & Dining",
     *     "description": "Restaurants, groceries, and food delivery",
     *     "color": "#EF4444",
     *     "is_active": true,
     *     "created_at": "2025-10-04T10:37:50.000000Z",
     *     "updated_at": "2025-10-04T10:37:50.000000Z",
     *     "expenses": [
     *       {
     *         "id": 1,
     *         "title": "Grocery Shopping",
     *         "amount": "85.50",
     *         "expense_date": "2025-09-10"
     *       }
     *     ]
     *   }
     * }
     *
     * @response 404 {
     *   "success": false,
     *   "message": "Category not found"
     * }
     */
    public function show(Category $category): JsonResponse
    {
        // Ensure user can only access their own categories
        if ($category->user_id !== Auth::id()) {
            return response()->json([
                'success' => false,
                'message' => 'Category not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $category->load('expenses')
        ]);
    }

    /**
     * Update the specified category.
     *
     * Update an existing category's information.
     *
     * @authenticated
     * @urlParam id integer required The category ID. Example: 1
     *
     * @bodyParam name string The category name. Example: Food & Dining
     * @bodyParam description string The category description. Example: Restaurants, groceries, and food delivery
     * @bodyParam color string The category color in hex format. Example: #EF4444
     * @bodyParam is_active boolean Whether the category is active. Example: true
     *
     * @response 200 {
     *   "success": true,
     *   "message": "Category updated successfully",
     *   "data": {
     *     "id": 1,
     *     "user_id": 1,
     *     "name": "Food & Dining",
     *     "description": "Restaurants, groceries, and food delivery",
     *     "color": "#EF4444",
     *     "is_active": true,
     *     "created_at": "2025-10-04T10:38:18.000000Z",
     *     "updated_at": "2025-10-04T10:38:18.000000Z"
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
     *     "name": ["The name field is required when updating."]
     *   }
     * }
     */
    public function update(Request $request, Category $category): JsonResponse
    {
        // Ensure user can only update their own categories
        if ($category->user_id !== Auth::id()) {
            return response()->json([
                'success' => false,
                'message' => 'Category not found'
            ], 404);
        }

        try {
            $validated = $request->validate([
                'name' => 'sometimes|required|string|max:255',
                'description' => 'nullable|string',
                'color' => 'nullable|string|regex:/^#[0-9A-F]{6}$/i',
                'is_active' => 'boolean'
            ]);

            $category->update($validated);

            return response()->json([
                'success' => true,
                'message' => 'Category updated successfully',
                'data' => $category
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
     * Remove the specified resource from storage.
     */
    public function destroy(Category $category): JsonResponse
    {
        // Ensure user can only delete their own categories
        if ($category->user_id !== Auth::id()) {
            return response()->json([
                'success' => false,
                'message' => 'Category not found'
            ], 404);
        }

        // Check if category has expenses
        if ($category->expenses()->count() > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Cannot delete category with existing expenses'
            ], 422);
        }

        $category->delete();

        return response()->json([
            'success' => true,
            'message' => 'Category deleted successfully'
        ]);
    }
}
