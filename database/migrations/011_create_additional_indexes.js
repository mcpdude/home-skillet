/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema
    // Additional composite indexes for common query patterns
    .table('projects', function(table) {
      table.index(['property_id', 'status', 'priority'], 'idx_projects_property_status_priority');
      table.index(['property_id', 'category', 'status'], 'idx_projects_property_category_status');
      table.index(['created_at', 'property_id'], 'idx_projects_created_property');
      table.index(['updated_at', 'property_id'], 'idx_projects_updated_property');
    })
    .table('tasks', function(table) {
      table.index(['project_id', 'is_completed', 'due_date'], 'idx_tasks_project_completed_due');
      table.index(['assigned_to_user_id', 'is_completed', 'due_date'], 'idx_tasks_assignee_completed_due');
      table.index(['project_id', 'assigned_to_user_id'], 'idx_tasks_project_assignee');
    })
    .table('maintenance_schedules', function(table) {
      table.index(['property_id', 'category', 'is_active'], 'idx_maintenance_schedules_property_category_active');
      table.index(['default_assignee_id', 'is_active'], 'idx_maintenance_schedules_assignee_active');
    })
    .table('maintenance_records', function(table) {
      table.index(['property_id', 'category', 'completed_date'], 'idx_maintenance_records_property_category_date');
      table.index(['performed_by_user_id', 'completed_date'], 'idx_maintenance_records_performer_date');
      table.index(['system_or_appliance', 'property_id'], 'idx_maintenance_records_system_property');
    })
    .table('documents', function(table) {
      table.index(['property_id', 'category', 'document_status'], 'idx_documents_property_category_status');
      table.index(['expiration_date', 'is_expired'], 'idx_documents_expiration_status');
      table.index(['project_id', 'category'], 'idx_documents_project_category');
      table.index(['vendor_id', 'document_date'], 'idx_documents_vendor_date');
    })
    .table('user_property_roles', function(table) {
      table.index(['property_id', 'role', 'is_active'], 'idx_upr_property_role_active');
      table.index(['user_id', 'is_active'], 'idx_upr_user_active');
      table.index(['invited_by_user_id', 'invitation_status'], 'idx_upr_inviter_status');
    })
    .table('vendors', function(table) {
      table.index(['vendor_status', 'relationship_type'], 'idx_vendors_status_relationship');
      table.index(['emergency_services', 'vendor_status'], 'idx_vendors_emergency_status');
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema
    .table('projects', function(table) {
      table.dropIndex([], 'idx_projects_property_status_priority');
      table.dropIndex([], 'idx_projects_property_category_status');
      table.dropIndex([], 'idx_projects_created_property');
      table.dropIndex([], 'idx_projects_updated_property');
    })
    .table('tasks', function(table) {
      table.dropIndex([], 'idx_tasks_project_completed_due');
      table.dropIndex([], 'idx_tasks_assignee_completed_due');
      table.dropIndex([], 'idx_tasks_project_assignee');
    })
    .table('maintenance_schedules', function(table) {
      table.dropIndex([], 'idx_maintenance_schedules_property_category_active');
      table.dropIndex([], 'idx_maintenance_schedules_assignee_active');
    })
    .table('maintenance_records', function(table) {
      table.dropIndex([], 'idx_maintenance_records_property_category_date');
      table.dropIndex([], 'idx_maintenance_records_performer_date');
      table.dropIndex([], 'idx_maintenance_records_system_property');
    })
    .table('documents', function(table) {
      table.dropIndex([], 'idx_documents_property_category_status');
      table.dropIndex([], 'idx_documents_expiration_status');
      table.dropIndex([], 'idx_documents_project_category');
      table.dropIndex([], 'idx_documents_vendor_date');
    })
    .table('user_property_roles', function(table) {
      table.dropIndex([], 'idx_upr_property_role_active');
      table.dropIndex([], 'idx_upr_user_active');
      table.dropIndex([], 'idx_upr_inviter_status');
    })
    .table('vendors', function(table) {
      table.dropIndex([], 'idx_vendors_status_relationship');
      table.dropIndex([], 'idx_vendors_emergency_status');
    });
};