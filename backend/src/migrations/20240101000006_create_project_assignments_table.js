/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('project_assignments', function (table) {
    table.increments('id').primary();
    table.uuid('project_id').notNullable();
    table.integer('user_id').unsigned().notNullable();
    table.string('role', 50).notNullable(); // lead, contributor, viewer
    table.timestamps(true, true);
    
    // Foreign key constraints
    table.foreign('project_id').references('id').inTable('projects').onDelete('CASCADE');
    table.foreign('user_id').references('id').inTable('users').onDelete('CASCADE');
    
    // Unique constraint to prevent duplicate assignments
    table.unique(['project_id', 'user_id'], 'unique_project_user_assignment');
    
    // Supabase-specific optimizations
    table.index(['project_id'], 'idx_project_assignments_project_id');
    table.index(['user_id'], 'idx_project_assignments_user_id');
    table.index(['role'], 'idx_project_assignments_role');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTableIfExists('project_assignments');
};