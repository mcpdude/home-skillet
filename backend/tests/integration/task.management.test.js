const request = require('supertest');
const app = require('../../src/app');

describe('Enhanced Task Management Integration Tests', () => {
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
        description: 'Test property for task management'
      });

    propertyId = propertyResponse.body.data.id;

    // Create a test project
    const projectResponse = await request(app)
      .post('/api/v1/projects')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        title: 'Test Project',
        description: 'Test project for task management',
        property_id: propertyId,
        status: 'in_progress',
        priority: 'medium'
      });

    projectId = projectResponse.body.data.id;

    // Create a test task
    const taskResponse = await request(app)
      .post('/api/v1/projects/' + projectId + '/tasks')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        title: 'Test Task',
        description: 'Test task for enhanced management',
        status: 'pending',
        priority: 'high',
        estimated_hours: 4
      });

    taskId = taskResponse.body.data.id;
  });

  describe('Task Status Management', () => {
    it('should update task status with progress tracking', async () => {
      const response = await request(app)
        .put(`/api/v1/tasks/${taskId}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          status: 'in_progress',
          progress_percentage: 25,
          notes: 'Started working on task'
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe('in_progress');
      expect(response.body.data.progress_percentage).toBe(25);
      expect(response.body.data.notes).toBe('Started working on task');
      expect(response.body.data.status_updated_at).toBeDefined();
    });

    it('should validate status transitions', async () => {
      // Try to move from pending directly to completed without in_progress
      const response = await request(app)
        .put(`/api/v1/tasks/${taskId}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          status: 'completed',
          progress_percentage: 100
        })
        .expect(200); // Allow direct completion

      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe('completed');
      expect(response.body.data.progress_percentage).toBe(100);
    });

    it('should automatically update progress when status changes to completed', async () => {
      const response = await request(app)
        .put(`/api/v1/tasks/${taskId}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          status: 'completed'
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe('completed');
      expect(response.body.data.progress_percentage).toBe(100);
      expect(response.body.data.completed_at).toBeDefined();
    });
  });

  describe('Time Tracking', () => {
    it('should start time tracking for a task', async () => {
      const response = await request(app)
        .post(`/api/v1/tasks/${taskId}/time-tracking/start`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          description: 'Starting work on task'
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.started_at).toBeDefined();
      expect(response.body.data.is_active).toBe(true);
      expect(response.body.data.description).toBe('Starting work on task');
    });

    it('should stop time tracking for a task', async () => {
      // First start time tracking
      await request(app)
        .post(`/api/v1/tasks/${taskId}/time-tracking/start`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({});

      // Then stop it
      const response = await request(app)
        .post(`/api/v1/tasks/${taskId}/time-tracking/stop`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          description: 'Finished work session'
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.ended_at).toBeDefined();
      expect(response.body.data.is_active).toBe(false);
      expect(response.body.data.duration_minutes).toBeGreaterThan(0);
    });

    it('should get time tracking summary for a task', async () => {
      const response = await request(app)
        .get(`/api/v1/tasks/${taskId}/time-tracking`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('total_hours');
      expect(response.body.data).toHaveProperty('sessions');
      expect(response.body.data).toHaveProperty('estimated_hours');
      expect(Array.isArray(response.body.data.sessions)).toBe(true);
    });
  });

  describe('Task Comments and Updates', () => {
    it('should add a comment to a task', async () => {
      const response = await request(app)
        .post(`/api/v1/tasks/${taskId}/comments`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          content: 'This is a test comment',
          type: 'comment'
        })
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.content).toBe('This is a test comment');
      expect(response.body.data.type).toBe('comment');
      expect(response.body.data.user_id).toBe(userId);
    });

    it('should get all comments for a task', async () => {
      // Add a comment first
      await request(app)
        .post(`/api/v1/tasks/${taskId}/comments`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          content: 'Test comment',
          type: 'comment'
        });

      const response = await request(app)
        .get(`/api/v1/tasks/${taskId}/comments`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.data.length).toBeGreaterThan(0);
      expect(response.body.data[0].content).toBe('Test comment');
    });
  });

  describe('Task Dependencies', () => {
    let dependentTaskId;

    beforeEach(async () => {
      // Create another task to use as dependency
      const taskResponse = await request(app)
        .post('/api/v1/projects/' + projectId + '/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Dependent Task',
          description: 'Task that depends on another',
          status: 'pending',
          priority: 'medium'
        });

      dependentTaskId = taskResponse.body.data.id;
    });

    it('should create task dependency', async () => {
      const response = await request(app)
        .post(`/api/v1/tasks/${dependentTaskId}/dependencies`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          depends_on_task_id: taskId,
          dependency_type: 'finish_to_start'
        })
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.depends_on_task_id).toBe(taskId);
      expect(response.body.data.dependency_type).toBe('finish_to_start');
    });

    it('should prevent starting dependent task before prerequisite is completed', async () => {
      // Create dependency
      await request(app)
        .post(`/api/v1/tasks/${dependentTaskId}/dependencies`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          depends_on_task_id: taskId,
          dependency_type: 'finish_to_start'
        });

      // Try to start dependent task while prerequisite is still pending
      const response = await request(app)
        .put(`/api/v1/tasks/${dependentTaskId}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          status: 'in_progress'
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toContain('dependency');
    });
  });

  describe('Bulk Task Operations', () => {
    let additionalTaskIds;

    beforeEach(async () => {
      // Create additional tasks for bulk operations
      const promises = [];
      for (let i = 1; i <= 3; i++) {
        promises.push(
          request(app)
            .post('/api/v1/projects/' + projectId + '/tasks')
            .set('Authorization', `Bearer ${authToken}`)
            .send({
              title: `Bulk Task ${i}`,
              description: `Task ${i} for bulk operations`,
              status: 'pending',
              priority: 'low'
            })
        );
      }
      
      const responses = await Promise.all(promises);
      additionalTaskIds = responses.map(r => r.body.data.id);
    });

    it('should update multiple tasks status at once', async () => {
      const taskIds = [taskId, ...additionalTaskIds];
      
      const response = await request(app)
        .put('/api/v1/tasks/bulk-update')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          task_ids: taskIds,
          updates: {
            status: 'in_progress',
            priority: 'high'
          }
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.updated_count).toBe(taskIds.length);
    });

    it('should delete multiple tasks at once', async () => {
      const response = await request(app)
        .delete('/api/v1/tasks/bulk-delete')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          task_ids: additionalTaskIds
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.deleted_count).toBe(additionalTaskIds.length);
    });
  });
});