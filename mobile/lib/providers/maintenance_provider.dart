import 'package:flutter/foundation.dart';
import '../models/maintenance.dart';
import '../services/maintenance_service.dart';

/// Provider for managing maintenance state
class MaintenanceProvider extends ChangeNotifier {
  final MaintenanceService _maintenanceService;

  // State variables
  List<MaintenanceSchedule> _schedules = [];
  List<MaintenanceTask> _tasks = [];
  MaintenanceStats? _stats;
  
  bool _isLoading = false;
  bool _isLoadingSchedules = false;
  bool _isLoadingTasks = false;
  bool _isLoadingStats = false;
  
  String? _errorMessage;
  String? _schedulesErrorMessage;
  String? _tasksErrorMessage;
  String? _statsErrorMessage;

  String? _selectedPropertyId;

  MaintenanceProvider({required MaintenanceService maintenanceService})
      : _maintenanceService = maintenanceService;

  // Getters
  List<MaintenanceSchedule> get schedules => List.unmodifiable(_schedules);
  List<MaintenanceTask> get tasks => List.unmodifiable(_tasks);
  MaintenanceStats? get stats => _stats;

  bool get isLoading => _isLoading;
  bool get isLoadingSchedules => _isLoadingSchedules;
  bool get isLoadingTasks => _isLoadingTasks;
  bool get isLoadingStats => _isLoadingStats;

  String? get errorMessage => _errorMessage;
  String? get schedulesErrorMessage => _schedulesErrorMessage;
  String? get tasksErrorMessage => _tasksErrorMessage;
  String? get statsErrorMessage => _statsErrorMessage;

  String? get selectedPropertyId => _selectedPropertyId;

  // Computed getters
  List<MaintenanceSchedule> get activeSchedules =>
      _schedules.where((schedule) => schedule.isActive).toList();

  List<MaintenanceSchedule> get overdueSchedules =>
      _schedules.where((schedule) => schedule.isOverdue).toList();

  List<MaintenanceSchedule> get dueSoonSchedules =>
      _schedules.where((schedule) => schedule.isDueSoon).toList();

  List<MaintenanceTask> get overdueTasks =>
      _tasks.where((task) => task.isOverdue).toList();

  List<MaintenanceTask> get todaysTasks =>
      _tasks.where((task) => task.isDueToday).toList();

  List<MaintenanceTask> get dueSoonTasks =>
      _tasks.where((task) => task.isDueSoon).toList();

  List<MaintenanceTask> get completedTasks =>
      _tasks.where((task) => task.status == MaintenanceStatus.completed).toList();

  List<MaintenanceTask> get activeTasks =>
      _tasks.where((task) => task.status == MaintenanceStatus.active).toList();

  // Property filter methods
  void setSelectedProperty(String? propertyId) {
    if (_selectedPropertyId != propertyId) {
      _selectedPropertyId = propertyId;
      notifyListeners();
      // Reload data for the new property
      loadMaintenanceData();
    }
  }

  void clearSelectedProperty() {
    setSelectedProperty(null);
  }

