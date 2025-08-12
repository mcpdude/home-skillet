const knex = require('knex');
const config = require('../knexfile');

// Use test configuration
const db = knex(config.test);

describe('Database Seeds Tests', () => {
  beforeAll(async () => {
    // Run migrations and seeds before tests
    await db.migrate.latest();
    await db.seed.run();
  });

  afterAll(async () => {
    // Clean up and close database connection
    await db.destroy();
  });

  describe('Seed Data Integrity', () => {
    test('should have seeded users', async () => {
      const users = await db('users').select('*');
      expect(users.length).toBeGreaterThan(0);
      
      // Check for specific test users
      const johnOwner = users.find(u => u.email === 'john.owner@example.com');
      expect(johnOwner).toBeDefined();
      expect(johnOwner.first_name).toBe('John');
      expect(johnOwner.last_name).toBe('Owner');
      expect(johnOwner.is_active).toBe(true);
    });

    test('should have seeded properties', async () => {
      const properties = await db('properties').select('*');
      expect(properties.length).toBeGreaterThan(0);
      
      // Check for specific test property
      const mainHome = properties.find(p => p.name === 'Main Family Home');
      expect(mainHome).toBeDefined();
      expect(mainHome.property_type).toBe('single_family');
      expect(mainHome.city).toBe('Springfield');
    });

    test('should have seeded user property roles with proper relationships', async () => {
      const roles = await db('user_property_roles')
        .select('user_property_roles.*', 'users.email', 'properties.name')
        .join('users', 'user_property_roles.user_id', 'users.id')
        .join('properties', 'user_property_roles.property_id', 'properties.id');
      
      expect(roles.length).toBeGreaterThan(0);
      
      // Check for owner role
      const ownerRole = roles.find(r => r.role === 'owner' && r.email === 'john.owner@example.com');
      expect(ownerRole).toBeDefined();
      
      // Verify permissions structure
      const permissions = JSON.parse(ownerRole.permissions);
      expect(permissions).toHaveProperty('projects');
      expect(permissions).toHaveProperty('maintenance');
      expect(permissions).toHaveProperty('documents');
      expect(permissions.projects.view_all).toBe(true);
      expect(permissions.property.manage_users).toBe(true);
    });

    test('should have seeded vendors with complete information', async () => {
      const vendors = await db('vendors').select('*');
      expect(vendors.length).toBeGreaterThan(0);
      
      // Check for specific vendor
      const hvacVendor = vendors.find(v => v.company_name === 'Springfield HVAC Services');
      expect(hvacVendor).toBeDefined();
      expect(hvacVendor.emergency_services).toBe(true);
      expect(hvacVendor.vendor_status).toBe('preferred');
      
      // Check service categories JSON
      const serviceCategories = JSON.parse(hvacVendor.service_categories);
      expect(serviceCategories).toContain('hvac');
      expect(Array.isArray(serviceCategories)).toBe(true);
    });

    test('should have seeded projects with proper property relationships', async () => {
      const projects = await db('projects')
        .select('projects.*', 'properties.name as property_name', 'users.email as creator_email')
        .join('properties', 'projects.property_id', 'properties.id')
        .join('users', 'projects.created_by_user_id', 'users.id');
      
      expect(projects.length).toBeGreaterThan(0);
      
      // Check for specific project
      const bathroomProject = projects.find(p => p.title === 'Master Bathroom Renovation');
      expect(bathroomProject).toBeDefined();
      expect(bathroomProject.category).toBe('renovation');
      expect(bathroomProject.status).toBe('in_progress');
      expect(bathroomProject.property_name).toBe('Main Family Home');
      expect(bathroomProject.creator_email).toBe('john.owner@example.com');
      
      // Check required materials JSON
      const requiredMaterials = JSON.parse(bathroomProject.required_materials);
      expect(Array.isArray(requiredMaterials)).toBe(true);
      expect(requiredMaterials.length).toBeGreaterThan(0);
    });

    test('should have seeded tasks with proper project relationships', async () => {
      const tasks = await db('tasks')
        .select('tasks.*', 'projects.title as project_title')
        .join('projects', 'tasks.project_id', 'projects.id');
      
      expect(tasks.length).toBeGreaterThan(0);
      
      // Check for specific task
      const removeFixturesTask = tasks.find(t => t.title === 'Remove existing fixtures');
      expect(removeFixturesTask).toBeDefined();
      expect(removeFixturesTask.is_completed).toBe(true);
      expect(removeFixturesTask.project_title).toBe('Master Bathroom Renovation');
      expect(removeFixturesTask.sort_order).toBe(1);
      
      // Check for completed task with actual values
      expect(removeFixturesTask.actual_hours).toBeGreaterThan(0);
      expect(removeFixturesTask.actual_cost).toBeGreaterThan(0);
    });

    test('should have seeded maintenance schedules with proper property relationships', async () => {
      const schedules = await db('maintenance_schedules')
        .select('maintenance_schedules.*', 'properties.name as property_name')
        .join('properties', 'maintenance_schedules.property_id', 'properties.id');
      
      expect(schedules.length).toBeGreaterThan(0);
      
      // Check for specific schedule
      const hvacFilterSchedule = schedules.find(s => s.title === 'HVAC Filter Replacement');
      expect(hvacFilterSchedule).toBeDefined();
      expect(hvacFilterSchedule.frequency_type).toBe('months');
      expect(hvacFilterSchedule.frequency_value).toBe(3);
      expect(hvacFilterSchedule.category).toBe('hvac');
      expect(hvacFilterSchedule.is_active).toBe(true);
      
      // Check required materials JSON
      const requiredMaterials = JSON.parse(hvacFilterSchedule.required_materials);
      expect(Array.isArray(requiredMaterials)).toBe(true);
      expect(requiredMaterials.length).toBeGreaterThan(0);
    });

    test('should have seeded maintenance records with schedule relationships', async () => {
      const records = await db('maintenance_records')
        .select('maintenance_records.*', 'maintenance_schedules.title as schedule_title', 'properties.name as property_name')
        .leftJoin('maintenance_schedules', 'maintenance_records.maintenance_schedule_id', 'maintenance_schedules.id')
        .join('properties', 'maintenance_records.property_id', 'properties.id');
      
      expect(records.length).toBeGreaterThan(0);
      
      // Check for specific record
      const hvacFilterRecord = records.find(r => r.title === 'HVAC Filter Replacement - Q3 2023');
      expect(hvacFilterRecord).toBeDefined();
      expect(hvacFilterRecord.completion_status).toBe('completed');
      expect(hvacFilterRecord.total_cost).toBeGreaterThan(0);
      expect(hvacFilterRecord.was_preventive).toBe(true);
      
      // Check materials used JSON
      const materialsUsed = JSON.parse(hvacFilterRecord.materials_used);
      expect(Array.isArray(materialsUsed)).toBe(true);
      expect(materialsUsed.length).toBeGreaterThan(0);
    });
  });

  describe('Referential Integrity of Seed Data', () => {
    test('all user_property_roles should reference valid users and properties', async () => {
      const invalidRoles = await db.raw(`
        SELECT upr.id
        FROM user_property_roles upr
        LEFT JOIN users u ON upr.user_id = u.id
        LEFT JOIN properties p ON upr.property_id = p.id
        WHERE u.id IS NULL OR p.id IS NULL
      `);
      
      expect(invalidRoles.rows.length).toBe(0);
    });

    test('all projects should reference valid properties and users', async () => {
      const invalidProjects = await db.raw(`
        SELECT proj.id
        FROM projects proj
        LEFT JOIN properties p ON proj.property_id = p.id
        LEFT JOIN users u ON proj.created_by_user_id = u.id
        WHERE p.id IS NULL OR u.id IS NULL
      `);
      
      expect(invalidProjects.rows.length).toBe(0);
    });

    test('all tasks should reference valid projects and users', async () => {
      const invalidTasks = await db.raw(`
        SELECT t.id
        FROM tasks t
        LEFT JOIN projects p ON t.project_id = p.id
        LEFT JOIN users u ON t.created_by_user_id = u.id
        WHERE p.id IS NULL OR u.id IS NULL
      `);
      
      expect(invalidTasks.rows.length).toBe(0);
    });

    test('all maintenance records should reference valid properties', async () => {
      const invalidRecords = await db.raw(`
        SELECT mr.id
        FROM maintenance_records mr
        LEFT JOIN properties p ON mr.property_id = p.id
        WHERE p.id IS NULL
      `);
      
      expect(invalidRecords.rows.length).toBe(0);
    });
  });

  describe('Multi-Tenant Data Isolation', () => {
    test('should have proper property-based data isolation setup', async () => {
      // Get John's properties
      const johnProperties = await db('user_property_roles')
        .select('property_id')
        .join('users', 'user_property_roles.user_id', 'users.id')
        .where('users.email', 'john.owner@example.com');
      
      const johnPropertyIds = johnProperties.map(p => p.property_id);
      
      // All projects should belong to John's properties
      const projects = await db('projects').select('property_id');
      projects.forEach(project => {
        expect(johnPropertyIds).toContain(project.property_id);
      });
      
      // All maintenance schedules should belong to John's properties
      const schedules = await db('maintenance_schedules').select('property_id');
      schedules.forEach(schedule => {
        expect(johnPropertyIds).toContain(schedule.property_id);
      });
    });

    test('should have different permission levels for different roles', async () => {
      const roles = await db('user_property_roles')
        .select('role', 'permissions')
        .join('users', 'user_property_roles.user_id', 'users.id')
        .where('users.email', 'IN', ['john.owner@example.com', 'jane.family@example.com', 'mike.contractor@example.com']);
      
      roles.forEach(role => {
        const permissions = JSON.parse(role.permissions);
        
        if (role.role === 'owner') {
          expect(permissions.property.manage_users).toBe(true);
          expect(permissions.projects.delete).toBe(true);
        } else if (role.role === 'family') {
          expect(permissions.projects.view_all).toBe(true);
          expect(permissions.projects.delete).toBe(false); // Family can't delete projects
        } else if (role.role === 'contractor') {
          expect(permissions.projects.view_all).toBe(false); // Only assigned projects
          expect(permissions.property.manage_users).toBe(false);
        }
      });
    });
  });

  describe('Data Consistency', () => {
    test('project progress should be consistent with completed tasks', async () => {
      const projectsWithTasks = await db('projects')
        .select('projects.id', 'projects.title', 'projects.progress_percentage')
        .join('tasks', 'projects.id', 'tasks.project_id')
        .groupBy('projects.id', 'projects.title', 'projects.progress_percentage')
        .having(db.raw('COUNT(tasks.id) > 0'));
      
      for (const project of projectsWithTasks) {
        const totalTasks = await db('tasks')
          .where('project_id', project.id)
          .count('id as total');
        
        const completedTasks = await db('tasks')
          .where('project_id', project.id)
          .where('is_completed', true)
          .count('id as completed');
        
        const actualProgress = Math.round((completedTasks[0].completed / totalTasks[0].total) * 100);
        
        // Progress should be reasonably close to calculated progress
        // (allowing for some manual adjustment)
        expect(Math.abs(project.progress_percentage - actualProgress)).toBeLessThanOrEqual(20);
      }
    });

    test('maintenance schedules should have valid frequency configurations', async () => {
      const schedules = await db('maintenance_schedules').select('*');
      
      schedules.forEach(schedule => {
        expect(schedule.frequency_type).toMatch(/^(days|weeks|months|years|seasonal|custom)$/);
        expect(schedule.frequency_value).toBeGreaterThan(0);
        expect(new Date(schedule.first_due_date)).toBeInstanceOf(Date);
        
        if (schedule.seasons) {
          const seasons = JSON.parse(schedule.seasons);
          if (seasons.length > 0) {
            seasons.forEach(season => {
              expect(season).toMatch(/^(spring|summer|fall|winter)$/);
            });
          }
        }
      });
    });

    test('vendor contact information should be properly formatted', async () => {
      const vendors = await db('vendors').select('*');
      
      vendors.forEach(vendor => {
        // Email should be valid format if present
        if (vendor.email) {
          expect(vendor.email).toMatch(/^[^\s@]+@[^\s@]+\.[^\s@]+$/);
        }
        
        // Phone should be formatted if present
        if (vendor.phone_primary) {
          expect(vendor.phone_primary).toMatch(/^\+?[\d\s\-\(\)]+$/);
        }
        
        // Service categories should be valid JSON array
        const serviceCategories = JSON.parse(vendor.service_categories);
        expect(Array.isArray(serviceCategories)).toBe(true);
        
        // Average rating should be between 0 and 5
        if (vendor.average_rating !== null) {
          expect(vendor.average_rating).toBeGreaterThanOrEqual(0);
          expect(vendor.average_rating).toBeLessThanOrEqual(5);
        }
      });
    });
  });
});