const knex = require('knex');

const config = {
  development: {
    client: 'pg',
    connection: process.env.SUPABASE_DB_URL || {
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5432,
      database: process.env.DB_NAME || 'home_skillet_dev',
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
    },
    pool: {
      min: 2,
      max: 10,
      acquireTimeoutMillis: 60000,
      idleTimeoutMillis: 600000,
    },
    migrations: {
      directory: __dirname + '/../migrations',
      tableName: 'knex_migrations'
    },
    seeds: {
      directory: __dirname + '/../seeds'
    }
  },
  test: {
    client: 'sqlite3',
    connection: {
      filename: ':memory:'
    },
    useNullAsDefault: true,
    pool: {
      min: 1,
      max: 1,
    },
    migrations: {
      directory: __dirname + '/../migrations',
      tableName: 'knex_migrations'
    },
    seeds: {
      directory: __dirname + '/../seeds'
    }
  },
  production: {
    client: 'pg',
    connection: {
      host: 'yrkbpbwwewjjdmsspifl.supabase.co',
      port: 5432,
      database: 'postgres',
      user: 'postgres',
      password: 'lk5FPenvv8yk4nqY',
      ssl: { rejectUnauthorized: false },
      // Force IPv4 DNS resolution
      family: 4,
      keepAlive: true,
      keepAliveInitialDelay: 0
    },
    pool: {
      min: 1,
      max: 5,
      acquireTimeoutMillis: 20000,
      idleTimeoutMillis: 300000,
      createTimeoutMillis: 10000,
      destroyTimeoutMillis: 5000,
      reapIntervalMillis: 1000,
      createRetryIntervalMillis: 200,
    },
    // Force IPv4 for Railway
    asyncStackTraces: false,
    acquireConnectionTimeout: 20000,
    migrations: {
      directory: __dirname + '/../migrations',
      tableName: 'knex_migrations'
    },
    seeds: {
      directory: __dirname + '/../seeds'
    }
  }
};

const environment = process.env.NODE_ENV || 'development';
const db = knex(config[environment]);

module.exports = db;