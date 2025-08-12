/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> } 
 */
exports.seed = async function(knex) {
  // Deletes ALL existing entries (in development only)
  if (process.env.NODE_ENV === 'development') {
    await knex('properties').del();
  }

  // Insert seed entries
  const properties = [
    {
      id: 'f5jjgh44-2h5g-9jk3-gg1i-1gg4gh835f66',
      name: 'Main Family Home',
      property_type: 'single_family',
      street_address: '123 Maple Street',
      city: 'Springfield',
      state_province: 'MA',
      postal_code: '01103',
      country: 'US',
      latitude: 42.1015,
      longitude: -72.5898,
      year_built: 1995,
      square_footage: 2400,
      lot_size_sqft: 8000.00,
      bedrooms: 4,
      bathrooms: 2.5,
      architectural_style: 'Colonial',
      purchase_price: 385000.00,
      purchase_date: '2018-06-15',
      current_assessed_value: 450000.00,
      last_assessment_date: '2023-01-15',
      utility_accounts: JSON.stringify({
        electric: {
          provider: 'Springfield Electric',
          account_number: 'SE-123456789'
        },
        gas: {
          provider: 'National Grid',
          account_number: 'NG-987654321'
        },
        water: {
          provider: 'Springfield Water',
          account_number: 'SW-456789123'
        }
      }),
      insurance_info: JSON.stringify({
        provider: 'State Farm',
        policy_number: 'SF-HOME-789123',
        coverage_amount: 500000,
        deductible: 1000
      }),
      property_features: JSON.stringify({
        garage: {
          spaces: 2,
          type: 'attached'
        },
        pool: false,
        basement: {
          finished: true,
          square_footage: 800
        },
        deck: {
          material: 'composite',
          square_footage: 200
        }
      }),
      appliances: JSON.stringify({
        hvac: {
          system_type: 'forced_air',
          brand: 'Carrier',
          model: 'CA-2400',
          install_date: '2020-05-15',
          warranty_expires: '2030-05-15'
        },
        water_heater: {
          type: 'gas',
          brand: 'Rheem',
          model: 'RH-50',
          capacity_gallons: 50,
          install_date: '2019-03-20'
        }
      }),
      hvac_systems: JSON.stringify([
        {
          system_id: 1,
          type: 'central_air',
          zones: 2,
          brand: 'Carrier',
          model: 'CA-2400',
          install_date: '2020-05-15',
          last_maintenance: '2023-09-15'
        }
      ]),
      photos: JSON.stringify([
        'https://example.com/photos/property1/front.jpg',
        'https://example.com/photos/property1/kitchen.jpg',
        'https://example.com/photos/property1/living_room.jpg'
      ]),
      primary_photo_url: 'https://example.com/photos/property1/front.jpg',
      floor_plans: JSON.stringify([
        'https://example.com/floor_plans/property1/main_floor.pdf',
        'https://example.com/floor_plans/property1/second_floor.pdf'
      ]),
      is_primary_residence: true,
      is_active: true,
      settings: JSON.stringify({
        maintenance_reminders: true,
        auto_assign_family: true,
        public_listing: false
      })
    },
    {
      id: 'g6kkhi55-3i6h-0kl4-hh2j-2hh5hi946g77',
      name: 'Downtown Rental Property',
      property_type: 'condo',
      street_address: '456 Oak Avenue, Unit 12B',
      city: 'Springfield',
      state_province: 'MA',
      postal_code: '01108',
      country: 'US',
      latitude: 42.1085,
      longitude: -72.5798,
      year_built: 2005,
      square_footage: 1200,
      lot_size_sqft: 0, // Condo
      bedrooms: 2,
      bathrooms: 2.0,
      architectural_style: 'Modern',
      purchase_price: 225000.00,
      purchase_date: '2020-02-28',
      current_assessed_value: 275000.00,
      last_assessment_date: '2023-01-15',
      utility_accounts: JSON.stringify({
        electric: {
          provider: 'Springfield Electric',
          account_number: 'SE-987654321'
        }
      }),
      insurance_info: JSON.stringify({
        provider: 'Allstate',
        policy_number: 'AS-CONDO-456789',
        coverage_amount: 300000,
        deductible: 500
      }),
      property_features: JSON.stringify({
        garage: false,
        pool: false, // Building has communal pool
        balcony: {
          square_footage: 80,
          orientation: 'east'
        }
      }),
      appliances: JSON.stringify({
        hvac: {
          system_type: 'mini_split',
          brand: 'Mitsubishi',
          model: 'MS-1200',
          install_date: '2020-03-15'
        }
      }),
      hvac_systems: JSON.stringify([
        {
          system_id: 1,
          type: 'mini_split',
          zones: 1,
          brand: 'Mitsubishi',
          model: 'MS-1200',
          install_date: '2020-03-15'
        }
      ]),
      photos: JSON.stringify([
        'https://example.com/photos/property2/front.jpg',
        'https://example.com/photos/property2/kitchen.jpg'
      ]),
      primary_photo_url: 'https://example.com/photos/property2/front.jpg',
      is_primary_residence: false,
      is_active: true,
      settings: JSON.stringify({
        maintenance_reminders: true,
        auto_assign_family: false,
        public_listing: true
      })
    }
  ];

  await knex('properties').insert(properties);
};