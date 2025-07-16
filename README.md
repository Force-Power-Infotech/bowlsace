# 🎳 BowlsAce

A modern and intuitive bowling practice and training application built with Flutter, implementing advanced performance tracking and real-time analytics.

## 📱 Project Overview

BowlsAce is a sophisticated bowling training application that revolutionizes how players approach their practice sessions. Built with Flutter's latest features and following MVVM architecture, it provides a comprehensive platform for bowlers to enhance their skills through structured training, performance analytics, and competitive challenges.

### 🎯 Key Features

- **Smart Practice Sessions**
  - Create customized practice routines with configurable parameters
  - Real-time performance tracking during sessions
  - Detailed session analytics with shot-by-shot breakdown
  - Progress visualization through interactive charts
  - Video analysis support for technique improvement

- **Advanced Drill Management**
  - Hierarchical drill organization system
  - Pre-built drill templates for common scenarios
  - Custom drill creation with specific focus areas
  - Difficulty progression tracking
  - Performance metrics for each drill type

- **Interactive Challenges**
  - Real-time multiplayer challenges
  - Global leaderboard system
  - Achievement unlocking mechanism
  - Peer-to-peer challenge creation
  - Tournament organization capabilities

- **Comprehensive Analytics**
  - Advanced statistical analysis of performance
  - Progress tracking with machine learning insights
  - Personalized improvement recommendations
  - Historical trend analysis
  - Export capabilities for detailed reports

- **Professional Profile System**
  - Detailed player statistics
  - Achievement showcase
  - Training history timeline
  - Social features for connecting with other players
  - Coach-player interaction platform

### 💡 Technical Insights

#### State Management
- Implements Provider pattern for efficient state management
- Uses ChangeNotifier for reactive UI updates
- Maintains separate state containers for different feature modules
- Implements state persistence for offline capability

#### Data Architecture
- Follows Repository pattern for data abstraction
- Implements clean architecture principles for maintainable code
- Uses custom DTOs for efficient data transformation
- Includes robust error handling and data validation

#### Performance Optimizations
- Lazy loading of heavy UI components
- Image caching for faster load times
- Background data synchronization
- Efficient memory management for long practice sessions

#### Security Features
- Secure local storage using Flutter Secure Storage
- Encrypted data transmission
- Token-based authentication system
- Regular security audits and updates

## 🗺️ Navigation Structure

### Authentication Screens
- `/splash` - Application splash screen
- `/login` - User login screen
- `/register` - New user registration

### Main Navigation
- `/dashboard` - Main dashboard (index: 0)
- `/practice` - Practice section (index: 1)
- `/challenges` - Challenges section (index: 2)
- `/profile` - User profile (index: 3)

### Practice Screens
- `/practice/new` - Create new practice session
- `/practice/details` - View practice session details
- `/practice/history` - View practice history
- `/drill-group/new` - Create new drill group
- `/drill-group/details` - View drill group details

### Challenge Screens
- `/challenge/details` - View challenge details

### Settings
- `/settings` - Application settings

## 🏗️ Project Architecture & Structure

### Directory Structure
```
lib/
├── api/                    # API integration layer
│   ├── services/          # Service implementations
│   ├── interceptors/      # Network interceptors
│   └── config/            # API configurations
├── di/                    # Dependency injection
│   └── service_locator.dart   # Service locator implementation
├── models/                # Data models & DTOs
│   ├── challenge.dart     # Challenge-related models
│   ├── practice_model.dart # Practice session models
│   └── drill_group.dart   # Drill organization models
├── providers/            # State management
│   ├── user_provider.dart    # User state management
│   ├── practice_provider.dart # Practice state
│   └── challenge_provider.dart # Challenge state
├── repositories/         # Data repositories
├── ui/                  # Presentation layer
│   ├── screens/         # Screen implementations
│   │   ├── auth/       # Authentication screens
│   │   ├── practice/   # Practice-related screens
│   │   └── challenge/  # Challenge screens
│   ├── widgets/        # Reusable widgets
│   └── theme/          # Theme configuration
└── utils/              # Utility functions
    └── navigation_service.dart # Navigation utilities
```

## 🛠️ Technical Stack & Implementation Details

### Core Technologies
- **Framework**: Flutter 3.x
  - Utilizing latest Flutter features
  - Custom widget implementations
  - Platform-specific optimizations

### Architecture & Patterns
- **Architecture**: Clean Architecture with MVVM
  - Clear separation of concerns
  - Testable business logic
  - Independent UI layer
  - Domain-driven design principles

### State Management
- **Provider Pattern**
  - Centralized state management
  - Reactive UI updates
  - Efficient dependency injection
  - State persistence

### Key Dependencies
- **API & Networking**:
  - HTTP package for REST API client
  - Connectivity Plus: Network connectivity handling
  
- **Storage & Security**:
  - Flutter Secure Storage: Encrypted storage
  - Shared Preferences: Local cache
  - SQLite: Offline data persistence
  
- **UI Components**:
  - Material Design 3
  - Custom animations
  - Responsive layouts
  
- **Analytics & Monitoring**:
  - Firebase Analytics
  - Custom event tracking
  - Performance monitoring

