import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../lib/config/api_config.dart';
import '../../lib/config/supabase_config.dart';
import '../../lib/models/project.dart';
import '../../lib/models/property.dart';
import '../../lib/models/user.dart';
import 'mocks.dart';

class SupabaseTestHelpers {
  // Create mock Supabase user
  static User createMockSupabaseUser({
    String id = 'test-user-id',
    String email = 'test@example.com',
    Map<String, dynamic>? metadata,
  }) {
    return User(
      id: id,
      appMetadata: {},
      userMetadata: metadata ?? {
        'first_name': 'Test',
        'last_name': 'User',
      },
      aud: 'authenticated',
      email: email,
      emailConfirmedAt: DateTime.now().toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // Create mock session
  static Session createMockSession({
    String accessToken = 'mock-access-token',
    String refreshToken = 'mock-refresh-token',
    int expiresIn = 3600,
  }) {
    return Session(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      tokenType: 'Bearer',
      user: createMockSupabaseUser(),
    );
  }

  // Create mock project data
  static Map<String, dynamic> createMockProjectData({
    String id = 'test-project-id',
    String title = 'Test Project',
    String propertyId = 'test-property-id',
    String userId = 'test-user-id',
  }) {
    return {
      'id': id,
      'title': title,
      'description': 'Test Description',
      'property_id': propertyId,
      'user_id': userId,
      'status': 'active',
      'priority': 'medium',
      'budget': 1000.0,
      'start_date': DateTime.now().toIso8601String(),
      'target_completion_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Create mock property data
  static Map<String, dynamic> createMockPropertyData({
    String id = 'test-property-id',
    String name = 'Test Property',
    String userId = 'test-user-id',
  }) {
    return {
      'id': id,
      'name': name,
      'address': '123 Test St',
      'city': 'Test City',
      'state': 'TS',
      'zip_code': '12345',
      'property_type': 'residential',
      'purchase_date': DateTime.now().subtract(const Duration(days: 365)).toIso8601String(),
      'purchase_price': 300000.0,
      'square_footage': 2000,
      'bedrooms': 3,
      'bathrooms': 2,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Set up mock Supabase client for testing
  static void setupMockSupabaseClient(MockSupabaseClient mockClient) {
    final mockAuth = MockGoTrueClient();
    final mockRealtime = MockRealtimeClient();

    when(mockClient.auth).thenReturn(mockAuth);
    when(mockClient.realtime).thenReturn(mockRealtime);
  }

  // Set up mock authentication responses
  static void setupMockAuth(MockGoTrueClient mockAuth, {
    bool isAuthenticated = false,
    User? user,
    Session? session,
  }) {
    when(mockAuth.currentUser).thenReturn(user);
    when(mockAuth.currentSession).thenReturn(session);

    if (isAuthenticated && user != null && session != null) {
      final authResponse = AuthResponse(
        user: user,
        session: session,
      );

      when(mockAuth.signInWithPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => authResponse);

      when(mockAuth.signUp(
        email: anyNamed('email'),
        password: anyNamed('password'),
        data: anyNamed('data'),
      )).thenAnswer((_) async => authResponse);
    }
  }

  // Set up mock database queries
  static void setupMockDatabase(MockSupabaseClient mockClient) {
    final mockPostgrest = MockPostgrestClient();
    when(mockClient.from(any)).thenReturn(MockPostgrestQueryBuilder());
  }

  // Set up mock real-time subscriptions
  static MockRealtimeChannel setupMockRealtimeChannel(
    MockRealtimeClient mockRealtime,
    String channelName,
  ) {
    final mockChannel = MockRealtimeChannel();
    when(mockRealtime.channel(channelName)).thenReturn(mockChannel);
    
    when(mockChannel.onPostgresChanges(
      event: anyNamed('event'),
      schema: anyNamed('schema'),
      table: anyNamed('table'),
      filter: anyNamed('filter'),
    )).thenReturn(mockChannel);

    when(mockChannel.subscribe()).thenReturn(mockChannel);
    when(mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');

    return mockChannel;
  }

  // Create test environment for Supabase testing
  static void setupTestEnvironment() {
    // Reset API config to known state
    ApiConfig.setApiMode(ApiMode.nodeBackend);
    
    // Mock environment variables if needed
    // This would typically be done through test configuration
  }

  // Clean up test environment
  static void tearDownTestEnvironment() {
    // Reset to default state
    ApiConfig.setApiMode(ApiMode.nodeBackend);
  }

  // Verify that Supabase configuration is valid for testing
  static bool isSupabaseConfiguredForTesting() {
    return SupabaseConfig.isConfigured() && 
           SupabaseConfig.supabaseUrl.contains('test') ||
           SupabaseConfig.supabaseUrl.contains('localhost');
  }

  // Create test data for integration tests
  static Future<void> createTestData() async {
    // This would create test data in the database for integration tests
    // Implementation depends on your specific test database setup
  }

  // Clean up test data after integration tests
  static Future<void> cleanUpTestData() async {
    // This would clean up test data after integration tests
    // Implementation depends on your specific test database setup
  }

  // Helper to wait for real-time events with timeout
  static Future<T> waitForRealtimeEvent<T>(
    Stream<T> stream, {
    Duration timeout = const Duration(seconds: 10),
    T? defaultValue,
  }) async {
    try {
      return await stream.first.timeout(timeout);
    } catch (e) {
      if (defaultValue != null) {
        return defaultValue;
      }
      rethrow;
    }
  }

  // Assert that two projects are equal (for testing)
  static void assertProjectsEqual(Project expected, Project actual) {
    expect(actual.id, equals(expected.id));
    expect(actual.title, equals(expected.title));
    expect(actual.description, equals(expected.description));
    expect(actual.propertyId, equals(expected.propertyId));
    expect(actual.status, equals(expected.status));
    expect(actual.priority, equals(expected.priority));
  }

  // Assert that two properties are equal (for testing)
  static void assertPropertiesEqual(Property expected, Property actual) {
    expect(actual.id, equals(expected.id));
    expect(actual.name, equals(expected.name));
    expect(actual.address, equals(expected.address));
    expect(actual.city, equals(expected.city));
    expect(actual.state, equals(expected.state));
  }

  // Create matcher for testing error types
  static TypeMatcher<T> isSupabaseError<T>() {
    return isA<T>();
  }

  // Helper to simulate network delays in tests
  static Future<void> simulateNetworkDelay([Duration? delay]) async {
    await Future.delayed(delay ?? const Duration(milliseconds: 100));
  }

  // Generate test UUIDs
  static String generateTestId([String prefix = 'test']) {
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}';
  }
}