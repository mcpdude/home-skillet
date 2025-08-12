# Home Skillet Mobile App

A Flutter application for home maintenance project management, built following TDD principles and clean architecture patterns.

## Project Structure

```
mobile/
├── lib/
│   ├── config/
│   │   ├── api_config.dart          # API configuration and constants
│   │   ├── app_router.dart          # GoRouter configuration with auth guards
│   │   └── routes.dart              # Route definitions
│   ├── models/
│   │   ├── auth_models.dart         # Login, register, auth response models
│   │   ├── property.dart            # Property model with JSON serialization
│   │   ├── project.dart             # Project model with status/priority enums
│   │   ├── task.dart                # Task model
│   │   └── user.dart                # User model
│   ├── providers/
│   │   ├── auth_provider.dart       # Authentication state management
│   │   ├── property_provider.dart   # Property state management
│   │   └── project_provider.dart    # Project and task state management
│   ├── services/
│   │   ├── auth_service.dart        # Authentication API calls
│   │   ├── http_client.dart         # Dio client with JWT interceptors
│   │   ├── project_service.dart     # Project/task API calls
│   │   ├── property_service.dart    # Property API calls
│   │   └── storage_service.dart     # Secure storage for tokens
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── forgot_password_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart
│   │   ├── profile/
│   │   │   └── profile_screen.dart
│   │   ├── projects/
│   │   │   ├── project_detail_screen.dart
│   │   │   └── project_list_screen.dart
│   │   ├── properties/
│   │   │   ├── property_detail_screen.dart
│   │   │   └── property_list_screen.dart
│   │   ├── settings/
│   │   │   └── settings_screen.dart
│   │   └── splash_screen.dart
│   ├── utils/
│   │   └── form_validators.dart     # Formz validators for forms
│   ├── widgets/
│   │   ├── error_message.dart       # Error display widgets
│   │   ├── loading_overlay.dart     # Loading state overlay
│   │   └── main_layout.dart         # Main app layout with bottom navigation
│   └── main.dart                    # App entry point with provider setup
├── test/
│   ├── helpers/
│   │   ├── mocks.dart              # Mock generation annotations
│   │   └── test_helpers.dart       # Test utilities and common setup
│   ├── integration/
│   │   └── app_navigation_test.dart # Navigation flow integration tests
│   ├── unit/
│   │   ├── auth_provider_test.dart  # Authentication provider tests
│   │   ├── auth_service_test.dart   # Authentication service tests
│   │   └── property_service_test.dart # Property service tests
│   └── widget/
│       ├── dashboard_screen_test.dart # Dashboard widget tests
│       └── login_screen_test.dart    # Login screen widget tests
├── test_driver/
│   ├── app.dart                    # Integration test app
│   └── app_test.dart              # Driver integration tests
├── pubspec.yaml                   # Dependencies and configuration
└── README.md                      # This file
```

## Key Features Implemented

### 🔐 Authentication System
- **JWT Token Management**: Secure storage with automatic refresh
- **Form Validation**: Email, password, and field validation with Formz
- **Auth Guards**: Route protection based on authentication status
- **Biometric Storage**: Flutter Secure Storage for sensitive data

### 🏠 Property Management
- **CRUD Operations**: Create, read, update, delete properties
- **Property Types**: Support for house, apartment, condo, townhouse
- **Image Management**: Property photo upload and management
- **Search Functionality**: Property search and filtering

### 🔨 Project & Task Management
- **Project Lifecycle**: Planned → In Progress → Completed workflow
- **Priority System**: Low, Medium, High, Urgent priority levels
- **Task Breakdown**: Projects divided into manageable tasks
- **Progress Tracking**: Visual progress indicators and statistics

### 📱 User Interface
- **Material Design 3**: Modern, consistent UI following Material guidelines
- **Responsive Design**: Adapts to different screen sizes and orientations
- **Dark/Light Theme**: System theme support (configurable)
- **Bottom Navigation**: Intuitive navigation between main sections

