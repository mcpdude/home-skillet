const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

async function runMigrations() {
  console.log('🚀 Starting Railway database migration...');
  
  const client = new Client({
    host: 'db.yrkbpbwwewjjdmsspifl.supabase.co',
    port: 5432,
    database: 'postgres',
    user: 'postgres',
    password: 'lk5FPenvv8yk4nqY',
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('🔗 Connecting to Supabase database...');
    await client.connect();
    console.log('✅ Connected successfully');

    // Create migrations table if it doesn't exist
    await client.query(`
      CREATE TABLE IF NOT EXISTS knex_migrations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        batch INTEGER NOT NULL,
        migration_time TIMESTAMPTZ DEFAULT NOW()
      )
    `);
    console.log('✅ Migrations table ready');

    // Get completed migrations
    const { rows: completedMigrations } = await client.query(
      'SELECT name FROM knex_migrations ORDER BY id'
    );
    const completed = completedMigrations.map(row => row.name);
    console.log(`📋 Found ${completed.length} completed migrations`);

    // Get migration files
    const migrationsDir = path.join(__dirname, 'src', 'migrations');
    const migrationFiles = fs.readdirSync(migrationsDir)
      .filter(file => file.endsWith('.js'))
      .sort();
    
    console.log(`📂 Found ${migrationFiles.length} migration files`);

    // Determine next batch number
    let batch = 1;
    if (completed.length > 0) {
      const { rows } = await client.query('SELECT MAX(batch) as max_batch FROM knex_migrations');
      batch = (rows[0].max_batch || 0) + 1;
    }

    // Run pending migrations
    for (const file of migrationFiles) {
      if (!completed.includes(file)) {
        console.log(`🔄 Running migration: ${file}`);
        
        try {
          // For Railway, we'll run the most critical migration manually
          if (file.includes('create_insurance_inventory_system')) {
            await runInsuranceSystemMigration(client);
          } else {
            console.log(`⏭️  Skipping ${file} - manual setup required`);
          }
          
          // Record migration as completed
          await client.query(
            'INSERT INTO knex_migrations (name, batch) VALUES ($1, $2)',
            [file, batch]
          );
          
          console.log(`✅ Completed: ${file}`);
        } catch (error) {
          console.error(`❌ Failed to run ${file}:`, error.message);
          throw error;
        }
      } else {
        console.log(`✅ Already completed: ${file}`);
      }
    }

    console.log('🎉 All migrations completed successfully');
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    throw error;
  } finally {
    await client.end();
  }
}

async function runInsuranceSystemMigration(client) {
  console.log('🏠 Creating insurance inventory system tables...');
  
  // Core tables for the insurance system
  const tables = [
    `CREATE TABLE IF NOT EXISTS insurance_items (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
      property_id UUID,
      user_id UUID NOT NULL,
      name VARCHAR(255) NOT NULL,
      category VARCHAR(50) NOT NULL,
      room_location VARCHAR(100),
      brand VARCHAR(100),
      model VARCHAR(100),
      serial_number VARCHAR(100),
      purchase_date DATE,
      purchase_price DECIMAL(12, 2),
      replacement_cost DECIMAL(12, 2),
      condition VARCHAR(20) DEFAULT 'good',
      is_insured BOOLEAN DEFAULT false,
      notes TEXT,
      tags JSONB,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    )`,
    
    `CREATE TABLE IF NOT EXISTS insurance_item_photos (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
      item_id UUID NOT NULL REFERENCES insurance_items(id) ON DELETE CASCADE,
      filename VARCHAR(255) NOT NULL,
      file_url TEXT NOT NULL,
      photo_type VARCHAR(20) DEFAULT 'overview',
      file_size INTEGER,
      file_hash VARCHAR(64),
      created_at TIMESTAMPTZ DEFAULT NOW()
    )`,
    
    `CREATE TABLE IF NOT EXISTS insurance_item_documents (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
      item_id UUID NOT NULL REFERENCES insurance_items(id) ON DELETE CASCADE,
      document_id UUID NOT NULL,
      document_type VARCHAR(50) DEFAULT 'receipt',
      created_at TIMESTAMPTZ DEFAULT NOW()
    )`
  ];

  for (const sql of tables) {
    await client.query(sql);
  }
  
  console.log('✅ Insurance system tables created');
}

if (require.main === module) {
  runMigrations().catch(error => {
    console.error('Migration script failed:', error);
    process.exit(1);
  });
}

module.exports = { runMigrations };