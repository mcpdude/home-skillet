import 'package:flutter/foundation.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/project_service.dart';

class ProjectProvider with ChangeNotifier {
  ProjectProvider({
    required ProjectService projectService,
  }) : _projectService = projectService;

  final ProjectService _projectService;

  List<Project> _projects = [];
  List<Task> _tasks = [];
  Project? _selectedProject;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Project> get projects => List.unmodifiable(_projects);
  List<Task> get tasks => List.unmodifiable(_tasks);
  Project? get selectedProject => _selectedProject;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get projects filtered by status
  List<Project> getProjectsByStatus(ProjectStatus status) {
    return _projects.where((project) => project.status == status).toList();
  }

  // Get overdue projects
  List<Project> get overdueProjects {
    return _projects.where((project) => project.isOverdue).toList();
  }

  // Get tasks for selected project
  List<Task> get selectedProjectTasks {
    if (_selectedProject == null) return [];
    return _tasks.where((task) => task.projectId == _selectedProject!.id).toList();
  }

  // Load projects for a property
  Future<void> loadProjectsForProperty(String propertyId) async {
    try {
      _setLoading(true);
      _clearError();

      final projects = await _projectService.getProjectsForProperty(propertyId);
      _projects = projects;
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load all projects for user
  Future<void> loadAllProjects() async {
    try {
      _setLoading(true);
      _clearError();

      final projects = await _projectService.getAllProjects();
      _projects = projects;
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Create a new project
  Future<bool> createProject(Project project) async {
    try {
      _setLoading(true);
      _clearError();

      final createdProject = await _projectService.createProject(project);
      _projects.add(createdProject);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing project
  Future<bool> updateProject(Project project) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedProject = await _projectService.updateProject(project);
      
      final index = _projects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        _projects[index] = updatedProject;
        
        // Update selected project if it's the same
        if (_selectedProject?.id == project.id) {
          _selectedProject = updatedProject;
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a project
  Future<bool> deleteProject(String projectId) async {
    try {
      _setLoading(true);
      _clearError();

      await _projectService.deleteProject(projectId);
      
      _projects.removeWhere((p) => p.id == projectId);
      
      // Clear selected project if it was deleted
      if (_selectedProject?.id == projectId) {
        _selectedProject = null;
      }
      
      // Remove tasks for deleted project
      _tasks.removeWhere((task) => task.projectId == projectId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Select a project and load its tasks
  Future<void> selectProject(Project project) async {
    _selectedProject = project;
    notifyListeners();
    
    // Load tasks for the selected project
    await loadTasksForProject(project.id);
  }

  // Load tasks for a project
  Future<void> loadTasksForProject(String projectId) async {
    try {
      final tasks = await _projectService.getTasksForProject(projectId);
      
      // Remove old tasks for this project and add new ones
      _tasks.removeWhere((task) => task.projectId == projectId);
      _tasks.addAll(tasks);
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Create a task for a project
  Future<bool> createTask(Task task) async {
    try {
      _setLoading(true);
      _clearError();

      final createdTask = await _projectService.createTask(task);
      _tasks.add(createdTask);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update a task
  Future<bool> updateTask(Task task) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedTask = await _projectService.updateTask(task);
      
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a task
  Future<bool> deleteTask(String taskId) async {
    try {
      _setLoading(true);
      _clearError();

      await _projectService.deleteTask(taskId);
      
      _tasks.removeWhere((t) => t.id == taskId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get project by ID
  Project? getProjectById(String projectId) {
    try {
      return _projects.firstWhere((p) => p.id == projectId);
    } catch (e) {
      return null;
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}