/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('property_photos', function(table) {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('property_id').notNullable().references('id').inTable('properties').onDelete('CASCADE');
    table.string('filename', 255).notNullable();
    table.string('original_name', 255).notNullable();
    table.string('url', 500).notNullable();
    table.string('file_path', 500).notNullable();
    table.integer('file_size').notNullable();
    table.string('mime_type', 100).notNullable();
    table.boolean('is_primary').defaultTo(false);
    table.text('description');
    table.integer('display_order').defaultTo(0);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    
    // Indexes
    table.index('property_id');
    table.index(['property_id', 'is_primary']);
    table.index(['property_id', 'display_order']);
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTable('property_photos');
};