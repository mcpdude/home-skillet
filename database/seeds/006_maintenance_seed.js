/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> } 
 */
exports.seed = async function(knex) {
  // Deletes ALL existing entries (in development only)
  if (process.env.NODE_ENV === 'development') {
    await knex('maintenance_records').del();
    await knex('maintenance_schedules').del();
  }

  // Insert maintenance schedules first
  const maintenanceSchedules = [
    {
      id: 'z5ddac44-2c5a-9de3-aa1c-1aa4ac835z66',
      property_id: 'f5jjgh44-2h5g-9jk3-gg1i-1gg4gh835f66', // Main Family Home
      title: 'HVAC Filter Replacement',
      description: 'Replace HVAC system air filters to maintain air quality and system efficiency',
      category: 'hvac',
      subcategory: 'filter_change',
      frequency_type: 'months',
      frequency_value: 3, // Every 3 months
      first_due_date: new Date('2023-03-01'),
      priority: 'medium',
      estimated_duration_minutes: 15,
      estimated_cost: 25.00,
      default_assignee_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', // John Owner
      can_be_delegated: true,
      requires_professional: false,
      instructions: '1. Turn off HVAC system\n2. Locate filter compartments in basement\n3. Remove old filters and note airflow direction\n4. Install new filters with airflow arrow pointing toward unit\n5. Turn system back on\n6. Record filter brand and date on filter frame',
      required_materials: JSON.stringify([
        { item: 'HVAC Filter 20x25x1 MERV 11', quantity: 2, estimated_cost: 25.00 }
      ]),
      required_tools: JSON.stringify(['flashlight']),
      safety_notes: JSON.stringify(['Turn off system before handling filters', 'Dispose of old filters properly']),
      reminder_days_before: 7,
      notification_recipients: JSON.stringify(['a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b1ffcd00-8d1c-5fg9-cc7e-7cc0ce491b22']),
      send_email_reminders: true,
      send_push_notifications: true,
      system_or_appliance: 'Central HVAC System',
      location_in_property: 'Basement Filter Compartments',
      completion_rate_percentage: 95,
      average_actual_cost: 27.50,
      average_actual_duration_minutes: 12,
      is_active: true,
      created_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      last_modified_by: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    },
    {
      id: 'a6eebd55-3d6b-0ef4-bb2d-2bb5bd946a77',
      property_id: 'f5jjgh44-2h5g-9jk3-gg1i-1gg4gh835f66', // Main Family Home
      title: 'Gutter Cleaning and Inspection',
      description: 'Clean gutters and downspouts, inspect for damage and proper drainage',
      category: 'exterior',
      subcategory: 'gutter_cleaning',
      frequency_type: 'seasonal',
      frequency_value: 2, // Twice per year
      seasons: JSON.stringify(['spring', 'fall']),
      first_due_date: new Date('2023-04-15'),
      priority: 'medium',
      estimated_duration_minutes: 180, // 3 hours
      estimated_cost: 150.00,
      default_assignee_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      can_be_delegated: true,
      requires_professional: false,
      instructions: '1. Set up ladder safely with spotter\n2. Remove debris from gutters by hand\n3. Flush gutters with water from hose\n4. Check downspouts for clogs and clear if needed\n5. Inspect gutters for damage, rust, or loose brackets\n6. Test water flow and drainage\n7. Document any issues found',
      required_materials: JSON.stringify([
        { item: 'Garbage bags', quantity: 3, estimated_cost: 5.00 },
        { item: 'Garden hose', quantity: 1, estimated_cost: 0 }
      ]),
      required_tools: JSON.stringify(['extension_ladder', 'work_gloves', 'small_trowel', 'bucket']),
      safety_notes: JSON.stringify([
        'Always have a spotter when using ladder',
        'Do not lean ladder against gutters',
        'Wear non-slip shoes',
        'Check weather - do not clean in windy conditions'
      ]),
      reminder_days_before: 14,
      notification_recipients: JSON.stringify(['a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b1ffcd00-8d1c-5fg9-cc7e-7cc0ce491b22']),
      send_email_reminders: true,
      send_push_notifications: true,
      system_or_appliance: 'Gutter System',
      location_in_property: 'Exterior - All Sides',
      completion_rate_percentage: 85,
      average_actual_cost: 165.00, // Sometimes hire professional
      average_actual_duration_minutes: 195,
      is_active: true,
      created_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      last_modified_by: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    },
    {
      id: 'b7ffce66-4e7c-1fg5-cc3e-3cc6ce057b88',
      property_id: 'f5jjgh44-2h5g-9jk3-gg1i-1gg4gh835f66', // Main Family Home
      title: 'Smoke Detector Battery Check',
      description: 'Test smoke detectors and replace batteries as needed',
      category: 'safety',
      subcategory: 'smoke_detector_test',
      frequency_type: 'months',
      frequency_value: 6, // Every 6 months
      first_due_date: new Date('2023-03-15'), // Spring forward
      priority: 'high',
      estimated_duration_minutes: 30,
      estimated_cost: 20.00,
      default_assignee_id: 'b1ffcd00-8d1c-5fg9-cc7e-7cc0ce491b22', // Jane Family
      can_be_delegated: true,
      requires_professional: false,
      instructions: '1. Press test button on each smoke detector\n2. Listen for loud alarm sound\n3. If alarm is weak or no sound, replace battery\n4. Test again after battery replacement\n5. Document which units needed new batteries\n6. Check expiration dates on detectors (replace every 10 years)',
      required_materials: JSON.stringify([
        { item: '9V batteries', quantity: 8, estimated_cost: 20.00 }
      ]),
      required_tools: JSON.stringify(['step_stool', 'flashlight']),
      safety_notes: JSON.stringify([
        'Test early in day to avoid disturbing neighbors',
        'Have fresh batteries ready before starting',
        'Check that detectors are properly mounted'
      ]),
      reminder_days_before: 3,
      notification_recipients: JSON.stringify(['a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b1ffcd00-8d1c-5fg9-cc7e-7cc0ce491b22']),
      send_email_reminders: true,
      send_push_notifications: true,
      system_or_appliance: 'Smoke Detection System',
      location_in_property: 'All Floors - 6 Units Total',
      completion_rate_percentage: 100, // Critical safety item
      average_actual_cost: 15.00, // Usually only need a few batteries
      average_actual_duration_minutes: 25,
      is_active: true,
      created_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      last_modified_by: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    },
    {
      id: 'c8ggdf77-5f8d-2gh6-dd4f-4dd7df168c99',
      property_id: 'g6kkhi55-3i6h-0kl4-hh2j-2hh5hi946g77', // Downtown Rental
      title: 'Mini-Split System Cleaning',
      description: 'Clean mini-split indoor unit filters and outdoor condenser',
      category: 'hvac',
      subcategory: 'mini_split_maintenance',
      frequency_type: 'months',
      frequency_value: 4, // Every 4 months
      first_due_date: new Date('2023-04-01'),
      priority: 'medium',
      estimated_duration_minutes: 60,
      estimated_cost: 0.00, // DIY maintenance
      default_assignee_id: 'd3hhef22-0f3e-7hi1-ee9g-9ee2ef613d44', // Sarah Tenant
      can_be_delegated: false, // Tenant responsibility
      requires_professional: false,
      instructions: '1. Turn off mini-split system\n2. Remove front panel from indoor unit\n3. Remove and wash filters with mild soap and water\n4. Let filters dry completely\n5. Wipe down indoor unit interior with damp cloth\n6. Check outdoor unit for debris and clear if needed\n7. Reinstall dry filters and front panel\n8. Turn system back on and test',
      required_materials: JSON.stringify([
        { item: 'Mild dish soap', quantity: 1, estimated_cost: 0.00 }
      ]),
      required_tools: JSON.stringify(['soft_cloth', 'soft_brush', 'bucket']),
      safety_notes: JSON.stringify([
        'Always turn off power before cleaning',
        'Ensure filters are completely dry before reinstalling',
        'Do not use harsh chemicals on filters'
      ]),
      reminder_days_before: 7,
      notification_recipients: JSON.stringify(['d3hhef22-0f3e-7hi1-ee9g-9ee2ef613d44', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11']),
      send_email_reminders: true,
      send_push_notifications: true,
      system_or_appliance: 'Mitsubishi Mini-Split System',
      location_in_property: 'Living Room Unit and Exterior Condenser',
      completion_rate_percentage: 75, // Tenant sometimes delays
      average_actual_cost: 0.00,
      average_actual_duration_minutes: 45,
      is_active: true,
      created_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      last_modified_by: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    }
  ];

  await knex('maintenance_schedules').insert(maintenanceSchedules);

  // Insert maintenance records
  const maintenanceRecords = [
    {
      id: 'd9hheg88-6g9e-3hi7-ee5g-5ee8eg279d00',
      property_id: 'f5jjgh44-2h5g-9jk3-gg1i-1gg4gh835f66', // Main Family Home
      maintenance_schedule_id: 'z5ddac44-2c5a-9de3-aa1c-1aa4ac835z66', // HVAC Filter Replacement
      title: 'HVAC Filter Replacement - Q3 2023',
      description: 'Quarterly HVAC filter replacement',
      category: 'hvac',
      subcategory: 'filter_change',
      completed_date: new Date('2023-09-01'),
      started_at: new Date('2023-09-01 10:15:00'),
      completed_at: new Date('2023-09-01 10:27:00'),
      duration_minutes: 12,
      performed_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', // John Owner
      work_performed: 'Replaced both HVAC filters in basement. Old filters were moderately dirty with dust and pet hair. Noted airflow direction and installed new MERV 11 filters properly. System restarted successfully.',
      materials_used: JSON.stringify([
        { item: 'HVAC Filter 20x25x1 MERV 11', quantity: 2, cost: 24.98 }
      ]),
      tools_used: JSON.stringify(['flashlight']),
      labor_cost: 0.00, // DIY
      materials_cost: 24.98,
      total_cost: 24.98,
      payment_method: 'personal',
      completion_status: 'completed',
      quality_rating: 5,
      system_or_appliance: 'Central HVAC System',
      location_in_property: 'Basement Filter Compartments',
      before_condition: JSON.stringify({ filter_condition: 'moderately_dirty', airflow: 'restricted' }),
      after_condition: JSON.stringify({ filter_condition: 'new', airflow: 'optimal' }),
      photos: JSON.stringify({
        before: ['https://example.com/photos/filters_before_sept2023.jpg'],
        after: ['https://example.com/photos/filters_after_sept2023.jpg']
      }),
      next_maintenance_due: new Date('2023-12-01'),
      next_maintenance_notes: 'Continue quarterly replacement schedule. Monitor for increased dirt due to construction project.',
      was_due_date: new Date('2023-09-01'),
      days_overdue: 0,
      was_preventive: true,
      created_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      last_modified_by: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    },
    {
      id: 'e0iifh99-7h0f-4ij8-ff6h-6ff9fh380e11',
      property_id: 'f5jjgh44-2h5g-9jk3-gg1i-1gg4gh835f66', // Main Family Home
      maintenance_schedule_id: 'b7ffce66-4e7c-1fg5-cc3e-3cc6ce057b88', // Smoke Detector Battery Check
      title: 'Smoke Detector Battery Check - Fall 2023',
      description: 'Semi-annual smoke detector battery check and testing',
      category: 'safety',
      subcategory: 'smoke_detector_test',
      completed_date: new Date('2023-09-15'),
      started_at: new Date('2023-09-15 14:00:00'),
      completed_at: new Date('2023-09-15 14:30:00'),
      duration_minutes: 30,
      performed_by_user_id: 'b1ffcd00-8d1c-5fg9-cc7e-7cc0ce491b22', // Jane Family
      work_performed: 'Tested all 6 smoke detectors in house. Units in master bedroom and kitchen needed new batteries - alarms were weak. Replaced batteries in both units and retested. All units now functioning properly. Checked expiration dates - all detectors are still within 10-year limit.',
      materials_used: JSON.stringify([
        { item: '9V batteries', quantity: 2, cost: 5.98 }
      ]),
      tools_used: JSON.stringify(['step_stool']),
      labor_cost: 0.00, // Family member
      materials_cost: 5.98,
      total_cost: 5.98,
      payment_method: 'personal',
      completion_status: 'completed',
      quality_rating: 5,
      system_or_appliance: 'Smoke Detection System',
      location_in_property: 'All Floors - 6 Units Total',
      before_condition: JSON.stringify({ 
        working_units: 4, 
        weak_batteries: 2, 
        failed_units: 0 
      }),
      after_condition: JSON.stringify({ 
        working_units: 6, 
        weak_batteries: 0, 
        failed_units: 0 
      }),
      photos: JSON.stringify({
        after: ['https://example.com/photos/smoke_detector_test_sept2023.jpg']
      }),
      next_maintenance_due: new Date('2024-03-15'),
      next_maintenance_notes: 'Next check in spring 2024. Consider upgrading to 10-year lithium battery units when current detectors reach end of life.',
      was_due_date: new Date('2023-09-15'),
      days_overdue: 0,
      was_preventive: true,
      created_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      last_modified_by: 'b1ffcd00-8d1c-5fg9-cc7e-7cc0ce491b22'
    },
    {
      id: 'f1jjgi00-8i1g-5jk9-gg7i-7gg0gi491f22',
      property_id: 'f5jjgh44-2h5g-9jk3-gg1i-1gg4gh835f66', // Main Family Home
      maintenance_schedule_id: 'a6eebd55-3d6b-0ef4-bb2d-2bb5bd946a77', // Gutter Cleaning
      title: 'Spring Gutter Cleaning 2023',
      description: 'Spring gutter cleaning and inspection',
      category: 'exterior',
      subcategory: 'gutter_cleaning',
      completed_date: new Date('2023-04-20'),
      started_at: new Date('2023-04-20 09:00:00'),
      completed_at: new Date('2023-04-20 12:30:00'),
      duration_minutes: 210, // 3.5 hours
      performed_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', // John Owner
      supervised_by_user_id: 'b1ffcd00-8d1c-5fg9-cc7e-7cc0ce491b22', // Jane as spotter
      work_performed: 'Cleaned all gutters around house perimeter. Removed approximately 3 bags of leaves, twigs, and debris. Flushed all gutters and downspouts with hose. Found one loose bracket on east side - tightened with screwdriver. All downspouts draining properly. Small amount of granule accumulation normal for roof age.',
      materials_used: JSON.stringify([
        { item: 'Heavy duty garbage bags', quantity: 3, cost: 4.99 }
      ]),
      tools_used: JSON.stringify(['extension_ladder', 'work_gloves', 'garden_trowel', 'garden_hose', 'screwdriver']),
      labor_cost: 0.00, // DIY
      materials_cost: 4.99,
      total_cost: 4.99,
      payment_method: 'personal',
      completion_status: 'completed',
      quality_rating: 4,
      issues_found: 'One loose gutter bracket on east side of house.',
      recommendations: 'Monitor bracket for further loosening. Consider gutter guard installation to reduce debris accumulation.',
      system_or_appliance: 'Gutter System',
      location_in_property: 'Exterior - All Sides',
      before_condition: JSON.stringify({ 
        debris_level: 'moderate', 
        water_flow: 'restricted',
        loose_brackets: 1
      }),
      after_condition: JSON.stringify({ 
        debris_level: 'clean', 
        water_flow: 'excellent',
        loose_brackets: 0
      }),
      photos: JSON.stringify({
        before: ['https://example.com/photos/gutters_before_spring2023.jpg'],
        after: ['https://example.com/photos/gutters_after_spring2023.jpg']
      }),
      next_maintenance_due: new Date('2023-10-15'),
      next_maintenance_notes: 'Fall cleaning scheduled. Check east side bracket condition.',
      was_due_date: new Date('2023-04-15'),
      days_overdue: 5, // Completed a few days late
      was_preventive: true,
      created_by_user_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      last_modified_by: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    }
  ];

  await knex('maintenance_records').insert(maintenanceRecords);
};