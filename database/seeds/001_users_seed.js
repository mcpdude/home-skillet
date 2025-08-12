/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> } 
 */
exports.seed = async function(knex) {
  // Deletes ALL existing entries (in development only)
  if (process.env.NODE_ENV === 'development') {
    await knex('users').del();
  }

  // Insert seed entries
  const users = [
    {
      id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', // Fixed UUID for consistent testing
      email: 'john.owner@example.com',
      password_hash: '$2b$10$abcdefghijklmnopqrstuvwxyzABCDEF123456789', // Mock hash
      provider: 'local',
      first_name: 'John',
      last_name: 'Owner',
      phone: '+1-555-123-4567',
      is_email_verified: true,
      is_active: true,
      email_verified_at: new Date(),
      preferences: JSON.stringify({
        notifications: {
          email: true,
          push: true,
          sms: false
        },
        dashboard: {
          default_view: 'projects',
          show_completed: false
        }
      }),
      timezone: 'America/New_York',
      language: 'en'
    },
    {
      id: 'b1ffcd00-8d1c-5fg9-cc7e-7cc0ce491b22',
      email: 'jane.family@example.com',
      password_hash: '$2b$10$xyzabcdefghijklmnopqrstuvwxyzABCDEF789123',
      provider: 'local',
      first_name: 'Jane',
      last_name: 'Owner',
      phone: '+1-555-123-4568',
      is_email_verified: true,
      is_active: true,
      email_verified_at: new Date(),
      preferences: JSON.stringify({
        notifications: {
          email: true,
          push: true,
          sms: true
        }
      }),
      timezone: 'America/New_York',
      language: 'en'
    },
    {
      id: 'c2ggde11-9e2d-6hg0-dd8f-8dd1de502c33',
      email: 'mike.contractor@example.com',
      password_hash: '$2b$10$mnopqrstuvwxyzabcdefghijklmnopqrst456789',
      provider: 'local',
      first_name: 'Mike',
      last_name: 'Contractor',
      phone: '+1-555-987-6543',
      is_email_verified: true,
      is_active: true,
      email_verified_at: new Date(),
      preferences: JSON.stringify({
        notifications: {
          email: true,
          push: false,
          sms: true
        }
      }),
      timezone: 'America/New_York',
      language: 'en'
    },
    {
      id: 'd3hhef22-0f3e-7hi1-ee9g-9ee2ef613d44',
      email: 'sarah.tenant@example.com',
      provider: 'google',
      provider_id: 'google_123456789',
      first_name: 'Sarah',
      last_name: 'Tenant',
      phone: '+1-555-456-7890',
      is_email_verified: true,
      is_active: true,
      email_verified_at: new Date(),
      preferences: JSON.stringify({
        notifications: {
          email: true,
          push: true,
          sms: false
        }
      }),
      timezone: 'America/Los_Angeles',
      language: 'en'
    },
    {
      id: 'e4iifg33-1g4f-8ij2-ff0h-0ff3fg724e55',
      email: 'bob.realtor@example.com',
      password_hash: '$2b$10$stuvwxyzabcdefghijklmnopqrstuvwxyz123456',
      provider: 'local',
      first_name: 'Bob',
      last_name: 'Realtor',
      phone: '+1-555-321-0987',
      is_email_verified: true,
      is_active: true,
      email_verified_at: new Date(),
      preferences: JSON.stringify({
        notifications: {
          email: true,
          push: false,
          sms: false
        }
      }),
      timezone: 'America/Chicago',
      language: 'en'
    }
  ];

  await knex('users').insert(users);
};