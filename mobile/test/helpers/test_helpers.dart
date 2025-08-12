import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:home_skillet_mobile/providers/auth_provider.dart';
import 'package:home_skillet_mobile/providers/property_provider.dart';
import 'package:home_skillet_mobile/providers/project_provider.dart';
import 'package:home_skillet_mobile/services/auth_service.dart';
import 'package:home_skillet_mobile/services/property_service.dart';
import 'package:home_skillet_mobile/services/project_service.dart';
import 'package:home_skillet_mobile/services/storage_service.dart';
import 'package:home_skillet_mobile/services/http_client.dart';

import 'mocks.mocks.dart';

/// Creates a widget with all required providers for testing
Widget createTestWidget({
  required Widget child,
  MockAuthProvider? mockAuthProvider,
  MockPropertyProvider? mockPropertyProvider,
  MockProjectProvider? mockProjectProvider,
}) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider ?? MockAuthProvider(),
        ),
        ChangeNotifierProvider<PropertyProvider>.value(
          value: mockPropertyProvider ?? MockPropertyProvider(),
        ),
        ChangeNotifierProvider<ProjectProvider>.value(
          value: mockProjectProvider ?? MockProjectProvider(),
        ),
      ],
      child: child,
    ),
  );
}

/// Creates a minimal widget for testing individual components
Widget createMinimalTestWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

/// Test data helpers
class TestData {
  static const mockUser = {
    'id': '1',
    'email': 'test@example.com',
    'first_name': 'John',
    'last_name': 'Doe',
    'phone': '+1234567890',
    'profile_image_url': null,
    'created_at': '2023-01-01T00:00:00.000Z',
    'updated_at': '2023-01-01T00:00:00.000Z',
  };

  static const mockProperty = {
    'id': '1',
    'name': 'Test Property',
    'address': '123 Test St',
    'description': 'A test property',
    'type': 'house',
    'year_built': 2000,
    'square_footage': 2000.0,
    'bedrooms': 3,
    'bathrooms': 2,
    'image_urls': [],
    'owner_id': '1',
    'created_at': '2023-01-01T00:00:00.000Z',
    'updated_at': '2023-01-01T00:00:00.000Z',
  };

  static const mockProject = {
    'id': '1',
    'title': 'Test Project',
    'description': 'A test project',
    'status': 'planned',
    'priority': 'medium',
    'start_date': null,
    'end_date': null,
    'due_date': null,
    'estimated_cost': 1000.0,
    'actual_cost': null,
    'notes': null,
    'image_urls': [],
    'property_id': '1',
    'user_id': '1',
    'created_at': '2023-01-01T00:00:00.000Z',
    'updated_at': '2023-01-01T00:00:00.000Z',
  };

  static const mockTask = {
    'id': '1',
    'title': 'Test Task',
    'description': 'A test task',
    'status': 'pending',
    'priority': 'medium',
    'due_date': null,
    'estimated_hours': 2.0,
    'actual_hours': null,
    'notes': null,
    'image_urls': [],
    'project_id': '1',
    'assigned_user_id': '1',
    'created_at': '2023-01-01T00:00:00.000Z',
    'updated_at': '2023-01-01T00:00:00.000Z',
  };

  static const mockAuthResponse = {
    'access_token': 'mock_access_token',
    'refresh_token': 'mock_refresh_token',
    'user': mockUser,
    'expires_in': 3600,
    'token_type': 'Bearer',
  };

  static const mockLoginRequest = {
    'email': 'test@example.com',
    'password': 'password123',
  };

  static const mockRegisterRequest = {
    'email': 'test@example.com',
    'password': 'password123',
    'first_name': 'John',
    'last_name': 'Doe',
    'phone': '+1234567890',
  };
}

/// Common test matchers and finders
class TestFinders {
  static Finder get loginEmailField => find.byKey(const Key('login_email_field'));
  static Finder get loginPasswordField => find.byKey(const Key('login_password_field'));
  static Finder get loginButton => find.byKey(const Key('login_button'));
  
