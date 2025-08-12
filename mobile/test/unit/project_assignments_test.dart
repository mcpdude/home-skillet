import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:home_skillet_mobile/services/project_service.dart';
import 'package:home_skillet_mobile/services/http_client.dart';
import 'package:home_skillet_mobile/models/project.dart';
import 'package:home_skillet_mobile/models/project_assignment.dart';
import 'package:home_skillet_mobile/config/api_config.dart';

import 'project_assignments_test.mocks.dart';

@GenerateMocks([HttpClient])
void main() {
  group('Project Assignments and Collaboration Tests', () {
    late ProjectService projectService;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockHttpClient();
      projectService = ProjectService(httpClient: mockHttpClient);
    });

    group('Project Assignment Management', () {
      test('should assign user to project with specific role', () async {
        // Arrange
        const projectId = 'project-123';
        const userId = 'user-456';
        const role = ProjectRole.editor;

        final assignmentData = {
          'project_id': projectId,
          'user_id': userId,
          'role': 'editor',
        };

        final responseData = {
          'id': 'assignment-1',
          'project_id': projectId,
          'user_id': userId,
          'role': 'editor',
          'assigned_at': '2023-01-01T00:00:00Z',
          'assigned_by': 'admin-user',
          'user_name': 'John Smith',
          'user_email': 'john@example.com',
          'user_avatar': 'https://example.com/avatar.jpg',
          'is_active': true,
          'permissions': [],
        };

        final response = Response(
          data: responseData,
          statusCode: 201,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(
          '${ApiConfig.projectsEndpoint}/$projectId/assign',
          data: assignmentData,
        )).thenAnswer((_) async => response);

        // Act
        final result = await projectService.assignUserToProject(
          projectId,
          userId,
          role,
        );

        // Assert
        expect(result, isA<ProjectAssignment>());
        expect(result.projectId, projectId);
        expect(result.userId, userId);
        expect(result.role, ProjectRole.editor);
        expect(result.userName, 'John Smith');
        expect(result.canEdit, true);
        expect(result.canDelete, false);
        verify(mockHttpClient.post(
          '${ApiConfig.projectsEndpoint}/$projectId/assign',
          data: assignmentData,
        )).called(1);
      });

      test('should get all assignments for a project', () async {
        // Arrange
        const projectId = 'project-123';
        final responseData = [
          {
            'id': 'assignment-1',
            'project_id': projectId,
            'user_id': 'user-1',
            'role': 'owner',
            'assigned_at': '2023-01-01T00:00:00Z',
            'user_name': 'Project Owner',
            'user_email': 'owner@example.com',
            'is_active': true,
            'permissions': [],
          },
          {
            'id': 'assignment-2',
            'project_id': projectId,
            'user_id': 'user-2',
            'role': 'editor',
            'assigned_at': '2023-01-02T00:00:00Z',
            'user_name': 'Editor User',
            'user_email': 'editor@example.com',
            'is_active': true,
            'permissions': [],
          },
          {
            'id': 'assignment-3',
            'project_id': projectId,
            'user_id': 'user-3',
            'role': 'viewer',
            'assigned_at': '2023-01-03T00:00:00Z',
            'user_name': 'Viewer User',
            'user_email': 'viewer@example.com',
            'is_active': true,
            'permissions': [],
          }
        ];

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get('${ApiConfig.projectsEndpoint}/$projectId/assignments'))
            .thenAnswer((_) async => response);

        // Act
        final result = await projectService.getProjectAssignments(projectId);

        // Assert
        expect(result, isA<List<ProjectAssignment>>());
        expect(result.length, 3);
        expect(result[0].role, ProjectRole.owner);
        expect(result[0].canManageUsers, true);
        expect(result[1].role, ProjectRole.editor);
        expect(result[1].canEdit, true);
        expect(result[1].canManageUsers, false);
        expect(result[2].role, ProjectRole.viewer);
        expect(result[2].canViewOnly, true);
        expect(result[2].canEdit, false);
      });

      test('should update user role in project', () async {
        // Arrange
        const assignmentId = 'assignment-1';
        const newRole = ProjectRole.admin;

        final responseData = {
          'id': assignmentId,
          'project_id': 'project-123',
          'user_id': 'user-456',
          'role': 'admin',
          'assigned_at': '2023-01-01T00:00:00Z',
          'updated_at': '2023-01-02T00:00:00Z',
          'user_name': 'John Smith',
          'user_email': 'john@example.com',
          'is_active': true,
          'permissions': [],
        };

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.put(
          '${ApiConfig.projectsEndpoint}/assignments/$assignmentId',
          data: {'role': 'admin'},
        )).thenAnswer((_) async => response);

        // Act
        final result = await projectService.updateProjectAssignment(
          assignmentId,
          newRole,
        );

        // Assert
        expect(result.role, ProjectRole.admin);
        expect(result.canEdit, true);
        expect(result.canDelete, true);
        expect(result.canManageUsers, true);
      });

      test('should remove user from project', () async {
        // Arrange
        const assignmentId = 'assignment-1';
        final response = Response(
          statusCode: 204,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.delete('${ApiConfig.projectsEndpoint}/assignments/$assignmentId'))
            .thenAnswer((_) async => response);

        // Act
        await projectService.removeUserFromProject(assignmentId);

        // Assert
        verify(mockHttpClient.delete('${ApiConfig.projectsEndpoint}/assignments/$assignmentId'))
            .called(1);
      });
    });

    group('Project Invitations', () {
      test('should invite user to project via email', () async {
        // Arrange
        const projectId = 'project-123';
        const email = 'newuser@example.com';
        const role = ProjectRole.contributor;
        const message = 'Please join our renovation project!';

        final invitationData = {
          'email': email,
          'role': 'contributor',
          'message': message,
        };

        final responseData = {
          'id': 'invitation-1',
          'project_id': projectId,
          'email': email,
          'role': 'contributor',
          'invited_by': 'admin-user',
          'invited_at': '2023-01-01T00:00:00Z',
          'expires_at': '2023-01-08T00:00:00Z',
          'token': 'invitation-token-123',
          'message': message,
        };

        final response = Response(
          data: responseData,
          statusCode: 201,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(
          '${ApiConfig.projectsEndpoint}/$projectId/invite',
          data: invitationData,
        )).thenAnswer((_) async => response);

        // Act
        final result = await projectService.inviteUserToProject(
          projectId,
          email,
          role,
          message: message,
        );

        // Assert
        expect(result, isA<ProjectInvitation>());
        expect(result.email, email);
        expect(result.role, ProjectRole.contributor);
        expect(result.isPending, true);
        expect(result.isExpired, false);
        expect(result.message, message);
      });

      test('should get all pending invitations for project', () async {
        // Arrange
        const projectId = 'project-123';
        final responseData = [
          {
            'id': 'invitation-1',
            'project_id': projectId,
            'email': 'user1@example.com',
            'role': 'editor',
            'invited_by': 'admin-user',
            'invited_at': '2023-01-01T00:00:00Z',
            'expires_at': '2023-01-08T00:00:00Z',
            'token': 'token-1',
          },
          {
            'id': 'invitation-2',
            'project_id': projectId,
            'email': 'user2@example.com',
            'role': 'viewer',
            'invited_by': 'admin-user',
            'invited_at': '2023-01-02T00:00:00Z',
            'accepted_at': '2023-01-02T12:00:00Z',
            'token': 'token-2',
          },
          {
            'id': 'invitation-3',
            'project_id': projectId,
            'email': 'user3@example.com',
            'role': 'contributor',
            'invited_by': 'admin-user',
            'invited_at': '2022-12-15T00:00:00Z',
            'expires_at': '2022-12-22T00:00:00Z',
            'token': 'token-3',
          }
        ];

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get('${ApiConfig.projectsEndpoint}/$projectId/invitations'))
            .thenAnswer((_) async => response);

        // Act
        final result = await projectService.getProjectInvitations(projectId);

        // Assert
        expect(result, isA<List<ProjectInvitation>>());
        expect(result.length, 3);
        expect(result[0].isPending, true);
        expect(result[0].isExpired, false);
        expect(result[1].isPending, false);
        expect(result[1].isAccepted, true);
        expect(result[2].isPending, false);
        expect(result[2].isExpired, true);
      });

      test('should accept project invitation', () async {
        // Arrange
        const token = 'invitation-token-123';
        final responseData = {
          'id': 'assignment-new',
          'project_id': 'project-123',
          'user_id': 'user-new',
          'role': 'contributor',
          'assigned_at': '2023-01-01T12:00:00Z',
          'user_name': 'New User',
          'user_email': 'newuser@example.com',
          'is_active': true,
          'permissions': [],
        };

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(
          '${ApiConfig.projectsEndpoint}/invitations/accept',
          data: {'token': token},
        )).thenAnswer((_) async => response);

        // Act
        final result = await projectService.acceptProjectInvitation(token);

        // Assert
        expect(result, isA<ProjectAssignment>());
        expect(result.role, ProjectRole.contributor);
        expect(result.userEmail, 'newuser@example.com');
      });

      test('should reject project invitation', () async {
        // Arrange
        const token = 'invitation-token-456';
        final response = Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(
          '${ApiConfig.projectsEndpoint}/invitations/reject',
          data: {'token': token},
        )).thenAnswer((_) async => response);

        // Act
        await projectService.rejectProjectInvitation(token);

        // Assert
        verify(mockHttpClient.post(
          '${ApiConfig.projectsEndpoint}/invitations/reject',
          data: {'token': token},
        )).called(1);
      });
    });

    group('Role-Based Permissions', () {
      test('should validate owner permissions', () {
        // Arrange
        const assignment = ProjectAssignment(
          id: 'assignment-1',
          projectId: 'project-1',
          userId: 'user-1',
          role: ProjectRole.owner,
          assignedAt: '2023-01-01T00:00:00Z',
          isActive: true,
        );

        // Act & Assert
        expect(assignment.canEdit, true);
        expect(assignment.canDelete, true);
        expect(assignment.canAssignTasks, true);
        expect(assignment.canManageUsers, true);
        expect(assignment.canViewOnly, false);
        expect(assignment.hasPermission('read'), true);
        expect(assignment.hasPermission('edit'), true);
        expect(assignment.hasPermission('delete'), true);
        expect(assignment.hasPermission('assign_tasks'), true);
        expect(assignment.hasPermission('manage_users'), true);
      });

      test('should validate admin permissions', () {
        // Arrange
        const assignment = ProjectAssignment(
          id: 'assignment-2',
          projectId: 'project-1',
          userId: 'user-2',
          role: ProjectRole.admin,
          assignedAt: '2023-01-01T00:00:00Z',
          isActive: true,
        );

        // Act & Assert
        expect(assignment.canEdit, true);
        expect(assignment.canDelete, true);
        expect(assignment.canAssignTasks, true);
        expect(assignment.canManageUsers, true);
        expect(assignment.canViewOnly, false);
      });

      test('should validate editor permissions', () {
        // Arrange
        const assignment = ProjectAssignment(
          id: 'assignment-3',
          projectId: 'project-1',
          userId: 'user-3',
          role: ProjectRole.editor,
          assignedAt: '2023-01-01T00:00:00Z',
          isActive: true,
        );

        // Act & Assert
        expect(assignment.canEdit, true);
        expect(assignment.canDelete, false);
        expect(assignment.canAssignTasks, true);
        expect(assignment.canManageUsers, false);
        expect(assignment.canViewOnly, false);
      });

      test('should validate contributor permissions', () {
        // Arrange
        const assignment = ProjectAssignment(
          id: 'assignment-4',
          projectId: 'project-1',
          userId: 'user-4',
          role: ProjectRole.contributor,
          assignedAt: '2023-01-01T00:00:00Z',
          isActive: true,
        );

        // Act & Assert
        expect(assignment.canEdit, false);
        expect(assignment.canDelete, false);
        expect(assignment.canAssignTasks, false);
        expect(assignment.canManageUsers, false);
        expect(assignment.canViewOnly, false);
        expect(assignment.hasPermission('read'), true);
        expect(assignment.hasPermission('edit'), false);
      });

      test('should validate viewer permissions', () {
        // Arrange
        const assignment = ProjectAssignment(
          id: 'assignment-5',
          projectId: 'project-1',
          userId: 'user-5',
          role: ProjectRole.viewer,
          assignedAt: '2023-01-01T00:00:00Z',
          isActive: true,
        );

        // Act & Assert
        expect(assignment.canEdit, false);
        expect(assignment.canDelete, false);
        expect(assignment.canAssignTasks, false);
        expect(assignment.canManageUsers, false);
        expect(assignment.canViewOnly, true);
        expect(assignment.hasPermission('read'), true);
        expect(assignment.hasPermission('edit'), false);
      });

      test('should handle inactive assignments', () {
        // Arrange
        const inactiveAssignment = ProjectAssignment(
          id: 'assignment-6',
          projectId: 'project-1',
          userId: 'user-6',
          role: ProjectRole.admin,
          assignedAt: '2023-01-01T00:00:00Z',
          isActive: false,
        );

        // Act & Assert
        expect(inactiveAssignment.canEdit, false);
        expect(inactiveAssignment.canDelete, false);
        expect(inactiveAssignment.canAssignTasks, false);
        expect(inactiveAssignment.canManageUsers, false);
      });
    });

    group('Collaboration Features', () {
      test('should identify collaborative projects', () {
        // Arrange
        final collaborativeProject = Project(
          id: 'collaborative-project',
          title: 'Team Project',
          status: ProjectStatus.inProgress,
          priority: ProjectPriority.high,
          propertyId: 'prop-1',
          userId: 'owner-1',
          assignedUserIds: ['owner-1', 'user-2', 'user-3'],
          collaborationEnabled: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final soloProject = Project(
          id: 'solo-project',
          title: 'Solo Project',
          status: ProjectStatus.planned,
          priority: ProjectPriority.medium,
          propertyId: 'prop-1',
          userId: 'owner-1',
          assignedUserIds: ['owner-1'],
          collaborationEnabled: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act & Assert
        expect(collaborativeProject.isCollaborative, true);
        expect(collaborativeProject.hasAssignedUsers, true);
        expect(collaborativeProject.collaborationEnabled, true);
        
        expect(soloProject.isCollaborative, false);
        expect(soloProject.hasAssignedUsers, true);
        expect(soloProject.collaborationEnabled, false);
      });

      test('should track project activity for collaboration', () async {
        // Arrange
        const projectId = 'project-123';
        final activityData = {
          'user_id': 'user-1',
          'action': 'task_completed',
          'entity_type': 'task',
          'entity_id': 'task-456',
          'description': 'Completed task: Install kitchen cabinets',
          'timestamp': '2023-01-01T15:30:00Z',
        };

        final response = Response(
          statusCode: 201,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(
          '${ApiConfig.projectsEndpoint}/$projectId/activity',
          data: activityData,
        )).thenAnswer((_) async => response);

        // Act
        await projectService.logProjectActivity(
          projectId,
          'user-1',
          'task_completed',
          entityType: 'task',
          entityId: 'task-456',
          description: 'Completed task: Install kitchen cabinets',
        );

        // Assert
        verify(mockHttpClient.post(
          '${ApiConfig.projectsEndpoint}/$projectId/activity',
          data: activityData,
        )).called(1);
      });

      test('should get project activity feed', () async {
        // Arrange
        const projectId = 'project-123';
        final responseData = [
          {
            'id': 'activity-1',
            'user_id': 'user-1',
            'user_name': 'John Doe',
            'action': 'task_completed',
            'entity_type': 'task',
            'entity_id': 'task-1',
            'description': 'Completed task: Install plumbing',
            'timestamp': '2023-01-01T15:30:00Z',
          },
          {
            'id': 'activity-2',
            'user_id': 'user-2',
            'user_name': 'Jane Smith',
            'action': 'comment_added',
            'entity_type': 'task',
            'entity_id': 'task-2',
            'description': 'Added comment on electrical work task',
            'timestamp': '2023-01-01T14:15:00Z',
          }
        ];

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get('${ApiConfig.projectsEndpoint}/$projectId/activity'))
            .thenAnswer((_) async => response);

        // Act
        final result = await projectService.getProjectActivity(projectId);

        // Assert
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, 2);
        expect(result[0]['action'], 'task_completed');
        expect(result[0]['user_name'], 'John Doe');
        expect(result[1]['action'], 'comment_added');
      });
    });

    group('Error Handling for Assignments', () {
      test('should handle unauthorized assignment attempts', () async {
        // Arrange
        const projectId = 'project-123';
        const userId = 'user-456';
        const role = ProjectRole.admin;

        final response = Response(
          statusCode: 403,
          statusMessage: 'Forbidden',
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(
          '${ApiConfig.projectsEndpoint}/$projectId/assign',
          data: anyNamed('data'),
        )).thenAnswer((_) async => response);

        // Act & Assert
        expect(
          () async => await projectService.assignUserToProject(projectId, userId, role),
          throwsA(predicate((e) => e.toString().contains('Permission denied'))),
        );
      });

      test('should handle invalid invitation tokens', () async {
        // Arrange
        const invalidToken = 'invalid-token';
        final response = Response(
          statusCode: 404,
          statusMessage: 'Not Found',
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(
          '${ApiConfig.projectsEndpoint}/invitations/accept',
          data: {'token': invalidToken},
        )).thenAnswer((_) async => response);

        // Act & Assert
        expect(
          () async => await projectService.acceptProjectInvitation(invalidToken),
          throwsA(predicate((e) => e.toString().contains('Invalid invitation'))),
        );
      });

      test('should handle expired invitations', () async {
        // Arrange
        final expiredInvitation = ProjectInvitation(
          id: 'invitation-1',
          projectId: 'project-1',
          email: 'user@example.com',
          role: ProjectRole.viewer,
          invitedBy: 'admin-user',
          invitedAt: DateTime.parse('2022-01-01T00:00:00Z'),
          expiresAt: DateTime.parse('2022-01-08T00:00:00Z'),
        );

        // Act & Assert
        expect(expiredInvitation.isExpired, true);
        expect(expiredInvitation.isValid, false);
        expect(expiredInvitation.isPending, true);
      });
    });
  });
}