/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('maintenance_schedules', function(table) {
    // Primary key
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    
    // Property association (multi-tenant isolation)
    table.uuid('property_id').notNullable().references('id').inTable('properties').onDelete('CASCADE');
    
    // Schedule basic information
    table.string('title', 255).notNullable();
    table.text('description');
    table.string('category', 100).notNullable(); // hvac, plumbing, electrical, exterior, interior, appliances, safety
    table.string('subcategory', 100); // filter_change, gutter_cleaning, smoke_detector_test, etc.
    
    // Scheduling configuration
    table.enum('frequency_type', ['days', 'weeks', 'months', 'years', 'seasonal', 'custom']).notNullable();
    table.integer('frequency_value').notNullable(); // e.g., 3 for "every 3 months"
    table.json('custom_schedule').defaultTo('{}'); // For complex schedules, cron-like expressions
    
    // Seasonal scheduling
    table.json('seasons').defaultTo('[]'); // ['spring', 'summer', 'fall', 'winter']
    table.json('months').defaultTo('[]'); // [3, 6, 9, 12] for specific months
    
    // Start and end conditions
    table.date('first_due_date').notNullable();
    table.date('last_scheduled_date'); // When it's no longer needed
    table.boolean('is_active').defaultTo(true);
    
    // Task details
    table.enum('priority', ['low', 'medium', 'high']).defaultTo('medium');
    table.integer('estimated_duration_minutes'); // Expected time to complete
    table.decimal('estimated_cost', 10, 2); // Expected cost per occurrence
    
    // Assignment and responsibilities
    table.uuid('default_assignee_id').references('id').inTable('users'); // Default person responsible
    table.boolean('can_be_delegated').defaultTo(true);
    table.boolean('requires_professional').defaultTo(false); // Needs contractor/professional
    
    // Instructions and guidance
    table.text('instructions'); // Step-by-step instructions
    table.json('required_materials').defaultTo('[]'); // Materials needed
    table.json('required_tools').defaultTo('[]'); // Tools needed
    table.json('safety_notes').defaultTo('[]'); // Safety precautions
    
    // Reminders and notifications
    table.integer('reminder_days_before').defaultTo(7); // Days before due date to remind
    table.json('notification_recipients').defaultTo('[]'); // User IDs to notify
    table.boolean('send_email_reminders').defaultTo(true);
    table.boolean('send_push_notifications').defaultTo(true);
    
    // Related information
    table.string('system_or_appliance', 200); // "HVAC System 1", "Water Heater", "Roof"
    table.string('location_in_property', 200); // "Basement", "Attic", "Exterior East Side"
    table.json('related_documents').defaultTo('[]'); // Manuals, warranties, etc.
    
    // Performance tracking
    table.integer('completion_rate_percentage'); // Historical completion rate
    table.decimal('average_actual_cost', 10, 2); // Average actual cost from records
    table.integer('average_actual_duration_minutes'); // Average actual time from records
    
    // Audit fields
    table.uuid('created_by_user_id').notNullable().references('id').inTable('users');
    table.timestamps(true, true);
    table.uuid('last_modified_by').references('id').inTable('users');
    
    // Indexes for performance
    table.index(['property_id'], 'idx_maintenance_schedules_property');
    table.index(['is_active'], 'idx_maintenance_schedules_active');
    table.index(['category'], 'idx_maintenance_schedules_category');
    table.index(['frequency_type'], 'idx_maintenance_schedules_frequency');
    table.index(['first_due_date'], 'idx_maintenance_schedules_first_due');
    table.index(['default_assignee_id'], 'idx_maintenance_schedules_assignee');
    table.index(['requires_professional'], 'idx_maintenance_schedules_professional');
    table.index(['property_id', 'is_active'], 'idx_maintenance_schedules_property_active');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTable('maintenance_schedules');
};