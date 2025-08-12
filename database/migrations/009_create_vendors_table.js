/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('vendors', function(table) {
    // Primary key
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    
    // Basic vendor information
    table.string('company_name', 200).notNullable();
    table.string('contact_person', 100);
    table.string('title', 100); // Contact person's title/role
    
    // Contact information
    table.string('email', 255);
    table.string('phone_primary', 20);
    table.string('phone_secondary', 20);
    table.string('website', 500);
    
    // Address information
    table.string('street_address', 255);
    table.string('city', 100);
    table.string('state_province', 50);
    table.string('postal_code', 20);
    table.string('country', 2).defaultTo('US');
    
    // Business information
    table.string('business_license_number', 100);
    table.date('license_expiration_date');
    table.string('insurance_provider', 200);
    table.string('insurance_policy_number', 100);
    table.date('insurance_expiration_date');
    table.decimal('insurance_coverage_amount', 12, 2);
    
    // Service categories and capabilities
    table.json('service_categories').defaultTo('[]'); // plumbing, electrical, hvac, etc.
    table.json('specializations').defaultTo('[]'); // Specific areas of expertise
    table.text('services_description'); // Detailed description of services offered
    table.boolean('emergency_services').defaultTo(false);
    table.boolean('warranty_provided').defaultTo(false);
    table.integer('warranty_duration_months');
    
    // Business details
    table.integer('years_in_business');
    table.integer('number_of_employees');
    table.enum('business_type', ['sole_proprietor', 'partnership', 'llc', 'corporation', 'contractor']).defaultTo('contractor');
    table.string('tax_id', 50); // EIN or Tax ID
    
    // Service area and availability
    table.json('service_areas').defaultTo('[]'); // Cities, zip codes, or regions served
    table.integer('max_travel_distance_miles');
    table.json('business_hours').defaultTo('{}'); // Operating hours by day
    table.boolean('accepts_emergency_calls').defaultTo(false);
    table.string('emergency_contact', 20);
    
    // Pricing and payment
    table.decimal('hourly_rate', 8, 2);
    table.decimal('minimum_charge', 8, 2);
    table.boolean('free_estimates').defaultTo(false);
    table.integer('estimate_validity_days').defaultTo(30);
    table.json('accepted_payment_methods').defaultTo('[]'); // cash, check, card, financing
    table.integer('payment_terms_days').defaultTo(30); // Net 30, etc.
    
    // Performance and ratings
    table.decimal('average_rating', 3, 2).defaultTo(0); // 0.00 to 5.00
    table.integer('total_reviews').defaultTo(0);
    table.decimal('on_time_percentage', 5, 2).defaultTo(100); // Percentage of on-time completions
    table.decimal('within_budget_percentage', 5, 2).defaultTo(100); // Percentage within original estimate
    table.integer('total_projects_completed').defaultTo(0);
    
    // Certification and credentials
    table.json('certifications').defaultTo('[]'); // Professional certifications
    table.json('licenses').defaultTo('[]'); // Professional licenses by state/locality
    table.boolean('bonded').defaultTo(false);
    table.boolean('insured').defaultTo(false);
    table.boolean('background_check_completed').defaultTo(false);
    table.date('last_background_check_date');
    
    // Vendor relationships and status
    table.enum('vendor_status', ['active', 'inactive', 'blacklisted', 'preferred']).defaultTo('active');
    table.enum('relationship_type', ['occasional', 'preferred', 'exclusive', 'emergency_only']).defaultTo('occasional');
    table.text('internal_notes'); // Private notes about the vendor
    table.json('tags').defaultTo('[]'); // User-defined tags for organization
    
    // Communication preferences
    table.enum('preferred_contact_method', ['phone', 'email', 'text', 'app']).defaultTo('phone');
    table.string('preferred_contact_time', 100); // "Mornings", "After 5 PM", etc.
    table.boolean('accepts_text_messages').defaultTo(false);
    table.string('communication_notes', 500);
    
    // Multi-property support
    table.json('authorized_properties').defaultTo('[]'); // Property IDs this vendor is approved for
    table.boolean('global_vendor').defaultTo(true); // Available for all user's properties
    
    // Audit fields
    table.uuid('added_by_user_id').notNullable().references('id').inTable('users');
    table.timestamps(true, true);
    table.uuid('last_modified_by').references('id').inTable('users');
    
    // Indexes for performance
    table.index(['company_name'], 'idx_vendors_company_name');
    table.index(['vendor_status'], 'idx_vendors_status');
    table.index(['relationship_type'], 'idx_vendors_relationship');
    table.index(['emergency_services'], 'idx_vendors_emergency');
    table.index(['added_by_user_id'], 'idx_vendors_added_by');
    table.index(['average_rating'], 'idx_vendors_rating');
    table.index(['license_expiration_date'], 'idx_vendors_license_expiration');
    table.index(['insurance_expiration_date'], 'idx_vendors_insurance_expiration');
    table.index(['city', 'state_province'], 'idx_vendors_location');
    
    // Full-text search on company name and services description
    table.index(knex.raw('to_tsvector(\'english\', company_name || \' \' || COALESCE(services_description, \'\'))'), 'idx_vendors_fts', 'gin');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTable('vendors');
};