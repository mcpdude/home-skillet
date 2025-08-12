/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema
    // Create insurance_items table
    .createTable('insurance_items', function(table) {
      if (knex.client.config.client === 'sqlite3') {
        table.string('id').primary();
        table.string('property_id').notNullable();
        table.string('created_by').notNullable();
      } else {
        table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
        table.uuid('property_id').notNullable();
        table.uuid('created_by').notNullable();
      }
      
      // Basic item information
      table.string('name', 200).notNullable();
      table.text('description');
      table.string('category', 50).notNullable(); // electronics, furniture, jewelry, appliances, clothing, etc.
      table.string('subcategory', 50); // tv, sofa, ring, refrigerator, etc.
      table.string('room_location', 100); // living_room, kitchen, master_bedroom, basement, etc.
      table.string('specific_location', 200); // "Kitchen counter", "Living room TV stand", etc.
      
      // Item details
      table.string('brand', 100);
      table.string('model', 100);
      table.string('serial_number', 100);
      table.string('condition', 20).defaultTo('good'); // excellent, good, fair, poor, damaged
      table.date('purchase_date');
      table.string('purchase_location', 200); // Store/vendor where purchased
      
      // Valuation
      table.decimal('purchase_price', 12, 2);
      table.decimal('current_estimated_value', 12, 2);
      table.decimal('replacement_cost', 12, 2);
      table.string('currency', 3).defaultTo('USD');
      table.date('last_appraised_date');
      table.string('appraisal_type', 50); // professional, estimate, market_research
      
      // Insurance and tracking
      table.boolean('is_insured').defaultTo(false);
      table.string('insurance_policy_number', 100);
      table.decimal('insurance_coverage_amount', 12, 2);
      table.boolean('requires_separate_coverage').defaultTo(false); // For high-value items
      table.json('custom_fields'); // Flexible additional data
      
      // Organization and status
      table.string('status', 20).defaultTo('active'); // active, sold, damaged, stolen, disposed
      table.json('tags'); // Array of custom tags
      table.boolean('is_favorite').defaultTo(false);
      table.integer('priority', 1).defaultTo(3); // 1=high, 2=medium, 3=low (for insurance claim priority)
      table.text('notes');
      
      table.timestamps(true, true);
      
      // Foreign key constraints
      table.foreign('property_id').references('id').inTable('properties').onDelete('CASCADE');
      table.foreign('created_by').references('id').inTable('users').onDelete('CASCADE');
      
      // Indexes for efficient queries
      table.index(['property_id'], 'idx_insurance_items_property_id');
      table.index(['created_by'], 'idx_insurance_items_created_by');
      table.index(['category'], 'idx_insurance_items_category');
      table.index(['room_location'], 'idx_insurance_items_room_location');
      table.index(['status'], 'idx_insurance_items_status');
      table.index(['purchase_date'], 'idx_insurance_items_purchase_date');
      table.index(['replacement_cost'], 'idx_insurance_items_replacement_cost');
      table.index(['serial_number'], 'idx_insurance_items_serial_number');
    })
    
    // Create insurance_item_photos table
    .createTable('insurance_item_photos', function(table) {
      if (knex.client.config.client === 'sqlite3') {
        table.string('id').primary();
        table.string('item_id').notNullable();
        table.string('uploaded_by').notNullable();
      } else {
        table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
        table.uuid('item_id').notNullable();
        table.uuid('uploaded_by').notNullable();
      }
      
      table.string('photo_type', 30).notNullable(); // overview, detail, serial_number, damage, packaging, receipt
      table.string('title', 200);
      table.text('description');
      
      // File information
      table.string('filename').notNullable();
      table.string('original_filename').notNullable();
      table.string('file_path').notNullable();
      table.string('file_url').notNullable();
      table.bigInteger('file_size').notNullable();
      table.string('mime_type', 100).notNullable();
      table.integer('display_order').defaultTo(0);
      
      // Photo metadata
      table.boolean('is_primary').defaultTo(false); // Main photo for the item
      table.json('exif_data'); // Camera metadata if available
      table.json('annotations'); // Markup/highlighting data
      
      table.timestamps(true, true);
      
      // Foreign key constraints
      table.foreign('item_id').references('id').inTable('insurance_items').onDelete('CASCADE');
      table.foreign('uploaded_by').references('id').inTable('users').onDelete('CASCADE');
      
      // Indexes
      table.index(['item_id'], 'idx_item_photos_item_id');
      table.index(['photo_type'], 'idx_item_photos_photo_type');
      table.index(['is_primary'], 'idx_item_photos_is_primary');
      table.index(['display_order'], 'idx_item_photos_display_order');
    })
    
    // Create insurance_item_documents table (linking to existing documents)
    .createTable('insurance_item_documents', function(table) {
      if (knex.client.config.client === 'sqlite3') {
        table.string('id').primary();
        table.string('item_id').notNullable();
        table.string('document_id').notNullable();
        table.string('linked_by').notNullable();
      } else {
        table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
        table.uuid('item_id').notNullable();
        table.uuid('document_id').notNullable();
        table.uuid('linked_by').notNullable();
      }
      
      table.string('relationship_type', 30).notNullable(); // receipt, warranty, appraisal, manual, insurance_policy
      table.text('notes'); // Why this document is linked to this item
      table.timestamp('linked_at').defaultTo(knex.fn.now());
      
      // Foreign key constraints
      table.foreign('item_id').references('id').inTable('insurance_items').onDelete('CASCADE');
      table.foreign('document_id').references('id').inTable('documents').onDelete('CASCADE');
      table.foreign('linked_by').references('id').inTable('users').onDelete('CASCADE');
      
      // Indexes
      table.index(['item_id'], 'idx_item_documents_item_id');
      table.index(['document_id'], 'idx_item_documents_document_id');
      table.index(['relationship_type'], 'idx_item_documents_relationship_type');
      
      // Unique constraint
      table.unique(['item_id', 'document_id'], 'unique_item_document_link');
    })
    
    // Create insurance_valuations table for tracking value changes over time
    .createTable('insurance_valuations', function(table) {
      if (knex.client.config.client === 'sqlite3') {
        table.string('id').primary();
        table.string('item_id').notNullable();
        table.string('appraised_by').notNullable();
      } else {
        table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
        table.uuid('item_id').notNullable();
        table.uuid('appraised_by').notNullable();
      }
      
      table.decimal('appraised_value', 12, 2).notNullable();
      table.decimal('replacement_cost', 12, 2);
      table.string('currency', 3).defaultTo('USD');
      table.date('valuation_date').notNullable();
      table.string('valuation_type', 30).notNullable(); // professional, insurance, market_estimate, depreciation_calc
      table.string('appraiser_name', 200);
      table.string('appraiser_credentials', 200);
      table.text('valuation_notes');
      table.json('methodology'); // How the value was determined
      
      // Supporting documentation
      table.string('certificate_number', 100);
      table.date('certificate_expiry');
      table.boolean('is_current').defaultTo(true);
      
      table.timestamps(true, true);
      
      // Foreign key constraints
      table.foreign('item_id').references('id').inTable('insurance_items').onDelete('CASCADE');
      table.foreign('appraised_by').references('id').inTable('users').onDelete('CASCADE');
      
      // Indexes
      table.index(['item_id'], 'idx_valuations_item_id');
      table.index(['valuation_date'], 'idx_valuations_valuation_date');
      table.index(['is_current'], 'idx_valuations_is_current');
      table.index(['valuation_type'], 'idx_valuations_valuation_type');
    })
    
    // Create insurance_inventory_reports table for generating periodic reports
    .createTable('insurance_inventory_reports', function(table) {
      if (knex.client.config.client === 'sqlite3') {
        table.string('id').primary();
        table.string('property_id');
        table.string('generated_by').notNullable();
      } else {
        table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
        table.uuid('property_id');
        table.uuid('generated_by').notNullable();
      }
      
      table.string('report_type', 30).notNullable(); // full_inventory, insurance_claim, room_specific, category_specific
      table.string('title', 200).notNullable();
      table.text('description');
      table.json('filters_applied'); // What filters were used to generate this report
      table.json('summary_stats'); // Total values, item counts, etc.
      
      // Report metadata
      table.date('report_date').notNullable();
      table.date('data_as_of_date').notNullable(); // When the data snapshot was taken
      table.string('format', 20).defaultTo('json'); // json, pdf, csv
      table.string('file_path'); // If exported to file
      table.string('file_url'); // If exported to file
      
      table.timestamps(true, true);
      
      // Foreign key constraints
      table.foreign('property_id').references('id').inTable('properties').onDelete('CASCADE');
      table.foreign('generated_by').references('id').inTable('users').onDelete('CASCADE');
      
      // Indexes
      table.index(['property_id'], 'idx_inventory_reports_property_id');
      table.index(['generated_by'], 'idx_inventory_reports_generated_by');
      table.index(['report_type'], 'idx_inventory_reports_report_type');
      table.index(['report_date'], 'idx_inventory_reports_report_date');
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema
    .dropTableIfExists('insurance_inventory_reports')
    .dropTableIfExists('insurance_valuations')
    .dropTableIfExists('insurance_item_documents')
    .dropTableIfExists('insurance_item_photos')
    .dropTableIfExists('insurance_items');
};