## 🔌 API Integration & Implementation

### API Architecture Overview

The application implements a robust API integration layer with the following components:

```
lib/api/
├── api_client.dart         # Core API client implementation
├── api_config.dart         # API endpoints and configuration
├── api_error_handler.dart  # Centralized error handling
├── interceptors/           # Request/Response interceptors
└── services/              # Feature-specific API services
```

### Authentication Flow

```dart
// Example of login implementation
Future<UserModel> login(String email, String password) async {
  try {
    final response = await _apiClient.post(
      ApiConfig.login,
      body: {
        'email': email,
        'password': password,
      },
    );
    
    await _tokenManager.setToken(response['token']);
    return UserModel.fromJson(response['user']);
  } on UnauthorizedException {
    throw AuthException('Invalid credentials');
  }
}
```

### Token Management

The app implements secure token management with automatic token refresh:

```dart
class TokenManager {
  final SecureStorage _secureStorage = SecureStorage();
  String? _cachedToken;

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _secureStorage.read(key: 'access_token');
    return _cachedToken;
  }

  bool isTokenExpired() {
    // Token expiration check implementation
  }
}
```

### API Endpoints

```dart
class ApiConfig {
  static const String baseUrl = 'http://api.bowlsace.com/v1';

  // Authentication
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh-token';

  // User Management
  static const String currentUser = '/users/me';
  static const String updateProfile = '/users/me/profile';

  // Practice Features
  static const String drills = '/drills';
  static const String drillGroups = '/drill-groups';
  static const String practiceSession = '/practice/sessions';

  // Challenges
  static const String challenges = '/challenge';
  static const String acceptChallenge = '/challenge/{id}/accept';
}
```

### Example API Usage

1. **Creating a Practice Session:**
```dart
Future<PracticeSession> createPracticeSession(PracticeSessionDTO dto) async {
  final response = await _apiClient.post(
    ApiConfig.practiceSession,
    body: dto.toJson(),
  );
  return PracticeSession.fromJson(response);
}
```

2. **Fetching Drill Groups:**
```dart
Future<List<DrillGroup>> getDrillGroups() async {
  final response = await _apiClient.get(ApiConfig.drillGroups);
  return (response as List)
      .map((json) => DrillGroup.fromJson(json))
      .toList();
}
```

3. **Updating User Profile:**
```dart
Future<UserProfile> updateProfile(ProfileUpdateDTO dto) async {
  final response = await _apiClient.put(
    ApiConfig.updateProfile,
    body: dto.toJson(),
  );
  return UserProfile.fromJson(response);
}
```

### Error Handling

The API layer implements comprehensive error handling:

```dart
try {
  await apiClient.get('/protected-endpoint');
} on UnauthorizedException {
  // Handle authentication errors
} on ApiException catch (e) {
  // Handle API-specific errors
  if (e.statusCode == 404) {
    // Handle not found
  }
} on NetworkException {
  // Handle network connectivity issues
}
```

### Integration Testing

To test API integration:

```bash
# Run integration tests
flutter drive --target=test_driver/app.dart

# Run specific API tests
flutter test test/api_test.dart
```

Example test:
```dart
void main() {
  group('API Integration Tests', () {
    test('login should return user token', () async {
      final client = ApiClient();
      final response = await client.post(
        ApiConfig.login,
        body: {'email': 'test@example.com', 'password': 'test123'},
      );
      expect(response['token'], isNotNull);
    });
  });
}
```

## 🚀 Development Setup & Configuration

### Prerequisites
- Flutter SDK 3.x or higher
- Dart SDK 3.x or higher
- Android Studio / VS Code with Flutter extensions
- iOS development setup for Apple platform deployment

### Environment Setup
1. Clone the repository:
```bash
git clone https://github.com/Force-Power-Infotech/bowlsace.git
cd bowlsace
```

2. Install dependencies:
```bash
flutter pub get
```

3. Setup environment variables:
```bash
cp .env.example .env
# Configure your environment variables
```

4. Run the application:
```bash
# Development
flutter run --flavor development

# Production
flutter run --flavor production
```

### Build & Deployment
```bash
# Android APK
flutter build apk --flavor production

# iOS
flutter build ios --flavor production

# Web
flutter build web --web-renderer canvaskit
```

## 🎨 UI/UX Implementation

### Design System
- **Material Design 3 Implementation**
  - Dynamic color theming
  - Custom color palettes
  - Typography system
  - Elevation and shadows

### Responsive Design
- **Adaptive Layouts**
  - LayoutBuilder implementation
  - Screen size breakpoints
  - Orientation handling
  - Platform-specific adaptations

### Animations & Transitions
- **Custom Animations**
  - Hero transitions
  - Staggered animations
  - Custom route transitions
  - Micro-interactions

### Accessibility
- **A11y Features**
  - Screen reader support
  - High contrast themes
  - Dynamic text scaling
  - Voice-over compatibility

## 📱 Platform Support

- Android
- iOS
- Web (Progressive Web App)
- Windows
- macOS
- Linux

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

Made with ❤️ by Force Power Infotech
