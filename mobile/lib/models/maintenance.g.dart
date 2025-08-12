// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceSchedule _$MaintenanceScheduleFromJson(Map<String, dynamic> json) =>
    MaintenanceSchedule(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      frequency: $enumDecode(_$MaintenanceFrequencyEnumMap, json['frequency']),
      customIntervalDays: (json['customIntervalDays'] as num?)?.toInt(),
      priority: $enumDecode(_$MaintenancePriorityEnumMap, json['priority']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastCompleted: json['lastCompleted'] == null
          ? null
          : DateTime.parse(json['lastCompleted'] as String),
      nextDue: DateTime.parse(json['nextDue'] as String),
      isActive: json['isActive'] as bool? ?? true,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      estimatedDuration: (json['estimatedDuration'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$MaintenanceScheduleToJson(
        MaintenanceSchedule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'propertyId': instance.propertyId,
      'title': instance.title,
      'description': instance.description,
      'frequency': _$MaintenanceFrequencyEnumMap[instance.frequency]!,
      'customIntervalDays': instance.customIntervalDays,
      'priority': _$MaintenancePriorityEnumMap[instance.priority]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'lastCompleted': instance.lastCompleted?.toIso8601String(),
      'nextDue': instance.nextDue.toIso8601String(),
      'isActive': instance.isActive,
      'tags': instance.tags,
      'estimatedCost': instance.estimatedCost,
      'estimatedDuration': instance.estimatedDuration,
      'notes': instance.notes,
    };

const _$MaintenanceFrequencyEnumMap = {
  MaintenanceFrequency.weekly: 'weekly',
  MaintenanceFrequency.monthly: 'monthly',
  MaintenanceFrequency.quarterly: 'quarterly',
  MaintenanceFrequency.semiAnnually: 'semi_annually',
  MaintenanceFrequency.annually: 'annually',
  MaintenanceFrequency.custom: 'custom',
};

const _$MaintenancePriorityEnumMap = {
  MaintenancePriority.low: 'low',
  MaintenancePriority.medium: 'medium',
  MaintenancePriority.high: 'high',
  MaintenancePriority.critical: 'critical',
};

MaintenanceTask _$MaintenanceTaskFromJson(Map<String, dynamic> json) =>
    MaintenanceTask(
      id: json['id'] as String,
      scheduleId: json['scheduleId'] as String,
      propertyId: json['propertyId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: $enumDecode(_$MaintenanceStatusEnumMap, json['status']),
      priority: $enumDecode(_$MaintenancePriorityEnumMap, json['priority']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      completedBy: json['completedBy'] as String?,
      notes: json['notes'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      actualCost: (json['actualCost'] as num?)?.toDouble(),
      actualDuration: (json['actualDuration'] as num?)?.toInt(),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$MaintenanceTaskToJson(MaintenanceTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scheduleId': instance.scheduleId,
      'propertyId': instance.propertyId,
      'title': instance.title,
      'description': instance.description,
      'dueDate': instance.dueDate.toIso8601String(),
      'status': _$MaintenanceStatusEnumMap[instance.status]!,
      'priority': _$MaintenancePriorityEnumMap[instance.priority]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'completedBy': instance.completedBy,
      'notes': instance.notes,
      'attachments': instance.attachments,
      'actualCost': instance.actualCost,
      'actualDuration': instance.actualDuration,
      'tags': instance.tags,
    };

const _$MaintenanceStatusEnumMap = {
  MaintenanceStatus.active: 'active',
  MaintenanceStatus.completed: 'completed',
  MaintenanceStatus.overdue: 'overdue',
  MaintenanceStatus.skipped: 'skipped',
  MaintenanceStatus.paused: 'paused',
};

CreateMaintenanceScheduleRequest _$CreateMaintenanceScheduleRequestFromJson(
        Map<String, dynamic> json) =>
    CreateMaintenanceScheduleRequest(
      propertyId: json['propertyId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      frequency: $enumDecode(_$MaintenanceFrequencyEnumMap, json['frequency']),
      customIntervalDays: (json['customIntervalDays'] as num?)?.toInt(),
      priority: $enumDecode(_$MaintenancePriorityEnumMap, json['priority']),
      nextDue: DateTime.parse(json['nextDue'] as String),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      estimatedDuration: (json['estimatedDuration'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$CreateMaintenanceScheduleRequestToJson(
        CreateMaintenanceScheduleRequest instance) =>
    <String, dynamic>{
      'propertyId': instance.propertyId,
      'title': instance.title,
      'description': instance.description,
      'frequency': _$MaintenanceFrequencyEnumMap[instance.frequency]!,
      'customIntervalDays': instance.customIntervalDays,
      'priority': _$MaintenancePriorityEnumMap[instance.priority]!,
      'nextDue': instance.nextDue.toIso8601String(),
      'tags': instance.tags,
      'estimatedCost': instance.estimatedCost,
      'estimatedDuration': instance.estimatedDuration,
      'notes': instance.notes,
    };

CompleteMaintenanceTaskRequest _$CompleteMaintenanceTaskRequestFromJson(
        Map<String, dynamic> json) =>
    CompleteMaintenanceTaskRequest(
      taskId: json['taskId'] as String,
      notes: json['notes'] as String?,
      actualCost: (json['actualCost'] as num?)?.toDouble(),
      actualDuration: (json['actualDuration'] as num?)?.toInt(),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CompleteMaintenanceTaskRequestToJson(
        CompleteMaintenanceTaskRequest instance) =>
    <String, dynamic>{
      'taskId': instance.taskId,
      'notes': instance.notes,
      'actualCost': instance.actualCost,
      'actualDuration': instance.actualDuration,
      'attachments': instance.attachments,
    };
