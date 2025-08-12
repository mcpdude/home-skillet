/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> } 
 */
exports.seed = async function(knex) {
  // Deletes ALL existing entries
  await knex('projects').del();
  
  // Insert seed projects
  await knex('projects').insert([
    {
      id: '650e8400-e29b-41d4-a716-446655440001',
      property_id: '550e8400-e29b-41d4-a716-446655440001',
      title: 'Kitchen Renovation',
      description: 'Complete kitchen remodel with new appliances and granite countertops',
      status: 'in_progress',
      priority: 'high',
      budget: 25000.00,
      actual_cost: 15000.00,
      start_date: '2024-01-15',
      due_date: '2024-03-15',
      created_by: 1,
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: '650e8400-e29b-41d4-a716-446655440002',
      property_id: '550e8400-e29b-41d4-a716-446655440002',
      title: 'Bathroom Upgrade',
      description: 'Modernize master bathroom with new fixtures',
      status: 'pending',
      priority: 'medium',
      budget: 8000.00,
      start_date: '2024-02-01',
      due_date: '2024-02-28',
      created_by: 2,
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: '650e8400-e29b-41d4-a716-446655440003',
      property_id: '550e8400-e29b-41d4-a716-446655440003',
      title: 'Deck Construction',
      description: 'Build new wooden deck in backyard',
      status: 'completed',
      priority: 'low',
      budget: 5000.00,
      actual_cost: 4800.00,
      start_date: '2023-11-01',
      end_date: '2023-12-15',
      due_date: '2023-12-01',
      created_by: 1,
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: '650e8400-e29b-41d4-a716-446655440004',
      property_id: '550e8400-e29b-41d4-a716-446655440004',
      title: 'HVAC System Upgrade',
      description: 'Replace aging HVAC system with energy-efficient units',
      status: 'pending',
      priority: 'urgent',
      budget: 12000.00,
      start_date: '2024-02-15',
      due_date: '2024-03-30',
      created_by: 3,
      created_at: new Date(),
      updated_at: new Date()
    }
  ]);
};