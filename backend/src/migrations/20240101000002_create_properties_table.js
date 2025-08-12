/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('properties', function (table) {
    if (knex.client.config.client === 'sqlite3') {
      table.string('id').primary();
      table.string('owner_id').notNullable();
    } else {
      table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
      table.integer('owner_id').unsigned().notNullable();
    }
    
    table.string('name', 200).notNullable();
    table.text('description');
    table.string('address', 500).notNullable();
    table.string('type', 50).notNullable(); // residential, commercial, etc.
    table.integer('bedrooms');
    table.integer('bathrooms');
    table.integer('square_feet');
    table.decimal('lot_size', 10, 2);
    table.integer('year_built');
    table.timestamps(true, true);
    
    // Foreign key constraint
    table.foreign('owner_id').references('id').inTable('users').onDelete('CASCADE');
    
    // Indexes for efficient queries
    table.index(['owner_id'], 'idx_properties_owner_id');
    table.index(['type'], 'idx_properties_type');
    table.index(['created_at'], 'idx_properties_created_at');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTableIfExists('properties');
};