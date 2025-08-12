/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.table('users', function (table) {
    table.string('user_type', 50).defaultTo('tenant'); // property_owner, contractor, tenant
    table.timestamp('last_login_at');
    
    // Index for user_type
    table.index(['user_type'], 'idx_users_user_type');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.table('users', function (table) {
    table.dropIndex(['user_type'], 'idx_users_user_type');
    table.dropColumn('user_type');
    table.dropColumn('last_login_at');
  });
};