  static Finder get registerEmailField => find.byKey(const Key('register_email_field'));
  static Finder get registerPasswordField => find.byKey(const Key('register_password_field'));
  static Finder get registerFirstNameField => find.byKey(const Key('register_first_name_field'));
  static Finder get registerLastNameField => find.byKey(const Key('register_last_name_field'));
  static Finder get registerButton => find.byKey(const Key('register_button'));
  
  static Finder get loadingIndicator => find.byType(CircularProgressIndicator);
  static Finder get errorMessage => find.textContaining('error', skipOffstage: false);
}

/// Test utilities for async operations
class TestUtils {
  /// Pumps and settles multiple times to handle complex async operations
  static Future<void> pumpAndSettleMultiple(WidgetTester tester, [int times = 3]) async {
    for (int i = 0; i < times; i++) {
      await tester.pumpAndSettle();
    }
  }

  /// Waits for a specific widget to appear
  static Future<void> waitForWidget(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 5)}) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      await tester.pump();
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    throw Exception('Widget not found within timeout: $finder');
  }

  /// Verifies that a widget is not present
  static void verifyWidgetNotPresent(Finder finder) {
    expect(finder, findsNothing);
  }
}

/// Mock response builders
class MockResponses {
  static void setupSuccessfulAuth(MockHttpClient mockHttpClient) {
    when(mockHttpClient.post(any, data: anyNamed('data')))
        .thenAnswer((_) async => MockResponse(200, TestData.mockAuthResponse));
  }

  static void setupFailedAuth(MockHttpClient mockHttpClient) {
    when(mockHttpClient.post(any, data: anyNamed('data')))
        .thenThrow(Exception('Authentication failed'));
  }

  static void setupSuccessfulPropertyLoad(MockHttpClient mockHttpClient) {
    when(mockHttpClient.get(any))
        .thenAnswer((_) async => MockResponse(200, [TestData.mockProperty]));
  }

  static void setupSuccessfulProjectLoad(MockHttpClient mockHttpClient) {
    when(mockHttpClient.get(any))
        .thenAnswer((_) async => MockResponse(200, [TestData.mockProject]));
  }
}

/// Mock HTTP Response
class MockResponse {
  final int statusCode;
  final dynamic data;
  final String? statusMessage;

  MockResponse(this.statusCode, this.data, [this.statusMessage]);
}

/// Extensions for easier testing
extension WidgetTesterExtensions on WidgetTester {
  /// Enters text and triggers the field
  Future<void> enterTextAndTrigger(Finder finder, String text) async {
    await enterText(finder, text);
    await pump();
  }

  /// Taps and settles
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }
}

/// Provider state verification helpers
class ProviderTestHelpers {
  static void verifyAuthProviderState(
    AuthProvider provider, {
    AuthStatus? expectedStatus,
    bool? expectedLoading,
    String? expectedError,
    bool? expectedAuthenticated,
  }) {
    if (expectedStatus != null) {
      expect(provider.status, equals(expectedStatus));
    }
    if (expectedLoading != null) {
      expect(provider.isLoading, equals(expectedLoading));
    }
    if (expectedError != null) {
      expect(provider.errorMessage, equals(expectedError));
    }
    if (expectedAuthenticated != null) {
      expect(provider.isAuthenticated, equals(expectedAuthenticated));
    }
  }

  static void verifyPropertyProviderState(
    PropertyProvider provider, {
    bool? expectedLoading,
    String? expectedError,
    int? expectedPropertyCount,
  }) {
    if (expectedLoading != null) {
      expect(provider.isLoading, equals(expectedLoading));
    }
    if (expectedError != null) {
      expect(provider.errorMessage, equals(expectedError));
    }
    if (expectedPropertyCount != null) {
      expect(provider.properties.length, equals(expectedPropertyCount));
    }
  }
}