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
  group('AddProjectScreen Basic Tests', () {
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
      ];

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

    testWidgets('displays correct title and main sections', (WidgetTester tester) async {
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

    testWidgets('displays form fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Basic fields
      expect(find.text('Project Title *'), findsOneWidget);
      expect(find.text('Description'), findsAtLeastNWidgets(1));
      expect(find.text('Select Property *'), findsOneWidget);
      expect(find.text('Priority'), findsAtLeastNWidgets(1));
      expect(find.text('Start Date'), findsOneWidget);
      expect(find.text('Due Date'), findsOneWidget);
      expect(find.text('Estimated Budget'), findsOneWidget);
      expect(find.text('Task 1'), findsOneWidget);
    });

    testWidgets('can add tasks', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially has 1 task
      expect(find.text('Tasks (1)'), findsOneWidget);

      // Add another task
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      // Should now have 2 tasks
      expect(find.text('Tasks (2)'), findsOneWidget);
    });
  });
}