### 🧪 Testing Framework
- **Unit Tests**: Service and provider logic testing
- **Widget Tests**: UI component testing with mocks
- **Integration Tests**: End-to-end user flow testing
- **TDD Approach**: Tests written before implementation

## Architecture Patterns

### Clean Architecture
```
Presentation Layer (Screens/Widgets)
       ↓
Business Logic Layer (Providers)
       ↓
Data Layer (Services/Models)
```

### State Management
- **Provider Pattern**: Centralized state management
- **Separation of Concerns**: UI, business logic, and data separated
- **Reactive Updates**: Automatic UI updates on state changes

### API Integration
- **HTTP Client**: Dio-based client with interceptors
- **Authentication**: Automatic JWT token injection and refresh
- **Error Handling**: Comprehensive error handling and user feedback
- **Offline Support**: Cached data for offline functionality (planned)

## Dependencies

### Core Dependencies
- **flutter**: ^3.10.0 - Flutter SDK
- **provider**: ^6.0.5 - State management
- **go_router**: ^12.1.1 - Declarative routing
- **dio**: ^5.3.2 - HTTP client
- **flutter_secure_storage**: ^9.0.0 - Secure storage

### Form & Validation
- **formz**: ^0.6.1 - Form validation
- **json_annotation**: ^4.8.1 - JSON serialization

### UI & UX
- **flutter_spinkit**: ^5.2.0 - Loading animations
- **cached_network_image**: ^3.3.0 - Image caching
- **flutter_svg**: ^2.0.9 - SVG support

### Development & Testing
- **mockito**: ^5.4.2 - Mock generation
- **flutter_test**: SDK - Widget testing
- **integration_test**: SDK - Integration testing
- **build_runner**: ^2.4.7 - Code generation

## Getting Started

### Prerequisites
- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code with Flutter extensions
- Device or emulator for testing

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd home_skillet/mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Testing

1. **Run unit tests**
   ```bash
   flutter test
   ```

2. **Run widget tests**
   ```bash
   flutter test test/widget/
   ```

3. **Run integration tests**
   ```bash
   flutter test integration_test/
   ```

4. **Generate test coverage**
   ```bash
   flutter test --coverage
   genhtml coverage/lcov.info -o coverage/html
   ```

### Code Generation

When modifying models or services:

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## Configuration

### API Configuration
Update `lib/config/api_config.dart` with your backend API URL:

```dart
static const String baseUrl = 'https://your-api-domain.com/api';
```

### Theme Configuration
Customize app theme in `lib/main.dart`:

```dart
theme: ThemeData(
  primarySwatch: Colors.blue,
  primaryColor: const Color(0xFF1976D2),
  // ... additional theme configuration
),
```

## Development Guidelines

### Code Style
- Follow Dart style guide
- Use meaningful variable and function names
- Add documentation for public APIs
- Keep functions small and focused

### Testing
- Write tests before implementation (TDD)
- Maintain >80% code coverage
- Test both success and error scenarios
- Use descriptive test names

### State Management
- Use Provider for state management
- Keep business logic in providers
- Avoid direct service calls from widgets
- Use immutable state objects

### Error Handling
- Handle all potential errors gracefully
- Show user-friendly error messages
- Log errors for debugging
- Provide retry mechanisms where appropriate

## Deployment

### Android
1. Configure signing in `android/app/build.gradle`
2. Build release APK: `flutter build apk --release`
3. Build App Bundle: `flutter build appbundle --release`

### iOS
1. Configure signing in Xcode
2. Build iOS release: `flutter build ios --release`
3. Archive and distribute through Xcode

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Write tests for new functionality
4. Implement the feature
5. Ensure all tests pass
6. Commit changes: `git commit -m 'Add amazing feature'`
7. Push to branch: `git push origin feature/amazing-feature`
8. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Check existing documentation
- Review test examples for usage patterns