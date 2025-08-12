import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:home_skillet_mobile/screens/projects/add_project_screen.dart';
import 'package:home_skillet_mobile/models/project.dart';
import 'package:home_skillet_mobile/models/property.dart';
import 'package:home_skillet_mobile/models/task.dart';
import 'package:home_skillet_mobile/providers/project_provider.dart';
import 'package:home_skillet_mobile/providers/property_provider.dart';

// Simple mock implementations for testing
class MockProjectProvider extends ChangeNotifier implements ProjectProvider {
  bool _isLoading = false;
  String? _errorMessage;
  bool _createProjectResult = true;
  List<Project> _createProjectCalls = [];
  
  @override
  bool get isLoading => _isLoading;
  
  @override
  String? get errorMessage => _errorMessage;
  
  @override
  Future<bool> createProject(Project project) async {
    _createProjectCalls.add(project);
    return _createProjectResult;
  }
  
  void setCreateProjectResult(bool result, {String? error}) {
    _createProjectResult = result;
    _errorMessage = error;
  }
  
  List<Project> get createProjectCalls => _createProjectCalls;

  @override
  List<Project> get projects => [];
  @override
  List<Task> get tasks => [];
  @override
  Project? get selectedProject => null;
  @override
  List<Project> getProjectsByStatus(ProjectStatus status) => [];
  @override
  List<Project> get overdueProjects => [];
  @override
  List<Task> get selectedProjectTasks => [];
  @override
  Future<void> loadProjectsForProperty(String propertyId) async {}
  @override
  Future<void> loadAllProjects() async {}
  @override
  Future<bool> updateProject(Project project) async => true;
  @override
  Future<bool> deleteProject(String projectId) async => true;
  @override
  Future<void> selectProject(Project project) async {}
  @override
  Future<void> loadTasksForProject(String projectId) async {}
  @override
  Future<bool> createTask(Task task) async => true;
  @override
  Future<bool> updateTask(Task task) async => true;
  @override
  Future<bool> deleteTask(String taskId) async => true;
  @override
  Project? getProjectById(String projectId) => null;
}

class MockPropertyProvider extends ChangeNotifier implements PropertyProvider {
  List<Property> _properties = [];
  bool _loadPropertiesCalled = false;
  
  @override
  List<Property> get properties => _properties;
  
  void setProperties(List<Property> properties) {
    _properties = properties;
    notifyListeners();
  }
  
  @override
  Future<void> loadProperties() async {
    _loadPropertiesCalled = true;
  }
  
  bool get loadPropertiesCalled => _loadPropertiesCalled;

  @override
  List<Property> get allProperties => _properties;
  @override
  Property? get selectedProperty => null;
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  String get searchQuery => '';
  @override
  PropertyType? get selectedTypeFilter => null;
  @override
  bool get hasFilters => false;
  @override
  Future<bool> createProperty(Property property) async => true;
  @override
  Future<bool> updateProperty(Property property) async => true;
  @override
  Future<bool> deleteProperty(String propertyId) async => true;
  @override
  void selectProperty(Property property) {}
  @override
  Property? getPropertyById(String propertyId) => null;
  @override
  void searchProperties(String query) {}
  @override
  void filterByType(PropertyType? type) {}
  @override
  void clearFilters() {}
  @override
  List<Property> searchPropertiesLocal(String query) => [];
  @override
  List<Property> getPropertiesByType(PropertyType type) => [];
  @override
  Map<PropertyType, int> getPropertiesCountByType() => {};
}

