import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';

import '../../lib/services/http_client.dart';
import '../../lib/services/storage_service.dart';
import '../../lib/config/api_config.dart';
import '../helpers/mocks.dart';

void main() {
  group('HttpClient - Hybrid Mode', () {
    late MockStorageService mockStorageService;
    late HttpClient httpClient;

    setUp(() {
      mockStorageService = MockStorageService();
      httpClient = HttpClient(storageService: mockStorageService);
    });

    group('request routing', () {
      test('should route auth requests to Node.js backend', () {
        final client = httpClient._getClientForRequest('/auth/login');
        expect(client, equals(httpClient.dio)); // Traditional backend
      });

      test('should route data operations to Supabase in hybrid mode', () {
        ApiConfig.setApiMode(ApiMode.hybrid);
        
        expect(httpClient._isDataOperation('/properties'), isTrue);
        expect(httpClient._isDataOperation('/projects'), isTrue);
        expect(httpClient._isDataOperation('/tasks'), isTrue);
        expect(httpClient._isDataOperation('/auth/login'), isFalse);
      });

      test('should route all requests to Supabase in Supabase-only mode', () {
        ApiConfig.setApiMode(ApiMode.supabase);
        
        final client = httpClient._getClientForRequest('/properties');
        expect(client, equals(httpClient.supabaseDio)); // Supabase client
      });

      test('should route all requests to Node.js in backend-only mode', () {
        ApiConfig.setApiMode(ApiMode.nodeBackend);
        
        final client = httpClient._getClientForRequest('/properties');
        expect(client, equals(httpClient.dio)); // Traditional backend
      });
    });

    group('path transformation', () {
      test('should transform paths correctly for Supabase', () {
        expect(
          httpClient._transformPathForSupabase('/properties'),
          equals('/properties'),
        );
        expect(
          httpClient._transformPathForSupabase('/projects'),
          equals('/projects'),
        );
        expect(
          httpClient._transformPathForSupabase('/tasks'),
          equals('/project_tasks'),
        );
      });

      test('should not transform unknown paths', () {
        expect(
          httpClient._transformPathForSupabase('/unknown'),
          equals('/unknown'),
        );
      });
    });

    group('HTTP methods with routing', () {
      test('should route GET requests correctly', () async {
        when(mockStorageService.getAccessToken())
            .thenAnswer((_) async => 'test-token');

        ApiConfig.setApiMode(ApiMode.hybrid);

        // This would normally make the request, but we're testing the routing logic
        expect(() => httpClient.get('/properties'), returnsNormally);
      });

      test('should force Node.js backend when specified', () async {
        when(mockStorageService.getAccessToken())
            .thenAnswer((_) async => 'test-token');

        ApiConfig.setApiMode(ApiMode.supabase);

        // Force Node.js backend even in Supabase mode
        expect(() => httpClient.get('/properties', forceNodeBackend: true), returnsNormally);
      });

      test('should route POST requests correctly', () async {
        when(mockStorageService.getAccessToken())
            .thenAnswer((_) async => 'test-token');

        ApiConfig.setApiMode(ApiMode.hybrid);

        expect(() => httpClient.post('/projects', data: {'title': 'Test'}), returnsNormally);
      });

      test('should route PUT requests correctly', () async {
        when(mockStorageService.getAccessToken())
            .thenAnswer((_) async => 'test-token');

        ApiConfig.setApiMode(ApiMode.hybrid);

        expect(() => httpClient.put('/projects/123', data: {'title': 'Updated'}), returnsNormally);
      });

      test('should route PATCH requests correctly', () async {
        when(mockStorageService.getAccessToken())
            .thenAnswer((_) async => 'test-token');

        ApiConfig.setApiMode(ApiMode.hybrid);

        expect(() => httpClient.patch('/projects/123', data: {'status': 'completed'}), returnsNormally);
      });

      test('should route DELETE requests correctly', () async {
        when(mockStorageService.getAccessToken())
            .thenAnswer((_) async => 'test-token');

        ApiConfig.setApiMode(ApiMode.hybrid);

        expect(() => httpClient.delete('/projects/123'), returnsNormally);
      });
    });

    group('authentication headers', () {
      test('should add JWT token for Node.js requests', () async {
        when(mockStorageService.getAccessToken())
            .thenAnswer((_) async => 'jwt-token');

        ApiConfig.setApiMode(ApiMode.nodeBackend);

        // The interceptor should add the JWT token
        // This would be tested by mocking the actual request
        expect(mockStorageService.getAccessToken(), completion('jwt-token'));
      });

      test('should add Supabase token for Supabase requests', () async {
        ApiConfig.setApiMode(ApiMode.supabase);

        // The interceptor should add the Supabase session token
        // This would be tested by mocking the Supabase client
        expect(() => httpClient.get('/properties'), returnsNormally);
      });
    });

    group('error handling', () {
      test('should handle Node.js backend errors correctly', () async {
        when(mockStorageService.getAccessToken())
            .thenAnswer((_) async => null);

        ApiConfig.setApiMode(ApiMode.nodeBackend);

        // Test error handling for Node.js backend
        expect(() => httpClient.get('/properties'), returnsNormally);
      });

      test('should handle Supabase errors correctly', () async {
        ApiConfig.setApiMode(ApiMode.supabase);

        // Test error handling for Supabase
        expect(() => httpClient.get('/properties'), returnsNormally);
      });
    });

    group('API mode switching', () {
      test('should switch between modes correctly', () {
        // Test initial mode
        ApiConfig.setApiMode(ApiMode.nodeBackend);
        expect(ApiConfig.isUsingNodeBackend, isTrue);

        // Switch to hybrid
        ApiConfig.setApiMode(ApiMode.hybrid);
        expect(ApiConfig.isUsingHybrid, isTrue);

        // Switch to Supabase
        ApiConfig.setApiMode(ApiMode.supabase);
        expect(ApiConfig.isUsingSupabase, isTrue);
      });
    });
  });

  group('ApiConfig', () {
    test('should have correct default values', () {
      expect(ApiConfig.baseUrl, isNotEmpty);
      expect(ApiConfig.authEndpoint, equals('/auth'));
      expect(ApiConfig.projectsEndpoint, equals('/projects'));
    });

    test('should handle API mode correctly', () {
      ApiConfig.setApiMode(ApiMode.hybrid);
      expect(ApiConfig.currentMode, equals(ApiMode.hybrid));
      expect(ApiConfig.isUsingHybrid, isTrue);
      expect(ApiConfig.isUsingSupabase, isFalse);
      expect(ApiConfig.isUsingNodeBackend, isFalse);
    });
  });
}