import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:home_skillet_mobile/services/project_service.dart';
import 'package:home_skillet_mobile/services/http_client.dart';
import 'package:home_skillet_mobile/models/project.dart';
import 'package:home_skillet_mobile/models/task.dart';
import 'package:home_skillet_mobile/models/project_assignment.dart';
import 'package:home_skillet_mobile/config/api_config.dart';

import 'project_service_comprehensive_test.mocks.dart';

@GenerateMocks([HttpClient])
void main() {
  group('ProjectService Comprehensive Tests', () {
    late ProjectService projectService;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockHttpClient();
      projectService = ProjectService(httpClient: mockHttpClient);
    });

    group('Project CRUD Operations', () {
      test('getAllProjects should return list of projects on success', () async {
        // Arrange
        final responseData = [
          {
            'id': '1',
            'title': 'Test Project 1',
            'description': 'Test Description',
            'status': 'in_progress',
            'priority': 'high',
            'property_id': 'prop1',
            'user_id': 'user1',
            'created_at': '2023-01-01T00:00:00Z',
            'updated_at': '2023-01-01T00:00:00Z',
            'tasks': [],
            'assigned_user_ids': [],
            'tags': [],
            'is_template': false,
            'collaboration_enabled': true,
          },
          {
            'id': '2',
            'title': 'Test Project 2',
            'description': 'Test Description 2',
            'status': 'planned',
            'priority': 'medium',
            'property_id': 'prop2',
            'user_id': 'user1',
            'created_at': '2023-01-02T00:00:00Z',
            'updated_at': '2023-01-02T00:00:00Z',
            'tasks': [],
            'assigned_user_ids': [],
            'tags': [],
            'is_template': false,
            'collaboration_enabled': true,
          }
        ];

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get(ApiConfig.projectsEndpoint))
            .thenAnswer((_) async => response);

        // Act
        final result = await projectService.getAllProjects();

        // Assert
        expect(result, isA<List<Project>>());
        expect(result.length, 2);
        expect(result[0].id, '1');
        expect(result[0].title, 'Test Project 1');
        expect(result[0].status, ProjectStatus.inProgress);
        expect(result[1].id, '2');
        expect(result[1].title, 'Test Project 2');
        expect(result[1].status, ProjectStatus.planned);
      });

      test('getAllProjects should throw exception on API error', () async {
        // Arrange
        final response = Response(
          data: {'error': 'Server error'},
          statusCode: 500,
          statusMessage: 'Internal Server Error',
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get(ApiConfig.projectsEndpoint))
            .thenAnswer((_) async => response);

        // Act & Assert
        expect(() async => await projectService.getAllProjects(),
            throwsA(isA<Exception>()));
      });

      test('getProjectsForProperty should filter by property ID', () async {
        // Arrange
        const propertyId = 'prop1';
        final responseData = [
          {
            'id': '1',
            'title': 'Property Project',
            'description': 'Test Description',
            'status': 'in_progress',
            'priority': 'high',
            'property_id': propertyId,
            'user_id': 'user1',
            'created_at': '2023-01-01T00:00:00Z',
            'updated_at': '2023-01-01T00:00:00Z',
            'tasks': [],
            'assigned_user_ids': [],
            'tags': [],
            'is_template': false,
            'collaboration_enabled': true,
          }
        ];

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get(
          ApiConfig.projectsEndpoint,
          queryParameters: {'property_id': propertyId},
        )).thenAnswer((_) async => response);

        // Act
        final result = await projectService.getProjectsForProperty(propertyId);

        // Assert
        expect(result, isA<List<Project>>());
        expect(result.length, 1);
        expect(result[0].propertyId, propertyId);
        verify(mockHttpClient.get(
          ApiConfig.projectsEndpoint,
          queryParameters: {'property_id': propertyId},
        )).called(1);
      });

      test('getProject should return single project by ID', () async {
        // Arrange
        const projectId = '1';
        final responseData = {
          'id': projectId,
          'title': 'Test Project',
          'description': 'Test Description',
          'status': 'in_progress',
          'priority': 'high',
          'property_id': 'prop1',
          'user_id': 'user1',
          'created_at': '2023-01-01T00:00:00Z',
          'updated_at': '2023-01-01T00:00:00Z',
          'tasks': [
            {
              'id': 'task1',
              'title': 'Task 1',
              'status': 'pending',
              'priority': 'medium',
              'project_id': projectId,
              'created_at': '2023-01-01T00:00:00Z',
              'updated_at': '2023-01-01T00:00:00Z',
              'subtasks': [],
              'dependencies': [],
              'tags': [],
              'comments': [],
              'attachments': [],
              'order': 0,
            }
          ],
          'assigned_user_ids': ['user1', 'user2'],
          'tags': ['renovation', 'urgent'],
          'is_template': false,
          'collaboration_enabled': true,
        };

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get('${ApiConfig.projectsEndpoint}/$projectId'))
            .thenAnswer((_) async => response);

        // Act
        final result = await projectService.getProject(projectId);

        // Assert
        expect(result, isA<Project>());
        expect(result.id, projectId);
        expect(result.title, 'Test Project');
        expect(result.tasks.length, 1);
        expect(result.assignedUserIds.length, 2);
        expect(result.tags, contains('renovation'));
        expect(result.isCollaborative, true);
      });

      test('createProject should create new project and return created project', () async {
        // Arrange
        final newProject = Project(
          id: '',
          title: 'New Project',
          description: 'New Description',
          status: ProjectStatus.planned,
          priority: ProjectPriority.medium,
          propertyId: 'prop1',
          userId: 'user1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final createdProjectData = {
          'id': 'new-project-id',
          'title': 'New Project',
          'description': 'New Description',
          'status': 'planned',
          'priority': 'medium',
          'property_id': 'prop1',
          'user_id': 'user1',
          'created_at': '2023-01-01T00:00:00Z',
          'updated_at': '2023-01-01T00:00:00Z',
          'tasks': [],
          'assigned_user_ids': [],
          'tags': [],
          'is_template': false,
          'collaboration_enabled': true,
        };

        final response = Response(
          data: createdProjectData,
          statusCode: 201,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(
          ApiConfig.projectsEndpoint,
          data: anyNamed('data'),
        )).thenAnswer((_) async => response);

        // Act
        final result = await projectService.createProject(newProject);

        // Assert
        expect(result, isA<Project>());
        expect(result.id, 'new-project-id');
        expect(result.title, 'New Project');
        verify(mockHttpClient.post(
          ApiConfig.projectsEndpoint,
          data: anyNamed('data'),
        )).called(1);
      });

      test('updateProject should update existing project', () async {
        // Arrange
        final updatedProject = Project(
          id: '1',
          title: 'Updated Project',
          description: 'Updated Description',
          status: ProjectStatus.inProgress,
          priority: ProjectPriority.high,
          propertyId: 'prop1',
          userId: 'user1',
          createdAt: DateTime.parse('2023-01-01T00:00:00Z'),
          updatedAt: DateTime.now(),
          assignedUserIds: ['user1', 'user2'],
          tags: ['updated'],
        );

        final responseData = {
          'id': '1',
          'title': 'Updated Project',
          'description': 'Updated Description',
          'status': 'in_progress',
          'priority': 'high',
          'property_id': 'prop1',
          'user_id': 'user1',
          'created_at': '2023-01-01T00:00:00Z',
          'updated_at': '2023-01-01T01:00:00Z',
          'tasks': [],
          'assigned_user_ids': ['user1', 'user2'],
          'tags': ['updated'],
          'is_template': false,
          'collaboration_enabled': true,
        };

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.put(
          '${ApiConfig.projectsEndpoint}/1',
          data: anyNamed('data'),
        )).thenAnswer((_) async => response);

        // Act
        final result = await projectService.updateProject(updatedProject);

        // Assert
        expect(result, isA<Project>());
        expect(result.id, '1');
        expect(result.title, 'Updated Project');
        expect(result.assignedUserIds, contains('user2'));
        verify(mockHttpClient.put(
          '${ApiConfig.projectsEndpoint}/1',
          data: anyNamed('data'),
        )).called(1);
      });

      test('deleteProject should call DELETE endpoint', () async {
        // Arrange
        const projectId = '1';
        final response = Response(
          statusCode: 204,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.delete('${ApiConfig.projectsEndpoint}/$projectId'))
            .thenAnswer((_) async => response);

        // Act
        await projectService.deleteProject(projectId);

        // Assert
        verify(mockHttpClient.delete('${ApiConfig.projectsEndpoint}/$projectId'))
            .called(1);
      });
    });

    group('Task Management within Projects', () {
      test('getTasksForProject should return tasks for specific project', () async {
        // Arrange
        const projectId = '1';
        final responseData = [
          {
            'id': 'task1',
            'title': 'Task 1',
            'description': 'Task Description',
            'status': 'pending',
            'priority': 'medium',
            'project_id': projectId,
            'created_at': '2023-01-01T00:00:00Z',
            'updated_at': '2023-01-01T00:00:00Z',
            'subtasks': [],
            'dependencies': [],
            'tags': [],
            'comments': [],
            'attachments': [],
            'order': 0,
          },
          {
            'id': 'task2',
            'title': 'Task 2',
            'description': 'Task Description 2',
            'status': 'in_progress',
            'priority': 'high',
            'project_id': projectId,
            'assigned_user_id': 'user1',
            'created_at': '2023-01-01T00:00:00Z',
            'updated_at': '2023-01-01T00:00:00Z',
            'subtasks': [],
            'dependencies': [],
            'tags': [],
            'comments': [],
            'attachments': [],
            'order': 1,
          }
        ];

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get(
          ApiConfig.tasksEndpoint,
          queryParameters: {'project_id': projectId},
        )).thenAnswer((_) async => response);

        // Act
        final result = await projectService.getTasksForProject(projectId);

        // Assert
        expect(result, isA<List<Task>>());
        expect(result.length, 2);
        expect(result[0].id, 'task1');
        expect(result[0].projectId, projectId);
        expect(result[1].isAssigned, true);
        expect(result[1].order, 1);
      });

      test('createTask should create new task for project', () async {
        // Arrange
        final newTask = Task(
          id: '',
          title: 'New Task',
          description: 'New Task Description',
          status: TaskStatus.pending,
          priority: TaskPriority.medium,
          projectId: '1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final createdTaskData = {
          'id': 'new-task-id',
          'title': 'New Task',
          'description': 'New Task Description',
          'status': 'pending',
          'priority': 'medium',
          'project_id': '1',
          'created_at': '2023-01-01T00:00:00Z',
          'updated_at': '2023-01-01T00:00:00Z',
          'subtasks': [],
          'dependencies': [],
          'tags': [],
          'comments': [],
          'attachments': [],
          'order': 0,
        };

        final response = Response(
          data: createdTaskData,
          statusCode: 201,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(
          ApiConfig.tasksEndpoint,
          data: anyNamed('data'),
        )).thenAnswer((_) async => response);

        // Act
        final result = await projectService.createTask(newTask);

        // Assert
        expect(result, isA<Task>());
        expect(result.id, 'new-task-id');
        expect(result.title, 'New Task');
        expect(result.projectId, '1');
      });

      test('updateTaskStatus should update task status', () async {
        // Arrange
        const taskId = 'task1';
        const newStatus = TaskStatus.completed;

        final responseData = {
          'id': taskId,
          'title': 'Updated Task',
          'status': 'completed',
          'priority': 'medium',
          'project_id': '1',
          'completed_at': '2023-01-01T10:00:00Z',
          'created_at': '2023-01-01T00:00:00Z',
          'updated_at': '2023-01-01T10:00:00Z',
          'subtasks': [],
          'dependencies': [],
          'tags': [],
          'comments': [],
          'attachments': [],
          'order': 0,
        };

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.patch(
          '${ApiConfig.tasksEndpoint}/$taskId/status',
          data: {'status': 'completed'},
        )).thenAnswer((_) async => response);

        // Act
        final result = await projectService.updateTaskStatus(taskId, newStatus);

        // Assert
        expect(result, isA<Task>());
        expect(result.status, TaskStatus.completed);
        expect(result.isCompleted, true);
        verify(mockHttpClient.patch(
          '${ApiConfig.tasksEndpoint}/$taskId/status',
          data: {'status': 'completed'},
        )).called(1);
      });
    });

    group('Project Statistics and Analytics', () {
      test('getProjectStatistics should return project stats', () async {
        // Arrange
        const projectId = '1';
        final responseData = {
          'total_tasks': 10,
          'completed_tasks': 7,
          'in_progress_tasks': 2,
          'pending_tasks': 1,
          'overdue_tasks': 1,
          'progress_percentage': 70.0,
          'estimated_hours': 100.0,
          'actual_hours': 75.5,
          'total_cost': 5000.0,
          'assigned_users': 3,
          'activity_score': 85.5,
          'last_activity': '2023-01-01T10:00:00Z',
        };

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get('${ApiConfig.projectsEndpoint}/$projectId/stats'))
            .thenAnswer((_) async => response);

        // Act
        final result = await projectService.getProjectStatistics(projectId);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['total_tasks'], 10);
        expect(result['completed_tasks'], 7);
        expect(result['progress_percentage'], 70.0);
        expect(result['assigned_users'], 3);
      });
    });

    group('Search and Filtering', () {
      test('searchProjects should return filtered projects', () async {
        // Arrange
        const query = 'kitchen renovation';
        final responseData = [
          {
            'id': '1',
            'title': 'Kitchen Renovation Project',
            'description': 'Complete kitchen renovation',
            'status': 'in_progress',
            'priority': 'high',
            'property_id': 'prop1',
            'user_id': 'user1',
            'created_at': '2023-01-01T00:00:00Z',
            'updated_at': '2023-01-01T00:00:00Z',
            'tasks': [],
            'assigned_user_ids': [],
            'tags': ['kitchen', 'renovation'],
            'is_template': false,
            'collaboration_enabled': true,
          }
        ];

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get(
          '${ApiConfig.projectsEndpoint}/search',
          queryParameters: {'q': query},
        )).thenAnswer((_) async => response);

        // Act
        final result = await projectService.searchProjects(query);

        // Assert
        expect(result, isA<List<Project>>());
        expect(result.length, 1);
        expect(result[0].title, contains('Kitchen'));
        expect(result[0].tags, contains('renovation'));
      });
    });

    group('Error Handling', () {
      test('should throw appropriate exceptions for 404 errors', () async {
        // Arrange
        final response = Response(
          statusCode: 404,
          statusMessage: 'Not Found',
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get('${ApiConfig.projectsEndpoint}/nonexistent'))
            .thenAnswer((_) async => response);

        // Act & Assert
        expect(
          () async => await projectService.getProject('nonexistent'),
          throwsA(predicate((e) => e.toString().contains('Failed to load project'))),
        );
      });

      test('should handle network errors gracefully', () async {
        // Arrange
        when(mockHttpClient.get(ApiConfig.projectsEndpoint))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.connectionTimeout,
            ));

        // Act & Assert
        expect(
          () async => await projectService.getAllProjects(),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw validation error for invalid project data', () async {
        // Arrange
        final response = Response(
          statusCode: 400,
          statusMessage: 'Bad Request',
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(
          ApiConfig.projectsEndpoint,
          data: anyNamed('data'),
        )).thenAnswer((_) async => response);

        final invalidProject = Project(
          id: '',
          title: '', // Invalid empty title
          status: ProjectStatus.planned,
          priority: ProjectPriority.medium,
          propertyId: 'prop1',
          userId: 'user1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act & Assert
        expect(
          () async => await projectService.createProject(invalidProject),
          throwsA(predicate((e) => e.toString().contains('check your project information'))),
        );
      });
    });
  });
}