  // Combined loading methods
  Future<void> loadMaintenanceData() async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        loadSchedules(),
        loadTasks(),
        loadStats(),
      ]);
    } catch (e) {
      _setError('Failed to load maintenance data: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshMaintenanceData() async {
    await loadMaintenanceData();
  }

  // Schedule management
  Future<void> loadSchedules() async {
    _setLoadingSchedules(true);
    _clearSchedulesError();

    try {
      final schedules = _selectedPropertyId != null
          ? await _maintenanceService.getSchedulesByProperty(_selectedPropertyId!)
          : await _maintenanceService.getSchedules();
      
      _schedules = schedules;
      notifyListeners();
    } catch (e) {
      _setSchedulesError('Failed to load maintenance schedules: $e');
    } finally {
      _setLoadingSchedules(false);
    }
  }

  Future<MaintenanceSchedule> createSchedule(CreateMaintenanceScheduleRequest request) async {
    try {
      final schedule = await _maintenanceService.createSchedule(request);
      _schedules.add(schedule);
      notifyListeners();
      return schedule;
    } catch (e) {
      _setSchedulesError('Failed to create maintenance schedule: $e');
      rethrow;
    }
  }

  Future<MaintenanceSchedule> updateSchedule(
    String id,
    CreateMaintenanceScheduleRequest request,
  ) async {
    try {
      final updatedSchedule = await _maintenanceService.updateSchedule(id, request);
      
      final index = _schedules.indexWhere((schedule) => schedule.id == id);
      if (index != -1) {
        _schedules[index] = updatedSchedule;
        notifyListeners();
      }
      
      return updatedSchedule;
    } catch (e) {
      _setSchedulesError('Failed to update maintenance schedule: $e');
      rethrow;
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      await _maintenanceService.deleteSchedule(id);
      _schedules.removeWhere((schedule) => schedule.id == id);
      notifyListeners();
    } catch (e) {
      _setSchedulesError('Failed to delete maintenance schedule: $e');
      rethrow;
    }
  }

  Future<void> toggleSchedule(String id) async {
    try {
      final updatedSchedule = await _maintenanceService.toggleSchedule(id);
      
      final index = _schedules.indexWhere((schedule) => schedule.id == id);
      if (index != -1) {
        _schedules[index] = updatedSchedule;
        notifyListeners();
      }
    } catch (e) {
      _setSchedulesError('Failed to toggle maintenance schedule: $e');
      rethrow;
    }
  }

  MaintenanceSchedule? getScheduleById(String id) {
    try {
      return _schedules.firstWhere((schedule) => schedule.id == id);
    } catch (e) {
      return null;
    }
  }

  // Task management
  Future<void> loadTasks({
    MaintenanceStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoadingTasks(true);
    _clearTasksError();

    try {
      final tasks = await _maintenanceService.getTasks(
        status: status,
        propertyId: _selectedPropertyId,
        startDate: startDate,
        endDate: endDate,
      );
      
      _tasks = tasks;
      notifyListeners();
    } catch (e) {
      _setTasksError('Failed to load maintenance tasks: $e');
    } finally {
      _setLoadingTasks(false);
    }
  }

  Future<void> loadOverdueTasks() async {
    _setLoadingTasks(true);
    _clearTasksError();

    try {
      final tasks = await _maintenanceService.getOverdueTasks(
        propertyId: _selectedPropertyId,
      );
      
      _tasks = tasks;
      notifyListeners();
    } catch (e) {
      _setTasksError('Failed to load overdue tasks: $e');
    } finally {
      _setLoadingTasks(false);
    }
  }

  Future<void> loadTodaysTasks() async {
    _setLoadingTasks(true);
    _clearTasksError();

    try {
      final tasks = await _maintenanceService.getTodaysTasks(
        propertyId: _selectedPropertyId,
      );
      
      _tasks = tasks;
      notifyListeners();
    } catch (e) {
      _setTasksError('Failed to load today\'s tasks: $e');
    } finally {
      _setLoadingTasks(false);
    }
  }

  Future<void> loadThisWeeksTasks() async {
    _setLoadingTasks(true);
    _clearTasksError();

    try {
      final tasks = await _maintenanceService.getThisWeeksTasks(
        propertyId: _selectedPropertyId,
      );
      
      _tasks = tasks;
      notifyListeners();
    } catch (e) {
      _setTasksError('Failed to load this week\'s tasks: $e');
    } finally {
      _setLoadingTasks(false);
    }
  }

  Future<MaintenanceTask> completeTask(CompleteMaintenanceTaskRequest request) async {
    try {
      final completedTask = await _maintenanceService.completeTask(request);
      
      final index = _tasks.indexWhere((task) => task.id == request.taskId);
      if (index != -1) {
        _tasks[index] = completedTask;
        notifyListeners();
      }
      
      return completedTask;
    } catch (e) {
      _setTasksError('Failed to complete maintenance task: $e');
      rethrow;
    }
  }

  Future<MaintenanceTask> skipTask(String taskId, {String? reason}) async {
    try {
      final skippedTask = await _maintenanceService.skipTask(taskId, reason: reason);
      
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        _tasks[index] = skippedTask;
        notifyListeners();
      }
      
      return skippedTask;
    } catch (e) {
      _setTasksError('Failed to skip maintenance task: $e');
      rethrow;
    }
  }

  MaintenanceTask? getTaskById(String id) {
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  // Statistics management
  Future<void> loadStats() async {
    _setLoadingStats(true);
    _clearStatsError();

    try {
      final stats = await _maintenanceService.getStats(
        propertyId: _selectedPropertyId,
      );
      
      _stats = stats;
      notifyListeners();
    } catch (e) {
      _setStatsError('Failed to load maintenance statistics: $e');
    } finally {
      _setLoadingStats(false);
    }
  }

  // Search and filtering
  List<MaintenanceSchedule> searchSchedules(String query) {
    if (query.isEmpty) return schedules;

    final lowerQuery = query.toLowerCase();
    return _schedules.where((schedule) {
      return schedule.title.toLowerCase().contains(lowerQuery) ||
          schedule.description.toLowerCase().contains(lowerQuery) ||
          schedule.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  List<MaintenanceTask> searchTasks(String query) {
    if (query.isEmpty) return tasks;

    final lowerQuery = query.toLowerCase();
    return _tasks.where((task) {
      return task.title.toLowerCase().contains(lowerQuery) ||
          task.description.toLowerCase().contains(lowerQuery) ||
          task.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  List<MaintenanceSchedule> filterSchedulesByProperty(String propertyId) {
    return _schedules.where((schedule) => schedule.propertyId == propertyId).toList();
  }

  List<MaintenanceTask> filterTasksByProperty(String propertyId) {
    return _tasks.where((task) => task.propertyId == propertyId).toList();
  }

  List<MaintenanceSchedule> filterSchedulesByPriority(MaintenancePriority priority) {
    return _schedules.where((schedule) => schedule.priority == priority).toList();
  }

  List<MaintenanceTask> filterTasksByPriority(MaintenancePriority priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }

  List<MaintenanceTask> filterTasksByStatus(MaintenanceStatus status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  // State management helpers
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setLoadingSchedules(bool loading) {
    if (_isLoadingSchedules != loading) {
      _isLoadingSchedules = loading;
      notifyListeners();
    }
  }

  void _setLoadingTasks(bool loading) {
    if (_isLoadingTasks != loading) {
      _isLoadingTasks = loading;
      notifyListeners();
    }
  }

  void _setLoadingStats(bool loading) {
    if (_isLoadingStats != loading) {
      _isLoadingStats = loading;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _setSchedulesError(String message) {
    _schedulesErrorMessage = message;
    notifyListeners();
  }

  void _setTasksError(String message) {
    _tasksErrorMessage = message;
    notifyListeners();
  }

  void _setStatsError(String message) {
    _statsErrorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _clearSchedulesError() {
    if (_schedulesErrorMessage != null) {
      _schedulesErrorMessage = null;
      notifyListeners();
    }
  }

  void _clearTasksError() {
    if (_tasksErrorMessage != null) {
      _tasksErrorMessage = null;
      notifyListeners();
    }
  }

  void _clearStatsError() {
    if (_statsErrorMessage != null) {
      _statsErrorMessage = null;
      notifyListeners();
    }
  }

  void clearAllErrors() {
    _clearError();
    _clearSchedulesError();
    _clearTasksError();
    _clearStatsError();
  }

  void reset() {
    _schedules.clear();
    _tasks.clear();
    _stats = null;
    _selectedPropertyId = null;
    
    _isLoading = false;
    _isLoadingSchedules = false;
    _isLoadingTasks = false;
    _isLoadingStats = false;
    
    clearAllErrors();
    notifyListeners();
  }
}