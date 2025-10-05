<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/**
 * @group Authentication
 *
 * APIs for user authentication and authorization
 *
 * ## Authentication Flow
 *
 * 1. **Register** a new account or **Login** with existing credentials
 * 2. **Copy the token** from the response (field: `data.token`)
 * 3. **Click "Authorize"** button in Swagger UI (top right)
 * 4. **Enter token** in format: `Bearer {your_token_here}`
 * 5. **Now you can test** all protected endpoints
 *
 * ## Using the Bearer Token
 *
 * After successful login/register, you'll receive a token like:
 * `1|WNKYnSyHSw3CSMqWkwmXOa43nutFzT6Xwg3LnbEI136c0def`
 *
 * In Swagger UI:
 * - Click the "Authorize" button (🔒 icon)
 * - Enter: `Bearer 1|WNKYnSyHSw3CSMqWkwmXOa43nutFzT6Xwg3LnbEI136c0def`
 * - Click "Authorize"
 * - Now all protected endpoints will include the token automatically
 */
class AuthController extends Controller
{
    /**
     * Register a new user.
     *
     * Create a new user account with name, email, and password.
     *
     * @bodyParam name string required The user's full name. Example: John Doe
     * @bodyParam email string required The user's email address. Must be unique. Example: john@example.com
     * @bodyParam password string required The user's password (minimum 8 characters). Example: password123
     * @bodyParam password_confirmation string required Must match the password field. Example: password123
     *
     * @response 201 {
     *   "success": true,
     *   "message": "User registered successfully",
     *   "data": {
     *     "user": {
     *       "id": 1,
     *       "name": "John Doe",
     *       "email": "john@example.com",
     *       "email_verified_at": null,
     *       "created_at": "2025-10-04T10:34:47.000000Z",
     *       "updated_at": "2025-10-04T10:34:47.000000Z"
     *     },
     *     "token": "1|WNKYnSyHSw3CSMqWkwmXOa43nutFzT6Xwg3LnbEI136c0def"
     *   }
     * }
     *
     * @response 200 {
     *   "success": true,
     *   "message": "User registered successfully",
     *   "data": {
     *     "user": {
     *       "id": 1,
     *       "name": "John Doe",
     *       "email": "john@example.com"
     *     },
     *     "token": "1|WNKYnSyHSw3CSMqWkwmXOa43nutFzT6Xwg3LnbEI136c0def"
     *   }
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Validation failed",
     *   "errors": {
     *     "email": ["The email has already been taken."],
     *     "password": ["The password must be at least 8 characters."]
     *   }
     * }
     */
    public function register(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'email' => 'required|string|email|max:255|unique:users',
                'password' => 'required|string|min:8|confirmed',
            ]);

            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'password' => Hash::make($validated['password']),
            ]);

            $token = $user->createToken('expense-tracker-token')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'User registered successfully',
                'data' => [
                    'user' => $user,
                    'token' => $token
                ]
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
     * Login user and return token.
     *
     * Authenticate user with email and password and return JWT token.
     *
     * @bodyParam email string required The user's email address. Example: john@example.com
     * @bodyParam password string required The user's password. Example: password123
     *
     * @response 200 {
     *   "success": true,
     *   "message": "Login successful",
     *   "data": {
     *     "user": {
     *       "id": 1,
     *       "name": "John Doe",
     *       "email": "john@example.com",
     *       "email_verified_at": null,
     *       "created_at": "2025-10-04T10:34:47.000000Z",
     *       "updated_at": "2025-10-04T10:34:47.000000Z"
     *     },
     *     "token": "1|WNKYnSyHSw3CSMqWkwmXOa43nutFzT6Xwg3LnbEI136c0def"
     *   }
     * }
     *
     * @response 401 {
     *   "success": false,
     *   "message": "Invalid credentials"
     * }
     *
     * @response 422 {
     *   "success": false,
     *   "message": "Validation failed",
     *   "errors": {
     *     "email": ["The email field is required."],
     *     "password": ["The password field is required."]
     *   }
     * }
     */
    public function login(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'email' => 'required|string|email',
                'password' => 'required|string',
            ]);

            if (!Auth::attempt($validated)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid credentials'
                ], 401);
            }

            $user = Auth::user();
            $token = $user->createToken('expense-tracker-token')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'Login successful',
                'data' => [
                    'user' => $user,
                    'token' => $token
                ]
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
     * Logout user and revoke token.
     *
     * Revoke the current user's access token, effectively logging them out.
     *
     * @authenticated
     * @security bearerAuth
     *
     * @response 200 {
     *   "success": true,
     *   "message": "Logout successful"
     * }
     *
     * @response 401 {
     *   "message": "Unauthenticated."
     * }
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logout successful'
        ]);
    }
}
