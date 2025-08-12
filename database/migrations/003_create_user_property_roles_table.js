/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('user_property_roles', function(table) {
    // Primary key
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    
    // Foreign keys
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.uuid('property_id').notNullable().references('id').inTable('properties').onDelete('CASCADE');
    
    // Role information
    table.enum('role', ['owner', 'family', 'contractor', 'tenant', 'realtor']).notNullable();
    table.string('title', 100); // Optional descriptive title like "Property Manager", "Lead Contractor"
    
    // Permission configuration - JSON object with granular permissions
    table.json('permissions').notNullable().defaultTo(JSON.stringify({
      projects: {
        view_all: false,
        create: false,
        edit: false,
        delete: false,
        assign: false
      },
      maintenance: {
        view_schedules: false,
        manage_schedules: false,
        view_records: false,
        create_records: false
      },
      documents: {
        view_all: false,
        upload: false,
        delete: false,
        share: false
      },
      financial: {
        view_summary: false,
        view_detailed: false,
        manage_budgets: false
      },
      vendors: {
        view: false,
        manage: false,
        contact: false
      },
      property: {
        view_details: false,
        edit_details: false,
        manage_users: false
      }
    }));
    
    // Access control
    table.boolean('is_active').defaultTo(true);
    table.timestamp('access_granted_at').defaultTo(knex.fn.now());
    table.timestamp('access_expires_at'); // Optional expiration for temporary access
    table.uuid('invited_by_user_id').references('id').inTable('users'); // Who granted access
    
    // Invitation flow
    table.enum('invitation_status', ['pending', 'accepted', 'declined', 'expired']).defaultTo('accepted');
    table.string('invitation_token', 255); // For email invitations
    table.timestamp('invitation_sent_at');
    table.timestamp('invitation_accepted_at');
    
    // Audit fields
    table.timestamps(true, true);
    
    // Constraints and indexes
    table.unique(['user_id', 'property_id'], 'unique_user_property_role');
    table.index(['property_id'], 'idx_upr_property');
    table.index(['user_id'], 'idx_upr_user');
    table.index(['role'], 'idx_upr_role');
    table.index(['is_active'], 'idx_upr_active');
    table.index(['invitation_status'], 'idx_upr_invitation_status');
    table.index(['invitation_token'], 'idx_upr_invitation_token');
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTable('user_property_roles');
};