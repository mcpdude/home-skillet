/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema
    // Create documents table
    .createTable('documents', function(table) {
      if (knex.client.config.client === 'sqlite3') {
        table.string('id').primary();
        table.string('property_id');
        table.string('project_id');
        table.string('uploaded_by').notNullable();
      } else {
        table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
        table.uuid('property_id');
        table.uuid('project_id');
        table.uuid('uploaded_by').notNullable();
      }
      
      table.string('title', 200).notNullable();
      table.text('description');
      table.string('document_type', 50).notNullable(); // receipt, contract, warranty, invoice, permit, report, other
      table.string('category', 50); // supplies, services, appliances, maintenance, construction, etc.
      table.string('vendor_name', 200);
      table.decimal('amount', 12, 2); // For receipts/invoices
      table.string('currency', 3).defaultTo('USD');
      table.date('document_date'); // Date on the document (purchase date, contract date, etc.)
      table.date('expiry_date'); // For warranties, contracts, permits
      table.json('metadata'); // Additional structured data
      
      // File information
      table.string('filename').notNullable();
      table.string('original_filename').notNullable();
      table.string('file_path').notNullable();
      table.string('file_url').notNullable();
      table.bigInteger('file_size').notNullable();
      table.string('mime_type', 100).notNullable();
      table.string('file_hash', 64); // For duplicate detection
      
      // Organization
      table.string('status', 20).defaultTo('active'); // active, archived, deleted
      table.json('tags'); // Array of tags for better organization
      table.boolean('is_favorite').defaultTo(false);
      table.integer('view_count').defaultTo(0);
      
      table.timestamps(true, true);
      
      // Foreign key constraints
      table.foreign('property_id').references('id').inTable('properties').onDelete('CASCADE');
      table.foreign('project_id').references('id').inTable('projects').onDelete('CASCADE');
      table.foreign('uploaded_by').references('id').inTable('users').onDelete('CASCADE');
      
      // Indexes for efficient queries
      table.index(['property_id'], 'idx_documents_property_id');
      table.index(['project_id'], 'idx_documents_project_id');
      table.index(['uploaded_by'], 'idx_documents_uploaded_by');
      table.index(['document_type'], 'idx_documents_type');
      table.index(['category'], 'idx_documents_category');
      table.index(['document_date'], 'idx_documents_date');
      table.index(['expiry_date'], 'idx_documents_expiry');
      table.index(['status'], 'idx_documents_status');
      table.index(['file_hash'], 'idx_documents_hash');
      
      // Note: SQLite doesn't support check constraints with OR logic well, so this is enforced at application level
    })
    
    // Create document access log table
    .createTable('document_access_log', function(table) {
      if (knex.client.config.client === 'sqlite3') {
        table.string('id').primary();
        table.string('document_id').notNullable();
        table.string('user_id').notNullable();
      } else {
        table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
        table.uuid('document_id').notNullable();
        table.uuid('user_id').notNullable();
      }
      
      table.string('action', 50).notNullable(); // view, download, share, delete
      table.string('ip_address', 45);
      table.string('user_agent', 500);
      table.json('additional_info'); // Any additional context
      table.timestamp('accessed_at').defaultTo(knex.fn.now());
      
      // Foreign key constraints
      table.foreign('document_id').references('id').inTable('documents').onDelete('CASCADE');
      table.foreign('user_id').references('id').inTable('users').onDelete('CASCADE');
      
      // Indexes
      table.index(['document_id'], 'idx_access_log_document_id');
      table.index(['user_id'], 'idx_access_log_user_id');
      table.index(['accessed_at'], 'idx_access_log_accessed_at');
    })
    
    // Create document shares table for sharing documents with other users
    .createTable('document_shares', function(table) {
      if (knex.client.config.client === 'sqlite3') {
        table.string('id').primary();
        table.string('document_id').notNullable();
        table.string('shared_by').notNullable();
        table.string('shared_with').notNullable();
      } else {
        table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
        table.uuid('document_id').notNullable();
        table.uuid('shared_by').notNullable();
        table.uuid('shared_with').notNullable();
      }
      
      table.string('permission', 20).defaultTo('view'); // view, download, edit
      table.text('message'); // Optional message when sharing
      table.timestamp('shared_at').defaultTo(knex.fn.now());
      table.timestamp('expires_at'); // Optional expiration
      table.boolean('is_active').defaultTo(true);
      
      // Foreign key constraints
      table.foreign('document_id').references('id').inTable('documents').onDelete('CASCADE');
      table.foreign('shared_by').references('id').inTable('users').onDelete('CASCADE');
      table.foreign('shared_with').references('id').inTable('users').onDelete('CASCADE');
      
      // Indexes
      table.index(['document_id'], 'idx_document_shares_document_id');
      table.index(['shared_with'], 'idx_document_shares_shared_with');
      table.index(['is_active'], 'idx_document_shares_is_active');
      
      // Unique constraint
      table.unique(['document_id', 'shared_with'], 'unique_document_user_share');
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema
    .dropTableIfExists('document_shares')
    .dropTableIfExists('document_access_log')
    .dropTableIfExists('documents');
};