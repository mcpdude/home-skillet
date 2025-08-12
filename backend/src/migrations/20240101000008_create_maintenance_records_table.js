/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('maintenance_records', function (table) {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('schedule_id').notNullable();
    table.date('completed_date').notNullable();
    table.text('notes');
    table.decimal('actual_cost', 10, 2);
    table.integer('completed_by').unsigned().notNullable();
    table.string('status', 50).notNullable().defaultTo('completed'); // completed, skipped, rescheduled
    table.timestamps(true, true);
    
    // Foreign key constraints
    table.foreign('schedule_id').references('id').inTable('maintenance_schedules').onDelete('CASCADE');
    table.foreign('completed_by').references('id').inTable('users').onDelete('CASCADE');
    
    // Supabase-specific optimizations
    table.index(['schedule_id'], 'idx_maintenance_records_schedule_id');
    table.index(['completed_date'], 'idx_maintenance_records_completed_date');
    table.index(['completed_by'], 'idx_maintenance_records_completed_by');
    table.index(['status'], 'idx_maintenance_records_status');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTableIfExists('maintenance_records');
};