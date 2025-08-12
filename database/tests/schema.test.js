const knex = require('knex');
const config = require('../knexfile');

// Use test configuration
const db = knex(config.test);

describe('Database Schema Tests', () => {
  beforeAll(async () => {
    // Run migrations before tests
    await db.migrate.latest();
  });

  afterAll(async () => {
    // Clean up and close database connection
    await db.destroy();
  });

  describe('Table Existence', () => {
    test('should have users table', async () => {
      const exists = await db.schema.hasTable('users');
      expect(exists).toBe(true);
    });

    test('should have properties table', async () => {
      const exists = await db.schema.hasTable('properties');
      expect(exists).toBe(true);
    });

    test('should have user_property_roles table', async () => {
      const exists = await db.schema.hasTable('user_property_roles');
      expect(exists).toBe(true);
    });

    test('should have projects table', async () => {
      const exists = await db.schema.hasTable('projects');
      expect(exists).toBe(true);
    });

    test('should have tasks table', async () => {
      const exists = await db.schema.hasTable('tasks');
      expect(exists).toBe(true);
    });

    test('should have maintenance_schedules table', async () => {
      const exists = await db.schema.hasTable('maintenance_schedules');
      expect(exists).toBe(true);
    });

    test('should have maintenance_records table', async () => {
      const exists = await db.schema.hasTable('maintenance_records');
      expect(exists).toBe(true);
    });

    test('should have documents table', async () => {
      const exists = await db.schema.hasTable('documents');
      expect(exists).toBe(true);
    });

    test('should have vendors table', async () => {
      const exists = await db.schema.hasTable('vendors');
      expect(exists).toBe(true);
    });

    test('should have project_assignments table', async () => {
      const exists = await db.schema.hasTable('project_assignments');
      expect(exists).toBe(true);
    });
  });

  describe('Table Columns', () => {
    test('users table should have required columns', async () => {
      const columns = await db('users').columnInfo();
      
      expect(columns).toHaveProperty('id');
      expect(columns).toHaveProperty('email');
      expect(columns).toHaveProperty('password_hash');
      expect(columns).toHaveProperty('first_name');
      expect(columns).toHaveProperty('last_name');
      expect(columns).toHaveProperty('is_email_verified');
      expect(columns).toHaveProperty('is_active');
      expect(columns).toHaveProperty('created_at');
      expect(columns).toHaveProperty('updated_at');
    });

    test('properties table should have required columns', async () => {
      const columns = await db('properties').columnInfo();
      
      expect(columns).toHaveProperty('id');
      expect(columns).toHaveProperty('name');
      expect(columns).toHaveProperty('property_type');
      expect(columns).toHaveProperty('street_address');
      expect(columns).toHaveProperty('city');
      expect(columns).toHaveProperty('state_province');
      expect(columns).toHaveProperty('postal_code');
      expect(columns).toHaveProperty('is_active');
    });

    test('user_property_roles table should have required columns', async () => {
      const columns = await db('user_property_roles').columnInfo();
      
      expect(columns).toHaveProperty('id');
      expect(columns).toHaveProperty('user_id');
      expect(columns).toHaveProperty('property_id');
      expect(columns).toHaveProperty('role');
      expect(columns).toHaveProperty('permissions');
      expect(columns).toHaveProperty('is_active');
      expect(columns).toHaveProperty('invitation_status');
    });

    test('projects table should have required columns', async () => {
      const columns = await db('projects').columnInfo();
      
      expect(columns).toHaveProperty('id');
      expect(columns).toHaveProperty('property_id');
      expect(columns).toHaveProperty('title');
      expect(columns).toHaveProperty('category');
      expect(columns).toHaveProperty('priority');
      expect(columns).toHaveProperty('status');
      expect(columns).toHaveProperty('progress_percentage');
      expect(columns).toHaveProperty('created_by_user_id');
    });

    test('tasks table should have required columns', async () => {
      const columns = await db('tasks').columnInfo();
      
      expect(columns).toHaveProperty('id');
      expect(columns).toHaveProperty('project_id');
      expect(columns).toHaveProperty('title');
      expect(columns).toHaveProperty('is_completed');
      expect(columns).toHaveProperty('sort_order');
      expect(columns).toHaveProperty('created_by_user_id');
    });
  });

  describe('Foreign Key Relationships', () => {
    test('user_property_roles should reference users and properties', async () => {
      // This test checks that foreign key constraints exist by attempting to insert invalid data
      await expect(
        db('user_property_roles').insert({
          user_id: 'invalid-user-id',
          property_id: 'invalid-property-id',
          role: 'owner',
          permissions: '{}',
          invited_by_user_id: 'invalid-user-id'
        })
      ).rejects.toThrow();
    });

    test('projects should reference properties and users', async () => {
      await expect(
        db('projects').insert({
          property_id: 'invalid-property-id',
          title: 'Test Project',
          category: 'test',
          priority: 'medium',
          project_type: 'maintenance',
          status: 'not_started',
          created_by_user_id: 'invalid-user-id'
        })
      ).rejects.toThrow();
    });

    test('tasks should reference projects', async () => {
      await expect(
        db('tasks').insert({
          project_id: 'invalid-project-id',
          title: 'Test Task',
          created_by_user_id: 'invalid-user-id'
        })
      ).rejects.toThrow();
    });
  });

  describe('Data Integrity Constraints', () => {
    test('users email should be unique', async () => {
      const testEmail = 'test@example.com';
      
      // Insert first user
      const user1 = await db('users').insert({
        email: testEmail,
        first_name: 'Test',
        last_name: 'User1'
      }).returning('id');

      // Attempt to insert second user with same email should fail
      await expect(
        db('users').insert({
          email: testEmail,
          first_name: 'Test',
          last_name: 'User2'
        })
      ).rejects.toThrow();

      // Clean up
      await db('users').where('id', user1[0].id).del();
    });

    test('user_property_roles should have unique user-property combination', async () => {
      // First create a user and property
      const user = await db('users').insert({
        email: 'unique.test@example.com',
        first_name: 'Unique',
        last_name: 'Test'
      }).returning('id');

      const property = await db('properties').insert({
        name: 'Test Property',
        property_type: 'single_family',
        street_address: '123 Test St',
        city: 'Test City',
        state_province: 'TS',
        postal_code: '12345',
        country: 'US'
      }).returning('id');

      // Insert first role assignment
      await db('user_property_roles').insert({
        user_id: user[0].id,
        property_id: property[0].id,
        role: 'owner',
        permissions: '{}',
        invitation_status: 'accepted'
      });

      // Attempt to insert duplicate role assignment should fail
      await expect(
        db('user_property_roles').insert({
          user_id: user[0].id,
          property_id: property[0].id,
          role: 'family',
          permissions: '{}',
          invitation_status: 'accepted'
        })
      ).rejects.toThrow();

      // Clean up
      await db('user_property_roles').where('user_id', user[0].id).del();
      await db('properties').where('id', property[0].id).del();
      await db('users').where('id', user[0].id).del();
    });

    test('projects progress_percentage should be between 0 and 100', async () => {
      // Create test user and property
      const user = await db('users').insert({
        email: 'progress.test@example.com',
        first_name: 'Progress',
        last_name: 'Test'
      }).returning('id');

      const property = await db('properties').insert({
        name: 'Progress Test Property',
        property_type: 'single_family',
        street_address: '456 Progress St',
        city: 'Progress City',
        state_province: 'PR',
        postal_code: '54321',
        country: 'US'
      }).returning('id');

      // Valid progress percentage should work
      const validProject = await db('projects').insert({
        property_id: property[0].id,
        title: 'Valid Progress Project',
        category: 'test',
        priority: 'medium',
        project_type: 'maintenance',
        status: 'not_started',
        progress_percentage: 50,
        created_by_user_id: user[0].id
      }).returning('id');

      expect(validProject[0]).toBeDefined();

      // Invalid progress percentage (over 100) should fail
      await expect(
        db('projects').insert({
          property_id: property[0].id,
          title: 'Invalid Progress Project',
          category: 'test',
          priority: 'medium',
          project_type: 'maintenance',
          status: 'not_started',
          progress_percentage: 150,
          created_by_user_id: user[0].id
        })
      ).rejects.toThrow();

      // Invalid progress percentage (negative) should fail
      await expect(
        db('projects').insert({
          property_id: property[0].id,
          title: 'Invalid Progress Project 2',
          category: 'test',
          priority: 'medium',
          project_type: 'maintenance',
          status: 'not_started',
          progress_percentage: -10,
          created_by_user_id: user[0].id
        })
      ).rejects.toThrow();

      // Clean up
      await db('projects').where('id', validProject[0].id).del();
      await db('properties').where('id', property[0].id).del();
      await db('users').where('id', user[0].id).del();
    });
  });

  describe('Index Existence', () => {
    test('should have indexes on frequently queried columns', async () => {
      // Test some key indexes - this is PostgreSQL specific
      const indexes = await db.raw(`
        SELECT indexname, tablename 
        FROM pg_indexes 
        WHERE schemaname = 'public' 
        AND tablename IN ('users', 'properties', 'user_property_roles', 'projects', 'tasks')
        ORDER BY tablename, indexname
      `);

      const indexNames = indexes.rows.map(row => row.indexname);
      
      // Check for some expected indexes
      expect(indexNames.some(name => name.includes('users_email'))).toBe(true);
      expect(indexNames.some(name => name.includes('projects_property'))).toBe(true);
      expect(indexNames.some(name => name.includes('tasks_project'))).toBe(true);
      expect(indexNames.some(name => name.includes('upr_property'))).toBe(true);
    });
  });

  describe('JSON Column Functionality', () => {
    test('should be able to store and query JSON data in permissions column', async () => {
      // Create test user and property
      const user = await db('users').insert({
        email: 'json.test@example.com',
        first_name: 'JSON',
        last_name: 'Test'
      }).returning('id');

      const property = await db('properties').insert({
        name: 'JSON Test Property',
        property_type: 'condo',
        street_address: '789 JSON Ave',
        city: 'JSON City',
        state_province: 'JS',
        postal_code: '78901',
        country: 'US'
      }).returning('id');

      const testPermissions = {
        projects: {
          view_all: true,
          create: false,
          edit: true
        },
        maintenance: {
          view_schedules: true,
          manage_schedules: false
        }
      };

      // Insert role with JSON permissions
      const role = await db('user_property_roles').insert({
        user_id: user[0].id,
        property_id: property[0].id,
        role: 'family',
        permissions: JSON.stringify(testPermissions),
        invitation_status: 'accepted'
      }).returning('id');

      // Query and verify JSON data
      const retrievedRole = await db('user_property_roles')
        .where('id', role[0].id)
        .first();

      const retrievedPermissions = JSON.parse(retrievedRole.permissions);
      expect(retrievedPermissions.projects.view_all).toBe(true);
      expect(retrievedPermissions.projects.create).toBe(false);
      expect(retrievedPermissions.maintenance.view_schedules).toBe(true);

      // Clean up
      await db('user_property_roles').where('id', role[0].id).del();
      await db('properties').where('id', property[0].id).del();
      await db('users').where('id', user[0].id).del();
    });
  });

  describe('Cascade Delete Behavior', () => {
    test('should cascade delete user_property_roles when user is deleted', async () => {
      // Create test user and property
      const user = await db('users').insert({
        email: 'cascade.test@example.com',
        first_name: 'Cascade',
        last_name: 'Test'
      }).returning('id');

      const property = await db('properties').insert({
        name: 'Cascade Test Property',
        property_type: 'single_family',
        street_address: '321 Cascade Ln',
        city: 'Cascade City',
        state_province: 'CA',
        postal_code: '32109',
        country: 'US'
      }).returning('id');

      // Create user-property role relationship
      await db('user_property_roles').insert({
        user_id: user[0].id,
        property_id: property[0].id,
        role: 'owner',
        permissions: '{}',
        invitation_status: 'accepted'
      });

      // Verify role exists
      const rolesBefore = await db('user_property_roles')
        .where('user_id', user[0].id)
        .count();
      expect(parseInt(rolesBefore[0].count)).toBe(1);

      // Delete user
      await db('users').where('id', user[0].id).del();

      // Verify role was cascade deleted
      const rolesAfter = await db('user_property_roles')
        .where('user_id', user[0].id)
        .count();
      expect(parseInt(rolesAfter[0].count)).toBe(0);

      // Clean up property
      await db('properties').where('id', property[0].id).del();
    });
  });

  describe('Enum Constraints', () => {
    test('should enforce role enum values in user_property_roles', async () => {
      const user = await db('users').insert({
        email: 'enum.test@example.com',
        first_name: 'Enum',
        last_name: 'Test'
      }).returning('id');

      const property = await db('properties').insert({
        name: 'Enum Test Property',
        property_type: 'townhouse',
        street_address: '654 Enum St',
        city: 'Enum City',
        state_province: 'EN',
        postal_code: '65432',
        country: 'US'
      }).returning('id');

      // Valid enum value should work
      const validRole = await db('user_property_roles').insert({
        user_id: user[0].id,
        property_id: property[0].id,
        role: 'contractor', // Valid enum value
        permissions: '{}',
        invitation_status: 'accepted'
      }).returning('id');

      expect(validRole[0]).toBeDefined();

      // Invalid enum value should fail
      await expect(
        db('user_property_roles').insert({
          user_id: user[0].id,
          property_id: property[0].id,
          role: 'invalid_role', // Invalid enum value
          permissions: '{}',
          invitation_status: 'accepted'
        })
      ).rejects.toThrow();

      // Clean up
      await db('user_property_roles').where('id', validRole[0].id).del();
      await db('properties').where('id', property[0].id).del();
      await db('users').where('id', user[0].id).del();
    });
  });
});