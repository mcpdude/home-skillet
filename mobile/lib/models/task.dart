import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';

enum TaskStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

enum TaskPriority {
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
class TaskComment extends Equatable {
  const TaskComment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String content;
  @JsonKey(name: 'author_id')
  final String authorId;
  @JsonKey(name: 'author_name')
  final String authorName;
  @JsonKey(name: 'author_avatar')
  final String? authorAvatar;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  factory TaskComment.fromJson(Map<String, dynamic> json) => _$TaskCommentFromJson(json);
  Map<String, dynamic> toJson() => _$TaskCommentToJson(this);

  @override
  List<Object?> get props => [id, content, authorId, authorName, authorAvatar, createdAt, updatedAt];
}

@JsonSerializable()
class TaskAttachment extends Equatable {
  const TaskAttachment({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.mimeType,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  final String id;
  @JsonKey(name: 'file_name')
  final String fileName;
  @JsonKey(name: 'file_url')
  final String fileUrl;
  @JsonKey(name: 'file_size')
  final int fileSize;
  @JsonKey(name: 'mime_type')
  final String mimeType;
  @JsonKey(name: 'uploaded_by')
  final String uploadedBy;
  @JsonKey(name: 'uploaded_at')
  final DateTime uploadedAt;

  factory TaskAttachment.fromJson(Map<String, dynamic> json) => _$TaskAttachmentFromJson(json);
  Map<String, dynamic> toJson() => _$TaskAttachmentToJson(this);

  @override
  List<Object?> get props => [id, fileName, fileUrl, fileSize, mimeType, uploadedBy, uploadedAt];
}

@JsonSerializable()
class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    this.estimatedHours,
    this.actualHours,
    this.notes,
    this.imageUrls = const [],
    required this.projectId,
    this.assignedUserId,
    required this.createdAt,
    required this.updatedAt,
    this.subtasks = const [],
    this.dependencies = const [],
    this.tags = const [],
    this.comments = const [],
    this.attachments = const [],
    this.completedAt,
    this.order = 0,
    this.assignedUserName,
    this.assignedUserAvatar,
  });

  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;
  
  @JsonKey(name: 'estimated_hours')
  final double? estimatedHours;
  
  @JsonKey(name: 'actual_hours')
  final double? actualHours;
  
  final String? notes;
  
  @JsonKey(name: 'image_urls')
  final List<String> imageUrls;
  
  @JsonKey(name: 'project_id')
  final String projectId;
  
  @JsonKey(name: 'assigned_user_id')
  final String? assignedUserId;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // New collaboration and workflow fields
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<Task> subtasks;
  
  final List<String> dependencies; // Task IDs that this task depends on
  
  final List<String> tags;
  
  final List<TaskComment> comments;
  
  final List<TaskAttachment> attachments;
  
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  
  final int order; // For drag-and-drop reordering
  
  @JsonKey(name: 'assigned_user_name')
  final String? assignedUserName;
  
  @JsonKey(name: 'assigned_user_avatar')
  final String? assignedUserAvatar;

  bool get isCompleted => status == TaskStatus.completed;
  
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get hasSubtasks => subtasks.isNotEmpty;
  int get completedSubtasks => subtasks.where((task) => task.isCompleted).length;
  double get subtaskProgress => hasSubtasks ? (completedSubtasks / subtasks.length) * 100 : 0;
  
  bool get hasComments => comments.isNotEmpty;
  bool get hasAttachments => attachments.isNotEmpty;
  bool get hasDependencies => dependencies.isNotEmpty;
  
  bool get isAssigned => assignedUserId != null;
  
  Duration? get timeSpent {
    if (actualHours != null) {
      return Duration(milliseconds: (actualHours! * 3600 * 1000).round());
    }
    return null;
  }
  
  Duration? get estimatedDuration {
    if (estimatedHours != null) {
      return Duration(milliseconds: (estimatedHours! * 3600 * 1000).round());
    }
    return null;
  }

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  
  Map<String, dynamic> toJson() => _$TaskToJson(this);

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    double? estimatedHours,
    double? actualHours,
    String? notes,
    List<String>? imageUrls,
    String? projectId,
    String? assignedUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Task>? subtasks,
    List<String>? dependencies,
    List<String>? tags,
    List<TaskComment>? comments,
    List<TaskAttachment>? attachments,
    DateTime? completedAt,
    int? order,
    String? assignedUserName,
    String? assignedUserAvatar,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualHours: actualHours ?? this.actualHours,
      notes: notes ?? this.notes,
      imageUrls: imageUrls ?? this.imageUrls,
      projectId: projectId ?? this.projectId,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subtasks: subtasks ?? this.subtasks,
      dependencies: dependencies ?? this.dependencies,
      tags: tags ?? this.tags,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
      completedAt: completedAt ?? this.completedAt,
      order: order ?? this.order,
      assignedUserName: assignedUserName ?? this.assignedUserName,
      assignedUserAvatar: assignedUserAvatar ?? this.assignedUserAvatar,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        priority,
        dueDate,
        estimatedHours,
        actualHours,
        notes,
        imageUrls,
        projectId,
        assignedUserId,
        createdAt,
        updatedAt,
        subtasks,
        dependencies,
        tags,
        comments,
        attachments,
        completedAt,
        order,
        assignedUserName,
        assignedUserAvatar,
      ];
}