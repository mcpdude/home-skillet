const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

async function runMigrations() {
  const client = new Client({
    host: 'db.yrkbpbwwewjjdmsspifl.supabase.co',
    port: 5432,
    database: 'postgres',
    user: 'postgres',
    password: 'lk5FPenvv8yk4nqY',
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('🔗 Connecting to database...');
    await client.connect();
    console.log('✅ Connected to database');

    // Create migrations table if it doesn't exist
    await client.query(`
      CREATE TABLE IF NOT EXISTS knex_migrations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        batch INTEGER NOT NULL,
        migration_time TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    // Get list of completed migrations
    const { rows: completedMigrations } = await client.query(
      'SELECT name FROM knex_migrations ORDER BY id'
    );
    const completed = completedMigrations.map(row => row.name);

    // Get list of migration files
    const migrationsDir = path.join(__dirname, 'src', 'migrations');
    const migrationFiles = fs.readdirSync(migrationsDir)
      .filter(file => file.endsWith('.js'))
      .sort();

    console.log(`📂 Found ${migrationFiles.length} migration files`);
    console.log(`✅ ${completed.length} migrations already completed`);

    // Run pending migrations
    let batch = 1;
    if (completed.length > 0) {
      const { rows } = await client.query('SELECT MAX(batch) as max_batch FROM knex_migrations');
      batch = (rows[0].max_batch || 0) + 1;
    }

    for (const file of migrationFiles) {
      if (!completed.includes(file)) {
        console.log(`🔄 Running migration: ${file}`);
        
        const migrationPath = path.join(migrationsDir, file);
        const migration = require(migrationPath);
        
        if (migration.up) {
          // Create a simple knex-like interface for the migration
          const knex = {
            schema: {
              createTable: async (tableName, callback) => {
                let sql = `CREATE TABLE IF NOT EXISTS ${tableName} (`;
                const columns = [];
                
                const table = {
                  uuid: (name) => {
                    columns.push(`${name} UUID DEFAULT gen_random_uuid()`);
                    return { primary: () => columns[columns.length - 1] += ' PRIMARY KEY' };
                  },
                  string: (name, length) => {
                    const col = `${name} VARCHAR${length ? `(${length})` : ''}`;
                    columns.push(col);
                    return {
                      notNullable: () => { columns[columns.length - 1] += ' NOT NULL'; return this; },
                      defaultTo: (val) => { columns[columns.length - 1] += ` DEFAULT '${val}'`; return this; }
                    };
                  },
                  text: (name) => {
                    columns.push(`${name} TEXT`);
                    return {
                      notNullable: () => { columns[columns.length - 1] += ' NOT NULL'; return this; }
                    };
                  },
                  decimal: (name, precision, scale) => {
                    columns.push(`${name} DECIMAL(${precision}, ${scale})`);
                    return {
                      notNullable: () => { columns[columns.length - 1] += ' NOT NULL'; return this; }
                    };
                  },
                  boolean: (name) => {
                    columns.push(`${name} BOOLEAN`);
                    return {
                      defaultTo: (val) => { columns[columns.length - 1] += ` DEFAULT ${val}`; return this; },
                      notNullable: () => { columns[columns.length - 1] += ' NOT NULL'; return this; }
                    };
                  },
                  json: (name) => {
                    columns.push(`${name} JSONB`);
                    return {
                      notNullable: () => { columns[columns.length - 1] += ' NOT NULL'; return this; }
                    };
                  },
                  integer: (name) => {
                    columns.push(`${name} INTEGER`);
                    return {
                      notNullable: () => { columns[columns.length - 1] += ' NOT NULL'; return this; },
                      defaultTo: (val) => { columns[columns.length - 1] += ` DEFAULT ${val}`; return this; }
                    };
                  },
                  timestamps: (useTimestamps, defaultToNow) => {
                    columns.push('created_at TIMESTAMPTZ DEFAULT NOW()');
                    columns.push('updated_at TIMESTAMPTZ DEFAULT NOW()');
                  },
                  foreign: (column) => {
                    return {
                      references: (refColumn) => {
                        return {
                          inTable: (table) => {
                            columns[columns.length - 1] += ` REFERENCES ${table}(${refColumn})`;
                            return {
                              onDelete: (action) => {
                                columns[columns.length - 1] += ` ON DELETE ${action}`;
                                return this;
                              }
                            };
                          }
                        };
                      }
                    };
                  }
                };
                
                callback(table);
                sql += columns.join(', ') + ')';
                await client.query(sql);
              }
            }
          };
          
          await migration.up(knex);
          
          // Record migration as completed
          await client.query(
            'INSERT INTO knex_migrations (name, batch) VALUES ($1, $2)',
            [file, batch]
          );
          
          console.log(`✅ Completed migration: ${file}`);
        }
      }
    }

    console.log('✅ All migrations completed successfully');
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    await client.end();
  }
}

if (require.main === module) {
  runMigrations().catch(error => {
    console.error('Migration script failed:', error);
    process.exit(1);
  });
}

module.exports = { runMigrations };