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
      connectionTimeout: 60000,
      keepAlive: true,
      keepAliveInitialDelay: 0
    },
    pool: {
      min: 0,
      max: 5,
      acquireTimeoutMillis: 120000,
      idleTimeoutMillis: 30000,
      createTimeoutMillis: 60000,
      destroyTimeoutMillis: 5000,
      reapIntervalMillis: 1000,
      createRetryIntervalMillis: 200,
      propagateCreateError: false
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
      keepAliveInitialDelay: 0,
      connectionTimeoutMillis: 60000,
      requestTimeout: 60000,
      statement_timeout: 60000,
      idle_in_transaction_session_timeout: 60000
    },
    pool: {
      min: 0,
      max: 1,
      acquireTimeoutMillis: 120000,
      idleTimeoutMillis: 5000,
      createTimeoutMillis: 120000,
      destroyTimeoutMillis: 10000,
      reapIntervalMillis: 500,
      createRetryIntervalMillis: 1000,
      propagateCreateError: false,
      log: (message, logLevel) => console.log('Pool:', logLevel, message)
    },
    // Force IPv4 for Railway
    asyncStackTraces: false,
    acquireConnectionTimeout: 30000,
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