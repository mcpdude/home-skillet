/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> } 
 */
exports.seed = async function(knex) {
  // Deletes ALL existing entries (in development only)
  if (process.env.NODE_ENV === 'development') {
    await knex('tasks').del();
    await knex('projects').del();
  }

  // Insert projects first
  const projects = [
    {
      id: 'q6uurs55-3s6r-0uv4-rr2t-2rr5rs946q77',
      property_id: 'f5jjgh44-2h5g-9jk3-gg1i-1gg4gh835f66', // Main Family Home
      title: 'Master Bathroom Renovation',
      description: 'Complete renovation of master bathroom including new tile, vanity, toilet, and lighting.',
      category: 'renovation',
      subcategory: 'bathroom_renovation',
      priority: 'high',
      project_type: 'improvement',
      complexity: 'complex',
      status: 'in_progress',
      progress_percentage: 35,
      planned_start_date: new Date('2023-10-01'),
      planned_end_date: new Date('2023-11-15'),
      actual_start_date: new Date('2023-10-05'),
      estimated_hours: 120,
      actual_hours: 45,
      estimated_cost: 15000.00,
      actual_cost: 6750.00,
      budget_limit: 18000.00,
      requires_permits: true,
      permit_info: JSON.stringify({
        permit_number: 'SP-BATH-2023-0145',
        status: 'approved',
        issued_date: '2023-09-15',
        expiration_date: '2024-03-15'
      }),
      location_in_property: 'Master Bathroom',
      affected_areas: JSON.stringify(['master_bathroom', 'master_bedroom_access']),
      required_materials: JSON.stringify([
        { item: 'Porcelain floor tile', quantity: '80 sq ft', estimated_cost: 480.00 },
        { item: 'Vanity with countertop', quantity: 1, estimated_cost: 1200.00 },
        { item: 'Toilet', quantity: 1, estimated_cost: 350.00 },
        { item: 'LED light fixtures', quantity: 3, estimated_cost: 225.00 }
      ]),
      required_tools: JSON.stringify(['tile_saw', 'drill', 'level', 'measuring_tape']),
      photos: JSON.stringify({
        before: ['https://example.com/photos/bathroom_before_1.jpg', 'https://example.com/photos/bathroom_before_2.jpg'],
        during: ['https://example.com/photos/bathroom_progress_1.jpg'],
        after: []
      }),
      attachments: JSON.stringify([
        'https://example.com/attachments/bathroom_plans.pdf',
        'https://example.com/attachments/permit_approval.pdf'
      ]),
      warranty_applicable: true,
      warranty_info: JSON.stringify({
        materials_warranty: '5 years',
        labor_warranty: '2 years',
        warranty_provider: 'Elite Electrical Services'
      }),
      created_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', // John Owner
      primary_assignee_id: 'b1ffcd00-8d1c-5fg9-cc7e-7cc0ce491b22', // Jane Family
      last_modified_by: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    },
    {
      id: 'r7vvst66-4t7s-1vw5-ss3u-3ss6st057r88',
      property_id: 'f5jjgh44-2h5g-9jk3-gg1i-1gg4gh835f66', // Main Family Home
      title: 'HVAC System Annual Maintenance',
      description: 'Annual maintenance of central air conditioning system including filter replacement, coil cleaning, and system inspection.',
      category: 'maintenance',
      subcategory: 'hvac_maintenance',
      priority: 'medium',
      project_type: 'maintenance',
      complexity: 'simple',
      status: 'completed',
      progress_percentage: 100,
      planned_start_date: new Date('2023-09-15'),
      planned_end_date: new Date('2023-09-15'),
      actual_start_date: new Date('2023-09-15'),
      actual_end_date: new Date('2023-09-15'),
      estimated_hours: 3,
      actual_hours: 2.5,
      estimated_cost: 350.00,
      actual_cost: 325.00,
      budget_limit: 400.00,
      requires_permits: false,
      location_in_property: 'Basement and Exterior Unit',
      affected_areas: JSON.stringify(['basement', 'exterior_east_side']),
      required_materials: JSON.stringify([
        { item: 'HVAC Filter 20x25x1', quantity: 2, estimated_cost: 25.00 },
        { item: 'Coil cleaner', quantity: 1, estimated_cost: 15.00 }
      ]),
      photos: JSON.stringify({
        before: ['https://example.com/photos/hvac_before_maintenance.jpg'],
        during: [],
        after: ['https://example.com/photos/hvac_after_maintenance.jpg']
      }),
      quality_rating: 5,
      completion_notes: 'System is running efficiently. Recommended replacing thermostat within next year.',
      warranty_applicable: true,
      warranty_info: JSON.stringify({
        service_warranty: '90 days',
        warranty_provider: 'Springfield HVAC Services'
      }),
      created_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      primary_assignee_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      last_modified_by: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    },
    {
      id: 's8wwtu77-5u8t-2wx6-tt4v-4tt7tu168s99',
      property_id: 'g6kkhi55-3i6h-0kl4-hh2j-2hh5hi946g77', // Downtown Rental
      title: 'Kitchen Faucet Replacement',
      description: 'Replace leaking kitchen faucet with new modern fixture.',
      category: 'repair',
      subcategory: 'plumbing_repair',
      priority: 'medium',
      project_type: 'repair',
      complexity: 'simple',
      status: 'not_started',
      progress_percentage: 0,
      planned_start_date: new Date('2023-11-01'),
      planned_end_date: new Date('2023-11-01'),
      estimated_hours: 2,
      estimated_cost: 275.00,
      budget_limit: 350.00,
      requires_permits: false,
      location_in_property: 'Kitchen',
      affected_areas: JSON.stringify(['kitchen']),
      required_materials: JSON.stringify([
        { item: 'Kitchen faucet with sprayer', quantity: 1, estimated_cost: 150.00 },
        { item: 'Supply lines', quantity: 2, estimated_cost: 25.00 }
      ]),
      required_tools: JSON.stringify(['wrench_set', 'plumbers_tape', 'bucket']),
      photos: JSON.stringify({
        before: ['https://example.com/photos/faucet_leak.jpg'],
        during: [],
        after: []
      }),
      created_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      last_modified_by: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    }
  ];

  await knex('projects').insert(projects);

  // Insert tasks for the bathroom renovation project
  const tasks = [
    {
      id: 't9xxuv88-6v9u-3xy7-uu5w-5uu8uv279t00',
      project_id: 'q6uurs55-3s6r-0uv4-rr2t-2rr5rs946q77', // Master Bathroom Renovation
      title: 'Remove existing fixtures',
      description: 'Remove old toilet, vanity, and light fixtures',
      sort_order: 1,
      is_completed: true,
      completed_at: new Date('2023-10-06'),
      completed_by_user_id: 'c2ggde11-9e2d-6hg0-dd8f-8dd1de502c33', // Mike Contractor
      assigned_to_user_id: 'c2ggde11-9e2d-6hg0-dd8f-8dd1de502c33',
      priority: 'high',
      category: 'renovation',
      estimated_hours: 4,
      actual_hours: 3.5,
      estimated_cost: 200.00,
      actual_cost: 175.00,
      required_tools: JSON.stringify(['wrench_set', 'screwdriver_set', 'reciprocating_saw']),
      photos: JSON.stringify(['https://example.com/photos/fixtures_removed.jpg']),
      completion_notes: 'All fixtures removed without damage to walls. Ready for tile work.',
      created_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      last_modified_by: 'c2ggde11-9e2d-6hg0-dd8f-8dd1de502c33'
    },
    {
      id: 'u0yyvw99-7w0v-4yz8-vv6x-6vv9vw380u11',
      project_id: 'q6uurs55-3s6r-0uv4-rr2t-2rr5rs946q77', // Master Bathroom Renovation
      title: 'Install new floor tile',
      description: 'Install porcelain floor tile with proper waterproofing',
      sort_order: 2,
      is_completed: true,
      completed_at: new Date('2023-10-10'),
      completed_by_user_id: 'c2ggde11-9e2d-6hg0-dd8f-8dd1de502c33',
      assigned_to_user_id: 'c2ggde11-9e2d-6hg0-dd8f-8dd1de502c33',
      priority: 'high',
      category: 'renovation',
      estimated_hours: 12,
      actual_hours: 14,
      estimated_cost: 800.00,
      actual_cost: 950.00,
      prerequisite_task_ids: JSON.stringify(['t9xxuv88-6v9u-3xy7-uu5w-5uu8uv279t00']),
      required_materials: JSON.stringify([
        { item: 'Porcelain floor tile', quantity: '80 sq ft', cost: 480.00 },
        { item: 'Tile adhesive', quantity: '2 bags', cost: 45.00 },
        { item: 'Grout', quantity: '1 bag', cost: 25.00 },
        { item: 'Waterproof membrane', quantity: '1 roll', cost: 75.00 }
      ]),
      required_tools: JSON.stringify(['tile_saw', 'trowel', 'level', 'spacers']),
      photos: JSON.stringify(['https://example.com/photos/floor_tile_progress.jpg']),
      completion_notes: 'Floor tile installation complete. Grout needs 24 hours to cure before fixture installation.',
      created_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      last_modified_by: 'c2ggde11-9e2d-6hg0-dd8f-8dd1de502c33'
    },
    {
      id: 'v1zzwx00-8x1w-5za9-ww7y-7ww0wx491v22',
      project_id: 'q6uurs55-3s6r-0uv4-rr2t-2rr5rs946q77', // Master Bathroom Renovation
      title: 'Install new vanity',
      description: 'Install new vanity with countertop and plumbing connections',
      sort_order: 3,
      is_completed: false,
      assigned_to_user_id: 'c2ggde11-9e2d-6hg0-dd8f-8dd1de502c33',
      due_date: new Date('2023-10-25'),
      priority: 'high',
      category: 'renovation',
      estimated_hours: 6,
      estimated_cost: 300.00,
      prerequisite_task_ids: JSON.stringify(['u0yyvw99-7w0v-4yz8-vv6x-6vv9vw380u11']),
      required_materials: JSON.stringify([
        { item: 'Vanity with countertop', quantity: 1, cost: 1200.00 },
        { item: 'Faucet', quantity: 1, cost: 180.00 },
        { item: 'Supply lines', quantity: 2, cost: 30.00 }
      ]),
      required_tools: JSON.stringify(['drill', 'level', 'wrench_set', 'silicone_caulk']),
      created_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      last_modified_by: 'b1ffcd00-8d1c-5fg9-cc7e-7cc0ce491b22'
    },
    {
      id: 'w2aaxy11-9y2x-6ab0-xx8z-8xx1xy502w33',
      project_id: 'q6uurs55-3s6r-0uv4-rr2t-2rr5rs946q77', // Master Bathroom Renovation
      title: 'Install new toilet',
      description: 'Install new toilet with wax ring and water connection',
      sort_order: 4,
      is_completed: false,
      assigned_to_user_id: 'c2ggde11-9e2d-6hg0-dd8f-8dd1de502c33',
      due_date: new Date('2023-10-26'),
      priority: 'high',
      category: 'renovation',
      estimated_hours: 2,
      estimated_cost: 150.00,
      prerequisite_task_ids: JSON.stringify(['u0yyvw99-7w0v-4yz8-vv6x-6vv9vw380u11']),
      required_materials: JSON.stringify([
        { item: 'Toilet', quantity: 1, cost: 350.00 },
        { item: 'Wax ring', quantity: 1, cost: 12.00 },
        { item: 'Toilet bolts', quantity: 1, cost: 8.00 }
      ]),
      required_tools: JSON.stringify(['wrench_set', 'level']),
      created_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      last_modified_by: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    },
    {
      id: 'x3bbyz22-0z3y-7bc1-yy9a-9yy2yz613x44',
      project_id: 'q6uurs55-3s6r-0uv4-rr2t-2rr5rs946q77', // Master Bathroom Renovation
      title: 'Install new light fixtures',
      description: 'Install LED light fixtures and update electrical connections',
      sort_order: 5,
      is_completed: false,
      assigned_to_user_id: 'p5ttqr44-2r5q-9tu3-qq1s-1qq4qr835p66', // Elite Electrical (vendor)
      due_date: new Date('2023-11-01'),
      priority: 'medium',
      category: 'electrical',
      estimated_hours: 4,
      estimated_cost: 400.00,
      prerequisite_task_ids: JSON.stringify(['v1zzwx00-8x1w-5za9-ww7y-7ww0wx491v22']),
      required_materials: JSON.stringify([
        { item: 'LED vanity lights', quantity: 2, cost: 150.00 },
        { item: 'Ceiling light fixture', quantity: 1, cost: 75.00 },
        { item: 'Electrical wire', quantity: '50 ft', cost: 25.00 }
      ]),
      required_tools: JSON.stringify(['wire_strippers', 'electrical_tester', 'drill', 'wire_nuts']),
      requires_verification: true,
      created_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      last_modified_by: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    },
    // Simple task for HVAC maintenance project
    {
      id: 'y4cczb33-1b4z-8cd2-zz0b-0zz3zb724y55',
      project_id: 'r7vvst66-4t7s-1vw5-ss3u-3ss6st057r88', // HVAC Maintenance
      title: 'Replace HVAC filters',
      description: 'Replace both return air filters with new high-efficiency filters',
      sort_order: 1,
      is_completed: true,
      completed_at: new Date('2023-09-15'),
      completed_by_user_id: 'n3rrop22-0p3o-7rs1-oo9q-9oo2op613n44', // Springfield HVAC (vendor)
      priority: 'medium',
      category: 'maintenance',
      estimated_hours: 0.5,
      actual_hours: 0.5,
      estimated_cost: 50.00,
      actual_cost: 45.00,
      required_materials: JSON.stringify([
        { item: 'HVAC Filter 20x25x1 MERV 11', quantity: 2, cost: 25.00 }
      ]),
      completion_notes: 'Filters replaced. Old filters were moderately dirty, replacement was due.',
      created_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      last_modified_by: 'n3rrop22-0p3o-7rs1-oo9q-9oo2op613n44'
    }
  ];

  await knex('tasks').insert(tasks);
};