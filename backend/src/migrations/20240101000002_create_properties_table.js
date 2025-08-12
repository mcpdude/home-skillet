/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('properties', function (table) {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.string('name', 200).notNullable();
    table.text('description');
    table.string('address', 500).notNullable();
    table.string('type', 50).notNullable(); // residential, commercial, etc.
    table.integer('bedrooms');
    table.integer('bathrooms');
    table.integer('square_feet');
    table.decimal('lot_size', 10, 2);
    table.integer('year_built');
    table.integer('owner_id').unsigned().notNullable();
    table.timestamps(true, true);
    
    // Foreign key constraint
    table.foreign('owner_id').references('id').inTable('users').onDelete('CASCADE');
    
    // Supabase-specific optimizations
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