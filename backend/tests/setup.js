// Global test setup
require('dotenv').config({ path: '.env.test' });

// Increase timeout for database operations
jest.setTimeout(10000);

// Test database setup - In a real app, this would be a test database
// For now, using in-memory storage for MVP testing
global.testData = {
  users: [],
  properties: [],
  projects: [],
  maintenanceSchedules: [],
  maintenanceRecords: [],
  userPropertyRoles: [],
  projectAssignments: []
};

// Reset test data before each test
beforeEach(() => {
  global.testData = {
    users: [],
    properties: [],
    projects: [],
    maintenanceSchedules: [],
    maintenanceRecords: [],
    userPropertyRoles: [],
    projectAssignments: []
  };
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