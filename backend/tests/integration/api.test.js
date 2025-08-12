const request = require('supertest');
const app = require('../../src/app');

describe('Home Skillet API Integration Tests', () => {
  // Helper function to create and authenticate a user
  const createAuthenticatedUser = async (userData = {
    email: 'test@example.com',
    password: 'SecurePass123!',
    firstName: 'John',
    lastName: 'Doe',
    userType: 'property_owner'
  }) => {
    const registerResponse = await request(app)
      .post('/api/v1/auth/register')
      .send(userData);

    const loginResponse = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: userData.email,
        password: userData.password
      });

    return {
      user: registerResponse.body.data.user,
      token: loginResponse.body.data.token
    };
  };

  // Helper function to create a property
  const createProperty = async (token, propertyData = {
    name: 'Test Property',
    address: {
      street: '123 Test St',
      city: 'Test City',
      state: 'CA',
      zipCode: '12345',
      country: 'USA'
    },
    propertyType: 'single_family'
  }) => {
    const response = await request(app)
      .post('/api/v1/properties')
      .set('Authorization', `Bearer ${token}`)
      .send(propertyData);

    return response.body.data.property;
  };

  describe('Authentication Endpoints', () => {
    describe('POST /api/v1/auth/register', () => {
      it('should register a new user successfully', async () => {
        const userData = {
          email: 'register@example.com',
          password: 'SecurePass123!',
          firstName: 'John',
          lastName: 'Doe',
          userType: 'property_owner'
        };

        const response = await request(app)
          .post('/api/v1/auth/register')
          .send(userData)
          .expect(201);

        expect(response.body).toHaveProperty('success', true);
        expect(response.body.data).toHaveProperty('user');
        expect(response.body.data).toHaveProperty('token');
        expect(response.body.data.user.email).toBe(userData.email);
        expect(response.body.data.user).not.toHaveProperty('password');
      });

      it('should return 400 for missing required fields', async () => {
        const response = await request(app)
          .post('/api/v1/auth/register')
          .send({ email: 'incomplete@example.com' })
          .expect(400);

        expect(response.body).toHaveProperty('success', false);
        expect(response.body.error).toHaveProperty('details');
      });

      it('should return 409 for duplicate email', async () => {
        const userData = {
          email: 'duplicate@example.com',
          password: 'SecurePass123!',
          firstName: 'First',
          lastName: 'User',
          userType: 'property_owner'
        };

        // Register first user
        await request(app)
          .post('/api/v1/auth/register')
          .send(userData)
          .expect(201);

        // Try to register with same email
        await request(app)
          .post('/api/v1/auth/register')
          .send(userData)
          .expect(409);
      });
    });

    describe('POST /api/v1/auth/login', () => {
      it('should login successfully with correct credentials', async () => {
        const userData = {
          email: 'login@example.com',
          password: 'SecurePass123!',
          firstName: 'Login',
          lastName: 'User',
          userType: 'property_owner'
        };

        // First register the user
        await request(app)
          .post('/api/v1/auth/register')
          .send(userData);

        // Then login
        const response = await request(app)
          .post('/api/v1/auth/login')
          .send({
            email: userData.email,
            password: userData.password
          })
          .expect(200);

        expect(response.body).toHaveProperty('success', true);
        expect(response.body.data).toHaveProperty('user');
        expect(response.body.data).toHaveProperty('token');
      });

      it('should return 401 for invalid credentials', async () => {
        const response = await request(app)
          .post('/api/v1/auth/login')
          .send({
            email: 'nonexistent@example.com',
            password: 'wrongpassword'
          })
          .expect(401);

        expect(response.body).toHaveProperty('success', false);
      });
    });

    describe('GET /api/v1/auth/me', () => {
      it('should return user profile with valid token', async () => {
        const { user, token } = await createAuthenticatedUser({
          email: 'me@example.com',
          password: 'SecurePass123!',
          firstName: 'Me',
          lastName: 'User',
          userType: 'property_owner'
        });

        const response = await request(app)
          .get('/api/v1/auth/me')
          .set('Authorization', `Bearer ${token}`)
          .expect(200);

        expect(response.body).toHaveProperty('success', true);
        expect(response.body.data.user.email).toBe(user.email);
      });

      it('should return 401 without token', async () => {
        await request(app)
          .get('/api/v1/auth/me')
          .expect(401);
      });
    });
  });

  describe('Properties Endpoints', () => {
    it('should create a new property successfully', async () => {
      const { token } = await createAuthenticatedUser({
        email: 'property@example.com',
        password: 'SecurePass123!',
        firstName: 'Property',
        lastName: 'Owner',
        userType: 'property_owner'
      });

      const propertyData = {
        name: 'My Test Property',
        address: {
          street: '123 Property St',
          city: 'Property City',
          state: 'CA',
          zipCode: '12345',
          country: 'USA'
        },
        propertyType: 'single_family'
      };

      const response = await request(app)
        .post('/api/v1/properties')
        .set('Authorization', `Bearer ${token}`)
        .send(propertyData)
        .expect(201);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data.property.name).toBe(propertyData.name);
    });

    it('should retrieve user properties', async () => {
      const { token } = await createAuthenticatedUser({
        email: 'list@example.com',
        password: 'SecurePass123!',
        firstName: 'List',
        lastName: 'User',
        userType: 'property_owner'
      });

      // Create a property first
      await createProperty(token);

      const response = await request(app)
        .get('/api/v1/properties')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(Array.isArray(response.body.data.properties)).toBe(true);
      expect(response.body.data.properties).toHaveLength(1);
    });

    it('should return 401 for unauthenticated request', async () => {
      await request(app)
        .post('/api/v1/properties')
        .send({ name: 'Unauthorized Property' })
        .expect(401);
    });
  });

  describe('Projects Endpoints', () => {
    it('should create a new project successfully', async () => {
      const { token } = await createAuthenticatedUser({
        email: 'project@example.com',
        password: 'SecurePass123!',
        firstName: 'Project',
        lastName: 'User',
        userType: 'property_owner'
      });

      const property = await createProperty(token);

      const projectData = {
        title: 'Test Project',
        description: 'A test project for integration testing',
        category: 'interior',
        priority: 'medium',
        propertyId: property.id,
        tasks: [
          {
            title: 'Task 1',
            description: 'First test task',
            completed: false
          }
        ]
      };

      const response = await request(app)
        .post('/api/v1/projects')
        .set('Authorization', `Bearer ${token}`)
        .send(projectData)
        .expect(201);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data.project.title).toBe(projectData.title);
      expect(response.body.data.project.tasks).toHaveLength(1);
    });

    it('should retrieve user projects', async () => {
      const { token } = await createAuthenticatedUser({
        email: 'projects@example.com',
        password: 'SecurePass123!',
        firstName: 'Projects',
        lastName: 'User',
        userType: 'property_owner'
      });

      const property = await createProperty(token);

      // Create a project first
      await request(app)
        .post('/api/v1/projects')
        .set('Authorization', `Bearer ${token}`)
        .send({
          title: 'List Test Project',
          description: 'Project for list testing',
          category: 'exterior',
          propertyId: property.id
        });

      const response = await request(app)
        .get('/api/v1/projects')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(Array.isArray(response.body.data.projects)).toBe(true);
      expect(response.body.data.projects).toHaveLength(1);
    });
  });

  describe('Maintenance Schedules Endpoints', () => {
    it('should create a new maintenance schedule', async () => {
      const { token } = await createAuthenticatedUser({
        email: 'maintenance@example.com',
        password: 'SecurePass123!',
        firstName: 'Maintenance',
        lastName: 'User',
        userType: 'property_owner'
      });

      const property = await createProperty(token);

      const scheduleData = {
        title: 'HVAC Filter Change',
        description: 'Replace HVAC air filter',
        category: 'hvac',
        propertyId: property.id,
        frequency: 'monthly',
        priority: 'medium'
      };

      const response = await request(app)
        .post('/api/v1/maintenance-schedules')
        .set('Authorization', `Bearer ${token}`)
        .send(scheduleData)
        .expect(201);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data.schedule.title).toBe(scheduleData.title);
      expect(response.body.data.schedule.frequency).toBe(scheduleData.frequency);
    });

    it('should retrieve maintenance schedules', async () => {
      const { token } = await createAuthenticatedUser({
        email: 'schedules@example.com',
        password: 'SecurePass123!',
        firstName: 'Schedules',
        lastName: 'User',
        userType: 'property_owner'
      });

      const property = await createProperty(token);

      // Create a schedule first
      await request(app)
        .post('/api/v1/maintenance-schedules')
        .set('Authorization', `Bearer ${token}`)
        .send({
          title: 'Test Schedule',
          description: 'Schedule for testing',
          category: 'plumbing',
          propertyId: property.id,
          frequency: 'yearly'
        });

      const response = await request(app)
        .get('/api/v1/maintenance-schedules')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(Array.isArray(response.body.data.schedules)).toBe(true);
      expect(response.body.data.schedules).toHaveLength(1);
    });
  });

  describe('Users and Permissions', () => {
    it('should retrieve all users', async () => {
      const { token } = await createAuthenticatedUser({
        email: 'admin@example.com',
        password: 'SecurePass123!',
        firstName: 'Admin',
        lastName: 'User',
        userType: 'property_owner'
      });

      const response = await request(app)
        .get('/api/v1/users')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(Array.isArray(response.body.data.users)).toBe(true);
      expect(response.body.data.users.length).toBeGreaterThan(0);
    });

    it('should grant and retrieve property permissions', async () => {
      const { token } = await createAuthenticatedUser({
        email: 'permissions@example.com',
        password: 'SecurePass123!',
        firstName: 'Permissions',
        lastName: 'Owner',
        userType: 'property_owner'
      });

      // Create a second user
      const secondUser = await createAuthenticatedUser({
        email: 'member@example.com',
        password: 'SecurePass123!',
        firstName: 'Family',
        lastName: 'Member',
        userType: 'family_member'
      });

      const property = await createProperty(token);

      // Grant permissions
      const permissionData = {
        userId: secondUser.user.id,
        role: 'editor',
        permissions: {
          viewProjects: true,
          createProjects: true,
          editProjects: true,
          deleteProjects: false
        }
      };

      const grantResponse = await request(app)
        .post(`/api/v1/users/properties/${property.id}/permissions`)
        .set('Authorization', `Bearer ${token}`)
        .send(permissionData)
        .expect(201);

      expect(grantResponse.body).toHaveProperty('success', true);
      expect(grantResponse.body.data.permission.userId).toBe(secondUser.user.id);
      expect(grantResponse.body.data.permission.role).toBe('editor');

      // Retrieve permissions
      const getResponse = await request(app)
        .get(`/api/v1/users/properties/${property.id}/permissions`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(getResponse.body).toHaveProperty('success', true);
      expect(Array.isArray(getResponse.body.data.permissions)).toBe(true);
      expect(getResponse.body.data.permissions).toHaveLength(1);
    });
  });

  describe('Error Handling', () => {
    it('should return 404 for unknown routes', async () => {
      const { token } = await createAuthenticatedUser({
        email: 'error@example.com',
        password: 'SecurePass123!',
        firstName: 'Error',
        lastName: 'User',
        userType: 'property_owner'
      });

      const response = await request(app)
        .get('/api/v1/unknown-route')
        .set('Authorization', `Bearer ${token}`)
        .expect(404);

      expect(response.body).toHaveProperty('success', false);
      expect(response.body.error.message).toContain('not found');
    });

    it('should handle validation errors properly', async () => {
      const { token } = await createAuthenticatedUser({
        email: 'validation@example.com',
        password: 'SecurePass123!',
        firstName: 'Validation',
        lastName: 'User',
        userType: 'property_owner'
      });

      const response = await request(app)
        .post('/api/v1/properties')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: '' }) // Invalid data
        .expect(400);

      expect(response.body).toHaveProperty('success', false);
      expect(response.body.error).toHaveProperty('details');
    });
  });

  describe('Health Check', () => {
    it('should return health status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toHaveProperty('message');
      expect(response.body.data.message).toContain('running');
    });
  });
});