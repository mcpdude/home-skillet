import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'maintenance.g.dart';

/// Represents how frequently maintenance should be performed
enum MaintenanceFrequency {
  @JsonValue('weekly')
  weekly,
  @JsonValue('monthly')
  monthly,
  @JsonValue('quarterly')
  quarterly,
  @JsonValue('semi_annually')
  semiAnnually,
  @JsonValue('annually')
  annually,
  @JsonValue('custom')
  custom,
}

/// Represents the status of a maintenance schedule or task
enum MaintenanceStatus {
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('overdue')
  overdue,
  @JsonValue('skipped')
  skipped,
  @JsonValue('paused')
  paused,
}

/// Represents the priority level of maintenance
enum MaintenancePriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

/// Represents a maintenance schedule for recurring tasks
@JsonSerializable()
class MaintenanceSchedule extends Equatable {
  final String id;
  final String propertyId;
  final String title;
  final String description;
  final MaintenanceFrequency frequency;
  final int? customIntervalDays;
  final MaintenancePriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastCompleted;
  final DateTime nextDue;
  final bool isActive;
  final List<String> tags;
  final double? estimatedCost;
  final int? estimatedDuration; // in minutes
  final String? notes;

  const MaintenanceSchedule({
    required this.id,
    required this.propertyId,
    required this.title,
    required this.description,
    required this.frequency,
    this.customIntervalDays,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.lastCompleted,
    required this.nextDue,
    this.isActive = true,
    this.tags = const [],
    this.estimatedCost,
    this.estimatedDuration,
    this.notes,
  });

  factory MaintenanceSchedule.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceScheduleFromJson(json);

  Map<String, dynamic> toJson() => _$MaintenanceScheduleToJson(this);

  MaintenanceSchedule copyWith({
    String? id,
    String? propertyId,
    String? title,
    String? description,
    MaintenanceFrequency? frequency,
    int? customIntervalDays,
    MaintenancePriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastCompleted,
    DateTime? nextDue,
    bool? isActive,
    List<String>? tags,
    double? estimatedCost,
    int? estimatedDuration,
    String? notes,
  }) {
    return MaintenanceSchedule(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      title: title ?? this.title,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      customIntervalDays: customIntervalDays ?? this.customIntervalDays,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      nextDue: nextDue ?? this.nextDue,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      notes: notes ?? this.notes,
    );
  }

  /// Returns true if the maintenance is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(nextDue) && isActive;
  }

  /// Returns true if the maintenance is due soon (within 7 days)
  bool get isDueSoon {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return nextDue.isBefore(weekFromNow) && nextDue.isAfter(now) && isActive;
  }

  /// Calculates the next due date based on frequency
  DateTime calculateNextDueDate(DateTime fromDate) {
    switch (frequency) {
      case MaintenanceFrequency.weekly:
        return fromDate.add(const Duration(days: 7));
      case MaintenanceFrequency.monthly:
        return DateTime(fromDate.year, fromDate.month + 1, fromDate.day);
      case MaintenanceFrequency.quarterly:
        return DateTime(fromDate.year, fromDate.month + 3, fromDate.day);
      case MaintenanceFrequency.semiAnnually:
        return DateTime(fromDate.year, fromDate.month + 6, fromDate.day);
      case MaintenanceFrequency.annually:
        return DateTime(fromDate.year + 1, fromDate.month, fromDate.day);
      case MaintenanceFrequency.custom:
        if (customIntervalDays != null) {
          return fromDate.add(Duration(days: customIntervalDays!));
        }
        throw ArgumentError('Custom frequency requires customIntervalDays');
    }
  }

  @override
  List<Object?> get props => [
        id,
        propertyId,
        title,
        description,
        frequency,
        customIntervalDays,
        priority,
        createdAt,
        updatedAt,
        lastCompleted,
        nextDue,
        isActive,
        tags,
        estimatedCost,
        estimatedDuration,
        notes,
      ];
}

/// Represents a specific maintenance task instance
@JsonSerializable()
class MaintenanceTask extends Equatable {
  final String id;
  final String scheduleId;
  final String propertyId;
  final String title;
  final String description;
  final DateTime dueDate;
  final MaintenanceStatus status;
  final MaintenancePriority priority;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? completedBy;
  final String? notes;
  final List<String> attachments;
  final double? actualCost;
  final int? actualDuration; // in minutes
  final List<String> tags;

  const MaintenanceTask({
    required this.id,
    required this.scheduleId,
    required this.propertyId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.completedAt,
    this.completedBy,
    this.notes,
    this.attachments = const [],
    this.actualCost,
    this.actualDuration,
    this.tags = const [],
  });

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceTaskFromJson(json);

