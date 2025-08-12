const request = require('supertest');
const app = require('../../src/app');
const path = require('path');
const fs = require('fs');

describe('Insurance Documentation Simple Tests', () => {
  let authToken;
  let userId;
  let propertyId;
  let insuranceItemId;

  beforeAll(async () => {
    // Create test fixtures directory
    const fixturesDir = path.join(__dirname, '../fixtures');
    if (!fs.existsSync(fixturesDir)) {
      fs.mkdirSync(fixturesDir, { recursive: true });
    }
  });

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

    if (registerResponse.status !== 200) {
      console.error('Registration failed:', registerResponse.body);
    }

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
        description: 'Test property for insurance documentation'
      });

    if (propertyResponse.status !== 201) {
      console.error('Property creation failed:', propertyResponse.body);
    }

    propertyId = propertyResponse.body.data.id;
  });

  // Helper function to create a test file
  const createTestFile = (filename = 'test-photo.jpg', content = 'fake-image-content') => {
    const testFilePath = path.join(__dirname, '../fixtures', filename);
    
    if (!fs.existsSync(testFilePath)) {
      fs.writeFileSync(testFilePath, content);
    }
    
    return testFilePath;
  };

  describe('Insurance Item Basic Operations', () => {
    it('should create a basic insurance item', async () => {
      const response = await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'Test TV',
          category: 'electronics'
        })
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe('Test TV');
      expect(response.body.data.category).toBe('electronics');
      expect(response.body.data.property_id).toBe(propertyId);

      insuranceItemId = response.body.data.id;
    });

    it('should retrieve insurance items', async () => {
      // First create an item
      await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'Test Sofa',
          category: 'furniture'
        });

      const response = await request(app)
        .get('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.items).toBeInstanceOf(Array);
      expect(response.body.data.items.length).toBeGreaterThan(0);
    });

    it('should update insurance item', async () => {
      // First create an item
      const createResponse = await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'Original Name',
          category: 'electronics'
        });

      const itemId = createResponse.body.data.id;

      const response = await request(app)
        .put(`/api/v1/insurance/items/${itemId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Updated Name',
          brand: 'Samsung',
          purchase_price: 899.99
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe('Updated Name');
      expect(response.body.data.brand).toBe('Samsung');
      expect(response.body.data.purchase_price).toBe(899.99);
    });

    it('should delete insurance item', async () => {
      // First create an item
      const createResponse = await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'Item to Delete',
          category: 'electronics'
        });

      const itemId = createResponse.body.data.id;

      const response = await request(app)
        .delete(`/api/v1/insurance/items/${itemId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.message).toBe('Insurance item deleted successfully');
    });

    it('should require authentication', async () => {
      const response = await request(app)
        .post('/api/v1/insurance/items')
        .send({
          property_id: propertyId,
          name: 'Test Item',
          category: 'electronics'
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Access token is required');
    });

    it('should require name and category', async () => {
      const response = await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Name and category are required');
    });

    it('should get analytics summary', async () => {
      // First create some items
      await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'Analytics TV',
          category: 'electronics',
          purchase_price: 1000.00
        });

      const response = await request(app)
        .get('/api/v1/insurance/analytics')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.overview).toBeDefined();
      expect(response.body.data.overview.total_items).toBeGreaterThan(0);
      expect(response.body.data.categories_breakdown).toBeInstanceOf(Array);
    });
  });

  describe('Photo Management Basic', () => {
    beforeEach(async () => {
      const itemResponse = await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'TV for Photos',
          category: 'electronics'
        });

      insuranceItemId = itemResponse.body.data.id;
    });

    it('should upload photos to insurance item', async () => {
      const testPhoto = createTestFile('tv-photo.jpg');

      const response = await request(app)
        .post(`/api/v1/insurance/items/${insuranceItemId}/photos`)
        .set('Authorization', `Bearer ${authToken}`)
        .field('photo_types', JSON.stringify(['overview']))
        .field('titles', JSON.stringify(['TV Overview']))
        .attach('photos', testPhoto)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.uploaded_photos).toHaveLength(1);
      expect(response.body.data.uploaded_photos[0].photo_type).toBe('overview');
    });

    it('should get photos for insurance item', async () => {
      // First upload a photo
      const testPhoto = createTestFile('test-get-photo.jpg');
      await request(app)
        .post(`/api/v1/insurance/items/${insuranceItemId}/photos`)
        .set('Authorization', `Bearer ${authToken}`)
        .field('photo_types', JSON.stringify(['overview']))
        .attach('photos', testPhoto);

      const response = await request(app)
        .get(`/api/v1/insurance/items/${insuranceItemId}/photos`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.photos).toBeInstanceOf(Array);
      expect(response.body.data.photos.length).toBeGreaterThan(0);
    });
  });

  describe('Bulk Operations Basic', () => {
    let itemIds = [];

    beforeEach(async () => {
      // Create multiple items for bulk operations
      const item1Response = await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'Bulk Item 1',
          category: 'electronics',
          is_insured: false
        });

      const item2Response = await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'Bulk Item 2',
          category: 'electronics', 
          is_insured: false
        });

      itemIds = [item1Response.body.data.id, item2Response.body.data.id];
    });

    it('should bulk update insurance status', async () => {
      const response = await request(app)
        .put('/api/v1/insurance/items/bulk-update')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          item_ids: itemIds,
          updates: {
            is_insured: true,
            insurance_policy_number: 'BULK-POL-123'
          }
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.updated_count).toBe(2);
    });

    it('should bulk delete insurance items', async () => {
      const response = await request(app)
        .post('/api/v1/insurance/items/bulk-delete')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          item_ids: itemIds
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.deleted_count).toBe(2);
    });
  });
});