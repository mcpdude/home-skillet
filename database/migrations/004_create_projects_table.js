/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('projects', function(table) {
    // Primary key
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    
    // Property association (multi-tenant isolation)
    table.uuid('property_id').notNullable().references('id').inTable('properties').onDelete('CASCADE');
    
    // Project basic information
    table.string('title', 255).notNullable();
    table.text('description');
    table.string('category', 100).notNullable(); // plumbing, electrical, cosmetic, hvac, etc.
    table.string('subcategory', 100); // bathroom_renovation, kitchen_upgrade, etc.
    
    // Project classification and priority
    table.enum('priority', ['low', 'medium', 'high', 'urgent']).defaultTo('medium');
    table.enum('project_type', ['maintenance', 'repair', 'improvement', 'renovation']).notNullable();
    table.enum('complexity', ['simple', 'moderate', 'complex']).defaultTo('moderate');
    
    // Status and progress tracking
    table.enum('status', ['not_started', 'planning', 'in_progress', 'on_hold', 'completed', 'cancelled']).defaultTo('not_started');
    table.integer('progress_percentage').defaultTo(0).checkBetween([0, 100]);
    
    // Timeline information
    table.date('planned_start_date');
    table.date('planned_end_date');
    table.date('actual_start_date');
    table.date('actual_end_date');
    table.integer('estimated_hours'); // Time estimation in hours
    table.integer('actual_hours'); // Actual time spent
    
    // Financial information
    table.decimal('estimated_cost', 12, 2);
    table.decimal('actual_cost', 12, 2);
    table.decimal('budget_limit', 12, 2);
    table.boolean('requires_permits').defaultTo(false);
    table.json('permit_info').defaultTo('{}'); // Permit numbers, status, dates
    
    // Location and scope
    table.string('location_in_property', 200); // "Master Bathroom", "Kitchen", "Exterior - Front Yard"
    table.json('affected_areas').defaultTo('[]'); // Array of specific areas/rooms
    table.json('required_materials').defaultTo('[]'); // Materials list with quantities
    table.json('required_tools').defaultTo('[]'); // Tools needed
    
    // Media and documentation
    table.json('photos').defaultTo('{}'); // {before: [], during: [], after: []}
    table.json('attachments').defaultTo('[]'); // Additional files, plans, etc.
    
    // Project relationships and dependencies
    table.uuid('parent_project_id').references('id').inTable('projects'); // For sub-projects
    table.json('dependent_project_ids').defaultTo('[]'); // Projects that depend on this one
    
    // Quality and completion
    table.integer('quality_rating').checkBetween([1, 5]); // 1-5 stars rating after completion
    table.text('completion_notes');
    table.boolean('warranty_applicable').defaultTo(false);
    table.json('warranty_info').defaultTo('{}'); // Warranty details, expiration dates
    
    // Creator and ownership
    table.uuid('created_by_user_id').notNullable().references('id').inTable('users');
    table.uuid('primary_assignee_id').references('id').inTable('users'); // Main responsible person
    
    // Audit and versioning
    table.timestamps(true, true);
    table.uuid('last_modified_by').references('id').inTable('users');
    
    // Indexes for performance
    table.index(['property_id'], 'idx_projects_property');
    table.index(['status'], 'idx_projects_status');
    table.index(['priority'], 'idx_projects_priority');
    table.index(['category'], 'idx_projects_category');
    table.index(['created_by_user_id'], 'idx_projects_creator');
    table.index(['primary_assignee_id'], 'idx_projects_assignee');
    table.index(['planned_start_date'], 'idx_projects_planned_start');
    table.index(['actual_end_date'], 'idx_projects_actual_end');
    table.index(['parent_project_id'], 'idx_projects_parent');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTable('projects');
};