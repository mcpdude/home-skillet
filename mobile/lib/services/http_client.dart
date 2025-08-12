import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';
import '../config/supabase_config.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

class HttpClient {
  late final Dio _dio;
  late final Dio _supabaseDio;
  final StorageService _storageService;

  HttpClient({required StorageService storageService})
      : _storageService = storageService {
    // Traditional backend API client
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Supabase REST API client (for direct REST API calls)
    _supabaseDio = Dio(BaseOptions(
      baseUrl: SupabaseConfig.isConfigured() ? '${SupabaseConfig.supabaseUrl}${ApiConfig.supabaseRestEndpoint}' : '',
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Prefer': 'return=representation',
        if (SupabaseConfig.isConfigured()) 'apikey': SupabaseConfig.supabaseAnonKey,
      },
    ));

    _setupInterceptors();
  }

  Dio get dio => _dio;
  Dio get supabaseDio => _supabaseDio;

  void _setupInterceptors() {
    // Traditional backend API interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to requests
        final token = await _storageService.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        if (kDebugMode) {
          print('🌐 NODE REQUEST: ${options.method} ${options.path}');
          print('📤 Headers: ${options.headers}');
          if (options.data != null) {
            print('📤 Data: ${options.data}');
          }
        }

        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
          print('📥 Data: ${response.data}');
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          print('❌ ERROR: ${error.response?.statusCode} ${error.requestOptions.path}');
          print('❌ Message: ${error.message}');
          if (error.response?.data != null) {
            print('❌ Response: ${error.response?.data}');
          }
        }

        // Handle 401 Unauthorized - try to refresh token
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the original request
            final options = error.requestOptions;
            final token = await _storageService.getAccessToken();
            options.headers['Authorization'] = 'Bearer $token';
            
            try {
              final response = await _dio.fetch(options);
              handler.resolve(response);
              return;
            } catch (e) {
              // If retry fails, proceed with original error
            }
          }
        }

        handler.next(error);
      },
    ));

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
      ));
    }

    // Supabase REST API interceptors
    _supabaseDio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add Supabase auth token to requests
        final supabaseUser = SupabaseService.instance.currentUser;
        if (supabaseUser != null) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session?.accessToken != null) {
            options.headers['Authorization'] = 'Bearer ${session!.accessToken}';
          }
        }

        if (kDebugMode) {
          print('🌐 SUPABASE REQUEST: ${options.method} ${options.path}');
          print('📤 Headers: ${options.headers}');
          if (options.data != null) {
            print('📤 Data: ${options.data}');
          }
        }

        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('✅ SUPABASE RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
          print('📥 Data: ${response.data}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          print('❌ SUPABASE ERROR: ${error.response?.statusCode} ${error.requestOptions.path}');
          print('❌ Message: ${error.message}');
          if (error.response?.data != null) {
            print('❌ Response: ${error.response?.data}');
          }
        }
        handler.next(error);
      },
    ));

    if (kDebugMode) {
      _supabaseDio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
      ));
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      // Create a separate Dio instance for refresh to avoid interceptor loops
      final refreshDio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
      ));

      final response = await refreshDio.post(
        '${ApiConfig.authEndpoint}/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _storageService.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        );
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Token refresh failed: $e');
      }
      // Clear tokens if refresh fails
      await _storageService.clearTokens();
    }
    return false;
  }

  // Helper method to determine which client to use
  Dio _getClientForRequest(String path) {
    // Use Supabase client for table operations when in Supabase or hybrid mode
    if (ApiConfig.isUsingSupabase || 
        (ApiConfig.isUsingHybrid && _isDataOperation(path))) {
      return _supabaseDio;
    }
    return _dio;
  }
  
  bool _isDataOperation(String path) {
    // Data operations that should use Supabase in hybrid mode
    const dataEndpoints = ['/properties', '/projects', '/tasks'];
    return dataEndpoints.any((endpoint) => path.startsWith(endpoint));
  }
  
  String _transformPathForSupabase(String path) {
    // Transform traditional API paths to Supabase table names
    if (path.startsWith('/properties')) {
      return path.replaceFirst('/properties', '/properties');
    } else if (path.startsWith('/projects')) {
      return path.replaceFirst('/projects', '/projects');
    } else if (path.startsWith('/tasks')) {
      return path.replaceFirst('/tasks', '/project_tasks');
    }
    return path;
  }

  // HTTP Methods with smart routing
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
    bool? forceNodeBackend,
  }) {
    final client = forceNodeBackend == true ? _dio : _getClientForRequest(path);
    final finalPath = client == _supabaseDio ? _transformPathForSupabase(path) : path;
    
    return client.get<T>(
      finalPath,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
    bool? forceNodeBackend,
  }) {
    final client = forceNodeBackend == true ? _dio : _getClientForRequest(path);
    final finalPath = client == _supabaseDio ? _transformPathForSupabase(path) : path;
    
    return client.post<T>(
      finalPath,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
    bool? forceNodeBackend,
  }) {
    final client = forceNodeBackend == true ? _dio : _getClientForRequest(path);
    final finalPath = client == _supabaseDio ? _transformPathForSupabase(path) : path;
    
    return client.put<T>(
      finalPath,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
    bool? forceNodeBackend,
  }) {
    final client = forceNodeBackend == true ? _dio : _getClientForRequest(path);
    final finalPath = client == _supabaseDio ? _transformPathForSupabase(path) : path;
    
    return client.patch<T>(
      finalPath,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool? forceNodeBackend,
  }) {
    final client = forceNodeBackend == true ? _dio : _getClientForRequest(path);
    final finalPath = client == _supabaseDio ? _transformPathForSupabase(path) : path;
    
    return client.delete<T>(
      finalPath,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response> download(
    String urlPath,
    dynamic savePath, {
    void Function(int, int)? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Options? options,
  }) {
    return _dio.download(
      urlPath,
      savePath,
      onReceiveProgress: onReceiveProgress,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      deleteOnError: deleteOnError,
      lengthHeader: lengthHeader,
      options: options,
    );
  }
}