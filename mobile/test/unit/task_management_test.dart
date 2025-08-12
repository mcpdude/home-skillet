import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:home_skillet_mobile/services/project_service.dart';
import 'package:home_skillet_mobile/services/http_client.dart';
import 'package:home_skillet_mobile/models/task.dart';
import 'package:home_skillet_mobile/config/api_config.dart';

import 'task_management_test.mocks.dart';

@GenerateMocks([HttpClient])
void main() {
  group('Task Management within Projects', () {
    late ProjectService projectService;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockHttpClient();
      projectService = ProjectService(httpClient: mockHttpClient);
    });

    group('Task CRUD Operations', () {
      test('createTask should create task with subtasks and dependencies', () async {
        // Arrange
        final newTask = Task(
          id: '',
          title: 'Main Task',
          description: 'Task with subtasks',
          status: TaskStatus.pending,
          priority: TaskPriority.high,
          projectId: 'project1',
          assignedUserId: 'user1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          subtasks: [
            Task(
              id: '',
              title: 'Subtask 1',
              status: TaskStatus.pending,
              priority: TaskPriority.medium,
              projectId: 'project1',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          dependencies: ['task-dep-1'],
          tags: ['important', 'urgent'],
          order: 1,
        );

        final responseData = {
          'id': 'task-123',
          'title': 'Main Task',
          'description': 'Task with subtasks',
          'status': 'pending',
          'priority': 'high',
          'project_id': 'project1',
          'assigned_user_id': 'user1',
          'created_at': '2023-01-01T00:00:00Z',
          'updated_at': '2023-01-01T00:00:00Z',
          'subtasks': [
            {
              'id': 'subtask-1',
              'title': 'Subtask 1',
              'status': 'pending',
              'priority': 'medium',
              'project_id': 'project1',
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
          'dependencies': ['task-dep-1'],
          'tags': ['important', 'urgent'],
          'comments': [],
          'attachments': [],
          'order': 1,
        };

        final response = Response(
          data: responseData,
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
        expect(result.id, 'task-123');
        expect(result.title, 'Main Task');
        expect(result.hasSubtasks, true);
        expect(result.subtasks.length, 1);
        expect(result.hasDependencies, true);
        expect(result.dependencies, contains('task-dep-1'));
        expect(result.tags, containsAll(['important', 'urgent']));
        expect(result.order, 1);
      });

      test('updateTask should handle subtask progress calculation', () async {
        // Arrange
        final taskWithSubtasks = Task(
          id: 'task-123',
          title: 'Main Task',
          status: TaskStatus.inProgress,
          priority: TaskPriority.high,
          projectId: 'project1',
          createdAt: DateTime.parse('2023-01-01T00:00:00Z'),
          updatedAt: DateTime.now(),
          subtasks: [
            Task(
              id: 'subtask-1',
              title: 'Subtask 1',
              status: TaskStatus.completed,
              priority: TaskPriority.medium,
              projectId: 'project1',
              createdAt: DateTime.parse('2023-01-01T00:00:00Z'),
              updatedAt: DateTime.now(),
            ),
            Task(
              id: 'subtask-2',
              title: 'Subtask 2',
              status: TaskStatus.pending,
              priority: TaskPriority.medium,
              projectId: 'project1',
              createdAt: DateTime.parse('2023-01-01T00:00:00Z'),
              updatedAt: DateTime.now(),
            ),
          ],
        );

        final responseData = {
          'id': 'task-123',
          'title': 'Main Task',
          'status': 'in_progress',
          'priority': 'high',
          'project_id': 'project1',
          'created_at': '2023-01-01T00:00:00Z',
          'updated_at': '2023-01-01T01:00:00Z',
          'subtasks': [
            {
              'id': 'subtask-1',
              'title': 'Subtask 1',
              'status': 'completed',
              'priority': 'medium',
              'project_id': 'project1',
              'created_at': '2023-01-01T00:00:00Z',
              'updated_at': '2023-01-01T01:00:00Z',
              'subtasks': [],
              'dependencies': [],
              'tags': [],
              'comments': [],
              'attachments': [],
              'order': 0,
            },
            {
              'id': 'subtask-2',
              'title': 'Subtask 2',
              'status': 'pending',
              'priority': 'medium',
              'project_id': 'project1',
              'created_at': '2023-01-01T00:00:00Z',
              'updated_at': '2023-01-01T00:00:00Z',
              'subtasks': [],
              'dependencies': [],
              'tags': [],
              'comments': [],
              'attachments': [],
              'order': 1,
            }
          ],
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

        when(mockHttpClient.put(
          '${ApiConfig.tasksEndpoint}/task-123',
          data: anyNamed('data'),
        )).thenAnswer((_) async => response);

        // Act
        final result = await projectService.updateTask(taskWithSubtasks);

        // Assert
        expect(result, isA<Task>());
        expect(result.subtasks.length, 2);
        expect(result.completedSubtasks, 1);
        expect(result.subtaskProgress, 50.0); // 1 out of 2 completed = 50%
      });

      test('deleteTask should handle cascading delete of subtasks', () async {
        // Arrange
        const taskId = 'task-with-subtasks';
        final response = Response(
          statusCode: 204,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.delete('${ApiConfig.tasksEndpoint}/$taskId'))
            .thenAnswer((_) async => response);

        // Act
        await projectService.deleteTask(taskId);

        // Assert
        verify(mockHttpClient.delete('${ApiConfig.tasksEndpoint}/$taskId'))
            .called(1);
      });
    });

    group('Task Ordering and Drag-and-Drop', () {
      test('should maintain task order when updating tasks', () async {
        // Arrange
        final orderedTasks = [
          Task(
            id: 'task-1',
            title: 'First Task',
            status: TaskStatus.pending,
            priority: TaskPriority.medium,
            projectId: 'project1',
            order: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Task(
            id: 'task-2', 
            title: 'Second Task',
            status: TaskStatus.pending,
            priority: TaskPriority.medium,
            projectId: 'project1',
            order: 1,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Task(
            id: 'task-3',
            title: 'Third Task',
            status: TaskStatus.pending,
            priority: TaskPriority.medium,
            projectId: 'project1',
            order: 2,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // Simulate reordering: move task-3 to position 0
        final reorderedTask = orderedTasks[2].copyWith(order: 0);

        final responseData = {
          'id': 'task-3',
          'title': 'Third Task',
          'status': 'pending',
          'priority': 'medium',
          'project_id': 'project1',
          'order': 0,
          'created_at': '2023-01-01T00:00:00Z',
          'updated_at': '2023-01-01T01:00:00Z',
          'subtasks': [],
          'dependencies': [],
          'tags': [],
          'comments': [],
          'attachments': [],
        };

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.put(
          '${ApiConfig.tasksEndpoint}/task-3',
          data: anyNamed('data'),
        )).thenAnswer((_) async => response);

        // Act
        final result = await projectService.updateTask(reorderedTask);

        // Assert
        expect(result.order, 0);
        expect(result.id, 'task-3');
      });
    });

    group('Task Dependencies', () {
      test('should handle task dependencies correctly', () async {
        // Arrange
        final taskWithDeps = Task(
          id: 'dependent-task',
          title: 'Dependent Task',
          status: TaskStatus.pending,
          priority: TaskPriority.medium,
          projectId: 'project1',
          dependencies: ['prereq-task-1', 'prereq-task-2'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final responseData = {
          'id': 'dependent-task',
          'title': 'Dependent Task',
          'status': 'pending',
          'priority': 'medium',
          'project_id': 'project1',
          'dependencies': ['prereq-task-1', 'prereq-task-2'],
          'created_at': '2023-01-01T00:00:00Z',
          'updated_at': '2023-01-01T00:00:00Z',
          'subtasks': [],
          'tags': [],
          'comments': [],
          'attachments': [],
          'order': 0,
        };

        final response = Response(
          data: responseData,
          statusCode: 201,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(
          ApiConfig.tasksEndpoint,
          data: anyNamed('data'),
        )).thenAnswer((_) async => response);

        // Act
        final result = await projectService.createTask(taskWithDeps);

        // Assert
        expect(result.hasDependencies, true);
        expect(result.dependencies.length, 2);
        expect(result.dependencies, contains('prereq-task-1'));
        expect(result.dependencies, contains('prereq-task-2'));
      });
    });

    group('Task Comments and Attachments', () {
      test('should handle tasks with comments', () async {
        // Arrange
        const taskId = 'task-with-comments';
        final responseData = {
          'id': taskId,
          'title': 'Task with Comments',
          'status': 'in_progress',
          'priority': 'medium',
          'project_id': 'project1',
          'created_at': '2023-01-01T00:00:00Z',
          'updated_at': '2023-01-01T00:00:00Z',
          'subtasks': [],
          'dependencies': [],
          'tags': [],
          'comments': [
            {
              'id': 'comment-1',
              'content': 'This task needs more details',
              'author_id': 'user1',
              'author_name': 'John Doe',
              'created_at': '2023-01-01T01:00:00Z',
            },
            {
              'id': 'comment-2',
              'content': 'Updated the requirements',
              'author_id': 'user2',
              'author_name': 'Jane Smith',
              'author_avatar': 'https://example.com/avatar.jpg',
              'created_at': '2023-01-01T02:00:00Z',
            }
          ],
          'attachments': [],
          'order': 0,
        };

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get('${ApiConfig.tasksEndpoint}/$taskId'))
            .thenAnswer((_) async => response);

        // Act
        final result = await projectService.getTask(taskId);

        // Assert
        expect(result.hasComments, true);
        expect(result.comments.length, 2);
        expect(result.comments[0].content, 'This task needs more details');
        expect(result.comments[0].authorName, 'John Doe');
        expect(result.comments[1].authorAvatar, 'https://example.com/avatar.jpg');
      });

      test('should handle tasks with attachments', () async {
        // Arrange
        const taskId = 'task-with-attachments';
        final responseData = {
          'id': taskId,
          'title': 'Task with Attachments',
          'status': 'in_progress',
          'priority': 'medium',
          'project_id': 'project1',
          'created_at': '2023-01-01T00:00:00Z',
          'updated_at': '2023-01-01T00:00:00Z',
          'subtasks': [],
          'dependencies': [],
          'tags': [],
          'comments': [],
          'attachments': [
            {
              'id': 'attachment-1',
              'file_name': 'blueprint.pdf',
              'file_url': 'https://example.com/files/blueprint.pdf',
              'file_size': 2048576,
              'mime_type': 'application/pdf',
              'uploaded_by': 'user1',
              'uploaded_at': '2023-01-01T01:00:00Z',
            },
            {
              'id': 'attachment-2',
              'file_name': 'photo.jpg',
              'file_url': 'https://example.com/files/photo.jpg',
              'file_size': 1024000,
              'mime_type': 'image/jpeg',
              'uploaded_by': 'user2',
              'uploaded_at': '2023-01-01T02:00:00Z',
            }
          ],
          'order': 0,
        };

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get('${ApiConfig.tasksEndpoint}/$taskId'))
            .thenAnswer((_) async => response);

        // Act
        final result = await projectService.getTask(taskId);

        // Assert
        expect(result.hasAttachments, true);
        expect(result.attachments.length, 2);
        expect(result.attachments[0].fileName, 'blueprint.pdf');
        expect(result.attachments[0].mimeType, 'application/pdf');
        expect(result.attachments[1].fileName, 'photo.jpg');
        expect(result.attachments[1].fileSize, 1024000);
      });
    });

    group('Task Time Tracking', () {
      test('should handle estimated and actual hours', () async {
        // Arrange
        final taskWithTime = Task(
          id: 'timed-task',
          title: 'Task with Time Tracking',
          status: TaskStatus.completed,
          priority: TaskPriority.medium,
          projectId: 'project1',
          estimatedHours: 8.5,
          actualHours: 10.25,
          completedAt: DateTime.parse('2023-01-01T17:00:00Z'),
          createdAt: DateTime.parse('2023-01-01T08:00:00Z'),
          updatedAt: DateTime.parse('2023-01-01T17:00:00Z'),
        );

        // Act & Assert
        expect(taskWithTime.estimatedDuration?.inHours, 8);
        expect(taskWithTime.estimatedDuration?.inMinutes, 8 * 60 + 30);
        expect(taskWithTime.timeSpent?.inHours, 10);
        expect(taskWithTime.timeSpent?.inMinutes, 10 * 60 + 15);
        expect(taskWithTime.isCompleted, true);
      });

      test('should calculate overtime when actual exceeds estimated', () async {
        // Arrange
        final overtimeTask = Task(
          id: 'overtime-task',
          title: 'Overtime Task',
          status: TaskStatus.completed,
          priority: TaskPriority.high,
          projectId: 'project1',
          estimatedHours: 5.0,
          actualHours: 8.5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act & Assert
        expect(overtimeTask.estimatedDuration?.inHours, 5);
        expect(overtimeTask.timeSpent?.inHours, 8);
        // Overtime = 3.5 hours
        final overtime = overtimeTask.timeSpent!.inMilliseconds - 
                        overtimeTask.estimatedDuration!.inMilliseconds;
        expect(Duration(milliseconds: overtime).inHours, 3);
      });
    });

    group('Task Assignment and User Information', () {
      test('should handle task assignment with user details', () async {
        // Arrange
        const taskId = 'assigned-task';
        final responseData = {
          'id': taskId,
          'title': 'Assigned Task',
          'status': 'in_progress',
          'priority': 'high',
          'project_id': 'project1',
          'assigned_user_id': 'user123',
          'assigned_user_name': 'Alice Johnson',
          'assigned_user_avatar': 'https://example.com/alice-avatar.jpg',
          'created_at': '2023-01-01T00:00:00Z',
          'updated_at': '2023-01-01T00:00:00Z',
          'subtasks': [],
          'dependencies': [],
          'tags': ['assigned'],
          'comments': [],
          'attachments': [],
          'order': 0,
        };

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get('${ApiConfig.tasksEndpoint}/$taskId'))
            .thenAnswer((_) async => response);

        // Act
        final result = await projectService.getTask(taskId);

        // Assert
        expect(result.isAssigned, true);
        expect(result.assignedUserId, 'user123');
        expect(result.assignedUserName, 'Alice Johnson');
        expect(result.assignedUserAvatar, 'https://example.com/alice-avatar.jpg');
      });

      test('should handle unassigned tasks', () async {
        // Arrange
        final unassignedTask = Task(
          id: 'unassigned-task',
          title: 'Unassigned Task',
          status: TaskStatus.pending,
          priority: TaskPriority.low,
          projectId: 'project1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act & Assert
        expect(unassignedTask.isAssigned, false);
        expect(unassignedTask.assignedUserId, null);
        expect(unassignedTask.assignedUserName, null);
        expect(unassignedTask.assignedUserAvatar, null);
      });
    });

    group('Task Status Transitions', () {
      test('should update task status with completion timestamp', () async {
        // Arrange
        const taskId = 'status-task';
        final responseData = {
          'id': taskId,
          'title': 'Status Task',
          'status': 'completed',
          'priority': 'medium',
          'project_id': 'project1',
          'completed_at': '2023-01-01T15:30:00Z',
          'created_at': '2023-01-01T08:00:00Z',
          'updated_at': '2023-01-01T15:30:00Z',
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
        final result = await projectService.updateTaskStatus(taskId, TaskStatus.completed);

        // Assert
        expect(result.status, TaskStatus.completed);
        expect(result.isCompleted, true);
        expect(result.completedAt, isNotNull);
        expect(result.completedAt, DateTime.parse('2023-01-01T15:30:00Z'));
      });

      test('should handle status transition from completed to in progress', () async {
        // Arrange
        const taskId = 'reopened-task';
        final responseData = {
          'id': taskId,
          'title': 'Reopened Task',
          'status': 'in_progress',
          'priority': 'medium',
          'project_id': 'project1',
          'completed_at': null,
          'created_at': '2023-01-01T08:00:00Z',
          'updated_at': '2023-01-01T16:00:00Z',
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
          data: {'status': 'in_progress'},
        )).thenAnswer((_) async => response);

        // Act
        final result = await projectService.updateTaskStatus(taskId, TaskStatus.inProgress);

        // Assert
        expect(result.status, TaskStatus.inProgress);
        expect(result.isCompleted, false);
        expect(result.completedAt, null);
      });
    });
  });
}