import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../lib/models/maintenance.dart';
import '../../lib/providers/maintenance_provider.dart';
import '../../lib/services/maintenance_service.dart';
import '../helpers/mocks.dart';

void main() {
  group('MaintenanceProvider Tests', () {
    late MaintenanceProvider provider;
    late MockMaintenanceService mockService;

    setUp(() {
      mockService = MockMaintenanceService();
      provider = MaintenanceProvider(maintenanceService: mockService);
    });

    group('Initialization', () {
      test('starts with empty state', () {
        expect(provider.schedules, isEmpty);
        expect(provider.tasks, isEmpty);
        expect(provider.stats, isNull);
        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, isNull);
        expect(provider.selectedPropertyId, isNull);
      });

      test('computed getters work with empty state', () {
        expect(provider.activeSchedules, isEmpty);
        expect(provider.overdueSchedules, isEmpty);
        expect(provider.dueSoonSchedules, isEmpty);
        expect(provider.overdueTasks, isEmpty);
        expect(provider.todaysTasks, isEmpty);
        expect(provider.dueSoonTasks, isEmpty);
        expect(provider.completedTasks, isEmpty);
        expect(provider.activeTasks, isEmpty);
      });
    });

    group('Property Selection', () {
      test('setSelectedProperty updates property and triggers reload', () async {
        const propertyId = 'test-property-123';
        
        when(mockService.getSchedulesByProperty(propertyId))
            .thenAnswer((_) async => []);
        when(mockService.getTasks(propertyId: propertyId))
            .thenAnswer((_) async => []);
        when(mockService.getStats(propertyId: propertyId))
            .thenAnswer((_) async => const MaintenanceStats(
              totalSchedules: 0,
              activeSchedules: 0,
              totalTasks: 0,
              completedTasks: 0,
              overdueTasks: 0,
              dueSoonTasks: 0,
              totalCost: 0,
              averageCostPerTask: 0,
              totalDuration: 0,
              completionRate: 0,
            ));

        provider.setSelectedProperty(propertyId);

        expect(provider.selectedPropertyId, equals(propertyId));
        
        // Allow async operations to complete
        await Future.delayed(Duration.zero);

        verify(mockService.getSchedulesByProperty(propertyId)).called(1);
        verify(mockService.getTasks(propertyId: propertyId)).called(1);
        verify(mockService.getStats(propertyId: propertyId)).called(1);
      });

      test('clearSelectedProperty resets property selection', () async {
        provider.setSelectedProperty('test-property');
        
        when(mockService.getSchedules()).thenAnswer((_) async => []);
        when(mockService.getTasks()).thenAnswer((_) async => []);
        when(mockService.getStats()).thenAnswer((_) async => const MaintenanceStats(
          totalSchedules: 0,
          activeSchedules: 0,
          totalTasks: 0,
          completedTasks: 0,
          overdueTasks: 0,
          dueSoonTasks: 0,
          totalCost: 0,
          averageCostPerTask: 0,
          totalDuration: 0,
          completionRate: 0,
        ));

        provider.clearSelectedProperty();

        expect(provider.selectedPropertyId, isNull);
      });
    });

    group('Schedule Management', () {
      final testSchedule = MaintenanceSchedule(
        id: 'schedule-1',
        propertyId: 'property-1',
        title: 'HVAC Maintenance',
        description: 'Check and replace filters',
        frequency: MaintenanceFrequency.monthly,
        priority: MaintenancePriority.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        nextDue: DateTime.now().add(const Duration(days: 30)),
      );

      test('loadSchedules updates schedules list', () async {
        when(mockService.getSchedules())
            .thenAnswer((_) async => [testSchedule]);

        await provider.loadSchedules();

        expect(provider.schedules, contains(testSchedule));
        expect(provider.isLoadingSchedules, isFalse);
        expect(provider.schedulesErrorMessage, isNull);
      });

      test('loadSchedules handles errors', () async {
        const errorMessage = 'Failed to load schedules';
        when(mockService.getSchedules())
            .thenThrow(MaintenanceException(errorMessage));

        await provider.loadSchedules();

        expect(provider.schedules, isEmpty);
        expect(provider.schedulesErrorMessage, contains(errorMessage));
        expect(provider.isLoadingSchedules, isFalse);
      });

      test('createSchedule adds schedule to list', () async {
        final request = CreateMaintenanceScheduleRequest(
          propertyId: 'property-1',
          title: 'New Schedule',
          description: 'Description',
          frequency: MaintenanceFrequency.monthly,
          priority: MaintenancePriority.medium,
          nextDue: DateTime.now().add(const Duration(days: 30)),
        );

        when(mockService.createSchedule(request))
            .thenAnswer((_) async => testSchedule);

        final result = await provider.createSchedule(request);

        expect(result, equals(testSchedule));
        expect(provider.schedules, contains(testSchedule));
      });

      test('updateSchedule updates schedule in list', () async {
        provider.schedules.add(testSchedule);

        final request = CreateMaintenanceScheduleRequest(
          propertyId: testSchedule.propertyId,
          title: 'Updated Title',
          description: testSchedule.description,
          frequency: testSchedule.frequency,
          priority: testSchedule.priority,
          nextDue: testSchedule.nextDue,
        );

        final updatedSchedule = testSchedule.copyWith(title: 'Updated Title');
        when(mockService.updateSchedule(testSchedule.id, request))
            .thenAnswer((_) async => updatedSchedule);

        await provider.updateSchedule(testSchedule.id, request);

        expect(provider.schedules.first.title, equals('Updated Title'));
      });

      test('deleteSchedule removes schedule from list', () async {
        provider.schedules.add(testSchedule);

        when(mockService.deleteSchedule(testSchedule.id))
            .thenAnswer((_) async {});

        await provider.deleteSchedule(testSchedule.id);

        expect(provider.schedules, isEmpty);
      });

      test('toggleSchedule updates schedule status', () async {
        provider.schedules.add(testSchedule);

        final toggledSchedule = testSchedule.copyWith(isActive: false);
        when(mockService.toggleSchedule(testSchedule.id))
            .thenAnswer((_) async => toggledSchedule);

        await provider.toggleSchedule(testSchedule.id);

        expect(provider.schedules.first.isActive, isFalse);
      });

      test('getScheduleById returns correct schedule', () async {
        provider.schedules.add(testSchedule);

        final result = provider.getScheduleById(testSchedule.id);

        expect(result, equals(testSchedule));
      });

      test('getScheduleById returns null for non-existent id', () {
        final result = provider.getScheduleById('non-existent');

        expect(result, isNull);
      });
    });

    group('Task Management', () {
      final testTask = MaintenanceTask(
        id: 'task-1',
        scheduleId: 'schedule-1',
        propertyId: 'property-1',
        title: 'HVAC Check',
        description: 'Monthly HVAC maintenance',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        status: MaintenanceStatus.active,
        priority: MaintenancePriority.medium,
        createdAt: DateTime.now(),
      );

      test('loadTasks updates tasks list', () async {
        when(mockService.getTasks())
            .thenAnswer((_) async => [testTask]);

        await provider.loadTasks();

        expect(provider.tasks, contains(testTask));
        expect(provider.isLoadingTasks, isFalse);
        expect(provider.tasksErrorMessage, isNull);
      });

      test('loadTasks handles errors', () async {
        const errorMessage = 'Failed to load tasks';
        when(mockService.getTasks())
            .thenThrow(MaintenanceException(errorMessage));

        await provider.loadTasks();

        expect(provider.tasks, isEmpty);
        expect(provider.tasksErrorMessage, contains(errorMessage));
        expect(provider.isLoadingTasks, isFalse);
      });

      test('completeTask updates task in list', () async {
        provider.tasks.add(testTask);

        final request = CompleteMaintenanceTaskRequest(
          taskId: testTask.id,
          notes: 'Task completed successfully',
        );

        final completedTask = testTask.copyWith(
          status: MaintenanceStatus.completed,
          completedAt: DateTime.now(),
          notes: 'Task completed successfully',
        );

        when(mockService.completeTask(request))
            .thenAnswer((_) async => completedTask);

        await provider.completeTask(request);

        expect(provider.tasks.first.status, equals(MaintenanceStatus.completed));
        expect(provider.tasks.first.notes, equals('Task completed successfully'));
      });

      test('skipTask updates task in list', () async {
        provider.tasks.add(testTask);

        final skippedTask = testTask.copyWith(status: MaintenanceStatus.skipped);
        when(mockService.skipTask(testTask.id, reason: 'Not needed'))
            .thenAnswer((_) async => skippedTask);

        await provider.skipTask(testTask.id, reason: 'Not needed');

        expect(provider.tasks.first.status, equals(MaintenanceStatus.skipped));
      });

      test('loadOverdueTasks loads only overdue tasks', () async {
        when(mockService.getOverdueTasks())
            .thenAnswer((_) async => [testTask]);

        await provider.loadOverdueTasks();

        verify(mockService.getOverdueTasks()).called(1);
        expect(provider.tasks, contains(testTask));
      });

      test('loadTodaysTasks loads tasks for today', () async {
        when(mockService.getTodaysTasks())
            .thenAnswer((_) async => [testTask]);

        await provider.loadTodaysTasks();

        verify(mockService.getTodaysTasks()).called(1);
        expect(provider.tasks, contains(testTask));
      });

      test('getTaskById returns correct task', () {
        provider.tasks.add(testTask);

        final result = provider.getTaskById(testTask.id);

        expect(result, equals(testTask));
      });
    });

    group('Statistics Management', () {
      test('loadStats updates stats', () async {
        const testStats = MaintenanceStats(
          totalSchedules: 5,
          activeSchedules: 4,
          totalTasks: 20,
          completedTasks: 15,
          overdueTasks: 2,
          dueSoonTasks: 3,
          totalCost: 1500.0,
          averageCostPerTask: 75.0,
          totalDuration: 600,
          completionRate: 0.75,
        );

        when(mockService.getStats()).thenAnswer((_) async => testStats);

        await provider.loadStats();

        expect(provider.stats, equals(testStats));
        expect(provider.isLoadingStats, isFalse);
        expect(provider.statsErrorMessage, isNull);
      });

      test('loadStats handles errors', () async {
        const errorMessage = 'Failed to load stats';
        when(mockService.getStats())
            .thenThrow(MaintenanceException(errorMessage));

        await provider.loadStats();

        expect(provider.stats, isNull);
        expect(provider.statsErrorMessage, contains(errorMessage));
        expect(provider.isLoadingStats, isFalse);
      });
    });

    group('Search and Filtering', () {
      final schedule1 = MaintenanceSchedule(
        id: 'schedule-1',
        propertyId: 'property-1',
        title: 'HVAC Maintenance',
        description: 'Check and replace filters',
        frequency: MaintenanceFrequency.monthly,
        priority: MaintenancePriority.high,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        nextDue: DateTime.now().add(const Duration(days: 30)),
        tags: ['hvac', 'filters'],
      );

      final schedule2 = MaintenanceSchedule(
        id: 'schedule-2',
        propertyId: 'property-2',
        title: 'Lawn Care',
        description: 'Weekly mowing and trimming',
        frequency: MaintenanceFrequency.weekly,
        priority: MaintenancePriority.low,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        nextDue: DateTime.now().add(const Duration(days: 7)),
        tags: ['lawn', 'outdoor'],
      );

      setUp(() {
        provider.schedules.addAll([schedule1, schedule2]);
      });

      test('searchSchedules returns matching schedules by title', () {
        final results = provider.searchSchedules('HVAC');

        expect(results, contains(schedule1));
        expect(results, isNot(contains(schedule2)));
      });

      test('searchSchedules returns matching schedules by description', () {
        final results = provider.searchSchedules('mowing');

        expect(results, contains(schedule2));
        expect(results, isNot(contains(schedule1)));
      });

      test('searchSchedules returns matching schedules by tag', () {
        final results = provider.searchSchedules('filters');

        expect(results, contains(schedule1));
        expect(results, isNot(contains(schedule2)));
      });

      test('searchSchedules is case insensitive', () {
        final results = provider.searchSchedules('hvac');

        expect(results, contains(schedule1));
      });

      test('searchSchedules returns all schedules for empty query', () {
        final results = provider.searchSchedules('');

        expect(results, containsAll([schedule1, schedule2]));
      });

      test('filterSchedulesByProperty returns schedules for property', () {
        final results = provider.filterSchedulesByProperty('property-1');

        expect(results, contains(schedule1));
        expect(results, isNot(contains(schedule2)));
      });

      test('filterSchedulesByPriority returns schedules with priority', () {
        final results = provider.filterSchedulesByPriority(MaintenancePriority.high);

        expect(results, contains(schedule1));
        expect(results, isNot(contains(schedule2)));
      });
    });

    group('Computed Getters', () {
      final now = DateTime.now();
      
      final activeSchedule = MaintenanceSchedule(
        id: 'active-schedule',
        propertyId: 'property-1',
        title: 'Active Schedule',
        description: 'Description',
        frequency: MaintenanceFrequency.monthly,
        priority: MaintenancePriority.medium,
        createdAt: now,
        updatedAt: now,
        nextDue: now.add(const Duration(days: 30)),
        isActive: true,
      );

      final inactiveSchedule = MaintenanceSchedule(
        id: 'inactive-schedule',
        propertyId: 'property-1',
        title: 'Inactive Schedule',
        description: 'Description',
        frequency: MaintenanceFrequency.monthly,
        priority: MaintenancePriority.medium,
        createdAt: now,
        updatedAt: now,
        nextDue: now.add(const Duration(days: 30)),
        isActive: false,
      );

      final overdueSchedule = MaintenanceSchedule(
        id: 'overdue-schedule',
        propertyId: 'property-1',
        title: 'Overdue Schedule',
        description: 'Description',
        frequency: MaintenanceFrequency.monthly,
        priority: MaintenancePriority.medium,
        createdAt: now,
        updatedAt: now,
        nextDue: now.subtract(const Duration(days: 1)),
        isActive: true,
      );

      final activeTask = MaintenanceTask(
        id: 'active-task',
        scheduleId: 'schedule-1',
        propertyId: 'property-1',
        title: 'Active Task',
        description: 'Description',
        dueDate: now.add(const Duration(days: 1)),
        status: MaintenanceStatus.active,
        priority: MaintenancePriority.medium,
        createdAt: now,
      );

      final completedTask = MaintenanceTask(
        id: 'completed-task',
        scheduleId: 'schedule-1',
        propertyId: 'property-1',
        title: 'Completed Task',
        description: 'Description',
        dueDate: now,
        status: MaintenanceStatus.completed,
        priority: MaintenancePriority.medium,
        createdAt: now,
        completedAt: now,
      );

      final overdueTask = MaintenanceTask(
        id: 'overdue-task',
        scheduleId: 'schedule-1',
        propertyId: 'property-1',
        title: 'Overdue Task',
        description: 'Description',
        dueDate: now.subtract(const Duration(days: 1)),
        status: MaintenanceStatus.active,
        priority: MaintenancePriority.medium,
        createdAt: now,
      );

      setUp(() {
        provider.schedules.addAll([activeSchedule, inactiveSchedule, overdueSchedule]);
        provider.tasks.addAll([activeTask, completedTask, overdueTask]);
      });

      test('activeSchedules returns only active schedules', () {
        expect(provider.activeSchedules, contains(activeSchedule));
        expect(provider.activeSchedules, isNot(contains(inactiveSchedule)));
      });

      test('overdueSchedules returns overdue schedules', () {
        expect(provider.overdueSchedules, contains(overdueSchedule));
        expect(provider.overdueSchedules, isNot(contains(activeSchedule)));
      });

      test('activeTasks returns only active tasks', () {
        expect(provider.activeTasks, contains(activeTask));
        expect(provider.activeTasks, isNot(contains(completedTask)));
      });

      test('completedTasks returns only completed tasks', () {
        expect(provider.completedTasks, contains(completedTask));
        expect(provider.completedTasks, isNot(contains(activeTask)));
      });

      test('overdueTasks returns overdue tasks', () {
        expect(provider.overdueTasks, contains(overdueTask));
        expect(provider.overdueTasks, isNot(contains(activeTask)));
      });
    });

    group('Error Handling', () {
      test('clearAllErrors clears all error messages', () {
        provider.schedulesErrorMessage = 'Schedule error';
        provider.tasksErrorMessage = 'Task error';
        provider.statsErrorMessage = 'Stats error';

        provider.clearAllErrors();

        expect(provider.schedulesErrorMessage, isNull);
        expect(provider.tasksErrorMessage, isNull);
        expect(provider.statsErrorMessage, isNull);
      });
    });

    group('Reset', () {
      test('reset clears all data and state', () {
        // Add some data
        provider.schedules.add(MaintenanceSchedule(
          id: 'schedule-1',
          propertyId: 'property-1',
          title: 'Test Schedule',
          description: 'Description',
          frequency: MaintenanceFrequency.monthly,
          priority: MaintenancePriority.medium,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          nextDue: DateTime.now(),
        ));

        provider.setSelectedProperty('property-1');

        provider.reset();

        expect(provider.schedules, isEmpty);
        expect(provider.tasks, isEmpty);
        expect(provider.stats, isNull);
        expect(provider.selectedPropertyId, isNull);
        expect(provider.errorMessage, isNull);
        expect(provider.schedulesErrorMessage, isNull);
        expect(provider.tasksErrorMessage, isNull);
        expect(provider.statsErrorMessage, isNull);
      });
    });
  });
}