/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('properties', function(table) {
    // Primary key
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    
    // Basic property information
    table.string('name', 200).notNullable(); // User-defined property name
    table.string('property_type', 50).notNullable(); // single_family, condo, apartment, etc.
    
    // Address information
    table.string('street_address', 255).notNullable();
    table.string('city', 100).notNullable();
    table.string('state_province', 50).notNullable();
    table.string('postal_code', 20).notNullable();
    table.string('country', 2).notNullable().defaultTo('US');
    table.decimal('latitude', 10, 8); // For mapping and location services
    table.decimal('longitude', 11, 8);
    
    // Property details
    table.integer('year_built');
    table.integer('square_footage');
    table.decimal('lot_size_sqft', 10, 2);
    table.integer('bedrooms');
    table.decimal('bathrooms', 3, 1);
    table.string('architectural_style', 100);
    
    // Property value and assessment
    table.decimal('purchase_price', 12, 2);
    table.date('purchase_date');
    table.decimal('current_assessed_value', 12, 2);
    table.date('last_assessment_date');
    
    // Utility and service information
    table.json('utility_accounts').defaultTo('{}'); // Store account numbers, providers
    table.json('insurance_info').defaultTo('{}'); // Policy numbers, providers, coverage
    
    // Property configuration
    table.json('property_features').defaultTo('{}'); // Pool, garage, basement, etc.
    table.json('appliances').defaultTo('{}'); // Brand, model, purchase dates
    table.json('hvac_systems').defaultTo('{}'); // System details, maintenance schedules
    
    // Media
    table.json('photos').defaultTo('[]'); // Array of photo URLs
    table.string('primary_photo_url', 500);
    table.json('floor_plans').defaultTo('[]'); // Array of floor plan URLs
    
    // Status and settings
    table.boolean('is_primary_residence').defaultTo(true);
    table.boolean('is_active').defaultTo(true);
    table.json('settings').defaultTo('{}'); // Property-specific settings
    
    // Audit fields
    table.timestamps(true, true);
    
    // Indexes
    table.index(['is_active'], 'idx_properties_active');
    table.index(['city', 'state_province'], 'idx_properties_location');
    table.index(['property_type'], 'idx_properties_type');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTable('properties');
};