void main() {
  group('AddProjectScreen Widget Tests', () {
    late MockProjectProvider mockProjectProvider;
    late MockPropertyProvider mockPropertyProvider;
    late List<Property> testProperties;

    setUp(() {
      mockProjectProvider = MockProjectProvider();
      mockPropertyProvider = MockPropertyProvider();
      
      testProperties = [
        Property(
          id: '1',
          name: 'Test Property 1',
          address: '123 Main St',
          type: PropertyType.house,
          ownerId: 'user1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Property(
          id: '2',
          name: 'Test Property 2',
          address: '456 Oak Ave',
          type: PropertyType.apartment,
          ownerId: 'user1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Setup default mock responses
      mockPropertyProvider.setProperties(testProperties);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ProjectProvider>.value(value: mockProjectProvider),
            ChangeNotifierProvider<PropertyProvider>.value(value: mockPropertyProvider),
          ],
          child: const AddProjectScreen(),
        ),
      );
    }

    testWidgets('displays correct title and sections', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check app bar title
      expect(find.text('Create Project'), findsOneWidget);
      
      // Check main sections
      expect(find.text('Project Information'), findsOneWidget);
      expect(find.text('Property Selection'), findsOneWidget);
      expect(find.text('Project Details'), findsOneWidget);
      expect(find.text('Tasks (1)'), findsOneWidget);

      // Check CREATE button
      expect(find.text('CREATE'), findsOneWidget);
    });

    testWidgets('displays all required form fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Basic info fields
      expect(find.widgetWithText(TextFormField, 'Project Title *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Description'), findsOneWidget);
      
      // Property selection
      expect(find.widgetWithText(DropdownButtonFormField<Property>, 'Select Property *'), findsOneWidget);
      
      // Project details
      expect(find.widgetWithText(DropdownButtonFormField<ProjectPriority>, 'Priority'), findsOneWidget);
      expect(find.text('Start Date'), findsOneWidget);
      expect(find.text('Due Date'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Estimated Budget'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Additional Notes'), findsOneWidget);

      // Task form (default first task)
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Task Title'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Description'), findsAtLeastNWidgets(1)); // Project and task description
    });

    testWidgets('loads properties on init', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify loadProperties was called
      expect(mockPropertyProvider.loadPropertiesCalled, isTrue);
    });

    testWidgets('shows properties in dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap property dropdown
      await tester.tap(find.widgetWithText(DropdownButtonFormField<Property>, 'Select Property *'));
      await tester.pumpAndSettle();

      // Check properties are shown
      expect(find.text('Test Property 1'), findsOneWidget);
      expect(find.text('123 Main St'), findsOneWidget);
      expect(find.text('Test Property 2'), findsOneWidget);
      expect(find.text('456 Oak Ave'), findsOneWidget);
    });

    testWidgets('shows warning when no properties available', (WidgetTester tester) async {
      mockPropertyProvider.setProperties([]);
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No properties found. Please add a property first.'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('can add and remove tasks', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially has 1 task
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Tasks (1)'), findsOneWidget);

      // Add another task
      await tester.tap(find.widgetWithText(TextButton, 'Add Task'));
      await tester.pumpAndSettle();

      // Should now have 2 tasks
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsOneWidget);
      expect(find.text('Tasks (2)'), findsOneWidget);

      // Remove task should be available for both tasks when there are multiple
      expect(find.byIcon(Icons.remove_circle_outline), findsNWidgets(2));

      // Remove the second task
      await tester.tap(find.byIcon(Icons.remove_circle_outline).last);
      await tester.pumpAndSettle();

      // Should be back to 1 task
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Tasks (1)'), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsNothing); // No remove button when only 1 task
    });

    testWidgets('can select dates', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially shows "Select date"
      expect(find.text('Select date'), findsNWidgets(2)); // Start and Due date

      // Tap start date
      await tester.tap(find.text('Start Date'));
      await tester.pumpAndSettle();

      // Date picker should appear
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Cancel date picker for this test
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('validates required fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Try to submit without filling required fields
      await tester.tap(find.text('CREATE'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('This field is required'), findsAtLeastNWidgets(1));
      expect(find.text('Please select a property for this project'), findsOneWidget);
    });

    testWidgets('validates budget field correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter invalid budget
      await tester.enterText(find.widgetWithText(TextFormField, 'Estimated Budget'), '-100');
      await tester.tap(find.text('CREATE'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid budget amount'), findsOneWidget);
    });

    testWidgets('validates task estimated hours correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter invalid hours
      await tester.enterText(find.widgetWithText(TextFormField, 'Est. Hours'), '-5');
      await tester.tap(find.text('CREATE'));
      await tester.pumpAndSettle();

      expect(find.text('Valid hours required'), findsOneWidget);
    });

    testWidgets('submits form successfully when valid', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Fill required fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Project Title *'), 'Test Project');
      
      // Select property
      await tester.tap(find.widgetWithText(DropdownButtonFormField<Property>, 'Select Property *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Property 1').first);
      await tester.pumpAndSettle();

      // Fill at least one task
      await tester.enterText(find.widgetWithText(TextFormField, 'Task Title'), 'Test Task');

      // Submit form
      await tester.tap(find.text('CREATE'));
      await tester.pumpAndSettle();

      // Verify createProject was called
      expect(mockProjectProvider.createProjectCalls, hasLength(1));
      expect(mockProjectProvider.createProjectCalls.first.title, equals('Test Project'));
    });

    testWidgets('shows loading state during submission', (WidgetTester tester) async {
      when(mockProjectProvider.createProject(argThat(isA<Project>()))).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      });
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Fill required fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Project Title *'), 'Test Project');
      
      // Select property
      await tester.tap(find.widgetWithText(DropdownButtonFormField<Property>, 'Select Property *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Property 1').first);
      await tester.pumpAndSettle();

      // Fill task
      await tester.enterText(find.widgetWithText(TextFormField, 'Task Title'), 'Test Task');

      // Submit form
      await tester.tap(find.text('CREATE'));
      await tester.pump(); // Don't settle immediately

      // Should show loading overlay
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when submission fails', (WidgetTester tester) async {
      when(mockProjectProvider.createProject(argThat(isA<Project>()))).thenAnswer((_) async => false);
      when(mockProjectProvider.errorMessage).thenReturn('Failed to create project');
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Fill required fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Project Title *'), 'Test Project');
      
      // Select property
      await tester.tap(find.widgetWithText(DropdownButtonFormField<Property>, 'Select Property *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Property 1').first);
      await tester.pumpAndSettle();

      // Fill task
      await tester.enterText(find.widgetWithText(TextFormField, 'Task Title'), 'Test Task');

      // Submit form
      await tester.tap(find.text('CREATE'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Failed to create project'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('prevents submission without tasks', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Fill required fields but leave task title empty
      await tester.enterText(find.widgetWithText(TextFormField, 'Project Title *'), 'Test Project');
      
      // Select property
      await tester.tap(find.widgetWithText(DropdownButtonFormField<Property>, 'Select Property *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Property 1').first);
      await tester.pumpAndSettle();

      // Submit form without filling task title
      await tester.tap(find.text('CREATE'));
      await tester.pumpAndSettle();

      // Should show error about tasks
      expect(find.text('Please add at least one task'), findsOneWidget);
      
      // Verify createProject was not called
      verifyNever(mockProjectProvider.createProject(argThat(isA<Project>())));
    });

    testWidgets('priority dropdown works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Test project priority dropdown
      await tester.tap(find.widgetWithText(DropdownButtonFormField<ProjectPriority>, 'Priority'));
      await tester.pumpAndSettle();

      expect(find.text('Urgent'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Medium'), findsNWidgets(2)); // Project and default task priority
      expect(find.text('Low'), findsOneWidget);

      // Select High priority
      await tester.tap(find.text('High').first);
      await tester.pumpAndSettle();

      // Priority should be selected (we can't easily verify the internal state in widget tests)
    });

    testWidgets('task priority dropdown works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find task priority dropdown (should be the second priority dropdown)
      final taskPriorityDropdown = find.widgetWithText(DropdownButtonFormField<TaskPriority>, 'Priority');
      
      await tester.tap(taskPriorityDropdown);
      await tester.pumpAndSettle();

      // Should show task priority options
      expect(find.text('Urgent'), findsAtLeastNWidgets(1));
      expect(find.text('High'), findsAtLeastNWidgets(1));
      expect(find.text('Medium'), findsAtLeastNWidgets(1));
      expect(find.text('Low'), findsAtLeastNWidgets(1));
    });
  });
}