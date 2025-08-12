const request = require('supertest');
const app = require('../../src/app');

describe('Reporting Dashboard Integration Tests', () => {
  let authToken;
  let userId;
  let propertyId;
  let projectId;
  let taskId;

  beforeEach(async () => {
    // Register a test user and get auth token
    const registerResponse = await request(app)
      .post('/api/v1/auth/register')
      .send({
        firstName: 'Test',
        lastName: 'User',
        email: `test${Date.now()}@example.com`,
        password: 'TestPassword123!',
        userType: 'property_owner'
      });

    authToken = registerResponse.body.data.token;
    userId = registerResponse.body.data.user.id;

    // Create a test property
    const propertyResponse = await request(app)
      .post('/api/v1/properties')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Test Property',
        address: '123 Test St',
        type: 'residential',
        description: 'Test property for reporting'
      });

    propertyId = propertyResponse.body.data.id;

    // Create a test project
    const projectResponse = await request(app)
      .post('/api/v1/projects')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        title: 'Test Project',
        description: 'Test project for reporting',
        property_id: propertyId,
        status: 'in_progress',
        priority: 'high',
        budget: 5000
      });

    projectId = projectResponse.body.data.id;

    // Create test tasks
    const taskResponse = await request(app)
      .post('/api/v1/projects/' + projectId + '/tasks')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        title: 'Test Task',
        description: 'Test task for reporting',
        status: 'pending',
        priority: 'high',
        estimated_hours: 4
      });

    taskId = taskResponse.body.data.id;
  });

  describe('Dashboard Statistics', () => {
    it('should get dashboard statistics for authenticated user', async () => {
      const response = await request(app)
        .get('/api/v1/reports/dashboard')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('properties');
      expect(response.body.data).toHaveProperty('projects');
      expect(response.body.data).toHaveProperty('tasks');
      expect(response.body.data).toHaveProperty('summary');

      // Check properties section
      expect(response.body.data.properties).toHaveProperty('total');
      expect(response.body.data.properties).toHaveProperty('byType');
      expect(response.body.data.properties).toHaveProperty('averageAge');
      expect(response.body.data.properties).toHaveProperty('withActiveProjects');

      // Check projects section
      expect(response.body.data.projects).toHaveProperty('total');
      expect(response.body.data.projects).toHaveProperty('byStatus');
      expect(response.body.data.projects).toHaveProperty('byPriority');
      expect(response.body.data.projects).toHaveProperty('overdue');
      expect(response.body.data.projects).toHaveProperty('budget');

      // Check tasks section
      expect(response.body.data.tasks).toHaveProperty('total');
      expect(response.body.data.tasks).toHaveProperty('byStatus');
      expect(response.body.data.tasks).toHaveProperty('completionRate');
      expect(response.body.data.tasks).toHaveProperty('averageCompletionDays');

      // Check summary section
      expect(response.body.data.summary).toHaveProperty('totalBudget');
      expect(response.body.data.summary).toHaveProperty('totalSpent');
      expect(response.body.data.summary).toHaveProperty('savings');
      expect(response.body.data.summary).toHaveProperty('activeProjects');
      expect(response.body.data.summary).toHaveProperty('completedTasks');
    });

    it('should show correct property statistics', async () => {
      const response = await request(app)
        .get('/api/v1/reports/dashboard')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.properties.total).toBe(1);
      expect(response.body.data.properties.byType.residential).toBe(1);
      expect(response.body.data.properties.withActiveProjects).toBe(1);
    });

    it('should show correct project statistics', async () => {
      const response = await request(app)
        .get('/api/v1/reports/dashboard')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.projects.total).toBe(1);
      expect(response.body.data.projects.byStatus.in_progress).toBe(1);
      expect(response.body.data.projects.byPriority.high).toBe(1);
      expect(response.body.data.projects.budget.total).toBe(5000);
    });

    it('should show correct task statistics', async () => {
      const response = await request(app)
        .get('/api/v1/reports/dashboard')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.tasks.total).toBe(1);
      expect(response.body.data.tasks.byStatus.pending).toBe(1);
      expect(response.body.data.tasks.completionRate).toBe(0);
    });

    it('should require authentication', async () => {
      const response = await request(app)
        .get('/api/v1/reports/dashboard')
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Access token is required');
    });

    it('should return empty stats for user with no properties', async () => {
      // Register another user
      const newUserResponse = await request(app)
        .post('/api/v1/auth/register')
        .send({
          firstName: 'Empty',
          lastName: 'User',
          email: `empty${Date.now()}@example.com`,
          password: 'TestPassword123!',
          userType: 'property_owner'
        });

      const newUserToken = newUserResponse.body.data.token;

      const response = await request(app)
        .get('/api/v1/reports/dashboard')
        .set('Authorization', `Bearer ${newUserToken}`)
        .expect(200);

      expect(response.body.data.properties.total).toBe(0);
      expect(response.body.data.projects.total).toBe(0);
      expect(response.body.data.tasks.total).toBe(0);
    });
  });

  describe('Property Details Report', () => {
    it('should get detailed property statistics', async () => {
      const response = await request(app)
        .get(`/api/v1/reports/properties/${propertyId}/details`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('property');
      expect(response.body.data).toHaveProperty('overview');
      expect(response.body.data).toHaveProperty('projects');
      expect(response.body.data).toHaveProperty('budget');
      expect(response.body.data).toHaveProperty('timeTracking');
      expect(response.body.data).toHaveProperty('recentActivity');

      // Check property info
      expect(response.body.data.property.id).toBe(propertyId);
      expect(response.body.data.property.name).toBe('Test Property');
      expect(response.body.data.property.type).toBe('residential');

      // Check overview
      expect(response.body.data.overview.totalProjects).toBe(1);
      expect(response.body.data.overview.totalTasks).toBe(1);
      expect(response.body.data.overview.completedTasks).toBe(0);

      // Check budget
      expect(response.body.data.budget.totalBudgeted).toBe(5000);
      expect(response.body.data.budget.variance).toBe(5000); // No actual cost yet
    });

    it('should require property access', async () => {
      // Register another user
      const otherUserResponse = await request(app)
        .post('/api/v1/auth/register')
        .send({
          firstName: 'Other',
          lastName: 'User',
          email: `other${Date.now()}@example.com`,
          password: 'TestPassword123!',
          userType: 'property_owner'
        });

      const otherUserToken = otherUserResponse.body.data.token;

      const response = await request(app)
        .get(`/api/v1/reports/properties/${propertyId}/details`)
        .set('Authorization', `Bearer ${otherUserToken}`)
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Property not found or access denied');
    });

    it('should require authentication', async () => {
      const response = await request(app)
        .get(`/api/v1/reports/properties/${propertyId}/details`)
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Access token is required');
    });

    it('should return 404 for non-existent property', async () => {
      const fakePropertyId = '00000000-0000-0000-0000-000000000000';
      
      const response = await request(app)
        .get(`/api/v1/reports/properties/${fakePropertyId}/details`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Property not found or access denied');
    });
  });

  describe('Dashboard Data Accuracy', () => {
    it('should update statistics when task is completed', async () => {
      // Complete the task
      await request(app)
        .put(`/api/v1/tasks/${taskId}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          status: 'completed',
          notes: 'Task completed for testing'
        });

      const response = await request(app)
        .get('/api/v1/reports/dashboard')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.tasks.byStatus.completed).toBe(1);
      expect(response.body.data.tasks.completionRate).toBe(100);
      expect(response.body.data.summary.completedTasks).toBe(1);
    });

    it('should track project budget variance', async () => {
      // Update project with actual cost
      await request(app)
        .put(`/api/v1/projects/${projectId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          actualCost: 4500
        });

      const response = await request(app)
        .get('/api/v1/reports/dashboard')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.projects.budget.total).toBe(5000);
      expect(response.body.data.projects.budget.actual).toBe(4500);
      expect(response.body.data.projects.budget.variance).toBe(500);
      expect(response.body.data.summary.savings).toBe(500);
    });

    it('should identify overdue projects', async () => {
      // Set project due date to yesterday
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);

      await request(app)
        .put(`/api/v1/projects/${projectId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          dueDate: yesterday.toISOString()
        });

      const response = await request(app)
        .get('/api/v1/reports/dashboard')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.projects.overdue).toBe(1);
    });
  });
});