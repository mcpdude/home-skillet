/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> } 
 */
exports.seed = async function(knex) {
  // Deletes ALL existing entries
  await knex('project_tasks').del();
  
  // Insert seed project tasks
  await knex('project_tasks').insert([
    {
      id: '750e8400-e29b-41d4-a716-446655440001',
      project_id: '650e8400-e29b-41d4-a716-446655440001',
      title: 'Remove old cabinets',
      description: 'Carefully remove existing kitchen cabinets',
      status: 'completed',
      assigned_to: 2,
      estimated_hours: 8,
      actual_hours: 6,
      cost: 300.00,
      sort_order: 1,
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: '750e8400-e29b-41d4-a716-446655440002',
      project_id: '650e8400-e29b-41d4-a716-446655440001',
      title: 'Install new cabinets',
      description: 'Install new kitchen cabinets and hardware',
      status: 'in_progress',
      assigned_to: 2,
      due_date: '2024-02-15',
      estimated_hours: 16,
      actual_hours: 8,
      cost: 1200.00,
      sort_order: 2,
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: '750e8400-e29b-41d4-a716-446655440003',
      project_id: '650e8400-e29b-41d4-a716-446655440001',
      title: 'Install granite countertops',
      description: 'Measure, cut and install granite countertops',
      status: 'pending',
      due_date: '2024-03-01',
      estimated_hours: 12,
      cost: 2500.00,
      sort_order: 3,
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: '750e8400-e29b-41d4-a716-446655440004',
      project_id: '650e8400-e29b-41d4-a716-446655440002',
      title: 'Remove old fixtures',
      description: 'Remove existing bathroom fixtures and tiles',
      status: 'pending',
      assigned_to: 3,
      estimated_hours: 6,
      cost: 200.00,
      sort_order: 1,
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: '750e8400-e29b-41d4-a716-446655440005',
      project_id: '650e8400-e29b-41d4-a716-446655440003',
      title: 'Frame deck structure',
      description: 'Build the wooden frame for the deck',
      status: 'completed',
      assigned_to: 1,
      estimated_hours: 20,
      actual_hours: 18,
      cost: 800.00,
      sort_order: 1,
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: '750e8400-e29b-41d4-a716-446655440006',
      project_id: '650e8400-e29b-41d4-a716-446655440003',
      title: 'Install decking boards',
      description: 'Install and finish wooden decking boards',
      status: 'completed',
      assigned_to: 1,
      estimated_hours: 12,
      actual_hours: 14,
      cost: 600.00,
      sort_order: 2,
      created_at: new Date(),
      updated_at: new Date()
    }
  ]);
};