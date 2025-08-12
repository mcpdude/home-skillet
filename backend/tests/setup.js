// Global test setup
process.env.NODE_ENV = 'test';
require('dotenv').config({ path: '.env.test' });

const db = require('../src/config/database');

// Increase timeout for database operations
jest.setTimeout(30000);

// Set up test database
beforeAll(async () => {
  // Run migrations for test database
  await db.migrate.latest();
});

// Clean up database before each test
beforeEach(async () => {
  // Clear all tables in reverse dependency order
  const tables = [
    // Insurance system tables
    'insurance_inventory_reports',
    'insurance_valuations', 
    'insurance_item_documents',
    'insurance_item_photos',
    'insurance_items',
    // Document system tables
    'document_access_log',
    'documents',
    // Task system tables
    'task_dependencies',
    'task_comments', 
    'task_time_tracking',
    'property_photos',
    'project_tasks',
    'project_assignments',
    'projects',
    'property_permissions',
    'properties',
    'users'
  ];
  
  for (const table of tables) {
    try {
      await db(table).del();
    } catch (error) {
      // Table might not exist yet, ignore
    }
  }
});

// Close database connection after all tests
afterAll(async () => {
  await db.destroy();
});

// Mock console methods to avoid noise in tests
const originalError = console.error;
const originalWarn = console.warn;

beforeAll(() => {
  console.error = jest.fn();
  console.warn = jest.fn();
});

afterAll(() => {
  console.error = originalError;
  console.warn = originalWarn;
});

// Clean up after each test
afterEach(() => {
  jest.clearAllMocks();
});