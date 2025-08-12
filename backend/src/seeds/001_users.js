const bcrypt = require('bcryptjs');

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> } 
 */
exports.seed = async function(knex) {
  // Deletes ALL existing entries
  await knex('users').del();
  
  // Hash passwords for seed users
  const hashedPassword1 = await bcrypt.hash('password123', 12);
  const hashedPassword2 = await bcrypt.hash('password456', 12);
  const hashedPassword3 = await bcrypt.hash('password789', 12);
  
  // Insert seed users
  await knex('users').insert([
    {
      id: 1,
      email: 'john.doe@example.com',
      password: hashedPassword1,
      first_name: 'John',
      last_name: 'Doe',
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: 2,
      email: 'jane.smith@example.com',
      password: hashedPassword2,
      first_name: 'Jane',
      last_name: 'Smith',
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: 3,
      email: 'bob.johnson@example.com',
      password: hashedPassword3,
      first_name: 'Bob',
      last_name: 'Johnson',
      created_at: new Date(),
      updated_at: new Date()
    }
  ]);
  
  // Reset the sequence for the id column
  await knex.raw("SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));");
};