import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'task.dart';

part 'project.g.dart';

enum ProjectStatus {
  @JsonValue('planned')
  planned,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('on_hold')
  onHold,
  @JsonValue('cancelled')
  cancelled,
}

enum ProjectPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

@JsonSerializable()
class Project extends Equatable {
  const Project({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.startDate,
    this.endDate,
    this.dueDate,
    this.estimatedCost,
    this.actualCost,
    this.notes,
    this.imageUrls = const [],
    required this.propertyId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.tasks = const [],
    this.assignedUserIds = const [],
    this.tags = const [],
    this.templateId,
    this.isTemplate = false,
    this.collaborationEnabled = true,
    this.lastActivity,
  });

  final String id;
  final String title;
  final String? description;
  final ProjectStatus status;
  final ProjectPriority priority;
  
  @JsonKey(name: 'start_date')
  final DateTime? startDate;
  
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;
  
  @JsonKey(name: 'estimated_cost')
  final double? estimatedCost;
  
  @JsonKey(name: 'actual_cost')
  final double? actualCost;
  
  final String? notes;
  
  @JsonKey(name: 'image_urls')
  final List<String> imageUrls;
  
  @JsonKey(name: 'property_id')
  final String propertyId;
  
  @JsonKey(name: 'user_id')
  final String userId;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // New collaboration and relationship fields
  final List<Task> tasks;
  
  @JsonKey(name: 'assigned_user_ids')
  final List<String> assignedUserIds;
  
  final List<String> tags;
  
  @JsonKey(name: 'template_id')
  final String? templateId;
  
  @JsonKey(name: 'is_template')
  final bool isTemplate;
  
  @JsonKey(name: 'collaboration_enabled')
  final bool collaborationEnabled;
  
  @JsonKey(name: 'last_activity')
  final DateTime? lastActivity;

  bool get isOverdue {
    if (dueDate == null || status == ProjectStatus.completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  double get progressPercentage {
    if (tasks.isEmpty) {
      switch (status) {
        case ProjectStatus.planned:
          return 0.0;
        case ProjectStatus.inProgress:
          return 25.0;
        case ProjectStatus.completed:
          return 100.0;
        case ProjectStatus.onHold:
        case ProjectStatus.cancelled:
          return 0.0;
      }
    }
    
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    return (completedTasks / tasks.length) * 100;
  }

  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((task) => task.isCompleted).length;
  int get pendingTasks => tasks.where((task) => task.status == TaskStatus.pending).length;
  int get inProgressTasks => tasks.where((task) => task.status == TaskStatus.inProgress).length;
  
  List<Task> get overdueTasks => tasks.where((task) => task.isOverdue).toList();
  
  bool get hasAssignedUsers => assignedUserIds.isNotEmpty;
  
  bool get isCollaborative => assignedUserIds.length > 1;

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
  
  Map<String, dynamic> toJson() => _$ProjectToJson(this);

  Project copyWith({
    String? id,
    String? title,
    String? description,
    ProjectStatus? status,
    ProjectPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? dueDate,
    double? estimatedCost,
    double? actualCost,
    String? notes,
    List<String>? imageUrls,
    String? propertyId,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Task>? tasks,
    List<String>? assignedUserIds,
    List<String>? tags,
    String? templateId,
    bool? isTemplate,
    bool? collaborationEnabled,
    DateTime? lastActivity,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dueDate: dueDate ?? this.dueDate,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      notes: notes ?? this.notes,
      imageUrls: imageUrls ?? this.imageUrls,
      propertyId: propertyId ?? this.propertyId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tasks: tasks ?? this.tasks,
      assignedUserIds: assignedUserIds ?? this.assignedUserIds,
      tags: tags ?? this.tags,
      templateId: templateId ?? this.templateId,
      isTemplate: isTemplate ?? this.isTemplate,
      collaborationEnabled: collaborationEnabled ?? this.collaborationEnabled,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        priority,
        startDate,
        endDate,
        dueDate,
        estimatedCost,
        actualCost,
        notes,
        imageUrls,
        propertyId,
        userId,
        createdAt,
        updatedAt,
        tasks,
        assignedUserIds,
        tags,
        templateId,
        isTemplate,
        collaborationEnabled,
        lastActivity,
      ];
}