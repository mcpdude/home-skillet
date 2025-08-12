/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('project_assignments', function(table) {
    // Primary key
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    
    // Foreign key relationships
    table.uuid('project_id').notNullable().references('id').inTable('projects').onDelete('CASCADE');
    table.uuid('user_id').references('id').inTable('users').onDelete('CASCADE'); // NULL for vendor assignments
    table.uuid('vendor_id').references('id').inTable('vendors').onDelete('CASCADE'); // NULL for user assignments
    
    // Assignment details
    table.enum('assignee_type', ['user', 'vendor']).notNullable();
    table.enum('role_in_project', ['lead', 'contributor', 'reviewer', 'observer', 'contractor']).defaultTo('contributor');
    table.text('assignment_notes'); // Specific instructions or notes for this assignment
    
    // Assignment status
    table.enum('assignment_status', ['assigned', 'accepted', 'in_progress', 'completed', 'declined', 'removed']).defaultTo('assigned');
    table.timestamp('assigned_at').defaultTo(knex.fn.now());
    table.timestamp('accepted_at');
    table.timestamp('started_at');
    table.timestamp('completed_at');
    
    // Responsibility and access
    table.json('responsibilities').defaultTo('[]'); // Specific tasks or areas of responsibility
    table.json('permissions').defaultTo('{}'); // Project-specific permissions override
    table.boolean('can_assign_others').defaultTo(false);
    table.boolean('can_edit_project').defaultTo(false);
    table.boolean('receives_notifications').defaultTo(true);
    
    // Time and effort tracking
    table.integer('estimated_hours');
    table.integer('actual_hours');
    table.decimal('hourly_rate', 8, 2); // For vendor assignments or contractor family members
    table.decimal('estimated_cost', 10, 2);
    table.decimal('actual_cost', 10, 2);
    
    // Performance and quality
    table.integer('performance_rating').checkBetween([1, 5]); // Rating after completion
    table.text('performance_notes');
    table.boolean('would_work_with_again').defaultTo(true); // For vendors
    
    // Communication and coordination
    table.timestamp('last_check_in_at');
    table.text('last_status_update');
    table.boolean('requires_supervision').defaultTo(false);
    table.uuid('supervisor_user_id').references('id').inTable('users');
    
    // Availability and scheduling
    table.json('availability_schedule').defaultTo('{}'); // When assignee is available to work
    table.date('available_start_date');
    table.date('available_end_date');
    table.integer('max_hours_per_week');
    
    // Vendor-specific fields
    table.string('contract_number', 100); // For formal contracts
    table.decimal('quoted_price', 12, 2); // Original quote from vendor
    table.json('deliverables').defaultTo('[]'); // Specific deliverables expected
    table.boolean('insurance_verified').defaultTo(false);
    table.boolean('license_verified').defaultTo(false);
    table.date('verification_date');
    
    // Emergency and priority handling
    table.boolean('emergency_contact').defaultTo(false); // Can be contacted for emergencies
    table.string('emergency_phone', 20);
    table.enum('priority_level', ['low', 'medium', 'high']).defaultTo('medium');
    
    // Completion and handoff
    table.text('completion_notes');
    table.json('handoff_items').defaultTo('[]'); // Items to hand off to next assignee or property owner
    table.boolean('requires_final_approval').defaultTo(false);
    table.uuid('approved_by_user_id').references('id').inTable('users');
    table.timestamp('approved_at');
    
    // Audit fields
    table.uuid('assigned_by_user_id').notNullable().references('id').inTable('users');
    table.timestamps(true, true);
    table.uuid('last_modified_by').references('id').inTable('users');
    
    // Constraints
    table.check('(user_id IS NOT NULL) OR (vendor_id IS NOT NULL)'); // Must have either user or vendor
    table.check('NOT (user_id IS NOT NULL AND vendor_id IS NOT NULL)'); // Cannot have both
    
    // Indexes for performance
    table.index(['project_id'], 'idx_project_assignments_project');
    table.index(['user_id'], 'idx_project_assignments_user');
    table.index(['vendor_id'], 'idx_project_assignments_vendor');
    table.index(['assignee_type'], 'idx_project_assignments_type');
    table.index(['assignment_status'], 'idx_project_assignments_status');
    table.index(['role_in_project'], 'idx_project_assignments_role');
    table.index(['assigned_by_user_id'], 'idx_project_assignments_assigned_by');
    table.index(['assigned_at'], 'idx_project_assignments_assigned_at');
    table.index(['project_id', 'assignee_type'], 'idx_project_assignments_project_type');
    table.index(['project_id', 'assignment_status'], 'idx_project_assignments_project_status');
    
    // Unique constraint to prevent duplicate assignments
    table.unique(['project_id', 'user_id'], 'unique_project_user_assignment');
    table.unique(['project_id', 'vendor_id'], 'unique_project_vendor_assignment');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTable('project_assignments');
};