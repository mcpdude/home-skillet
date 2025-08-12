/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('tasks', function(table) {
    // Primary key
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    
    // Project association
    table.uuid('project_id').notNullable().references('id').inTable('projects').onDelete('CASCADE');
    
    // Task basic information
    table.string('title', 255).notNullable();
    table.text('description');
    table.integer('sort_order').defaultTo(0); // For ordering tasks within a project
    
    // Task status and completion
    table.boolean('is_completed').defaultTo(false);
    table.timestamp('completed_at');
    table.uuid('completed_by_user_id').references('id').inTable('users');
    
    // Task assignment
    table.uuid('assigned_to_user_id').references('id').inTable('users');
    table.date('due_date');
    
    // Task classification
    table.enum('priority', ['low', 'medium', 'high']).defaultTo('medium');
    table.string('category', 100); // Same categories as projects for consistency
    
    // Time and effort tracking
    table.integer('estimated_hours');
    table.integer('actual_hours');
    table.decimal('estimated_cost', 10, 2);
    table.decimal('actual_cost', 10, 2);
    
    // Task dependencies
    table.json('prerequisite_task_ids').defaultTo('[]'); // Tasks that must be completed first
    table.json('dependent_task_ids').defaultTo('[]'); // Tasks that depend on this one
    
    // Materials and tools
    table.json('required_materials').defaultTo('[]'); // Materials needed for this specific task
    table.json('required_tools').defaultTo('[]'); // Tools needed for this specific task
    
    // Quality control and verification
    table.boolean('requires_verification').defaultTo(false);
    table.uuid('verified_by_user_id').references('id').inTable('users');
    table.timestamp('verified_at');
    table.text('verification_notes');
    
    // Documentation
    table.json('photos').defaultTo('[]'); // Photos specific to this task
    table.json('attachments').defaultTo('[]'); // Files, documents, links
    table.text('completion_notes');
    
    // Audit fields
    table.uuid('created_by_user_id').notNullable().references('id').inTable('users');
    table.timestamps(true, true);
    table.uuid('last_modified_by').references('id').inTable('users');
    
    // Indexes for performance
    table.index(['project_id'], 'idx_tasks_project');
    table.index(['is_completed'], 'idx_tasks_completed');
    table.index(['assigned_to_user_id'], 'idx_tasks_assigned_user');
    table.index(['due_date'], 'idx_tasks_due_date');
    table.index(['priority'], 'idx_tasks_priority');
    table.index(['sort_order'], 'idx_tasks_sort_order');
    table.index(['created_by_user_id'], 'idx_tasks_creator');
    table.index(['project_id', 'sort_order'], 'idx_tasks_project_order');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTable('tasks');
};