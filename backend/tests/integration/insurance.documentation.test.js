const request = require('supertest');
const app = require('../../src/app');
const path = require('path');
const fs = require('fs');

describe('Insurance Documentation Integration Tests', () => {
  let authToken;
  let userId;
  let propertyId;
  let insuranceItemId;
  let documentId;

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
        description: 'Test property for insurance documentation'
      });

    propertyId = propertyResponse.body.data.id;

    // Upload a test document for linking tests
    const testFilePath = createTestFile('insurance-receipt.pdf');
    const docResponse = await request(app)
      .post('/api/v1/documents/upload')
      .set('Authorization', `Bearer ${authToken}`)
      .field('title', 'TV Receipt')
      .field('description', 'Purchase receipt for Samsung TV')
      .field('document_type', 'receipt')
      .field('category', 'electronics')
      .field('vendor_name', 'Best Buy')
      .field('amount', '899.99')
      .field('property_id', propertyId)
      .attach('document', testFilePath);

    documentId = docResponse.body.data.id;
  });

  // Helper function to create a test file
  const createTestFile = (filename = 'test-photo.jpg', content = 'fake-image-content') => {
    const testFilePath = path.join(__dirname, '../fixtures', filename);
    
    // Ensure fixtures directory exists
    const fixturesDir = path.dirname(testFilePath);
    if (!fs.existsSync(fixturesDir)) {
      fs.mkdirSync(fixturesDir, { recursive: true });
    }
    
    // Create test file if it doesn't exist
    if (!fs.existsSync(testFilePath)) {
      fs.writeFileSync(testFilePath, content);
    }
    
    return testFilePath;
  };

  describe('Insurance Item Creation', () => {
    it('should create a new insurance item with all required fields', async () => {
      const response = await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'Samsung 65" QLED TV',
          description: 'Main living room television',
          category: 'electronics',
          subcategory: 'television',
          room_location: 'living_room',
          specific_location: 'Mounted on north wall',
          brand: 'Samsung',
          model: 'QN65Q80A',
          serial_number: 'SN123456789',
          condition: 'excellent',
          purchase_date: '2023-01-15',
          purchase_location: 'Best Buy',
          purchase_price: 899.99,
          current_estimated_value: 750.00,
          replacement_cost: 999.99,
          is_insured: true,
          insurance_policy_number: 'POL-123456',
          insurance_coverage_amount: 1000.00,
          tags: ['electronics', 'living_room', 'high_value'],
          notes: 'Purchased during New Year sale'
        })
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe('Samsung 65" QLED TV');
      expect(response.body.data.category).toBe('electronics');
      expect(response.body.data.brand).toBe('Samsung');
      expect(response.body.data.model).toBe('QN65Q80A');
      expect(response.body.data.purchase_price).toBe(899.99);
      expect(response.body.data.is_insured).toBe(true);
      expect(response.body.data.tags).toEqual(['electronics', 'living_room', 'high_value']);
      expect(response.body.data.property_id).toBe(propertyId);

      insuranceItemId = response.body.data.id;
    });

    it('should create insurance item with minimal required fields', async () => {
      const response = await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'Dining Table',
          category: 'furniture'
        })
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe('Dining Table');
      expect(response.body.data.category).toBe('furniture');
      expect(response.body.data.condition).toBe('good'); // Default value
      expect(response.body.data.currency).toBe('USD'); // Default value
      expect(response.body.data.is_insured).toBe(false); // Default value
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

    it('should require property_id', async () => {
      const response = await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Test Item',
          category: 'electronics'
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Property ID is required');
    });

    it('should prevent access to other users properties', async () => {
      // Create another user
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
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${otherUserToken}`)
        .send({
          property_id: propertyId,
          name: 'Unauthorized Item',
          category: 'electronics'
        })
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Access denied to the specified property');
    });
  });

  describe('Insurance Item Retrieval', () => {
    beforeEach(async () => {
      // Create test insurance items
      const itemResponse = await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'Test TV',
          description: 'Living room television',
          category: 'electronics',
          subcategory: 'television',
          room_location: 'living_room',
          brand: 'Samsung',
          model: 'Q80A',
          purchase_price: 799.99,
          replacement_cost: 899.99,
          is_insured: true,
          tags: ['electronics', 'high_value']
        });

      insuranceItemId = itemResponse.body.data.id;

      // Create another item for filtering tests
      await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'Sofa',
          category: 'furniture',
          room_location: 'living_room',
          purchase_price: 1200.00,
          is_insured: false
        });
    });

    it('should get all insurance items for user', async () => {
      const response = await request(app)
        .get('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.items).toBeInstanceOf(Array);
      expect(response.body.data.items.length).toBeGreaterThanOrEqual(2);
      expect(response.body.data.pagination).toBeDefined();
    });

    it('should filter items by property', async () => {
      const response = await request(app)
        .get(`/api/v1/insurance/items?property_id=${propertyId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.items.forEach(item => {
        expect(item.property_id).toBe(propertyId);
      });
    });

    it('should filter items by category', async () => {
      const response = await request(app)
        .get('/api/v1/insurance/items?category=electronics')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.items.forEach(item => {
        expect(item.category).toBe('electronics');
      });
    });

    it('should filter items by room location', async () => {
      const response = await request(app)
        .get('/api/v1/insurance/items?room_location=living_room')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.items.forEach(item => {
        expect(item.room_location).toBe('living_room');
      });
    });

    it('should filter insured items only', async () => {
      const response = await request(app)
        .get('/api/v1/insurance/items?insured_only=true')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.items.forEach(item => {
        expect(item.is_insured).toBe(true);
      });
    });

    it('should search items by name', async () => {
      const response = await request(app)
        .get('/api/v1/insurance/items?search=Test TV')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      const foundItem = response.body.data.items.find(item => item.name === 'Test TV');
      expect(foundItem).toBeDefined();
    });

    it('should get specific item by ID', async () => {
      const response = await request(app)
        .get(`/api/v1/insurance/items/${insuranceItemId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.id).toBe(insuranceItemId);
      expect(response.body.data.name).toBe('Test TV');
      expect(response.body.data.category).toBe('electronics');
    });

    it('should return 404 for non-existent item', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';
      
      const response = await request(app)
        .get(`/api/v1/insurance/items/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Insurance item not found');
    });

    it('should support pagination', async () => {
      const response = await request(app)
        .get('/api/v1/insurance/items?page=1&limit=1')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.pagination.page).toBe(1);
      expect(response.body.data.pagination.limit).toBe(1);
      expect(response.body.data.items.length).toBe(1);
    });

    it('should support sorting by value', async () => {
      const response = await request(app)
        .get('/api/v1/insurance/items?sort_by=replacement_cost&sort_order=desc')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.items).toBeInstanceOf(Array);
    });
  });

  describe('Insurance Item Updates', () => {
    beforeEach(async () => {
      const itemResponse = await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'Original TV',
          category: 'electronics',
          brand: 'Samsung',
          model: 'Q70A',
          purchase_price: 699.99,
          condition: 'good'
        });

      insuranceItemId = itemResponse.body.data.id;
    });

    it('should update item details', async () => {
      const response = await request(app)
        .put(`/api/v1/insurance/items/${insuranceItemId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Updated TV',
          brand: 'LG',
          model: 'OLED55C1',
          purchase_price: 1299.99,
          current_estimated_value: 1100.00,
          condition: 'excellent',
          is_insured: true,
          insurance_policy_number: 'POL-789',
          notes: 'Upgraded to OLED'
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe('Updated TV');
      expect(response.body.data.brand).toBe('LG');
      expect(response.body.data.model).toBe('OLED55C1');
      expect(response.body.data.purchase_price).toBe(1299.99);
      expect(response.body.data.condition).toBe('excellent');
      expect(response.body.data.is_insured).toBe(true);
      expect(response.body.data.notes).toBe('Upgraded to OLED');
    });

    it('should return 404 for non-existent item update', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';
      
      const response = await request(app)
        .put(`/api/v1/insurance/items/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'New Name' })
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Insurance item not found');
    });

    it('should prevent updating other users items', async () => {
      // Create another user
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
        .put(`/api/v1/insurance/items/${insuranceItemId}`)
        .set('Authorization', `Bearer ${otherUserToken}`)
        .send({ name: 'Hacked Name' })
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Access denied to this insurance item');
    });
  });

  describe('Insurance Item Deletion', () => {
    beforeEach(async () => {
      const itemResponse = await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'Item to Delete',
          category: 'electronics'
        });

      insuranceItemId = itemResponse.body.data.id;
    });

    it('should soft delete an insurance item', async () => {
      const response = await request(app)
        .delete(`/api/v1/insurance/items/${insuranceItemId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.message).toBe('Insurance item deleted successfully');

      // Verify item is not returned in active items
      const listResponse = await request(app)
        .get('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`);

      const deletedItem = listResponse.body.data.items.find(item => item.id === insuranceItemId);
      expect(deletedItem).toBeUndefined();
    });

    it('should return 404 for non-existent item deletion', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';
      
      const response = await request(app)
        .delete(`/api/v1/insurance/items/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Insurance item not found');
    });
  });

  describe('Insurance Item Photo Management', () => {
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
      const testPhoto1 = createTestFile('tv-overview.jpg');
      const testPhoto2 = createTestFile('tv-serial.jpg');

      const response = await request(app)
        .post(`/api/v1/insurance/items/${insuranceItemId}/photos`)
        .set('Authorization', `Bearer ${authToken}`)
        .field('photo_types', JSON.stringify(['overview', 'serial_number']))
        .field('titles', JSON.stringify(['TV Overview', 'Serial Number']))
        .field('descriptions', JSON.stringify(['Front view of TV', 'Serial number sticker']))
        .attach('photos', testPhoto1)
        .attach('photos', testPhoto2)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.uploaded_photos).toHaveLength(2);
      expect(response.body.data.uploaded_photos[0].photo_type).toBe('overview');
      expect(response.body.data.uploaded_photos[0].title).toBe('TV Overview');
      expect(response.body.data.uploaded_photos[1].photo_type).toBe('serial_number');
    });

    it('should get photos for insurance item', async () => {
      // First upload a photo
      const testPhoto = createTestFile('test-photo.jpg');
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
      expect(response.body.data.photos[0].photo_type).toBe('overview');
    });

    it('should require authentication for photo upload', async () => {
      const testPhoto = createTestFile('test-photo.jpg');

      const response = await request(app)
        .post(`/api/v1/insurance/items/${insuranceItemId}/photos`)
        .field('photo_types', JSON.stringify(['overview']))
        .attach('photos', testPhoto)
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Access token is required');
    });

    it('should validate photo file types', async () => {
      const invalidFile = createTestFile('test.txt', 'not an image');

      const response = await request(app)
        .post(`/api/v1/insurance/items/${insuranceItemId}/photos`)
        .set('Authorization', `Bearer ${authToken}`)
        .field('photo_types', JSON.stringify(['overview']))
        .attach('photos', invalidFile)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toContain('Invalid file type');
    });
  });

  describe('Document Linking', () => {
    beforeEach(async () => {
      const itemResponse = await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'TV with Documents',
          category: 'electronics'
        });

      insuranceItemId = itemResponse.body.data.id;
    });

    it('should link existing document to insurance item', async () => {
      const response = await request(app)
        .post(`/api/v1/insurance/items/${insuranceItemId}/documents`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          document_id: documentId,
          relationship_type: 'receipt',
          notes: 'Purchase receipt for this TV'
        })
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.document_id).toBe(documentId);
      expect(response.body.data.relationship_type).toBe('receipt');
      expect(response.body.data.notes).toBe('Purchase receipt for this TV');
    });

    it('should get linked documents for insurance item', async () => {
      // First link a document
      await request(app)
        .post(`/api/v1/insurance/items/${insuranceItemId}/documents`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          document_id: documentId,
          relationship_type: 'receipt'
        });

      const response = await request(app)
        .get(`/api/v1/insurance/items/${insuranceItemId}/documents`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.linked_documents).toBeInstanceOf(Array);
      expect(response.body.data.linked_documents.length).toBeGreaterThan(0);
      expect(response.body.data.linked_documents[0].document.title).toBe('TV Receipt');
    });

    it('should unlink document from insurance item', async () => {
      // First link a document
      await request(app)
        .post(`/api/v1/insurance/items/${insuranceItemId}/documents`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          document_id: documentId,
          relationship_type: 'receipt'
        });

      const response = await request(app)
        .delete(`/api/v1/insurance/items/${insuranceItemId}/documents/${documentId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.message).toBe('Document unlinked successfully');
    });

    it('should prevent duplicate document linking', async () => {
      // First link
      await request(app)
        .post(`/api/v1/insurance/items/${insuranceItemId}/documents`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          document_id: documentId,
          relationship_type: 'receipt'
        });

      // Try to link again
      const response = await request(app)
        .post(`/api/v1/insurance/items/${insuranceItemId}/documents`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          document_id: documentId,
          relationship_type: 'warranty'
        })
        .expect(409);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Document is already linked to this item');
    });

    it('should require valid relationship type', async () => {
      const response = await request(app)
        .post(`/api/v1/insurance/items/${insuranceItemId}/documents`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          document_id: documentId,
          relationship_type: 'invalid_type'
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toContain('Invalid relationship type');
    });
  });

  describe('Insurance Analytics and Export', () => {
    beforeEach(async () => {
      // Create multiple insurance items for analytics
      await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'High Value TV',
          category: 'electronics',
          purchase_price: 2500.00,
          replacement_cost: 2800.00,
          is_insured: true
        });

      await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'Expensive Sofa',
          category: 'furniture',
          purchase_price: 1800.00,
          replacement_cost: 2000.00,
          is_insured: false
        });
    });

    it('should get analytics summary', async () => {
      const response = await request(app)
        .get('/api/v1/insurance/analytics')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.overview).toBeDefined();
      expect(response.body.data.overview.total_items).toBeGreaterThan(0);
      expect(response.body.data.overview.total_value).toBeGreaterThan(0);
      expect(response.body.data.categories_breakdown).toBeInstanceOf(Array);
      expect(response.body.data.rooms_breakdown).toBeInstanceOf(Array);
    });

    it('should filter analytics by property', async () => {
      const response = await request(app)
        .get(`/api/v1/insurance/analytics?property_id=${propertyId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.overview).toBeDefined();
    });

    it('should generate insurance claim report', async () => {
      const response = await request(app)
        .get(`/api/v1/insurance/export/claim-report/${propertyId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.report).toBeDefined();
      expect(response.body.data.report.property_info).toBeDefined();
      expect(response.body.data.report.items).toBeInstanceOf(Array);
      expect(response.body.data.report.summary).toBeDefined();
      expect(response.body.data.report.summary.total_replacement_cost).toBeGreaterThan(0);
    });

    it('should filter claim report by date range', async () => {
      const fromDate = '2023-01-01';
      const toDate = '2023-12-31';
      
      const response = await request(app)
        .get(`/api/v1/insurance/export/claim-report/${propertyId}?from_date=${fromDate}&to_date=${toDate}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.report.filters_applied.from_date).toBe(fromDate);
      expect(response.body.data.report.filters_applied.to_date).toBe(toDate);
    });

    it('should filter claim report by categories', async () => {
      const response = await request(app)
        .get(`/api/v1/insurance/export/claim-report/${propertyId}?categories=electronics,furniture`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.report.filters_applied.categories).toEqual(['electronics', 'furniture']);
    });

    it('should require property access for claim report', async () => {
      // Create another user
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
        .get(`/api/v1/insurance/export/claim-report/${propertyId}`)
        .set('Authorization', `Bearer ${otherUserToken}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Access denied to this property');
    });
  });

  describe('Insurance Value Tracking', () => {
    beforeEach(async () => {
      const itemResponse = await request(app)
        .post('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          property_id: propertyId,
          name: 'Valuable Watch',
          category: 'jewelry',
          purchase_price: 5000.00,
          current_estimated_value: 5500.00
        });

      insuranceItemId = itemResponse.body.data.id;
    });

    it('should add new valuation to insurance item', async () => {
      const response = await request(app)
        .post(`/api/v1/insurance/items/${insuranceItemId}/valuations`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          appraised_value: 6000.00,
          replacement_cost: 6500.00,
          valuation_date: '2023-06-01',
          valuation_type: 'professional',
          appraiser_name: 'John Smith Appraisals',
          appraiser_credentials: 'ASA, ISA',
          valuation_notes: 'Market value has increased due to brand appreciation',
          certificate_number: 'CERT-12345'
        })
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.appraised_value).toBe(6000.00);
      expect(response.body.data.valuation_type).toBe('professional');
      expect(response.body.data.appraiser_name).toBe('John Smith Appraisals');
      expect(response.body.data.is_current).toBe(true);
    });

    it('should get valuation history for insurance item', async () => {
      // Add a valuation first
      await request(app)
        .post(`/api/v1/insurance/items/${insuranceItemId}/valuations`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          appraised_value: 5800.00,
          valuation_date: '2023-06-01',
          valuation_type: 'market_estimate'
        });

      const response = await request(app)
        .get(`/api/v1/insurance/items/${insuranceItemId}/valuations`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.valuations).toBeInstanceOf(Array);
      expect(response.body.data.valuations.length).toBeGreaterThan(0);
      expect(response.body.data.current_valuation).toBeDefined();
    });

    it('should require valid valuation type', async () => {
      const response = await request(app)
        .post(`/api/v1/insurance/items/${insuranceItemId}/valuations`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          appraised_value: 6000.00,
          valuation_date: '2023-06-01',
          valuation_type: 'invalid_type'
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toContain('Invalid valuation type');
    });
  });

  describe('Bulk Operations', () => {
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

      // Verify updates applied
      const item1 = await request(app)
        .get(`/api/v1/insurance/items/${itemIds[0]}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(item1.body.data.is_insured).toBe(true);
      expect(item1.body.data.insurance_policy_number).toBe('BULK-POL-123');
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

      // Verify items are deleted
      const listResponse = await request(app)
        .get('/api/v1/insurance/items')
        .set('Authorization', `Bearer ${authToken}`);

      const foundItems = listResponse.body.data.items.filter(item => 
        itemIds.includes(item.id)
      );
      expect(foundItems).toHaveLength(0);
    });

    it('should require valid item IDs for bulk operations', async () => {
      const response = await request(app)
        .put('/api/v1/insurance/items/bulk-update')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          item_ids: ['invalid-id'],
          updates: { is_insured: true }
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toContain('No valid items found to update');
    });
  });
});