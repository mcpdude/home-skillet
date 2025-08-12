import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'project_assignment.g.dart';

enum ProjectRole {
  @JsonValue('owner')
  owner,
  @JsonValue('admin')
  admin,
  @JsonValue('editor')
  editor,
  @JsonValue('viewer')
  viewer,
  @JsonValue('contributor')
  contributor,
}

extension ProjectRoleExtension on ProjectRole {
  String get displayName {
    switch (this) {
      case ProjectRole.owner:
        return 'Owner';
      case ProjectRole.admin:
        return 'Admin';
      case ProjectRole.editor:
        return 'Editor';
      case ProjectRole.viewer:
        return 'Viewer';
      case ProjectRole.contributor:
        return 'Contributor';
    }
  }

  bool get canEdit {
    return this == ProjectRole.owner || 
           this == ProjectRole.admin || 
           this == ProjectRole.editor;
  }

  bool get canDelete {
    return this == ProjectRole.owner || this == ProjectRole.admin;
  }

  bool get canAssignTasks {
    return this == ProjectRole.owner || 
           this == ProjectRole.admin || 
           this == ProjectRole.editor;
  }

  bool get canManageUsers {
    return this == ProjectRole.owner || this == ProjectRole.admin;
  }

  bool get canViewOnly {
    return this == ProjectRole.viewer;
  }
}

@JsonSerializable()
class ProjectAssignment extends Equatable {
  const ProjectAssignment({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.role,
    required this.assignedAt,
    this.assignedBy,
    this.updatedAt,
    this.userName,
    this.userEmail,
    this.userAvatar,
    this.isActive = true,
    this.permissions = const [],
  });

  final String id;
  
  @JsonKey(name: 'project_id')
  final String projectId;
  
  @JsonKey(name: 'user_id')
  final String userId;
  
  final ProjectRole role;
  
  @JsonKey(name: 'assigned_at')
  final DateTime assignedAt;
  
  @JsonKey(name: 'assigned_by')
  final String? assignedBy;
  
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  
  // User information (populated from joins or cached)
  @JsonKey(name: 'user_name')
  final String? userName;
  
  @JsonKey(name: 'user_email')
  final String? userEmail;
  
  @JsonKey(name: 'user_avatar')
  final String? userAvatar;
  
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  // Additional granular permissions
  final List<String> permissions;

  // Computed properties
  bool get canEdit => role.canEdit && isActive;
  bool get canDelete => role.canDelete && isActive;
  bool get canAssignTasks => role.canAssignTasks && isActive;
  bool get canManageUsers => role.canManageUsers && isActive;
  bool get canViewOnly => role.canViewOnly;
  
  String get displayName => userName ?? userEmail ?? userId;
  
  bool hasPermission(String permission) {
    return permissions.contains(permission) || _hasRoleBasedPermission(permission);
  }
  
  bool _hasRoleBasedPermission(String permission) {
    switch (permission) {
      case 'read':
        return true; // All roles can read
      case 'edit':
        return canEdit;
      case 'delete':
        return canDelete;
      case 'assign_tasks':
        return canAssignTasks;
      case 'manage_users':
        return canManageUsers;
      default:
        return false;
    }
  }

  factory ProjectAssignment.fromJson(Map<String, dynamic> json) => _$ProjectAssignmentFromJson(json);
  
  Map<String, dynamic> toJson() => _$ProjectAssignmentToJson(this);

  ProjectAssignment copyWith({
    String? id,
    String? projectId,
    String? userId,
    ProjectRole? role,
    DateTime? assignedAt,
    String? assignedBy,
    DateTime? updatedAt,
    String? userName,
    String? userEmail,
    String? userAvatar,
    bool? isActive,
    List<String>? permissions,
  }) {
    return ProjectAssignment(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      assignedAt: assignedAt ?? this.assignedAt,
      assignedBy: assignedBy ?? this.assignedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userAvatar: userAvatar ?? this.userAvatar,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        userId,
        role,
        assignedAt,
        assignedBy,
        updatedAt,
        userName,
        userEmail,
        userAvatar,
        isActive,
        permissions,
      ];
}

@JsonSerializable()
class ProjectInvitation extends Equatable {
  const ProjectInvitation({
    required this.id,
    required this.projectId,
    required this.email,
    required this.role,
    required this.invitedBy,
    required this.invitedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.expiresAt,
    this.token,
    this.message,
  });

  final String id;
  
  @JsonKey(name: 'project_id')
  final String projectId;
  
  final String email;
  final ProjectRole role;
  
  @JsonKey(name: 'invited_by')
  final String invitedBy;
  
  @JsonKey(name: 'invited_at')
  final DateTime invitedAt;
  
  @JsonKey(name: 'accepted_at')
  final DateTime? acceptedAt;
  
  @JsonKey(name: 'rejected_at')
  final DateTime? rejectedAt;
  
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;
  
  final String? token;
  final String? message;

  bool get isPending => acceptedAt == null && rejectedAt == null;
  bool get isAccepted => acceptedAt != null;
  bool get isRejected => rejectedAt != null;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isValid => isPending && !isExpired;

  factory ProjectInvitation.fromJson(Map<String, dynamic> json) => _$ProjectInvitationFromJson(json);
  
  Map<String, dynamic> toJson() => _$ProjectInvitationToJson(this);

  @override
  List<Object?> get props => [
        id,
        projectId,
        email,
        role,
        invitedBy,
        invitedAt,
        acceptedAt,
        rejectedAt,
        expiresAt,
        token,
        message,
      ];
}