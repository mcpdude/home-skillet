/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> } 
 */
exports.seed = async function(knex) {
  // Deletes ALL existing entries
  await knex('property_permissions').del();
  
  // Insert seed property permissions
  await knex('property_permissions').insert([
    {
      property_id: '550e8400-e29b-41d4-a716-446655440001',
      user_id: 2,
      role: 'manager',
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      property_id: '550e8400-e29b-41d4-a716-446655440001',
      user_id: 3,
      role: 'viewer',
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      property_id: '550e8400-e29b-41d4-a716-446655440002',
      user_id: 1,
      role: 'viewer',
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      property_id: '550e8400-e29b-41d4-a716-446655440003',
      user_id: 2,
      role: 'maintainer',
      created_at: new Date(),
      updated_at: new Date()
    }
  ]);
};