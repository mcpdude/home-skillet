import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/maintenance.dart';
import '../services/http_client.dart';
import '../services/storage_service.dart';

part 'maintenance_service.g.dart';

/// API endpoints for maintenance operations
@RestApi(baseUrl: "/api/v1/maintenance")
abstract class MaintenanceApiClient {
  factory MaintenanceApiClient(Dio dio, {String baseUrl}) = _MaintenanceApiClient;

  /// Get all maintenance schedules for user's properties
  @GET("/schedules")
  Future<List<MaintenanceSchedule>> getSchedules();

  /// Get maintenance schedules for a specific property
  @GET("/schedules")
  Future<List<MaintenanceSchedule>> getSchedulesByProperty(
    @Query("propertyId") String propertyId,
  );

  /// Get a specific maintenance schedule
  @GET("/schedules/{id}")
  Future<MaintenanceSchedule> getSchedule(@Path("id") String id);

  /// Create a new maintenance schedule
  @POST("/schedules")
  Future<MaintenanceSchedule> createSchedule(
    @Body() CreateMaintenanceScheduleRequest request,
  );

  /// Update a maintenance schedule
  @PUT("/schedules/{id}")
  Future<MaintenanceSchedule> updateSchedule(
    @Path("id") String id,
    @Body() CreateMaintenanceScheduleRequest request,
  );

  /// Delete a maintenance schedule
  @DELETE("/schedules/{id}")
  Future<void> deleteSchedule(@Path("id") String id);

  /// Toggle schedule active status
  @PATCH("/schedules/{id}/toggle")
  Future<MaintenanceSchedule> toggleSchedule(@Path("id") String id);

  /// Get all maintenance tasks
  @GET("/tasks")
  Future<List<MaintenanceTask>> getTasks({
    @Query("status") String? status,
    @Query("propertyId") String? propertyId,
    @Query("startDate") String? startDate,
    @Query("endDate") String? endDate,
  });

  /// Get a specific maintenance task
  @GET("/tasks/{id}")
  Future<MaintenanceTask> getTask(@Path("id") String id);

  /// Complete a maintenance task
  @POST("/tasks/{id}/complete")
  Future<MaintenanceTask> completeTask(
    @Path("id") String id,
    @Body() CompleteMaintenanceTaskRequest request,
  );

  /// Skip a maintenance task
  @POST("/tasks/{id}/skip")
  Future<MaintenanceTask> skipTask(
    @Path("id") String id,
    @Body() Map<String, String> request,
  );

  /// Get maintenance statistics
  @GET("/stats")
  Future<MaintenanceStats> getStats({
    @Query("propertyId") String? propertyId,
  });
}

/// Service for managing maintenance schedules and tasks
class MaintenanceService {
  final MaintenanceApiClient _apiClient;
  final StorageService _storageService;

  MaintenanceService({
    required MaintenanceApiClient apiClient,
    required StorageService storageService,
  })  : _apiClient = apiClient,
        _storageService = storageService;

  factory MaintenanceService.create({
    required StorageService storageService,
  }) {
    final httpClient = HttpClientService.createDioClient(storageService);
    final apiClient = MaintenanceApiClient(httpClient);
    return MaintenanceService(
      apiClient: apiClient,
      storageService: storageService,
    );
  }

  // Schedules

  /// Get all maintenance schedules
  Future<List<MaintenanceSchedule>> getSchedules() async {
    try {
      return await _apiClient.getSchedules();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to load maintenance schedules');
    } catch (e) {
      throw MaintenanceException('Failed to load maintenance schedules: $e');
    }
  }

  /// Get maintenance schedules for a specific property
  Future<List<MaintenanceSchedule>> getSchedulesByProperty(String propertyId) async {
    try {
      return await _apiClient.getSchedulesByProperty(propertyId);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to load maintenance schedules for property');
    } catch (e) {
      throw MaintenanceException('Failed to load maintenance schedules: $e');
    }
  }

  /// Get a specific maintenance schedule
  Future<MaintenanceSchedule> getSchedule(String id) async {
    try {
      return await _apiClient.getSchedule(id);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to load maintenance schedule');
    } catch (e) {
      throw MaintenanceException('Failed to load maintenance schedule: $e');
    }
  }

  /// Create a new maintenance schedule
  Future<MaintenanceSchedule> createSchedule(CreateMaintenanceScheduleRequest request) async {
    try {
      // Validate request
      _validateScheduleRequest(request);
      
      final schedule = await _apiClient.createSchedule(request);
      return schedule;
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to create maintenance schedule');
    } catch (e) {
      if (e is MaintenanceException) rethrow;
      throw MaintenanceException('Failed to create maintenance schedule: $e');
    }
  }

  /// Update a maintenance schedule
  Future<MaintenanceSchedule> updateSchedule(
    String id,
    CreateMaintenanceScheduleRequest request,
  ) async {
    try {
      _validateScheduleRequest(request);
      
      final schedule = await _apiClient.updateSchedule(id, request);
      return schedule;
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to update maintenance schedule');
    } catch (e) {
      if (e is MaintenanceException) rethrow;
      throw MaintenanceException('Failed to update maintenance schedule: $e');
    }
  }

