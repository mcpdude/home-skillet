/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('projects', function (table) {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('property_id').notNullable();
    table.string('title', 200).notNullable();
    table.text('description');
    table.string('status', 50).notNullable().defaultTo('pending'); // pending, in_progress, completed, cancelled
    table.string('priority', 20).notNullable().defaultTo('medium'); // low, medium, high, urgent
    table.decimal('budget', 12, 2);
    table.decimal('actual_cost', 12, 2);
    table.date('start_date');
    table.date('end_date');
    table.date('due_date');
    table.integer('created_by').unsigned().notNullable();
    table.timestamps(true, true);
    
    // Foreign key constraints
    table.foreign('property_id').references('id').inTable('properties').onDelete('CASCADE');
    table.foreign('created_by').references('id').inTable('users').onDelete('CASCADE');
    
    // Supabase-specific optimizations
    table.index(['property_id'], 'idx_projects_property_id');
    table.index(['status'], 'idx_projects_status');
    table.index(['priority'], 'idx_projects_priority');
    table.index(['created_by'], 'idx_projects_created_by');
    table.index(['due_date'], 'idx_projects_due_date');
    table.index(['created_at'], 'idx_projects_created_at');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTableIfExists('projects');
};