  Map<String, dynamic> toJson() => _$MaintenanceTaskToJson(this);

  factory MaintenanceTask.fromSchedule(
    MaintenanceSchedule schedule, {
    required String taskId,
    DateTime? dueDate,
  }) {
    return MaintenanceTask(
      id: taskId,
      scheduleId: schedule.id,
      propertyId: schedule.propertyId,
      title: schedule.title,
      description: schedule.description,
      dueDate: dueDate ?? schedule.nextDue,
      status: MaintenanceStatus.active,
      priority: schedule.priority,
      createdAt: DateTime.now(),
      tags: schedule.tags,
    );
  }

  MaintenanceTask copyWith({
    String? id,
    String? scheduleId,
    String? propertyId,
    String? title,
    String? description,
    DateTime? dueDate,
    MaintenanceStatus? status,
    MaintenancePriority? priority,
    DateTime? createdAt,
    DateTime? completedAt,
    String? completedBy,
    String? notes,
    List<String>? attachments,
    double? actualCost,
    int? actualDuration,
    List<String>? tags,
  }) {
    return MaintenanceTask(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      propertyId: propertyId ?? this.propertyId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      actualCost: actualCost ?? this.actualCost,
      actualDuration: actualDuration ?? this.actualDuration,
      tags: tags ?? this.tags,
    );
  }

  /// Returns true if the task is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(dueDate) && 
           status != MaintenanceStatus.completed;
  }

  /// Returns true if the task is due today
  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year && 
           dueDate.month == now.month && 
           dueDate.day == now.day;
  }

  /// Returns true if the task is due within the next 7 days
  bool get isDueSoon {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return dueDate.isBefore(weekFromNow) && 
           dueDate.isAfter(now) && 
           status != MaintenanceStatus.completed;
  }

  @override
  List<Object?> get props => [
        id,
        scheduleId,
        propertyId,
        title,
        description,
        dueDate,
        status,
        priority,
        createdAt,
        completedAt,
        completedBy,
        notes,
        attachments,
        actualCost,
        actualDuration,
        tags,
      ];
}

/// Represents summary statistics for maintenance
class MaintenanceStats extends Equatable {
  final int totalSchedules;
  final int activeSchedules;
  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;
  final int dueSoonTasks;
  final double totalCost;
  final double averageCostPerTask;
  final int totalDuration; // in minutes
  final double completionRate;

  const MaintenanceStats({
    required this.totalSchedules,
    required this.activeSchedules,
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.dueSoonTasks,
    required this.totalCost,
    required this.averageCostPerTask,
    required this.totalDuration,
    required this.completionRate,
  });

  @override
  List<Object?> get props => [
        totalSchedules,
        activeSchedules,
        totalTasks,
        completedTasks,
        overdueTasks,
        dueSoonTasks,
        totalCost,
        averageCostPerTask,
        totalDuration,
        completionRate,
      ];
}

/// Create maintenance schedule request
@JsonSerializable()
class CreateMaintenanceScheduleRequest extends Equatable {
  final String propertyId;
  final String title;
  final String description;
  final MaintenanceFrequency frequency;
  final int? customIntervalDays;
  final MaintenancePriority priority;
  final DateTime nextDue;
  final List<String> tags;
  final double? estimatedCost;
  final int? estimatedDuration;
  final String? notes;

  const CreateMaintenanceScheduleRequest({
    required this.propertyId,
    required this.title,
    required this.description,
    required this.frequency,
    this.customIntervalDays,
    required this.priority,
    required this.nextDue,
    this.tags = const [],
    this.estimatedCost,
    this.estimatedDuration,
    this.notes,
  });

  factory CreateMaintenanceScheduleRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateMaintenanceScheduleRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateMaintenanceScheduleRequestToJson(this);

  @override
  List<Object?> get props => [
        propertyId,
        title,
        description,
        frequency,
        customIntervalDays,
        priority,
        nextDue,
        tags,
        estimatedCost,
        estimatedDuration,
        notes,
      ];
}

/// Complete maintenance task request
@JsonSerializable()
class CompleteMaintenanceTaskRequest extends Equatable {
  final String taskId;
  final String? notes;
  final double? actualCost;
  final int? actualDuration;
  final List<String>? attachments;

  const CompleteMaintenanceTaskRequest({
    required this.taskId,
    this.notes,
    this.actualCost,
    this.actualDuration,
    this.attachments,
  });

  factory CompleteMaintenanceTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$CompleteMaintenanceTaskRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CompleteMaintenanceTaskRequestToJson(this);

  @override
  List<Object?> get props => [taskId, notes, actualCost, actualDuration, attachments];
}