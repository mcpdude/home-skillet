/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('property_permissions', function (table) {
    table.increments('id').primary();
    table.uuid('property_id').notNullable();
    table.integer('user_id').unsigned().notNullable();
    table.string('role', 50).notNullable(); // owner, manager, viewer, maintainer
    table.timestamps(true, true);
    
    // Foreign key constraints
    table.foreign('property_id').references('id').inTable('properties').onDelete('CASCADE');
    table.foreign('user_id').references('id').inTable('users').onDelete('CASCADE');
    
    // Unique constraint to prevent duplicate permissions
    table.unique(['property_id', 'user_id'], 'unique_property_user_permission');
    
    // Supabase-specific optimizations
    table.index(['property_id'], 'idx_property_permissions_property_id');
    table.index(['user_id'], 'idx_property_permissions_user_id');
    table.index(['role'], 'idx_property_permissions_role');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTableIfExists('property_permissions');
};