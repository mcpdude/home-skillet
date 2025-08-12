/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('maintenance_schedules', function (table) {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('property_id').notNullable();
    table.string('title', 200).notNullable();
    table.text('description');
    table.string('frequency', 50).notNullable(); // daily, weekly, monthly, quarterly, yearly, custom
    table.integer('frequency_value').defaultTo(1); // for custom frequencies
    table.string('category', 100); // hvac, plumbing, electrical, landscaping, etc.
    table.date('next_due_date').notNullable();
    table.date('last_completed_date');
    table.boolean('is_active').defaultTo(true);
    table.decimal('estimated_cost', 10, 2);
    table.integer('assigned_to').unsigned();
    table.integer('created_by').unsigned().notNullable();
    table.timestamps(true, true);
    
    // Foreign key constraints
    table.foreign('property_id').references('id').inTable('properties').onDelete('CASCADE');
    table.foreign('assigned_to').references('id').inTable('users').onDelete('SET NULL');
    table.foreign('created_by').references('id').inTable('users').onDelete('CASCADE');
    
    // Supabase-specific optimizations
    table.index(['property_id'], 'idx_maintenance_schedules_property_id');
    table.index(['next_due_date'], 'idx_maintenance_schedules_next_due_date');
    table.index(['category'], 'idx_maintenance_schedules_category');
    table.index(['is_active'], 'idx_maintenance_schedules_is_active');
    table.index(['assigned_to'], 'idx_maintenance_schedules_assigned_to');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTableIfExists('maintenance_schedules');
};