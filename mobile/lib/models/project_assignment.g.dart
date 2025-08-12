// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_assignment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectAssignment _$ProjectAssignmentFromJson(Map<String, dynamic> json) =>
    ProjectAssignment(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      userId: json['user_id'] as String,
      role: $enumDecode(_$ProjectRoleEnumMap, json['role']),
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      assignedBy: json['assigned_by'] as String?,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      userName: json['user_name'] as String?,
      userEmail: json['user_email'] as String?,
      userAvatar: json['user_avatar'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ProjectAssignmentToJson(ProjectAssignment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'project_id': instance.projectId,
      'user_id': instance.userId,
      'role': _$ProjectRoleEnumMap[instance.role]!,
      'assigned_at': instance.assignedAt.toIso8601String(),
      'assigned_by': instance.assignedBy,
      'updated_at': instance.updatedAt?.toIso8601String(),
      'user_name': instance.userName,
      'user_email': instance.userEmail,
      'user_avatar': instance.userAvatar,
      'is_active': instance.isActive,
      'permissions': instance.permissions,
    };

const _$ProjectRoleEnumMap = {
  ProjectRole.owner: 'owner',
  ProjectRole.admin: 'admin',
  ProjectRole.editor: 'editor',
  ProjectRole.viewer: 'viewer',
  ProjectRole.contributor: 'contributor',
};

ProjectInvitation _$ProjectInvitationFromJson(Map<String, dynamic> json) =>
    ProjectInvitation(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      email: json['email'] as String,
      role: $enumDecode(_$ProjectRoleEnumMap, json['role']),
      invitedBy: json['invited_by'] as String,
      invitedAt: DateTime.parse(json['invited_at'] as String),
      acceptedAt: json['accepted_at'] == null
          ? null
          : DateTime.parse(json['accepted_at'] as String),
      rejectedAt: json['rejected_at'] == null
          ? null
          : DateTime.parse(json['rejected_at'] as String),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      token: json['token'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$ProjectInvitationToJson(ProjectInvitation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'project_id': instance.projectId,
      'email': instance.email,
      'role': _$ProjectRoleEnumMap[instance.role]!,
      'invited_by': instance.invitedBy,
      'invited_at': instance.invitedAt.toIso8601String(),
      'accepted_at': instance.acceptedAt?.toIso8601String(),
      'rejected_at': instance.rejectedAt?.toIso8601String(),
      'expires_at': instance.expiresAt?.toIso8601String(),
      'token': instance.token,
      'message': instance.message,
    };