  /// Delete a maintenance schedule
  Future<void> deleteSchedule(String id) async {
    try {
      await _apiClient.deleteSchedule(id);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to delete maintenance schedule');
    } catch (e) {
      throw MaintenanceException('Failed to delete maintenance schedule: $e');
    }
  }

  /// Toggle schedule active status
  Future<MaintenanceSchedule> toggleSchedule(String id) async {
    try {
      return await _apiClient.toggleSchedule(id);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to toggle maintenance schedule');
    } catch (e) {
      throw MaintenanceException('Failed to toggle maintenance schedule: $e');
    }
  }

  // Tasks

  /// Get maintenance tasks with optional filters
  Future<List<MaintenanceTask>> getTasks({
    MaintenanceStatus? status,
    String? propertyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _apiClient.getTasks(
        status: status?.name,
        propertyId: propertyId,
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
      );
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to load maintenance tasks');
    } catch (e) {
      throw MaintenanceException('Failed to load maintenance tasks: $e');
    }
  }

  /// Get overdue maintenance tasks
  Future<List<MaintenanceTask>> getOverdueTasks({String? propertyId}) async {
    return getTasks(
      status: MaintenanceStatus.overdue,
      propertyId: propertyId,
    );
  }

  /// Get maintenance tasks due today
  Future<List<MaintenanceTask>> getTodaysTasks({String? propertyId}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getTasks(
      propertyId: propertyId,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// Get maintenance tasks due this week
  Future<List<MaintenanceTask>> getThisWeeksTasks({String? propertyId}) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    return getTasks(
      propertyId: propertyId,
      startDate: weekStart,
      endDate: weekEnd,
    );
  }

  /// Get a specific maintenance task
  Future<MaintenanceTask> getTask(String id) async {
    try {
      return await _apiClient.getTask(id);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to load maintenance task');
    } catch (e) {
      throw MaintenanceException('Failed to load maintenance task: $e');
    }
  }

  /// Complete a maintenance task
  Future<MaintenanceTask> completeTask(CompleteMaintenanceTaskRequest request) async {
    try {
      return await _apiClient.completeTask(request.taskId, request);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to complete maintenance task');
    } catch (e) {
      throw MaintenanceException('Failed to complete maintenance task: $e');
    }
  }

  /// Skip a maintenance task
  Future<MaintenanceTask> skipTask(String taskId, {String? reason}) async {
    try {
      return await _apiClient.skipTask(taskId, {'reason': reason ?? ''});
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to skip maintenance task');
    } catch (e) {
      throw MaintenanceException('Failed to skip maintenance task: $e');
    }
  }

  // Statistics

  /// Get maintenance statistics
  Future<MaintenanceStats> getStats({String? propertyId}) async {
    try {
      return await _apiClient.getStats(propertyId: propertyId);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to load maintenance statistics');
    } catch (e) {
      throw MaintenanceException('Failed to load maintenance statistics: $e');
    }
  }

  // Validation helpers

  void _validateScheduleRequest(CreateMaintenanceScheduleRequest request) {
    if (request.title.trim().isEmpty) {
      throw MaintenanceException('Schedule title cannot be empty');
    }

    if (request.description.trim().isEmpty) {
      throw MaintenanceException('Schedule description cannot be empty');
    }

    if (request.frequency == MaintenanceFrequency.custom) {
      if (request.customIntervalDays == null || request.customIntervalDays! <= 0) {
        throw MaintenanceException('Custom frequency requires a valid interval in days');
      }
    }

    if (request.nextDue.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      throw MaintenanceException('Next due date cannot be in the past');
    }

    if (request.estimatedCost != null && request.estimatedCost! < 0) {
      throw MaintenanceException('Estimated cost cannot be negative');
    }

    if (request.estimatedDuration != null && request.estimatedDuration! <= 0) {
      throw MaintenanceException('Estimated duration must be positive');
    }
  }

  Exception _handleDioException(DioException e, String defaultMessage) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return MaintenanceException('Connection timeout. Please check your internet connection.');
      
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] as String?;
        
        switch (statusCode) {
          case 400:
            return MaintenanceException(message ?? 'Invalid request data');
          case 401:
            return MaintenanceException('Authentication required. Please log in again.');
          case 403:
            return MaintenanceException('Access denied. You don\'t have permission for this action.');
          case 404:
            return MaintenanceException('Resource not found');
          case 409:
            return MaintenanceException(message ?? 'Conflict with existing data');
          case 422:
            return MaintenanceException(message ?? 'Invalid data provided');
          case 500:
            return MaintenanceException('Server error. Please try again later.');
          default:
            return MaintenanceException(message ?? defaultMessage);
        }
      
      case DioExceptionType.cancel:
        return MaintenanceException('Request was cancelled');
      
      case DioExceptionType.connectionError:
        return MaintenanceException('Connection error. Please check your internet connection.');
      
      case DioExceptionType.unknown:
      case DioExceptionType.badCertificate:
        return MaintenanceException(defaultMessage);
    }
  }
}

/// Exception thrown by maintenance service operations
class MaintenanceException implements Exception {
  final String message;

  const MaintenanceException(this.message);

  @override
  String toString() => 'MaintenanceException: $message';
}