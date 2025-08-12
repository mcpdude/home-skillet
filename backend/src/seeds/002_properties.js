/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> } 
 */
exports.seed = async function(knex) {
  // Deletes ALL existing entries
  await knex('properties').del();
  
  // Insert seed properties
  await knex('properties').insert([
    {
      id: '550e8400-e29b-41d4-a716-446655440001',
      name: 'Sunset Villa',
      description: 'A beautiful 3-bedroom villa with ocean views',
      address: '123 Ocean Drive, Miami, FL 33139',
      type: 'residential',
      bedrooms: 3,
      bathrooms: 2,
      square_feet: 2200,
      lot_size: 0.25,
      year_built: 2015,
      owner_id: 1,
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: '550e8400-e29b-41d4-a716-446655440002',
      name: 'Downtown Apartment',
      description: 'Modern 2-bedroom apartment in the heart of downtown',
      address: '456 Main Street, Unit 5B, New York, NY 10001',
      type: 'residential',
      bedrooms: 2,
      bathrooms: 1,
      square_feet: 1200,
      lot_size: null,
      year_built: 2020,
      owner_id: 2,
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: '550e8400-e29b-41d4-a716-446655440003',
      name: 'Suburban Family Home',
      description: 'Spacious family home with large backyard',
      address: '789 Maple Lane, Austin, TX 78704',
      type: 'residential',
      bedrooms: 4,
      bathrooms: 3,
      square_feet: 2800,
      lot_size: 0.5,
      year_built: 2010,
      owner_id: 1,
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: '550e8400-e29b-41d4-a716-446655440004',
      name: 'Office Building',
      description: 'Small commercial office building',
      address: '321 Business Blvd, San Francisco, CA 94107',
      type: 'commercial',
      bedrooms: null,
      bathrooms: 4,
      square_feet: 5000,
      lot_size: 0.1,
      year_built: 2005,
      owner_id: 3,
      created_at: new Date(),
      updated_at: new Date()
    }
  ]);
};