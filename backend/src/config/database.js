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
    client: 'pg',
    connection: process.env.SUPABASE_DB_URL_TEST || {
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5432,
      database: process.env.DB_NAME || 'home_skillet_test',
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      ssl: false,
    },
    pool: {
      min: 1,
      max: 5,
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
    connection: process.env.SUPABASE_DB_URL || process.env.DATABASE_URL || {
      host: process.env.DB_HOST,
      port: process.env.DB_PORT || 5432,
      database: process.env.DB_NAME,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      ssl: { rejectUnauthorized: false },
    },
    pool: {
      min: 2,
      max: 20,
      acquireTimeoutMillis: 60000,
      idleTimeoutMillis: 600000,
      createTimeoutMillis: 30000,
      destroyTimeoutMillis: 5000,
      reapIntervalMillis: 1000,
      createRetryIntervalMillis: 200,
    },
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