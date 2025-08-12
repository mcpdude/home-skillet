import '../config/api_config.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/project_assignment.dart';
import '../services/http_client.dart';

class ProjectService {
  final HttpClient _httpClient;

  ProjectService({required HttpClient httpClient}) : _httpClient = httpClient;

  // Get all projects for the authenticated user
  Future<List<Project>> getAllProjects() async {
    try {
      final response = await _httpClient.get(ApiConfig.projectsEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Project.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load projects: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to load projects');
    }
  }

  // Get projects for a specific property
  Future<List<Project>> getProjectsForProperty(String propertyId) async {
    try {
      final response = await _httpClient.get(
        ApiConfig.projectsEndpoint,
        queryParameters: {'property_id': propertyId},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Project.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load projects: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to load projects');
    }
  }

  // Get a specific project by ID
  Future<Project> getProject(String projectId) async {
    try {
      final response = await _httpClient.get('${ApiConfig.projectsEndpoint}/$projectId');

      if (response.statusCode == 200) {
        return Project.fromJson(response.data);
      } else {
        throw Exception('Failed to load project: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to load project');
    }
  }

  // Create a new project
  Future<Project> createProject(Project project) async {
    try {
      final response = await _httpClient.post(
        ApiConfig.projectsEndpoint,
        data: project.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Project.fromJson(response.data);
      } else {
        throw Exception('Failed to create project: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('400')) {
        throw Exception('Please check your project information');
      } else {
        throw Exception('Failed to create project');
      }
    }
  }

  // Update an existing project
  Future<Project> updateProject(Project project) async {
    try {
      final response = await _httpClient.put(
        '${ApiConfig.projectsEndpoint}/${project.id}',
        data: project.toJson(),
      );

      if (response.statusCode == 200) {
        return Project.fromJson(response.data);
      } else {
        throw Exception('Failed to update project: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('400')) {
        throw Exception('Please check your project information');
      } else if (e.toString().contains('404')) {
        throw Exception('Project not found');
      } else {
        throw Exception('Failed to update project');
      }
    }
  }

  // Delete a project
  Future<void> deleteProject(String projectId) async {
    try {
      final response = await _httpClient.delete('${ApiConfig.projectsEndpoint}/$projectId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete project: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        throw Exception('Project not found');
      } else {
        throw Exception('Failed to delete project');
      }
    }
  }

  // Get tasks for a project
  Future<List<Task>> getTasksForProject(String projectId) async {
    try {
      final response = await _httpClient.get(
        ApiConfig.tasksEndpoint,
        queryParameters: {'project_id': projectId},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tasks: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to load tasks');
    }
  }

  // Get a specific task by ID
  Future<Task> getTask(String taskId) async {
    try {
      final response = await _httpClient.get('${ApiConfig.tasksEndpoint}/$taskId');

      if (response.statusCode == 200) {
        return Task.fromJson(response.data);
      } else {
        throw Exception('Failed to load task: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to load task');
    }
  }

  // Create a new task
  Future<Task> createTask(Task task) async {
    try {
      final response = await _httpClient.post(
        ApiConfig.tasksEndpoint,
        data: task.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Task.fromJson(response.data);
      } else {
        throw Exception('Failed to create task: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('400')) {
        throw Exception('Please check your task information');
      } else {
        throw Exception('Failed to create task');
      }
    }
  }

  // Update an existing task
  Future<Task> updateTask(Task task) async {
    try {
      final response = await _httpClient.put(
        '${ApiConfig.tasksEndpoint}/${task.id}',
        data: task.toJson(),
      );

      if (response.statusCode == 200) {
        return Task.fromJson(response.data);
      } else {
        throw Exception('Failed to update task: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('400')) {
        throw Exception('Please check your task information');
      } else if (e.toString().contains('404')) {
        throw Exception('Task not found');
      } else {
        throw Exception('Failed to update task');
      }
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      final response = await _httpClient.delete('${ApiConfig.tasksEndpoint}/$taskId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete task: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        throw Exception('Task not found');
      } else {
        throw Exception('Failed to delete task');
      }
    }
  }

  // Update task status
  Future<Task> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      final response = await _httpClient.patch(
        '${ApiConfig.tasksEndpoint}/$taskId/status',
        data: {'status': status.name},
      );

      if (response.statusCode == 200) {
        return Task.fromJson(response.data);
      } else {
        throw Exception('Failed to update task status: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        throw Exception('Task not found');
      } else {
        throw Exception('Failed to update task status');
      }
    }
  }

  // Search projects
  Future<List<Project>> searchProjects(String query) async {
    try {
      final response = await _httpClient.get(
        '${ApiConfig.projectsEndpoint}/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Project.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search projects: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to search projects');
    }
  }

  // Get project statistics
  Future<Map<String, dynamic>> getProjectStatistics(String projectId) async {
    try {
      final response = await _httpClient.get('${ApiConfig.projectsEndpoint}/$projectId/stats');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load project statistics: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to load project statistics');
    }
  }

  // ============================================================================
  // PROJECT ASSIGNMENT AND COLLABORATION METHODS
  // ============================================================================

  // Assign user to project with specific role
  Future<ProjectAssignment> assignUserToProject(
    String projectId,
    String userId,
    ProjectRole role,
  ) async {
    try {
      final response = await _httpClient.post(
        '${ApiConfig.projectsEndpoint}/$projectId/assign',
        data: {
          'user_id': userId,
          'role': role.name,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ProjectAssignment.fromJson(response.data);
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied: Cannot assign users to this project');
      } else {
        throw Exception('Failed to assign user: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('403')) {
        throw Exception('Permission denied: Cannot assign users to this project');
      } else {
        throw Exception('Failed to assign user to project');
      }
    }
  }

  // Get all assignments for a project
  Future<List<ProjectAssignment>> getProjectAssignments(String projectId) async {
    try {
      final response = await _httpClient.get('${ApiConfig.projectsEndpoint}/$projectId/assignments');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ProjectAssignment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load project assignments: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to load project assignments');
    }
  }

  // Update user role in project assignment
  Future<ProjectAssignment> updateProjectAssignment(
    String assignmentId,
    ProjectRole newRole,
  ) async {
    try {
      final response = await _httpClient.put(
        '${ApiConfig.projectsEndpoint}/assignments/$assignmentId',
        data: {'role': newRole.name},
      );

      if (response.statusCode == 200) {
        return ProjectAssignment.fromJson(response.data);
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied: Cannot update user role');
      } else if (response.statusCode == 404) {
        throw Exception('Assignment not found');
      } else {
        throw Exception('Failed to update assignment: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('403')) {
        throw Exception('Permission denied: Cannot update user role');
      } else if (e.toString().contains('404')) {
        throw Exception('Assignment not found');
      } else {
        throw Exception('Failed to update assignment');
      }
    }
  }

  // Remove user from project
  Future<void> removeUserFromProject(String assignmentId) async {
    try {
      final response = await _httpClient.delete('${ApiConfig.projectsEndpoint}/assignments/$assignmentId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        if (response.statusCode == 403) {
          throw Exception('Permission denied: Cannot remove user from project');
        } else if (response.statusCode == 404) {
          throw Exception('Assignment not found');
        } else {
          throw Exception('Failed to remove user: ${response.statusMessage}');
        }
      }
    } catch (e) {
      if (e.toString().contains('403')) {
        throw Exception('Permission denied: Cannot remove user from project');
      } else if (e.toString().contains('404')) {
        throw Exception('Assignment not found');
      } else {
        throw Exception('Failed to remove user from project');
      }
    }
  }

  // Invite user to project via email
  Future<ProjectInvitation> inviteUserToProject(
    String projectId,
    String email,
    ProjectRole role, {
    String? message,
  }) async {
    try {
      final response = await _httpClient.post(
        '${ApiConfig.projectsEndpoint}/$projectId/invite',
        data: {
          'email': email,
          'role': role.name,
          if (message != null) 'message': message,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ProjectInvitation.fromJson(response.data);
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied: Cannot invite users to this project');
      } else if (response.statusCode == 400) {
        throw Exception('Invalid email address or user already assigned');
      } else {
        throw Exception('Failed to send invitation: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('403')) {
        throw Exception('Permission denied: Cannot invite users to this project');
      } else if (e.toString().contains('400')) {
        throw Exception('Invalid email address or user already assigned');
      } else {
        throw Exception('Failed to send invitation');
      }
    }
  }

  // Get all invitations for a project
  Future<List<ProjectInvitation>> getProjectInvitations(String projectId) async {
    try {
      final response = await _httpClient.get('${ApiConfig.projectsEndpoint}/$projectId/invitations');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ProjectInvitation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load invitations: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to load invitations');
    }
  }

  // Accept project invitation
  Future<ProjectAssignment> acceptProjectInvitation(String token) async {
    try {
      final response = await _httpClient.post(
        '${ApiConfig.projectsEndpoint}/invitations/accept',
        data: {'token': token},
      );

      if (response.statusCode == 200) {
        return ProjectAssignment.fromJson(response.data);
      } else if (response.statusCode == 404) {
        throw Exception('Invalid invitation token or invitation expired');
      } else if (response.statusCode == 410) {
        throw Exception('Invitation has expired');
      } else {
        throw Exception('Failed to accept invitation: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        throw Exception('Invalid invitation token or invitation expired');
      } else if (e.toString().contains('410')) {
        throw Exception('Invitation has expired');
      } else {
        throw Exception('Failed to accept invitation');
      }
    }
  }

  // Reject project invitation
  Future<void> rejectProjectInvitation(String token) async {
    try {
      final response = await _httpClient.post(
        '${ApiConfig.projectsEndpoint}/invitations/reject',
        data: {'token': token},
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 404) {
          throw Exception('Invalid invitation token');
        } else {
          throw Exception('Failed to reject invitation: ${response.statusMessage}');
        }
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        throw Exception('Invalid invitation token');
      } else {
        throw Exception('Failed to reject invitation');
      }
    }
  }

  // Log project activity for collaboration tracking
  Future<void> logProjectActivity(
    String projectId,
    String userId,
    String action, {
    String? entityType,
    String? entityId,
    String? description,
  }) async {
    try {
      final response = await _httpClient.post(
        '${ApiConfig.projectsEndpoint}/$projectId/activity',
        data: {
          'user_id': userId,
          'action': action,
          if (entityType != null) 'entity_type': entityType,
          if (entityId != null) 'entity_id': entityId,
          if (description != null) 'description': description,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to log activity: ${response.statusMessage}');
      }
    } catch (e) {
      // Activity logging failures should not break the main functionality
      print('Warning: Failed to log project activity: $e');
    }
  }

  // Get project activity feed
  Future<List<Map<String, dynamic>>> getProjectActivity(
    String projectId, {
    int? limit,
    DateTime? since,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (since != null) queryParams['since'] = since.toIso8601String();

      final response = await _httpClient.get(
        '${ApiConfig.projectsEndpoint}/$projectId/activity',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to load activity: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to load project activity');
    }
  }

  // Get user's permissions for a project
  Future<Map<String, bool>> getUserProjectPermissions(
    String projectId,
    String userId,
  ) async {
    try {
      final response = await _httpClient.get(
        '${ApiConfig.projectsEndpoint}/$projectId/permissions/$userId',
      );

      if (response.statusCode == 200) {
        return Map<String, bool>.from(response.data);
      } else if (response.statusCode == 404) {
        throw Exception('User not assigned to project');
      } else {
        throw Exception('Failed to load permissions: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        throw Exception('User not assigned to project');
      } else {
        throw Exception('Failed to load permissions');
      }
    }
  }

  // Update project collaboration settings
  Future<Project> updateProjectCollaborationSettings(
    String projectId,
    bool collaborationEnabled,
  ) async {
    try {
      final response = await _httpClient.patch(
        '${ApiConfig.projectsEndpoint}/$projectId/collaboration',
        data: {'collaboration_enabled': collaborationEnabled},
      );

      if (response.statusCode == 200) {
        return Project.fromJson(response.data);
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied: Cannot modify collaboration settings');
      } else {
        throw Exception('Failed to update collaboration settings: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('403')) {
        throw Exception('Permission denied: Cannot modify collaboration settings');
      } else {
        throw Exception('Failed to update collaboration settings');
      }
    }
  }

  // Bulk assign tasks to users
  Future<List<Task>> bulkAssignTasks(
    List<String> taskIds,
    String assignedUserId,
  ) async {
    try {
      final response = await _httpClient.post(
        '${ApiConfig.tasksEndpoint}/bulk-assign',
        data: {
          'task_ids': taskIds,
          'assigned_user_id': assignedUserId,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Task.fromJson(json)).toList();
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied: Cannot assign tasks');
      } else {
        throw Exception('Failed to assign tasks: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('403')) {
        throw Exception('Permission denied: Cannot assign tasks');
      } else {
        throw Exception('Failed to assign tasks');
      }
    }
  }

  // Reorder tasks within a project
  Future<List<Task>> reorderProjectTasks(
    String projectId,
    List<Map<String, dynamic>> taskOrders,
  ) async {
    try {
      final response = await _httpClient.post(
        '${ApiConfig.projectsEndpoint}/$projectId/tasks/reorder',
        data: {'task_orders': taskOrders},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception('Failed to reorder tasks: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to reorder tasks');
    }
  }
}