/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> } 
 */
exports.seed = async function(knex) {
  // Deletes ALL existing entries
  await knex('maintenance_schedules').del();
  
  // Insert seed maintenance schedules
  await knex('maintenance_schedules').insert([
    {
      id: '850e8400-e29b-41d4-a716-446655440001',
      property_id: '550e8400-e29b-41d4-a716-446655440001',
      title: 'HVAC Filter Replacement',
      description: 'Replace HVAC air filters',
      frequency: 'monthly',
      frequency_value: 1,
      category: 'hvac',
      next_due_date: '2024-02-15',
      last_completed_date: '2024-01-15',
      is_active: true,
      estimated_cost: 25.00,
      assigned_to: 2,
      created_by: 1,
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: '850e8400-e29b-41d4-a716-446655440002',
      property_id: '550e8400-e29b-41d4-a716-446655440001',
      title: 'Pool Cleaning',
      description: 'Weekly pool cleaning and chemical balance',
      frequency: 'weekly',
      frequency_value: 1,
      category: 'landscaping',
      next_due_date: '2024-01-22',
      last_completed_date: '2024-01-15',
      is_active: true,
      estimated_cost: 80.00,
      assigned_to: 3,
      created_by: 1,
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: '850e8400-e29b-41d4-a716-446655440003',
      property_id: '550e8400-e29b-41d4-a716-446655440002',
      title: 'Smoke Detector Testing',
      description: 'Test all smoke detectors and replace batteries',
      frequency: 'quarterly',
      frequency_value: 3,
      category: 'electrical',
      next_due_date: '2024-04-01',
      last_completed_date: '2024-01-01',
      is_active: true,
      estimated_cost: 15.00,
      created_by: 2,
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: '850e8400-e29b-41d4-a716-446655440004',
      property_id: '550e8400-e29b-41d4-a716-446655440003',
      title: 'Gutter Cleaning',
      description: 'Clean gutters and downspouts',
      frequency: 'quarterly',
      frequency_value: 3,
      category: 'exterior',
      next_due_date: '2024-03-15',
      last_completed_date: '2023-12-15',
      is_active: true,
      estimated_cost: 150.00,
      assigned_to: 2,
      created_by: 1,
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: '850e8400-e29b-41d4-a716-446655440005',
      property_id: '550e8400-e29b-41d4-a716-446655440004',
      title: 'Fire Extinguisher Inspection',
      description: 'Annual fire extinguisher inspection and maintenance',
      frequency: 'yearly',
      frequency_value: 1,
      category: 'safety',
      next_due_date: '2024-12-01',
      last_completed_date: '2023-12-01',
      is_active: true,
      estimated_cost: 100.00,
      created_by: 3,
      created_at: new Date(),
      updated_at: new Date()
    }
  ]);
};