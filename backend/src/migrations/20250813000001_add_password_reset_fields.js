/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.alterTable('users', function(table) {
    table.string('reset_password_token').nullable();
    table.timestamp('reset_password_expires').nullable();
    
    // Add index on reset token for fast lookups
    table.index('reset_password_token', 'idx_users_reset_token');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.alterTable('users', function(table) {
    table.dropIndex('reset_password_token', 'idx_users_reset_token');
    table.dropColumn('reset_password_token');
    table.dropColumn('reset_password_expires');
  });
};