/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('maintenance_records', function(table) {
    // Primary key
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    
    // Property association (multi-tenant isolation)
    table.uuid('property_id').notNullable().references('id').inTable('properties').onDelete('CASCADE');
    
    // Schedule association (nullable for ad-hoc maintenance)
    table.uuid('maintenance_schedule_id').references('id').inTable('maintenance_schedules').onDelete('SET NULL');
    
    // Record basic information
    table.string('title', 255).notNullable();
    table.text('description');
    table.string('category', 100).notNullable(); // Same categories as schedules
    table.string('subcategory', 100);
    
    // Completion details
    table.date('completed_date').notNullable();
    table.timestamp('started_at');
    table.timestamp('completed_at');
    table.integer('duration_minutes'); // Actual time taken
    
    // Personnel
    table.uuid('performed_by_user_id').references('id').inTable('users');
    table.uuid('supervised_by_user_id').references('id').inTable('users'); // For contractor work
    table.string('contractor_name', 200); // If performed by external contractor
    
    // Work performed
    table.text('work_performed').notNullable(); // What was actually done
    table.json('materials_used').defaultTo('[]'); // Materials used with quantities and costs
    table.json('tools_used').defaultTo('[]'); // Tools used
    
    // Financial tracking
    table.decimal('labor_cost', 10, 2);
    table.decimal('materials_cost', 10, 2);
    table.decimal('total_cost', 10, 2).notNullable();
    table.string('payment_method', 50); // cash, check, card, etc.
    table.string('receipt_number', 100);
    
    // Quality and outcome
    table.enum('completion_status', ['completed', 'partially_completed', 'deferred', 'failed']).defaultTo('completed');
    table.integer('quality_rating').checkBetween([1, 5]); // 1-5 stars
    table.text('issues_found'); // Problems discovered during maintenance
    table.text('recommendations'); // Future recommendations
    
    // Follow-up and warranty
    table.boolean('requires_follow_up').defaultTo(false);
    table.date('follow_up_date');
    table.text('follow_up_notes');
    table.boolean('warranty_provided').defaultTo(false);
    table.date('warranty_expires_at');
    
    // Location and system information
    table.string('system_or_appliance', 200); // What was maintained
    table.string('location_in_property', 200);
    table.json('before_condition').defaultTo('{}'); // Condition before maintenance
    table.json('after_condition').defaultTo('{}'); // Condition after maintenance
    
    // Documentation
    table.json('photos').defaultTo('{}'); // {before: [], during: [], after: []}
    table.json('attachments').defaultTo('[]'); // Receipts, reports, etc.
    table.json('related_documents').defaultTo('[]'); // Manuals, warranties referenced
    
    // Next maintenance prediction
    table.date('next_maintenance_due'); // When next maintenance should occur
    table.text('next_maintenance_notes'); // Specific notes for next time
    
    // Schedule tracking (if from scheduled maintenance)
    table.date('was_due_date'); // Original due date if from schedule
    table.integer('days_overdue'); // How many days late (if applicable)
    table.boolean('was_preventive').defaultTo(true); // vs reactive/emergency
    
    // Audit fields
    table.uuid('created_by_user_id').notNullable().references('id').inTable('users');
    table.timestamps(true, true);
    table.uuid('last_modified_by').references('id').inTable('users');
    
    // Indexes for performance
    table.index(['property_id'], 'idx_maintenance_records_property');
    table.index(['maintenance_schedule_id'], 'idx_maintenance_records_schedule');
    table.index(['completed_date'], 'idx_maintenance_records_completed_date');
    table.index(['category'], 'idx_maintenance_records_category');
    table.index(['performed_by_user_id'], 'idx_maintenance_records_performed_by');
    table.index(['completion_status'], 'idx_maintenance_records_status');
    table.index(['requires_follow_up'], 'idx_maintenance_records_follow_up');
    table.index(['next_maintenance_due'], 'idx_maintenance_records_next_due');
    table.index(['property_id', 'completed_date'], 'idx_maintenance_records_property_date');
    table.index(['system_or_appliance'], 'idx_maintenance_records_system');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTable('maintenance_records');
};