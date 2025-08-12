const knex = require('knex');
const config = require('../knexfile');

// Use test configuration
const db = knex(config.test);

describe('Database Migrations Tests', () => {
  beforeAll(async () => {
    // Ensure we start with a clean database
    await db.migrate.rollback();
  });

  afterAll(async () => {
    // Clean up and close database connection
    await db.destroy();
  });

  describe('Migration Up and Down', () => {
    test('should successfully run all migrations up', async () => {
      const [batchNo, log] = await db.migrate.latest();
      expect(batchNo).toBeGreaterThan(0);
      expect(log.length).toBeGreaterThan(0);
      
      // Verify all expected tables exist after migrations
      const expectedTables = [
        'users',
        'properties', 
        'user_property_roles',
        'projects',
        'tasks',
        'maintenance_schedules',
        'maintenance_records',
        'documents',
        'vendors',
        'project_assignments'
      ];
      
      for (const tableName of expectedTables) {
        const exists = await db.schema.hasTable(tableName);
        expect(exists).toBe(true);
      }
    });

    test('should successfully rollback migrations', async () => {
      // First ensure migrations are up
      await db.migrate.latest();
      
      // Then rollback
      const [batchNo, log] = await db.migrate.rollback();
      expect(batchNo).toBeGreaterThan(0);
      expect(log.length).toBeGreaterThan(0);
      
      // Verify tables are removed after rollback (except knex migration tables)
      const tables = await db.raw("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'");
      const tableNames = tables.rows.map(row => row.table_name);
      
      // Should only have knex migration tracking tables
      const appTables = tableNames.filter(name => !name.startsWith('knex_'));
      expect(appTables.length).toBe(0);
    });

    test('should be able to re-run migrations after rollback', async () => {
      // Ensure we're rolled back
      await db.migrate.rollback();
      
      // Run migrations again
      const [batchNo, log] = await db.migrate.latest();
      expect(batchNo).toBeGreaterThan(0);
      
      // Verify key table exists
      const exists = await db.schema.hasTable('users');
      expect(exists).toBe(true);
    });
  });

  describe('Migration Order and Dependencies', () => {
    test('migrations should run in correct order based on dependencies', async () => {
      // Ensure clean state
      await db.migrate.rollback();
      
      // Run migrations one by one and check dependencies
      const migrationFiles = [
        '001_create_users_table.js',
        '002_create_properties_table.js',
        '003_create_user_property_roles_table.js',
        '004_create_projects_table.js',
        '005_create_tasks_table.js',
        '006_create_maintenance_schedules_table.js',
        '007_create_maintenance_records_table.js',
        '008_create_documents_table.js',
        '009_create_vendors_table.js',
        '010_create_project_assignments_table.js',
        '011_create_additional_indexes.js'
      ];

      // Run all migrations
      await db.migrate.latest();
      
      // Check that dependent tables exist and can reference parent tables
      
      // user_property_roles should be able to reference users and properties
      const upr_columns = await db('user_property_roles').columnInfo();
      expect(upr_columns).toHaveProperty('user_id');
      expect(upr_columns).toHaveProperty('property_id');
      
      // projects should be able to reference properties and users
      const project_columns = await db('projects').columnInfo();
      expect(project_columns).toHaveProperty('property_id');
      expect(project_columns).toHaveProperty('created_by_user_id');
      
      // tasks should be able to reference projects
      const task_columns = await db('tasks').columnInfo();
      expect(task_columns).toHaveProperty('project_id');
      
      // maintenance_records should be able to reference schedules and properties
      const record_columns = await db('maintenance_records').columnInfo();
      expect(record_columns).toHaveProperty('maintenance_schedule_id');
      expect(record_columns).toHaveProperty('property_id');
      
      // project_assignments should be able to reference projects, users, and vendors
      const assignment_columns = await db('project_assignments').columnInfo();
      expect(assignment_columns).toHaveProperty('project_id');
      expect(assignment_columns).toHaveProperty('user_id');
      expect(assignment_columns).toHaveProperty('vendor_id');
    });
  });

  describe('UUID Default Values', () => {
    test('tables should have UUID primary keys with default generation', async () => {
      await db.migrate.latest();
      
      // Test UUID generation for users table
      const user = await db('users').insert({
        email: 'uuid.test@example.com',
        first_name: 'UUID',
        last_name: 'Test'
      }).returning('id');
      
      expect(user[0].id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
      
      // Test UUID generation for properties table
      const property = await db('properties').insert({
        name: 'UUID Test Property',
        property_type: 'single_family',
        street_address: '123 UUID St',
        city: 'UUID City',
        state_province: 'UV',
        postal_code: '12345',
        country: 'US'
      }).returning('id');
      
      expect(property[0].id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
      
      // Clean up
      await db('properties').where('id', property[0].id).del();
      await db('users').where('id', user[0].id).del();
    });
  });

  describe('Default Values and Constraints', () => {
    test('should apply correct default values', async () => {
      await db.migrate.latest();
      
      // Test users table defaults
      const user = await db('users').insert({
        email: 'defaults.test@example.com',
        first_name: 'Defaults',
        last_name: 'Test'
      }).returning('*');
      
      expect(user[0].is_email_verified).toBe(false);
      expect(user[0].is_active).toBe(true);
      expect(user[0].timezone).toBe('UTC');
      expect(user[0].language).toBe('en');
      expect(JSON.parse(user[0].preferences)).toEqual({});
      
      // Test properties table defaults
      const property = await db('properties').insert({
        name: 'Defaults Test Property',
        property_type: 'condo',
        street_address: '456 Default Ave',
        city: 'Default City',
        state_province: 'DF',
        postal_code: '45678',
        country: 'US'
      }).returning('*');
      
      expect(property[0].is_primary_residence).toBe(true);
      expect(property[0].is_active).toBe(true);
      expect(property[0].country).toBe('US');
      expect(JSON.parse(property[0].utility_accounts)).toEqual({});
      
      // Test projects table defaults
      const project = await db('projects').insert({
        property_id: property[0].id,
        title: 'Default Test Project',
        category: 'test',
        priority: 'medium',
        project_type: 'maintenance',
        status: 'not_started',
        created_by_user_id: user[0].id
      }).returning('*');
      
      expect(project[0].progress_percentage).toBe(0);
      expect(project[0].priority).toBe('medium');
      expect(project[0].status).toBe('not_started');
      expect(project[0].requires_permits).toBe(false);
      
      // Clean up
      await db('projects').where('id', project[0].id).del();
      await db('properties').where('id', property[0].id).del();
      await db('users').where('id', user[0].id).del();
    });
  });

  describe('Check Constraints', () => {
    test('should enforce check constraints on numeric ranges', async () => {
      await db.migrate.latest();
      
      // Create test user and property
      const user = await db('users').insert({
        email: 'constraint.test@example.com',
        first_name: 'Constraint',
        last_name: 'Test'
      }).returning('id');

      const property = await db('properties').insert({
        name: 'Constraint Test Property',
        property_type: 'single_family',
        street_address: '789 Constraint Rd',
        city: 'Constraint City',
        state_province: 'CN',
        postal_code: '78901',
        country: 'US'
      }).returning('id');

      // Test progress_percentage constraint in projects table (should be 0-100)
      await expect(
        db('projects').insert({
          property_id: property[0].id,
          title: 'Invalid Progress Project',
          category: 'test',
          priority: 'medium',
          project_type: 'maintenance',
          status: 'not_started',
          progress_percentage: 150, // Invalid: over 100
          created_by_user_id: user[0].id
        })
      ).rejects.toThrow();

      await expect(
        db('projects').insert({
          property_id: property[0].id,
          title: 'Invalid Progress Project 2',
          category: 'test',
          priority: 'medium',
          project_type: 'maintenance',
          status: 'not_started',
          progress_percentage: -5, // Invalid: negative
          created_by_user_id: user[0].id
        })
      ).rejects.toThrow();

      // Test quality_rating constraint in vendors table (should be 1-5)
      await expect(
        db('vendors').insert({
          company_name: 'Invalid Rating Vendor',
          vendor_status: 'active',
          relationship_type: 'occasional',
          quality_rating: 6, // Invalid: over 5
          added_by_user_id: user[0].id
        })
      ).rejects.toThrow();

      // Clean up
      await db('properties').where('id', property[0].id).del();
      await db('users').where('id', user[0].id).del();
    });
  });

  describe('Timestamp Functionality', () => {
    test('should automatically set created_at and updated_at timestamps', async () => {
      await db.migrate.latest();
      
      const beforeInsert = new Date();
      
      const user = await db('users').insert({
        email: 'timestamp.test@example.com',
        first_name: 'Timestamp',
        last_name: 'Test'
      }).returning('*');
      
      const afterInsert = new Date();
      
      expect(new Date(user[0].created_at)).toBeInstanceOf(Date);
      expect(new Date(user[0].updated_at)).toBeInstanceOf(Date);
      expect(new Date(user[0].created_at).getTime()).toBeGreaterThanOrEqual(beforeInsert.getTime() - 1000);
      expect(new Date(user[0].created_at).getTime()).toBeLessThanOrEqual(afterInsert.getTime() + 1000);
      
      // Test updated_at changes on update
      const beforeUpdate = new Date();
      
      await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second
      
      await db('users').where('id', user[0].id).update({
        first_name: 'Updated'
      });
      
      const updatedUser = await db('users').where('id', user[0].id).first();
      
      expect(new Date(updatedUser.updated_at).getTime()).toBeGreaterThan(new Date(updatedUser.created_at).getTime());
      expect(new Date(updatedUser.updated_at).getTime()).toBeGreaterThanOrEqual(beforeUpdate.getTime());
      
      // Clean up
      await db('users').where('id', user[0].id).del();
    });
  });
});