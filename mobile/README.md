# Expense Tracker Mobile App

A Flutter-based expense tracking application with JWT authentication, real-time data synchronization, and comprehensive user management.

## Features

- **🔐 JWT Authentication** - Secure user authentication using JSON Web Tokens
- **📊 Dashboard Analytics** - Real-time expense statistics and budget tracking
- **👥 Multi-User Support** - User-specific data isolation and management
- **📱 Responsive Design** - Optimized for mobile devices
- **🔄 Real-Time Sync** - Automatic data refresh and synchronization
- **📈 Data Visualization** - Interactive charts and expense breakdowns

## Architecture

### Authentication System
- **JWT Token Management** - Secure storage and automatic token refresh
- **User Session Handling** - Persistent login state with secure token storage
- **API Integration** - Laravel backend with JWT authentication middleware

### Key Components

#### Core Services
- `ApiClient` - HTTP client with JWT token injection and error handling
- `AuthService` - User authentication, registration, and session management
- `DashboardService` - Expense statistics and analytics data fetching
- `CategoryService` - Category management with user-specific filtering

#### State Management
- Provider pattern for state management
- ViewModels for business logic separation
- Reactive UI updates with real-time data

## JWT Authentication Implementation

### Token Storage
```dart
// Secure token storage using FlutterSecureStorage
await _storage.write(key: 'token', value: jwtToken);
```

### API Client Integration
```dart
// Automatic JWT token injection in API requests
final token = await _storage.read(key: 'token');
if (token != null) {
  options.headers['Authorization'] = 'Bearer $token';
}
```

### Authentication Flow
1. **Login/Register** - User credentials sent to Laravel API
2. **Token Reception** - JWT token received and stored securely
3. **API Requests** - Token automatically included in all API calls
4. **Token Validation** - Server validates token and returns user-specific data
5. **Auto-Logout** - Invalid tokens automatically removed

## API Integration

### Base Configuration
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.1.104:8000/api',
);
```

### Request Interceptors
- **Request Interceptor** - Automatically adds JWT token to requests
- **Error Interceptor** - Handles 401 errors and token cleanup
- **Logging Interceptor** - Debug logging for development

## User Data Isolation

The application ensures complete user data isolation through:
- **JWT Token Validation** - Server validates user identity
- **User-Specific API Endpoints** - All data filtered by authenticated user
- **Secure Token Storage** - Tokens stored securely on device
- **Automatic Data Refresh** - Fresh data loaded for each user session

## Development Setup

### Environment Variables
Create `.env` file with:
```
API_BASE_URL=http://your-laravel-api-url/api
```

### Dependencies
- `flutter_secure_storage` - Secure token storage
- `dio` - HTTP client with interceptors
- `provider` - State management
- `intl` - Date/number formatting

## Security Features

- **Secure Storage** - JWT tokens stored encrypted
- **Automatic Token Refresh** - Handles token expiration
- **Request Throttling** - Prevents API abuse
- **Error Handling** - Graceful handling of authentication errors
- **User Session Management** - Proper login/logout flow

## API Endpoints

All API requests require JWT authentication:
- `POST /login` - User authentication
- `POST /register` - User registration
- `GET /user` - Current user information
- `POST /logout` - User logout
- `GET /expenses/statistics/dashboard` - User-specific expense statistics
- `GET /categories` - User-specific categories

## Troubleshooting

### Common Issues
- **"Too Many Attempts" Error** - Laravel rate limiting triggered by excessive API calls
- **Token Expiration** - Automatic token refresh handles expiration
- **User Data Mixing** - Ensure backend filters data by `auth()->id()`

### Debug Mode
Enable debug logging by checking `ApiClient` interceptors for request/response details.

## Contributing

1. Ensure JWT authentication is properly implemented
2. Test user data isolation thoroughly
3. Follow secure coding practices for token handling
4. Update documentation for any authentication changes
