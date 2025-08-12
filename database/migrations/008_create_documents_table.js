/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('documents', function(table) {
    // Primary key
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    
    // Property association (multi-tenant isolation)
    table.uuid('property_id').notNullable().references('id').inTable('properties').onDelete('CASCADE');
    
    // Document basic information
    table.string('title', 255).notNullable();
    table.text('description');
    table.string('original_filename', 255).notNullable();
    table.string('file_extension', 10).notNullable();
    table.string('mime_type', 100).notNullable();
    
    // File storage information (S3 or similar)
    table.string('storage_provider', 50).defaultTo('s3'); // s3, google_cloud, azure, etc.
    table.string('storage_bucket', 255).notNullable();
    table.string('storage_key', 500).notNullable(); // Full path/key in storage
    table.string('storage_region', 50);
    table.string('public_url', 1000); // Public access URL if applicable
    table.string('signed_url', 1000); // Temporary signed URL
    table.timestamp('signed_url_expires_at');
    
    // File metadata
    table.bigInteger('file_size_bytes').notNullable();
    table.string('file_hash', 128); // SHA-256 hash for integrity checking
    table.string('thumbnail_url', 1000); // Thumbnail for images/PDFs
    table.json('image_metadata').defaultTo('{}'); // Width, height, EXIF data for images
    table.json('document_metadata').defaultTo('{}'); // Pages, author, etc. for PDFs
    
    // Document categorization
    table.string('category', 100).notNullable(); // warranty, receipt, manual, permit, insurance, etc.
    table.string('subcategory', 100); // appliance_manual, hvac_receipt, building_permit, etc.
    table.json('tags').defaultTo('[]'); // User-defined tags for flexible organization
    
    // Document relationships
    table.uuid('project_id').references('id').inTable('projects').onDelete('CASCADE'); // Associated project
    table.uuid('maintenance_record_id').references('id').inTable('maintenance_records').onDelete('CASCADE');
    table.uuid('vendor_id').references('id').inTable('vendors').onDelete('SET NULL');
    table.string('system_or_appliance', 200); // What this document relates to
    
    // Document lifecycle
    table.date('document_date'); // Date the document was created/issued
    table.date('expiration_date'); // For warranties, permits, insurance, etc.
    table.boolean('is_expired').defaultTo(false);
    table.enum('document_status', ['active', 'archived', 'deleted']).defaultTo('active');
    
    // Version control
    table.uuid('parent_document_id').references('id').inTable('documents'); // For document versions
    table.integer('version_number').defaultTo(1);
    table.boolean('is_latest_version').defaultTo(true);
    table.text('version_notes'); // What changed in this version
    
    // OCR and search
    table.text('extracted_text'); // OCR extracted text for searchability
    table.boolean('ocr_processed').defaultTo(false);
    table.timestamp('ocr_processed_at');
    table.json('ocr_metadata').defaultTo('{}'); // OCR confidence, language, etc.
    
    // Access control and sharing
    table.enum('visibility', ['private', 'property_users', 'public']).defaultTo('property_users');
    table.json('shared_with_user_ids').defaultTo('[]'); // Specific users with access
    table.json('shared_with_roles').defaultTo('[]'); // Roles that can access this document
    table.boolean('allow_download').defaultTo(true);
    table.boolean('allow_sharing').defaultTo(true);
    
    // Important document flags
    table.boolean('is_pinned').defaultTo(false); // Pin important documents
    table.boolean('is_favorite').defaultTo(false);
    table.boolean('requires_action').defaultTo(false); // Document needs user attention
    table.date('action_due_date'); // When action is needed
    table.text('action_notes'); // What action is required
    
    // Financial information (for receipts, invoices)
    table.decimal('amount', 12, 2); // Total amount for financial documents
    table.string('currency', 3).defaultTo('USD');
    table.date('payment_date');
    table.string('vendor_name', 200); // Vendor name from receipt/invoice
    
    // Warranty specific fields
    table.date('purchase_date'); // For warranty documents
    table.date('warranty_start_date');
    table.date('warranty_end_date');
    table.string('warranty_type', 100); // manufacturer, extended, labor, parts
    table.text('warranty_coverage'); // What's covered
    
    // Audit fields
    table.uuid('uploaded_by_user_id').notNullable().references('id').inTable('users');
    table.timestamps(true, true);
    table.uuid('last_modified_by').references('id').inTable('users');
    
    // Indexes for performance
    table.index(['property_id'], 'idx_documents_property');
    table.index(['category'], 'idx_documents_category');
    table.index(['subcategory'], 'idx_documents_subcategory');
    table.index(['document_status'], 'idx_documents_status');
    table.index(['project_id'], 'idx_documents_project');
    table.index(['maintenance_record_id'], 'idx_documents_maintenance_record');
    table.index(['vendor_id'], 'idx_documents_vendor');
    table.index(['expiration_date'], 'idx_documents_expiration');
    table.index(['is_expired'], 'idx_documents_expired');
    table.index(['document_date'], 'idx_documents_date');
    table.index(['uploaded_by_user_id'], 'idx_documents_uploader');
    table.index(['parent_document_id'], 'idx_documents_parent');
    table.index(['is_latest_version'], 'idx_documents_latest_version');
    table.index(['requires_action'], 'idx_documents_requires_action');
    table.index(['property_id', 'category'], 'idx_documents_property_category');
    table.index(['property_id', 'document_status'], 'idx_documents_property_status');
    
    // Full-text search index on extracted text (PostgreSQL specific)
    table.index(knex.raw('to_tsvector(\'english\', extracted_text)'), 'idx_documents_fts', 'gin');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTable('documents');
};