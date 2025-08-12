/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> } 
 */
exports.seed = async function(knex) {
  // Deletes ALL existing entries (in development only)
  if (process.env.NODE_ENV === 'development') {
    await knex('user_property_roles').del();
  }

  // Insert seed entries
  const userPropertyRoles = [
    {
      id: 'h7llij66-4j7i-1lm5-ii3k-3ii6ij057h88',
      user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', // John Owner
      property_id: 'f5jjgh44-2h5g-9jk3-gg1i-1gg4gh835f66', // Main Family Home
      role: 'owner',
      title: 'Property Owner',
      permissions: JSON.stringify({
        projects: {
          view_all: true,
          create: true,
          edit: true,
          delete: true,
          assign: true
        },
        maintenance: {
          view_schedules: true,
          manage_schedules: true,
          view_records: true,
          create_records: true
        },
        documents: {
          view_all: true,
          upload: true,
          delete: true,
          share: true
        },
        financial: {
          view_summary: true,
          view_detailed: true,
          manage_budgets: true
        },
        vendors: {
          view: true,
          manage: true,
          contact: true
        },
        property: {
          view_details: true,
          edit_details: true,
          manage_users: true
        }
      }),
      is_active: true,
      invitation_status: 'accepted',
      invitation_accepted_at: new Date('2023-01-01')
    },
    {
      id: 'i8mmjk77-5k8j-2mn6-jj4l-4jj7jk168i99',
      user_id: 'b1ffcd00-8d1c-5fg9-cc7e-7cc0ce491b22', // Jane Family
      property_id: 'f5jjgh44-2h5g-9jk3-gg1i-1gg4gh835f66', // Main Family Home
      role: 'family',
      title: 'Co-Owner',
      permissions: JSON.stringify({
        projects: {
          view_all: true,
          create: true,
          edit: true,
          delete: false,
          assign: true
        },
        maintenance: {
          view_schedules: true,
          manage_schedules: true,
          view_records: true,
          create_records: true
        },
        documents: {
          view_all: true,
          upload: true,
          delete: false,
          share: true
        },
        financial: {
          view_summary: true,
          view_detailed: true,
          manage_budgets: false
        },
        vendors: {
          view: true,
          manage: false,
          contact: true
        },
        property: {
          view_details: true,
          edit_details: false,
          manage_users: false
        }
      }),
      is_active: true,
      invited_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      invitation_status: 'accepted',
      invitation_sent_at: new Date('2023-01-02'),
      invitation_accepted_at: new Date('2023-01-02')
    },
    {
      id: 'j9nnkl88-6l9k-3no7-kk5m-5kk8kl279j00',
      user_id: 'c2ggde11-9e2d-6hg0-dd8f-8dd1de502c33', // Mike Contractor
      property_id: 'f5jjgh44-2h5g-9jk3-gg1i-1gg4gh835f66', // Main Family Home
      role: 'contractor',
      title: 'Licensed Contractor',
      permissions: JSON.stringify({
        projects: {
          view_all: false, // Only assigned projects
          create: false,
          edit: false, // Only assigned projects
          delete: false,
          assign: false
        },
        maintenance: {
          view_schedules: false, // Only relevant schedules
          manage_schedules: false,
          view_records: false, // Only relevant records
          create_records: true // Can log completed work
        },
        documents: {
          view_all: false, // Only project-related
          upload: true, // Can upload work documentation
          delete: false,
          share: false
        },
        financial: {
          view_summary: false,
          view_detailed: false, // Only project budgets
          manage_budgets: false
        },
        vendors: {
          view: false,
          manage: false,
          contact: false
        },
        property: {
          view_details: false, // Only relevant details
          edit_details: false,
          manage_users: false
        }
      }),
      is_active: true,
      invited_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      invitation_status: 'accepted',
      invitation_sent_at: new Date('2023-02-15'),
      invitation_accepted_at: new Date('2023-02-16'),
      access_expires_at: new Date('2024-12-31') // Temporary access
    },
    {
      id: 'k0oolm99-7m0l-4op8-ll6n-6ll9lm380k11',
      user_id: 'd3hhef22-0f3e-7hi1-ee9g-9ee2ef613d44', // Sarah Tenant
      property_id: 'g6kkhi55-3i6h-0kl4-hh2j-2hh5hi946g77', // Downtown Rental
      role: 'tenant',
      title: 'Tenant',
      permissions: JSON.stringify({
        projects: {
          view_all: false, // Only maintenance requests
          create: false, // Can only request maintenance
          edit: false,
          delete: false,
          assign: false
        },
        maintenance: {
          view_schedules: true, // Can see maintenance schedules
          manage_schedules: false,
          view_records: true, // Can see maintenance history
          create_records: false // Cannot log maintenance
        },
        documents: {
          view_all: false, // Only relevant documents
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
          view_details: true, // Basic property info
          edit_details: false,
          manage_users: false
        }
      }),
      is_active: true,
      invited_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      invitation_status: 'accepted',
      invitation_sent_at: new Date('2023-03-01'),
      invitation_accepted_at: new Date('2023-03-01')
    },
    {
      id: 'l1ppmn00-8n1m-5pq9-mm7o-7mm0mn491l22',
      user_id: 'e4iifg33-1g4f-8ij2-ff0h-0ff3fg724e55', // Bob Realtor
      property_id: 'g6kkhi55-3i6h-0kl4-hh2j-2hh5hi946g77', // Downtown Rental
      role: 'realtor',
      title: 'Property Manager',
      permissions: JSON.stringify({
        projects: {
          view_all: true, // Can see all projects for property history
          create: false,
          edit: false,
          delete: false,
          assign: false
        },
        maintenance: {
          view_schedules: true,
          manage_schedules: false,
          view_records: true,
          create_records: false
        },
        documents: {
          view_all: true, // Needs access to all property documents
          upload: false,
          delete: false,
          share: false
        },
        financial: {
          view_summary: true, // Property value insights
          view_detailed: false,
          manage_budgets: false
        },
        vendors: {
          view: true, // Can see vendor history
          manage: false,
          contact: false
        },
        property: {
          view_details: true,
          edit_details: false,
          manage_users: false
        }
      }),
      is_active: true,
      invited_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      invitation_status: 'accepted',
      invitation_sent_at: new Date('2023-04-10'),
      invitation_accepted_at: new Date('2023-04-10')
    },
    // Owner role for the second property
    {
      id: 'm2qqno11-9o2n-6qr0-nn8p-8nn1no502m33',
      user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', // John Owner
      property_id: 'g6kkhi55-3i6h-0kl4-hh2j-2hh5hi946g77', // Downtown Rental
      role: 'owner',
      title: 'Property Owner',
      permissions: JSON.stringify({
        projects: {
          view_all: true,
          create: true,
          edit: true,
          delete: true,
          assign: true
        },
        maintenance: {
          view_schedules: true,
          manage_schedules: true,
          view_records: true,
          create_records: true
        },
        documents: {
          view_all: true,
          upload: true,
          delete: true,
          share: true
        },
        financial: {
          view_summary: true,
          view_detailed: true,
          manage_budgets: true
        },
        vendors: {
          view: true,
          manage: true,
          contact: true
        },
        property: {
          view_details: true,
          edit_details: true,
          manage_users: true
        }
      }),
      is_active: true,
      invitation_status: 'accepted',
      invitation_accepted_at: new Date('2023-01-01')
    }
  ];

  await knex('user_property_roles').insert(userPropertyRoles);
};