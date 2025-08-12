// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Project _$ProjectFromJson(Map<String, dynamic> json) => Project(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: $enumDecode(_$ProjectStatusEnumMap, json['status']),
      priority: $enumDecode(_$ProjectPriorityEnumMap, json['priority']),
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble(),
      actualCost: (json['actual_cost'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      imageUrls: (json['image_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      propertyId: json['property_id'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((e) => Task.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      assignedUserIds: (json['assigned_user_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      templateId: json['template_id'] as String?,
      isTemplate: json['is_template'] as bool? ?? false,
      collaborationEnabled: json['collaboration_enabled'] as bool? ?? true,
      lastActivity: json['last_activity'] == null
          ? null
          : DateTime.parse(json['last_activity'] as String),
    );

Map<String, dynamic> _$ProjectToJson(Project instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'status': _$ProjectStatusEnumMap[instance.status]!,
      'priority': _$ProjectPriorityEnumMap[instance.priority]!,
      'start_date': instance.startDate?.toIso8601String(),
      'end_date': instance.endDate?.toIso8601String(),
      'due_date': instance.dueDate?.toIso8601String(),
      'estimated_cost': instance.estimatedCost,
      'actual_cost': instance.actualCost,
      'notes': instance.notes,
      'image_urls': instance.imageUrls,
      'property_id': instance.propertyId,
      'user_id': instance.userId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'tasks': instance.tasks,
      'assigned_user_ids': instance.assignedUserIds,
      'tags': instance.tags,
      'template_id': instance.templateId,
      'is_template': instance.isTemplate,
      'collaboration_enabled': instance.collaborationEnabled,
      'last_activity': instance.lastActivity?.toIso8601String(),
    };

const _$ProjectStatusEnumMap = {
  ProjectStatus.planned: 'planned',
  ProjectStatus.inProgress: 'in_progress',
  ProjectStatus.completed: 'completed',
  ProjectStatus.onHold: 'on_hold',
  ProjectStatus.cancelled: 'cancelled',
};

const _$ProjectPriorityEnumMap = {
  ProjectPriority.low: 'low',
  ProjectPriority.medium: 'medium',
  ProjectPriority.high: 'high',
  ProjectPriority.urgent: 'urgent',
};
