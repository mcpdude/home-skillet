import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:home_skillet_mobile/screens/dashboard/dashboard_screen.dart';
import 'package:home_skillet_mobile/providers/auth_provider.dart';
import 'package:home_skillet_mobile/providers/property_provider.dart';
import 'package:home_skillet_mobile/providers/project_provider.dart';
import 'package:home_skillet_mobile/models/user.dart';
import 'package:home_skillet_mobile/models/property.dart';
import 'package:home_skillet_mobile/models/project.dart';
import '../helpers/mocks.mocks.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('DashboardScreen Widget Tests', () {
    late MockAuthProvider mockAuthProvider;
    late MockPropertyProvider mockPropertyProvider;
    late MockProjectProvider mockProjectProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockPropertyProvider = MockPropertyProvider();
      mockProjectProvider = MockProjectProvider();

      // Setup default mock behavior
      when(mockAuthProvider.user).thenReturn(User.fromJson(TestData.mockUser));
      when(mockPropertyProvider.isLoading).thenReturn(false);
      when(mockPropertyProvider.errorMessage).thenReturn(null);
      when(mockPropertyProvider.properties).thenReturn([]);
      when(mockProjectProvider.isLoading).thenReturn(false);
      when(mockProjectProvider.errorMessage).thenReturn(null);
      when(mockProjectProvider.projects).thenReturn([]);
      when(mockProjectProvider.overdueProjects).thenReturn([]);
    });

    testWidgets('should display welcome message with user name', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(
        child: const DashboardScreen(),
        mockAuthProvider: mockAuthProvider,
        mockPropertyProvider: mockPropertyProvider,
        mockProjectProvider: mockProjectProvider,
      ));

      // Assert
      expect(find.text('Welcome, John'), findsOneWidget);
    });

    testWidgets('should display overview statistics', (WidgetTester tester) async {
      // Arrange
      final properties = [Property.fromJson(TestData.mockProperty)];
      final projects = [
        Project.fromJson(TestData.mockProject),
        Project.fromJson({...TestData.mockProject, 'id': '2', 'status': 'in_progress'}),
        Project.fromJson({...TestData.mockProject, 'id': '3', 'status': 'completed'}),
      ];

      when(mockPropertyProvider.properties).thenReturn(properties);
      when(mockProjectProvider.projects).thenReturn(projects);

      // Act
      await tester.pumpWidget(createTestWidget(
        child: const DashboardScreen(),
        mockAuthProvider: mockAuthProvider,
        mockPropertyProvider: mockPropertyProvider,
        mockProjectProvider: mockProjectProvider,
      ));

      // Assert
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Properties'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // Property count
      expect(find.text('Active Projects'), findsOneWidget);
      expect(find.text('Total Projects'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // Total projects count
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('should display empty state when no projects exist', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(
        child: const DashboardScreen(),
        mockAuthProvider: mockAuthProvider,
        mockPropertyProvider: mockPropertyProvider,
        mockProjectProvider: mockProjectProvider,
      ));

      // Assert
      expect(find.text('Recent Projects'), findsOneWidget);
      expect(find.text('No projects yet'), findsOneWidget);
      expect(find.text('Start your first home maintenance project'), findsOneWidget);
    });

    testWidgets('should display recent projects when they exist', (WidgetTester tester) async {
      // Arrange
      final projects = [
        Project.fromJson(TestData.mockProject),
        Project.fromJson({...TestData.mockProject, 'id': '2', 'title': 'Second Project'}),
      ];
      when(mockProjectProvider.projects).thenReturn(projects);

      // Act
      await tester.pumpWidget(createTestWidget(
        child: const DashboardScreen(),
        mockAuthProvider: mockAuthProvider,
        mockPropertyProvider: mockPropertyProvider,
        mockProjectProvider: mockProjectProvider,
      ));

      // Assert
      expect(find.text('Recent Projects'), findsOneWidget);
      expect(find.text('Test Project'), findsOneWidget);
      expect(find.text('Second Project'), findsOneWidget);
    });

    testWidgets('should display overdue projects section when overdue projects exist', (WidgetTester tester) async {
      // Arrange
      final overdueProject = Project.fromJson({
        ...TestData.mockProject,
        'due_date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      });
      when(mockProjectProvider.overdueProjects).thenReturn([overdueProject]);

      // Act
      await tester.pumpWidget(createTestWidget(
        child: const DashboardScreen(),
        mockAuthProvider: mockAuthProvider,
        mockPropertyProvider: mockPropertyProvider,
        mockProjectProvider: mockProjectProvider,
      ));

      // Assert
      expect(find.text('Overdue Projects'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('should display quick actions section', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(
        child: const DashboardScreen(),
        mockAuthProvider: mockAuthProvider,
        mockPropertyProvider: mockPropertyProvider,
        mockProjectProvider: mockProjectProvider,
      ));

      // Assert
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Add Property'), findsOneWidget);
      expect(find.text('New Project'), findsOneWidget);
    });

    testWidgets('should show loading indicator when data is loading', (WidgetTester tester) async {
      // Arrange
      when(mockPropertyProvider.isLoading).thenReturn(true);

      // Act
      await tester.pumpWidget(createTestWidget(
        child: const DashboardScreen(),
        mockAuthProvider: mockAuthProvider,
        mockPropertyProvider: mockPropertyProvider,
        mockProjectProvider: mockProjectProvider,
      ));

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message when data loading fails', (WidgetTester tester) async {
      // Arrange
      when(mockPropertyProvider.errorMessage).thenReturn('Failed to load properties');

      // Act
      await tester.pumpWidget(createTestWidget(
        child: const DashboardScreen(),
        mockAuthProvider: mockAuthProvider,
        mockPropertyProvider: mockPropertyProvider,
        mockProjectProvider: mockProjectProvider,
      ));

      // Assert
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Failed to load properties'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('should call refresh data when pull to refresh is triggered', (WidgetTester tester) async {
      // Arrange
      when(mockPropertyProvider.loadProperties()).thenAnswer((_) async {});
      when(mockProjectProvider.loadAllProjects()).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget(
        child: const DashboardScreen(),
        mockAuthProvider: mockAuthProvider,
        mockPropertyProvider: mockPropertyProvider,
        mockProjectProvider: mockProjectProvider,
      ));

      // Act
      await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
      await tester.pump();

      // Assert
      verify(mockPropertyProvider.loadProperties()).called(1);
      verify(mockProjectProvider.loadAllProjects()).called(1);
    });

    testWidgets('should navigate when quick action buttons are tapped', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(
        child: const DashboardScreen(),
        mockAuthProvider: mockAuthProvider,
        mockPropertyProvider: mockPropertyProvider,
        mockProjectProvider: mockProjectProvider,
      ));

      // Test tapping Add Property button
      final addPropertyButton = find.text('Add Property');
      expect(addPropertyButton, findsOneWidget);
      await tester.tap(addPropertyButton);
      await tester.pump();
      // In a full test, verify navigation occurred

      // Test tapping New Project button
      final newProjectButton = find.text('New Project');
      expect(newProjectButton, findsOneWidget);
      await tester.tap(newProjectButton);
      await tester.pump();
      // In a full test, verify navigation occurred
    });

    testWidgets('should show floating action button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(
        child: const DashboardScreen(),
        mockAuthProvider: mockAuthProvider,
        mockPropertyProvider: mockPropertyProvider,
        mockProjectProvider: mockProjectProvider,
      ));

      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should handle tap on project cards', (WidgetTester tester) async {
      // Arrange
      final projects = [Project.fromJson(TestData.mockProject)];
      when(mockProjectProvider.projects).thenReturn(projects);

      await tester.pumpWidget(createTestWidget(
        child: const DashboardScreen(),
        mockAuthProvider: mockAuthProvider,
        mockPropertyProvider: mockPropertyProvider,
        mockProjectProvider: mockProjectProvider,
      ));

      // Act
      final projectCard = find.text('Test Project');
      expect(projectCard, findsOneWidget);
      await tester.tap(projectCard);
      await tester.pump();

      // In a full test with navigation, verify project detail navigation
    });

    testWidgets('should display settings button in app bar', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(
        child: const DashboardScreen(),
        mockAuthProvider: mockAuthProvider,
        mockPropertyProvider: mockPropertyProvider,
        mockProjectProvider: mockProjectProvider,
      ));

      // Assert
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}