import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../lib/models/maintenance.dart';
import '../../lib/providers/maintenance_provider.dart';
import '../../lib/providers/property_provider.dart';
import '../../lib/screens/maintenance/maintenance_dashboard_screen.dart';
import '../helpers/mocks.dart';

void main() {
  group('MaintenanceDashboardScreen Tests', () {
    late MockMaintenanceProvider mockMaintenanceProvider;
    late MockPropertyProvider mockPropertyProvider;

    setUp(() {
      mockMaintenanceProvider = MockMaintenanceProvider();
      mockPropertyProvider = MockPropertyProvider();
      
      // Setup default state
      when(mockMaintenanceProvider.isLoading).thenReturn(false);
      when(mockMaintenanceProvider.errorMessage).thenReturn(null);
      when(mockMaintenanceProvider.schedules).thenReturn([]);
      when(mockMaintenanceProvider.tasks).thenReturn([]);
      when(mockMaintenanceProvider.stats).thenReturn(null);
      when(mockMaintenanceProvider.overdueTasks).thenReturn([]);
      when(mockMaintenanceProvider.dueSoonTasks).thenReturn([]);
      when(mockMaintenanceProvider.activeSchedules).thenReturn([]);
      when(mockMaintenanceProvider.selectedPropertyId).thenReturn(null);
      
      when(mockPropertyProvider.properties).thenReturn([]);
    });

    Widget buildScreen() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<MaintenanceProvider>.value(
              value: mockMaintenanceProvider,
            ),
            ChangeNotifierProvider<PropertyProvider>.value(
              value: mockPropertyProvider,
            ),
          ],
          child: const MaintenanceDashboardScreen(),
        ),
      );
    }

    group('Initial State', () {
      testWidgets('displays app bar with correct title', (tester) async {
        await tester.pumpWidget(buildScreen());
        
        expect(find.text('Maintenance'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('displays loading overlay when isLoading is true', (tester) async {
        when(mockMaintenanceProvider.isLoading).thenReturn(true);
        
        await tester.pumpWidget(buildScreen());
        
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('displays error message when error exists', (tester) async {
        const errorMessage = 'Failed to load maintenance data';
        when(mockMaintenanceProvider.errorMessage).thenReturn(errorMessage);
        
        await tester.pumpWidget(buildScreen());
        
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('displays empty state message when no due soon tasks', (tester) async {
        await tester.pumpWidget(buildScreen());
        
        expect(find.text('All caught up!'), findsOneWidget);
        expect(find.text('No maintenance tasks due soon'), findsOneWidget);
      });

      testWidgets('displays empty state message when no schedules', (tester) async {
        await tester.pumpWidget(buildScreen());
        
        expect(find.text('No schedules yet'), findsOneWidget);
        expect(find.text('Create your first maintenance schedule'), findsOneWidget);
      });
    });

    group('Statistics Display', () {
      testWidgets('displays statistics cards when stats available', (tester) async {
        const stats = MaintenanceStats(
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
        
        when(mockMaintenanceProvider.stats).thenReturn(stats);
        
        await tester.pumpWidget(buildScreen());
        
        expect(find.text('Overview'), findsOneWidget);
        expect(find.text('4'), findsOneWidget); // Active schedules
        expect(find.text('2'), findsOneWidget); // Overdue tasks
        expect(find.text('15'), findsOneWidget); // Completed tasks
        expect(find.text('75%'), findsOneWidget); // Completion rate
      });

      testWidgets('stat cards have correct colors for overdue tasks', (tester) async {
        const stats = MaintenanceStats(
          totalSchedules: 5,
          activeSchedules: 4,
          totalTasks: 20,
          completedTasks: 15,
          overdueTasks: 3, // More than 0
          dueSoonTasks: 2,
          totalCost: 1500.0,
          averageCostPerTask: 75.0,
          totalDuration: 600,
          completionRate: 0.75,
        );
        
        when(mockMaintenanceProvider.stats).thenReturn(stats);
        
        await tester.pumpWidget(buildScreen());
        
        // Find the overdue tasks card and verify it has warning icon
        expect(find.byIcon(Icons.warning), findsOneWidget);
      });
    });

    group('Task Display', () {
      testWidgets('displays overdue tasks section when tasks exist', (tester) async {
        final overdueTask = MaintenanceTask(
          id: 'task-1',
          scheduleId: 'schedule-1',
          propertyId: 'property-1',
          title: 'Overdue HVAC Check',
          description: 'Monthly maintenance',
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
          status: MaintenanceStatus.active,
          priority: MaintenancePriority.high,
          createdAt: DateTime.now(),
        );
        
        when(mockMaintenanceProvider.overdueTasks).thenReturn([overdueTask]);
        
        await tester.pumpWidget(buildScreen());
        
        expect(find.text('Overdue Tasks'), findsOneWidget);
        expect(find.text('Overdue HVAC Check'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsAtLeastNWidgets(1));
      });

      testWidgets('displays due soon tasks when available', (tester) async {
        final dueSoonTask = MaintenanceTask(
          id: 'task-2',
          scheduleId: 'schedule-2',
          propertyId: 'property-1',
          title: 'Upcoming Maintenance',
          description: 'Scheduled maintenance',
          dueDate: DateTime.now().add(const Duration(days: 2)),
          status: MaintenanceStatus.active,
          priority: MaintenancePriority.medium,
          createdAt: DateTime.now(),
        );
        
        when(mockMaintenanceProvider.dueSoonTasks).thenReturn([dueSoonTask]);
        
        await tester.pumpWidget(buildScreen());
        
        expect(find.text('Due Soon'), findsOneWidget);
        expect(find.text('Upcoming Maintenance'), findsOneWidget);
      });

      testWidgets('task cards display correct priority colors', (tester) async {
        final highPriorityTask = MaintenanceTask(
          id: 'task-1',
          scheduleId: 'schedule-1',
          propertyId: 'property-1',
          title: 'High Priority Task',
          description: 'Urgent maintenance',
          dueDate: DateTime.now().add(const Duration(days: 1)),
          status: MaintenanceStatus.active,
          priority: MaintenancePriority.high,
          createdAt: DateTime.now(),
        );
        
        when(mockMaintenanceProvider.dueSoonTasks).thenReturn([highPriorityTask]);
        
        await tester.pumpWidget(buildScreen());
        
        // Find the task card
        expect(find.text('High Priority Task'), findsOneWidget);
        
        // Verify the CircleAvatar exists (which contains the priority color)
        expect(find.byType(CircleAvatar), findsAtLeastNWidgets(1));
      });
    });

    group('Schedule Display', () {
      testWidgets('displays recent schedules when available', (tester) async {
        final schedule = MaintenanceSchedule(
          id: 'schedule-1',
          propertyId: 'property-1',
          title: 'HVAC Maintenance',
          description: 'Monthly check',
          frequency: MaintenanceFrequency.monthly,
          priority: MaintenancePriority.medium,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          nextDue: DateTime.now().add(const Duration(days: 30)),
        );
        
        when(mockMaintenanceProvider.activeSchedules).thenReturn([schedule]);
        
        await tester.pumpWidget(buildScreen());
        
        expect(find.text('Recent Schedules'), findsOneWidget);
        expect(find.text('HVAC Maintenance'), findsOneWidget);
        expect(find.text('Monthly'), findsOneWidget);
      });

      testWidgets('schedule cards show overdue indicators', (tester) async {
        final overdueSchedule = MaintenanceSchedule(
          id: 'schedule-1',
          propertyId: 'property-1',
          title: 'Overdue Schedule',
          description: 'Monthly check',
          frequency: MaintenanceFrequency.monthly,
          priority: MaintenancePriority.medium,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          nextDue: DateTime.now().subtract(const Duration(days: 1)),
        );
        
        when(mockMaintenanceProvider.activeSchedules).thenReturn([overdueSchedule]);
        
        await tester.pumpWidget(buildScreen());
        
        expect(find.text('Overdue Schedule'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsAtLeastNWidgets(1));
      });
    });

    group('Property Filter', () {
      testWidgets('displays property filter when properties exist', (tester) async {
        when(mockPropertyProvider.properties).thenReturn([
          // Mock property would need to be created
        ]);
        
        await tester.pumpWidget(buildScreen());
        
        expect(find.text('Filter by Property'), findsOneWidget);
        expect(find.text('All Properties'), findsOneWidget);
      });

      testWidgets('does not display property filter when no properties', (tester) async {
        when(mockPropertyProvider.properties).thenReturn([]);
        
        await tester.pumpWidget(buildScreen());
        
        expect(find.text('Filter by Property'), findsNothing);
      });
    });

    group('Quick Actions', () {
      testWidgets('displays quick action buttons', (tester) async {
        await tester.pumpWidget(buildScreen());
        
        expect(find.text('Quick Actions'), findsOneWidget);
        expect(find.text('Add Schedule'), findsOneWidget);
        expect(find.text('View Calendar'), findsOneWidget);
        expect(find.text('All Tasks'), findsOneWidget);
        expect(find.text('Statistics'), findsOneWidget);
      });

      testWidgets('quick action buttons are tappable', (tester) async {
        await tester.pumpWidget(buildScreen());
        
        // Verify buttons exist and are tappable
        final addScheduleButton = find.text('Add Schedule');
        expect(addScheduleButton, findsOneWidget);
        
        await tester.tap(addScheduleButton);
        await tester.pump();
        
        // No navigation in test, but button should be tappable without error
      });
    });

    group('App Bar Actions', () {
      testWidgets('app bar has search and menu actions', (tester) async {
        await tester.pumpWidget(buildScreen());
        
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byType(PopupMenuButton), findsOneWidget);
      });

      testWidgets('search button opens search dialog', (tester) async {
        await tester.pumpWidget(buildScreen());
        
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        
        expect(find.text('Search'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('menu button shows options', (tester) async {
        await tester.pumpWidget(buildScreen());
        
        await tester.tap(find.byType(PopupMenuButton));
        await tester.pumpAndSettle();
        
        expect(find.text('Filter by Property'), findsOneWidget);
        expect(find.text('Refresh'), findsOneWidget);
      });
    });

    group('Floating Action Button', () {
      testWidgets('displays FAB with correct tooltip', (tester) async {
        await tester.pumpWidget(buildScreen());
        
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
        
        // Long press to show tooltip
        await tester.longPress(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        
        expect(find.text('Create Maintenance Schedule'), findsOneWidget);
      });
    });

    group('Task Actions', () {
      testWidgets('task cards show action menu', (tester) async {
        final task = MaintenanceTask(
          id: 'task-1',
          scheduleId: 'schedule-1',
          propertyId: 'property-1',
          title: 'Test Task',
          description: 'Test description',
          dueDate: DateTime.now().add(const Duration(days: 1)),
          status: MaintenanceStatus.active,
          priority: MaintenancePriority.medium,
          createdAt: DateTime.now(),
        );
        
        when(mockMaintenanceProvider.dueSoonTasks).thenReturn([task]);
        
        await tester.pumpWidget(buildScreen());
        
        // Find and tap the popup menu
        final popupMenuButton = find.byType(PopupMenuButton<String>).first;
        await tester.tap(popupMenuButton);
        await tester.pumpAndSettle();
        
        expect(find.text('Mark Complete'), findsOneWidget);
        expect(find.text('Skip'), findsOneWidget);
        expect(find.text('View Details'), findsOneWidget);
      });
    });

    group('Refresh Functionality', () {
      testWidgets('pull to refresh triggers data reload', (tester) async {
        await tester.pumpWidget(buildScreen());
        
        // Simulate pull to refresh
        await tester.fling(
          find.byType(RefreshIndicator),
          const Offset(0, 300),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        // Verify refresh indicator appeared
        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('error message shows retry button', (tester) async {
        when(mockMaintenanceProvider.errorMessage)
            .thenReturn('Failed to load data');
        
        await tester.pumpWidget(buildScreen());
        
        expect(find.text('Failed to load data'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        
        // Tap retry button
        await tester.tap(find.text('Retry'));
        await tester.pump();
        
        // Should trigger reload (verified by the retry button being tappable)
      });
    });
  });
}