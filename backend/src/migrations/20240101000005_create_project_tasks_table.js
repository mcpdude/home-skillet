/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('project_tasks', function (table) {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('project_id').notNullable();
    table.string('title', 200).notNullable();
    table.text('description');
    table.string('status', 50).notNullable().defaultTo('pending'); // pending, in_progress, completed
    table.integer('assigned_to').unsigned();
    table.date('due_date');
    table.integer('estimated_hours');
    table.integer('actual_hours');
    table.decimal('cost', 10, 2);
    table.integer('sort_order').defaultTo(0);
    table.timestamps(true, true);
    
    // Foreign key constraints
    table.foreign('project_id').references('id').inTable('projects').onDelete('CASCADE');
    table.foreign('assigned_to').references('id').inTable('users').onDelete('SET NULL');
    
    // Supabase-specific optimizations
    table.index(['project_id'], 'idx_project_tasks_project_id');
    table.index(['status'], 'idx_project_tasks_status');
    table.index(['assigned_to'], 'idx_project_tasks_assigned_to');
    table.index(['due_date'], 'idx_project_tasks_due_date');
    table.index(['sort_order'], 'idx_project_tasks_sort_order');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTableIfExists('project_tasks');
};