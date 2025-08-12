/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('users', function(table) {
    // Primary key
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    
    // Authentication fields
    table.string('email', 255).notNullable().unique();
    table.string('password_hash', 255); // nullable for OAuth users
    table.string('provider', 50); // 'local', 'google', 'apple', etc.
    table.string('provider_id', 255); // external provider ID
    
    // Profile information
    table.string('first_name', 100).notNullable();
    table.string('last_name', 100).notNullable();
    table.string('phone', 20);
    table.string('profile_image_url', 500);
    
    // Account status and verification
    table.boolean('is_email_verified').defaultTo(false);
    table.boolean('is_active').defaultTo(true);
    table.timestamp('email_verified_at');
    table.timestamp('last_login_at');
    
    // Preferences
    table.json('preferences').defaultTo('{}');
    table.string('timezone', 50).defaultTo('UTC');
    table.string('language', 10).defaultTo('en');
    
    // Audit fields
    table.timestamps(true, true); // created_at, updated_at
    
    // Indexes
    table.index(['email'], 'idx_users_email');
    table.index(['provider', 'provider_id'], 'idx_users_provider');
    table.index(['is_active'], 'idx_users_active');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTable('users');
};