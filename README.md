# 🚀 Personal Expense Tracker with AI Insights

A comprehensive full-stack expense tracking application featuring **Laravel** backend, **React** web frontend, and **Flutter** mobile app with AI-powered financial insights for intelligent money management.

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Backend Setup (Laravel)](#backend-setup-laravel)
- [Frontend Setup (React)](#frontend-setup-react)
- [Mobile App Setup (Flutter)](#mobile-app-setup-flutter)
- [Environment Configuration](#environment-configuration)
- [API Documentation](#api-documentation)
- [Postman Collection](#postman-collection)
- [Testing](#testing)
- [Development Workflow](#development-workflow)
- [Deployment](#deployment)
- [Default Credentials](#default-login-credentials)
- [Project Structure](#project-structure)
- [Contributing](#contributing)

## 🌟 Project Overview

The **Expense Tracker** is a comprehensive financial management solution that enables users to:

### 🔧 Core Features
- **Multi-platform support** - Web (React) and Mobile (Flutter) applications
- **Intelligent expense tracking** with categorization and filtering
- **AI-powered insights** using OpenAI for spending pattern analysis
- **Budget management** with automated suggestions and progress tracking
- **Financial goal setting** with milestone tracking
- **Cash flow analysis** with trend visualization
- **Savings opportunities** identification and recommendations

### 🤖 AI Capabilities
- **Spending pattern analysis** - Identify trends and anomalies
- **Predictive analytics** - Forecast future spending patterns
- **Anomaly detection** - Flag unusual spending behavior
- **Budget optimization** - AI-generated budget recommendations
- **Categorization suggestions** - Automated expense categorization
- **Subscription analysis** - Identify recurring expenses and subscriptions

## 🛠️ Technology Stack

### Backend (Laravel)
- **Laravel 10.10** - PHP web framework
- **PHP 8.1+** - Server-side scripting
- **MySQL** - Primary database
- **Laravel Sanctum** - API authentication
- **Scramble** - API documentation generation
- **OpenAI API** - AI-powered insights

### Frontend (React)
- **React 19.2.0** - User interface library
- **Tailwind CSS 3.4.18** - Utility-first CSS framework
- **React Router 7.9.3** - Client-side routing
- **Axios 1.12.2** - HTTP client for API calls
- **Recharts 3.2.1** - Data visualization
- **Context API** - State management

### Mobile App (Flutter)
- **Flutter 3.8.1** - Cross-platform mobile framework
- **Dart** - Programming language
- **Provider 6.1.1** - State management
- **Dio 5.4.0** - HTTP client
- **FL Chart 0.66.2** - Data visualization
- **Firebase** - Analytics and crash reporting

## 📋 Prerequisites

### System Requirements
- **PHP 8.1 or higher**
- **Composer** (PHP dependency manager)
- **Node.js 16+ and npm**
- **MySQL 8.0+**
- **Flutter SDK 3.8.1+**
- **Git**

### Optional Dependencies
- **OpenAI API key** (for enhanced AI features)
- **Android Studio** (for Android development)
- **Xcode** (for iOS development)
- **Visual Studio Code** or preferred IDE

## 🔧 Backend Setup (Laravel)

### 1. Clone and Install
```bash
# Clone the repository
git clone <repository-url>
cd expense-tracker

# Install PHP dependencies
composer install

# Copy environment file
cp .env.example .env

# Generate application key
php artisan key:generate
```

### 2. Database Configuration
Update your `.env` file with database credentials:
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=root
DB_PASSWORD=
```

### 3. Database Setup
```bash
# Run migrations
php artisan migrate

# Seed database with sample data
php artisan db:seed

# Or run both in one command
php artisan migrate:fresh --seed
```

### 4. Start Laravel Server
```bash
# Start the Laravel development server
php artisan serve

# Server will be available at http://localhost:8000
# API documentation at http://localhost:8000/docs/api
```

## 🌐 Frontend Setup (React)

### 1. Navigate to Frontend Directory
```bash
cd frontend
```

### 2. Install Dependencies
```bash
# Install npm dependencies
npm install
```

### 3. Environment Configuration
Create `.env` file in frontend directory:
```env
REACT_APP_API_BASE_URL=http://localhost:8000/api
```

### 4. Start Development Server
```bash
# Start React development server
npm start

# Frontend will be available at http://localhost:3000
```

### 5. Build for Production (Optional)
```bash
# Build optimized production version
npm run build
```

## 📱 Mobile App Setup (Flutter)

### 1. Flutter SDK Installation

#### Windows Installation
```bash
# Download Flutter SDK from https://docs.flutter.dev/get-started/install/windows
# Extract to C:\src\flutter

# Add Flutter to PATH
set PATH=%PATH%;C:\src\flutter\bin

# Verify installation
flutter doctor
```

#### macOS Installation
```bash
# Install Flutter via Homebrew (recommended)
brew install flutter

# Or download from https://docs.flutter.dev/get-started/install/macos
# Extract to ~/development/flutter

# Add Flutter to PATH in ~/.zshrc or ~/.bashrc
export PATH="$HOME/development/flutter/bin:$PATH"

# Reload shell
source ~/.zshrc

# Verify installation
flutter doctor
```

#### Linux Installation (Ubuntu/Debian)
```bash
# Install dependencies
sudo apt-get update
sudo apt-get install curl git unzip lib32stdc++6

# Download Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable ~/flutter

# Add Flutter to PATH in ~/.bashrc
export PATH="$HOME/flutter/bin:$PATH"

# Reload shell
source ~/.bashrc

# Verify installation
flutter doctor
```

### 2. Platform-Specific Development Setup

#### Android Development Setup

**Android Studio Installation:**
1. Download Android Studio from https://developer.android.com/studio
2. Install Android Studio and follow the setup wizard
3. Install Android SDK, NDK, and tools during setup

**Environment Variables (Linux/macOS):**
```bash
# Add Android SDK to PATH
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# For Linux, also add:
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
```

**Create Android Emulator:**
```bash
# List available system images
flutter emulators

# Create new emulator (replace with desired API level)
flutter emulators --create --name android-emulator

# Or use Android Studio AVD Manager to create emulators
```

#### iOS Development Setup (macOS only)

**Xcode Installation:**
1. Install Xcode from Mac App Store (requires macOS 12.0+)
2. Install Xcode command line tools:
```bash
xcode-select --install
```

**CocoaPods Installation:**
```bash
# Install CocoaPods for iOS dependencies
sudo gem install cocoapods

# Initialize CocoaPods in project (if needed)
cd mobile/ios && pod init
```

**Create iOS Simulator:**
```bash
# List available simulators
flutter devices

# Or use Xcode Simulator to create/manage simulators
```

### 3. Environment Configuration

#### Mobile App Environment (.env)
Update `mobile/.env` file with your configuration:
```env
# API Configuration
API_BASE_URL=http://192.168.1.103:8000
API_TIMEOUT=30

# App Configuration
APP_NAME=Expense Tracker Mobile
APP_VERSION=1.0.0
APP_BUILD_NUMBER=1

# Debug Configuration
DEBUG_MODE=true
LOG_REQUESTS=true
LOG_RESPONSES=true

# OpenAI Configuration (Optional)
OPENAI_API_KEY=your_openai_api_key_here

# Firebase Configuration (Optional)
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_APP_ID=your_firebase_app_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_PROJECT_ID=your_project_id
```

#### API Client Configuration
The API base URL is configured in `mobile/lib/core/network/api_client.dart`:
```dart
class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api', // Android emulator
  );
}
```

### 4. Firebase Configuration

#### Android Firebase Setup
1. **Create Firebase Project:**
   - Go to https://console.firebase.google.com
   - Create new project or use existing one
   - Add Android app to project

2. **Download Configuration:**
   ```bash
   # Download google-services.json from Firebase Console
   # Place in mobile/android/app/google-services.json
   ```

3. **Update Gradle Files:**
   ```kotlin
   // mobile/android/app/build.gradle.kts
   dependencies {
       implementation(platform("com.google.firebase:firebase-bom:32.7.2"))
       implementation("com.google.firebase:firebase-analytics")
       implementation("com.google.firebase:firebase-crashlytics")
   }
   ```

#### iOS Firebase Setup (macOS only)
1. **Add iOS App to Firebase:**
   - In Firebase Console, add iOS app to your project
   - Download GoogleService-Info.plist

2. **iOS Configuration:**
   ```bash
   # Place GoogleService-Info.plist in mobile/ios/Runner/GoogleService-Info.plist
   # Update iOS bundle identifier in Firebase Console
   ```

3. **Install Firebase Pods:**
   ```bash
   cd mobile/ios
   pod install
   ```

### 5. Android and iOS Permissions Setup

#### Android Permissions
Update `mobile/android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Internet permissions for API calls -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- Camera permissions for expense receipts -->
    <uses-permission android:name="android.permission.CAMERA" />

    <!-- Storage permissions for saving images -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

    <!-- Notification permissions -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.VIBRATE" />

    <application>
        <!-- Add your application configuration here -->
    </application>
</manifest>
```

#### iOS Permissions (macOS only)
Update `mobile/ios/Runner/Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Camera permissions -->
    <key>NSCameraUsageDescription</key>
    <string>This app needs camera access to capture expense receipts</string>

    <!-- Photo library permissions -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app needs photo library access to select expense receipts</string>

    <!-- Notifications permissions -->
    <key>NSLocalNetworkUsageDescription</key>
    <string>This app needs network access to sync your expense data</string>

    <!-- Location permissions (if needed) -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs location access for location-based expenses</string>
</dict>
</plist>
```

### 6. Development Run Commands

#### Development Mode
```bash
cd mobile

# Install dependencies
flutter pub get

# Run on connected Android device/emulator
flutter run

# Run on iOS simulator/device (macOS only)
flutter run -d ios

# Run on specific device
flutter run -d <device-id>

# Run in debug mode with hot reload
flutter run --debug
```

#### Profile/Release Mode
```bash
# Run in profile mode (performance testing)
flutter run --profile

# Run in release mode (production testing)
flutter run --release
```

#### Device Management
```bash
# List connected devices
flutter devices

# List available emulators
flutter emulators

# Create new emulator
flutter emulators --create --name my-emulator

# Start emulator
flutter emulators --launch my-emulator
```

### 7. Build Instructions for Release

#### Android Release Build
```bash
cd mobile

# Build APK for release
flutter build apk --release

# Build APK with specific target
flutter build apk --release --target-platform android-arm64

# Build app bundle (AAB) for Play Store
flutter build appbundle --release

# Build with custom keystore
flutter build apk --release \
  --keystore=path/to/keystore.jks \
  --keystore-password=your-keystore-password \
  --key-password=your-key-password \
  --key-alias=your-key-alias
```

#### iOS Release Build (macOS only)
```bash
cd mobile

# Build for iOS release
flutter build ios --release

# Build for specific iOS device
flutter build ios --release --device

# Build IPA for distribution
flutter build ipa --release
```

#### Code Signing (iOS/macOS only)
```bash
# Configure code signing
flutter build ios --release \
  --code-sign-identity "iPhone Distribution" \
  --provisioning-profile "Your Provisioning Profile"
```

### 8. Testing Procedures

#### Unit Testing
```bash
cd mobile

# Run all unit tests
flutter test

# Run specific test file
flutter test test/services/auth_service_test.dart

# Run tests with coverage
flutter test --coverage

# Run tests in verbose mode
flutter test --verbose

# Watch mode for continuous testing
flutter test --watch
```

#### Widget Testing
```bash
# Run widget tests
flutter test test/widget/expense_card_test.dart

# Run integration tests
flutter test integration_test/app_test.dart
```

#### Testing on Devices
```bash
# Test on Android device
flutter test --device-id <android-device-id>

# Test on iOS device
flutter test --device-id <ios-device-id>
```

### 9. Troubleshooting Common Issues

#### Flutter Doctor Issues
```bash
# Run Flutter doctor to diagnose issues
flutter doctor

# Fix common issues
flutter doctor --android-licenses  # Accept Android licenses
flutter doctor --fix               # Attempt to fix issues

# Update Flutter SDK
flutter upgrade
```

#### Build Issues
```bash
# Clean build cache
flutter clean
flutter pub get

# Clean and rebuild
flutter clean && flutter pub get && flutter run

# Fix iOS build issues (macOS only)
cd mobile/ios && pod repo update && pod install
```

#### Device Connection Issues
```bash
# Restart ADB server (Android)
adb kill-server && adb start-server

# Check device connection
flutter devices

# Enable USB debugging on Android device
# Enable Developer Options and USB Debugging in device settings
```

#### Performance Issues
```bash
# Enable performance overlay
flutter run --profile --trace-startup

# Check for memory leaks
flutter run --release --dart-define=flutter.inspector.structuredErrors=true

# Profile app performance
flutter run --profile
```

#### Network Issues
```bash
# Check API connectivity
# Update API_BASE_URL in .env file for your network

# # For Android emulator, use 10.0.2.2 as localhost
# API_BASE_URL=http://10.0.2.2:8000/api

# For iOS simulator, use your computer's IP
API_BASE_URL=http://192.168.1.103:8000/api
```

### 10. Development Workflow

#### Project Structure Overview
```
mobile/
├── 📁 android/              # Android-specific code
│   ├── app/src/main/        # Main Android source
│   └── build.gradle.kts     # Android build configuration
├── 📁 ios/                  # iOS-specific code (macOS only)
│   ├── Runner/              # iOS app configuration
│   └── Podfile              # CocoaPods dependencies
├── 📁 lib/                  # Dart source code
│   ├── core/                # Core functionality
│   │   ├── errors/          # Error handling
│   │   └── network/         # API client configuration
│   ├── data/                # Data layer
│   │   ├── models/          # Data models
│   │   └── services/        # API services
│   ├── presentation/        # UI layer
│   │   ├── providers/       # State management
│   │   ├── screens/         # App screens
│   │   └── widgets/         # Reusable widgets
│   └── main.dart            # Application entry point
├── 📁 test/                 # Unit and widget tests
├── 📁 .env                  # Environment configuration
└── 📁 pubspec.yaml          # Flutter dependencies
```

#### Development Best Practices

**Code Organization:**
1. **Follow MVVM pattern** - Models, ViewModels, Views separation
2. **Use Provider** for state management across the app
3. **Implement proper error handling** with custom exceptions
4. **Use secure storage** for sensitive data (JWT tokens)

**Performance Optimization:**
1. **Lazy load** heavy widgets and data
2. **Use ListView.builder** for long lists
3. **Implement proper image caching** with cached_network_image
4. **Minimize rebuilds** with proper Provider usage

**Testing Strategy:**
1. **Write unit tests** for services and viewmodels
2. **Create widget tests** for complex UI components
3. **Test API integration** with mock data
4. **Test on multiple devices** and screen sizes

**Version Control:**
```bash
# Create feature branch
git checkout -b feature/new-expense-feature

# Make changes and test thoroughly
flutter test

# Commit with descriptive message
git add .
git commit -m "feat: add new expense tracking feature"

# Push and create pull request
git push origin feature/new-expense-feature
```

#### Continuous Integration (Optional)
```yaml
# Example GitHub Actions workflow
name: Flutter CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.8.1'
      - run: flutter pub get
      - run: flutter test
      - run: flutter build apk --release
```

## 🔐 Environment Configuration

### Laravel Backend (.env)
```env
# Application
APP_NAME=Laravel
APP_ENV=local
APP_KEY=base64:your-generated-key
APP_DEBUG=true
APP_URL=http://localhost

# Database
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=root
DB_PASSWORD=

# OpenAI Configuration (Optional)
OPENAI_API_KEY=your_openai_api_key
OPENAI_API_BASE_URL=https://api.openai.com/v1

# CORS Settings
SANCTUM_STATEFUL_DOMAINS=localhost:3000,localhost:3001,127.0.0.1:3000

# Mail Configuration (Optional)
MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"
```

### React Frontend (.env)
```env
# API Configuration
REACT_APP_API_BASE_URL=http://localhost:8000/api

# Optional: Environment
REACT_APP_ENV=development
```

## 📚 API Documentation

### Swagger UI Documentation
Access interactive API documentation at:
```
http://localhost:8000/docs/api
```

**Features:**
- ✅ Interactive API testing for all endpoints
- ✅ Complete request/response documentation
- ✅ Parameter descriptions and examples
- ✅ Status codes and error handling
- ✅ Professional documentation layout

### Authentication
All protected endpoints require Bearer token authentication:
```
Authorization: Bearer YOUR_JWT_TOKEN
```

## 📮 Postman Collection

### Import Instructions
1. **Open Postman**
2. **Click "Import"** button
3. **Select `expense-tracker-postman-collection.json`**
4. **Collection will be imported with all endpoints**

### Collection Features
- ✅ **26 API endpoints** organized by category
- ✅ **Pre-configured authentication** with Bearer tokens
- ✅ **Example requests** for every endpoint
- ✅ **Variable management** for base URL and tokens
- ✅ **Automatic token handling** in requests

### Quick Start with Postman
1. **Import** the collection
2. **Set variables:**
   - `baseUrl`: `http://localhost:8000/api`
   - `authToken`: Leave empty initially
3. **Run "Authentication → Login"** - token auto-saves
4. **Test any endpoint** - authentication included automatically

## 🧪 Testing

### Backend Testing (Laravel)
```bash
# Run all tests
php artisan test

# Run specific test file
php artisan test --filter=UserTest

# Run with coverage
php artisan test --coverage

# Run tests in verbose mode
php artisan test --verbose
```

### Frontend Testing (React)
```bash
cd frontend

# Run tests
npm test

# Run tests in watch mode
npm test -- --watch

# Run tests with coverage
npm test -- --coverage
```

### Mobile Testing (Flutter)
```bash
cd mobile

# Run all tests
flutter test

# Run specific test file
flutter test test/services/auth_service_test.dart

# Run tests with coverage
flutter test --coverage
```

### API Testing
Use either **Swagger UI** or **Postman Collection** for comprehensive API testing.

## 🔄 Development Workflow

### Common Development Tasks

#### 1. Database Management
```bash
# Create new migration
php artisan make:migration create_new_table

# Create new model with migration
php artisan make:model NewModel -m

# Refresh database
php artisan migrate:fresh --seed

# Rollback migrations
php artisan migrate:rollback
```

#### 2. Code Generation
```bash
# Create new controller
php artisan make:controller Api/NewController --api

# Create new request class
php artisan make:request StoreNewRequest

# Create new seeder
php artisan make:seeder NewSeeder
```

#### 3. Cache Management
```bash
# Clear all caches
php artisan optimize:clear

# Cache configuration
php artisan config:cache

# Cache routes
php artisan route:cache
```

### Development Best Practices
1. **Always run tests** before committing
2. **Use migrations** for database changes
3. **Follow PSR-12** coding standards
4. **Write meaningful commit messages**
5. **Update documentation** for new features

## 🚀 Deployment

### Production Deployment Checklist

#### Backend (Laravel)
1. **Environment Setup:**
   ```bash
   # Set production environment
   APP_ENV=production
   APP_DEBUG=false

   # Configure production database
   DB_HOST=your_production_db_host
   DB_DATABASE=your_production_db

   # Set secure APP_KEY
   php artisan key:generate --force
   ```

2. **Security:**
   ```bash
   # Optimize for production
   php artisan optimize

   # Cache configuration
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   ```

3. **Web Server Configuration:**
   - Configure Nginx/Apache for Laravel
   - Set proper document root to `public/` directory
   - Configure SSL/TLS certificates

#### Frontend (React)
1. **Build for Production:**
   ```bash
   cd frontend
   npm run build
   ```

2. **Web Server:**
   - Serve `build/` directory with Nginx/Apache
   - Configure proper MIME types
   - Enable gzip compression

#### Mobile App (Flutter)
1. **Build Release:**
   ```bash
   cd mobile
   flutter build apk --release  # Android
   flutter build ios --release  # iOS
   ```

2. **App Store Deployment:**
   - **Android:** Upload APK/AAB to Google Play Store
   - **iOS:** Upload IPA to App Store Connect

### Environment Variables Template
Create production `.env` file:
```env
APP_NAME="Expense Tracker"
APP_ENV=production
APP_KEY=base64:your-secure-key
APP_DEBUG=false
APP_URL=https://yourdomain.com

DB_CONNECTION=mysql
DB_HOST=your_db_host
DB_DATABASE=your_db_name
DB_USERNAME=your_db_user
DB_PASSWORD=your_secure_password

OPENAI_API_KEY=your_production_openai_key

# Production CORS settings
SANCTUM_STATEFUL_DOMAINS=yourdomain.com,www.yourdomain.com
```

## 🔑 Default Login Credentials

After seeding, you can login with these test accounts:

### Web Application
- **Email**: `john@example.com`
- **Password**: `password123`

- **Email**: `christon@gmail.com`
- **Password**: `password123`

### API Testing
Use the Postman collection or Swagger UI with the credentials above.

## 📁 Project Structure

```
expense-tracker/
├── 📁 app/                          # Laravel application code
│   ├── Http/Controllers/            # API controllers (8 controllers)
│   ├── Models/                      # Eloquent models (5 models)
│   └── Http/Middleware/             # Custom middleware
├── 📁 database/                     # Database migrations & seeders
│   ├── migrations/                  # 9 migration files
│   └── seeders/                     # Database seeders (4 seeders)
├── 📁 frontend/                     # React application
│   ├── public/                      # Static assets
│   ├── src/                         # Source code
│   │   ├── components/              # Reusable React components
│   │   ├── pages/                   # Page components (8 pages)
│   │   ├── context/                 # React context providers
│   │   ├── services/                # API service functions
│   │   └── App.js                   # Main application component
│   └── package.json                 # React dependencies
├── 📁 mobile/                       # Flutter application
│   ├── android/                     # Android-specific code
│   ├── ios/                         # iOS-specific code
│   ├── lib/                         # Dart source code
│   │   ├── core/                    # Core functionality
│   │   ├── data/                    # Data layer (models, services)
│   │   ├── presentation/            # UI layer (screens, widgets)
│   │   └── main.dart                # Application entry point
│   └── pubspec.yaml                 # Flutter dependencies
├── 📁 config/                       # Laravel configuration files
├── 📁 routes/                       # API routes definitions
├── 📁 storage/                      # File storage
├── 📁 tests/                        # Test files
├── 📄 composer.json                 # PHP dependencies
├── 📄 expense-tracker-postman-collection.json  # Postman collection
├── 📄 API_TESTING_README.md         # API testing guide
└── 📄 README.md                     # This file
```

## 🤝 Contributing

### Development Setup
1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Make** your changes
4. **Test** thoroughly
5. **Commit** your changes: `git commit -m 'Add amazing feature'`
6. **Push** to the branch: `git push origin feature/amazing-feature`
7. **Open** a Pull Request

### Code Standards
- **PHP:** Follow PSR-12 coding standards
- **JavaScript/React:** Use ESLint configuration
- **Dart/Flutter:** Follow effective Dart guidelines
- **Commits:** Use conventional commit format

### Pull Request Process
1. Ensure all tests pass
2. Update documentation if needed
3. Add/update tests for new features
4. Follow the existing code style
5. Request review from maintainers

## 📜 API Endpoints Summary

### Authentication (Public)
- `POST /api/register` - Register new user
- `POST /api/login` - Login and get token
- `POST /api/logout` - Logout and revoke token

### Categories (Protected)
- `GET /api/categories` - List user categories
- `POST /api/categories` - Create new category
- `GET /api/categories/{id}` - Get specific category
- `PUT /api/categories/{id}` - Update category
- `DELETE /api/categories/{id}` - Delete category

### Expenses (Protected)
- `GET /api/expenses` - List expenses with filtering
- `POST /api/expenses` - Create new expense
- `GET /api/expenses/{id}` - Get specific expense
- `PUT /api/expenses/{id}` - Update expense
- `DELETE /api/expenses/{id}` - Delete expense
- `GET /api/expenses/statistics/dashboard` - Get expense analytics

### Budgets (Protected)
- `GET /api/budgets` - List user budgets
- `POST /api/budgets` - Create new budget
- `POST /api/budgets/ai-suggestions` - Get AI budget suggestions

### Financial Goals (Protected)
- `GET /api/financial-goals` - List financial goals
- `POST /api/financial-goals` - Create new goal

### Cash Flow (Protected)
- `GET /api/cash-flow` - List cash flow entries
- `POST /api/cash-flow` - Create cash flow entry
- `GET /api/cash-flow/monthly-trend` - Get monthly trends

### AI Insights (Protected)
- `POST /api/ai/insights` - Get AI insights
- `POST /api/ai/predictive-analysis` - Get spending predictions
- `POST /api/ai/anomaly-detection` - Detect spending anomalies

### Analytics (Protected)
- `GET /api/savings-opportunities` - Get savings opportunities
- `GET /api/categorization-suggestions` - Get categorization suggestions
- `GET /api/subscription-analysis` - Analyze subscriptions

## 📞 Support & Documentation

### Getting Help
- **API Documentation:** `http://localhost:8000/docs/api`
- **Postman Collection:** Import `expense-tracker-postman-collection.json`
- **Testing Guide:** See `API_TESTING_README.md`

### Troubleshooting
1. **Database Connection Issues:** Check `.env` configuration
2. **CORS Errors:** Update `SANCTUM_STATEFUL_DOMAINS` in `.env`
3. **OpenAI Features:** Ensure `OPENAI_API_KEY` is configured
4. **Mobile App Issues:** Check device/emulator configuration

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Laravel Framework** - PHP web framework
- **React.js** - User interface library
- **Flutter** - Cross-platform mobile framework
- **Tailwind CSS** - Utility-first CSS framework
- **OpenAI API** - AI-powered insights
- **MySQL** - Robust database solution
- **All contributors and supporters**

---

## 🎯 What You've Achieved

✅ **Complete Full-Stack Solution** - Web, Mobile, and API
✅ **AI-Powered Features** - Intelligent financial insights
✅ **Professional Documentation** - Swagger UI and Postman collection
✅ **Production Ready** - Comprehensive deployment guide
✅ **Developer Friendly** - Detailed setup and development workflow
✅ **Cross-Platform** - Web and mobile applications

**🚀 Your Expense Tracker is now a complete, professional-grade financial management solution!**

**Happy Expense Tracking! 💰📊**
