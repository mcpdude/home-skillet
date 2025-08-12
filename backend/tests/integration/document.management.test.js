const request = require('supertest');
const app = require('../../src/app');
const path = require('path');
const fs = require('fs');

describe('Document Management Integration Tests', () => {
  let authToken;
  let userId;
  let propertyId;
  let projectId;
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
        description: 'Test property for document management'
      });

    propertyId = propertyResponse.body.data.id;

    // Create a test project
    const projectResponse = await request(app)
      .post('/api/v1/projects')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        title: 'Test Project',
        description: 'Test project for documents',
        property_id: propertyId,
        status: 'in_progress',
        priority: 'medium',
        budget: 5000
      });

    projectId = projectResponse.body.data.id;
  });

  // Helper function to create a test file
  const createTestFile = (filename = 'test-document.pdf', content = 'fake-pdf-content') => {
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

  describe('Document Upload', () => {
    it('should upload a receipt document to a property', async () => {
      const testFilePath = createTestFile('receipt.pdf');

      const response = await request(app)
        .post('/api/v1/documents/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .field('title', 'Home Depot Receipt')
        .field('description', 'Purchased supplies for kitchen renovation')
        .field('document_type', 'receipt')
        .field('category', 'supplies')
        .field('vendor_name', 'Home Depot')
        .field('amount', '245.67')
        .field('currency', 'USD')
        .field('document_date', '2025-01-15')
        .field('property_id', propertyId)
        .field('tags', JSON.stringify(['kitchen', 'renovation', 'supplies']))
        .attach('document', testFilePath)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.title).toBe('Home Depot Receipt');
      expect(response.body.data.document_type).toBe('receipt');
      expect(response.body.data.category).toBe('supplies');
      expect(response.body.data.vendor_name).toBe('Home Depot');
      expect(response.body.data.amount).toBe(245.67);
      expect(response.body.data.property_id).toBe(propertyId);
      expect(response.body.data.tags).toEqual(['kitchen', 'renovation', 'supplies']);
      expect(response.body.data.file_url).toBeTruthy();

      documentId = response.body.data.id;
    });

    it('should upload a warranty document to a project', async () => {
      const testFilePath = createTestFile('warranty.pdf');

      const response = await request(app)
        .post('/api/v1/documents/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .field('title', 'Dishwasher Warranty')
        .field('description', 'Warranty for Samsung dishwasher')
        .field('document_type', 'warranty')
        .field('category', 'appliances')
        .field('vendor_name', 'Samsung')
        .field('expiry_date', '2027-01-15')
        .field('project_id', projectId)
        .attach('document', testFilePath)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.document_type).toBe('warranty');
      expect(response.body.data.expiry_date).toBe('2027-01-15');
      expect(response.body.data.project_id).toBe(projectId);
    });

    it('should upload a contract document', async () => {
      const testFilePath = createTestFile('contract.pdf');

      const response = await request(app)
        .post('/api/v1/documents/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .field('title', 'Plumbing Service Contract')
        .field('description', 'Annual plumbing maintenance contract')
        .field('document_type', 'contract')
        .field('category', 'services')
        .field('vendor_name', 'ABC Plumbing')
        .field('amount', '1200.00')
        .field('document_date', '2025-01-01')
        .field('expiry_date', '2025-12-31')
        .field('property_id', propertyId)
        .attach('document', testFilePath)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.document_type).toBe('contract');
      expect(response.body.data.category).toBe('services');
    });

    it('should require title and document type', async () => {
      const testFilePath = createTestFile('test.pdf');

      const response = await request(app)
        .post('/api/v1/documents/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .field('property_id', propertyId)
        .attach('document', testFilePath)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Title and document type are required');
    });

    it('should require property or project association', async () => {
      const testFilePath = createTestFile('test.pdf');

      const response = await request(app)
        .post('/api/v1/documents/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .field('title', 'Test Document')
        .field('document_type', 'receipt')
        .attach('document', testFilePath)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Document must be associated with either a property or project');
    });

    it('should require authentication', async () => {
      const testFilePath = createTestFile('test.pdf');

      const response = await request(app)
        .post('/api/v1/documents/upload')
        .field('title', 'Test Document')
        .field('document_type', 'receipt')
        .field('property_id', propertyId)
        .attach('document', testFilePath)
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Access token is required');
    });

    it('should reject invalid file types', async () => {
      const testFilePath = createTestFile('test.exe', 'fake-exe-content');

      const response = await request(app)
        .post('/api/v1/documents/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .field('title', 'Test Document')
        .field('document_type', 'receipt')
        .field('property_id', propertyId)
        .attach('document', testFilePath)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toContain('File type not allowed');
    });

    it('should detect duplicate documents', async () => {
      const testFilePath = createTestFile('duplicate.pdf', 'identical-content');

      // Upload first document
      await request(app)
        .post('/api/v1/documents/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .field('title', 'First Document')
        .field('document_type', 'receipt')
        .field('property_id', propertyId)
        .attach('document', testFilePath)
        .expect(201);

      // Try to upload identical document
      const response = await request(app)
        .post('/api/v1/documents/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .field('title', 'Duplicate Document')
        .field('document_type', 'receipt')
        .field('property_id', propertyId)
        .attach('document', testFilePath)
        .expect(409);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('A document with identical content already exists');
    });
  });

  describe('Document Retrieval', () => {
    beforeEach(async () => {
      // Upload a test document for retrieval tests
      const testFilePath = createTestFile('retrieval-test.pdf');
      
      const uploadResponse = await request(app)
        .post('/api/v1/documents/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .field('title', 'Test Receipt')
        .field('description', 'Test document for retrieval')
        .field('document_type', 'receipt')
        .field('category', 'supplies')
        .field('vendor_name', 'Test Vendor')
        .field('amount', '100.00')
        .field('property_id', propertyId)
        .field('tags', JSON.stringify(['test', 'retrieval']))
        .attach('document', testFilePath);

      documentId = uploadResponse.body.data.id;
    });

    it('should get all documents for authenticated user', async () => {
      const response = await request(app)
        .get('/api/v1/documents')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.documents).toBeInstanceOf(Array);
      expect(response.body.data.documents.length).toBeGreaterThan(0);
      expect(response.body.data.pagination).toBeDefined();
    });

    it('should filter documents by property', async () => {
      const response = await request(app)
        .get(`/api/v1/documents?property_id=${propertyId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.documents).toBeInstanceOf(Array);
      response.body.data.documents.forEach(doc => {
        expect(doc.property_id).toBe(propertyId);
      });
    });

    it('should filter documents by type', async () => {
      const response = await request(app)
        .get('/api/v1/documents?document_type=receipt')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.documents.forEach(doc => {
        expect(doc.document_type).toBe('receipt');
      });
    });

    it('should search documents by title', async () => {
      const response = await request(app)
        .get('/api/v1/documents?search=Test Receipt')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      const foundDoc = response.body.data.documents.find(doc => doc.title === 'Test Receipt');
      expect(foundDoc).toBeDefined();
    });

    it('should get specific document by ID', async () => {
      const response = await request(app)
        .get(`/api/v1/documents/${documentId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.id).toBe(documentId);
      expect(response.body.data.title).toBe('Test Receipt');
      expect(response.body.data.view_count).toBe(1); // Should increment on view
    });

    it('should return 404 for non-existent document', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';
      
      const response = await request(app)
        .get(`/api/v1/documents/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Document not found');
    });

    it('should require authentication for document access', async () => {
      const response = await request(app)
        .get('/api/v1/documents')
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Access token is required');
    });

    it('should get categories summary', async () => {
      const response = await request(app)
        .get('/api/v1/documents/categories/summary')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.types).toBeInstanceOf(Array);
      expect(response.body.data.categories).toBeInstanceOf(Array);
      expect(response.body.data.summary).toBeDefined();
      expect(response.body.data.summary.expiring_soon).toBeDefined();
      expect(response.body.data.summary.recent_uploads).toBeDefined();
    });
  });

  describe('Document Updates', () => {
    beforeEach(async () => {
      // Upload a test document for update tests
      const testFilePath = createTestFile('update-test.pdf');
      
      const uploadResponse = await request(app)
        .post('/api/v1/documents/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .field('title', 'Original Title')
        .field('description', 'Original description')
        .field('document_type', 'receipt')
        .field('category', 'supplies')
        .field('vendor_name', 'Original Vendor')
        .field('amount', '50.00')
        .field('property_id', propertyId)
        .attach('document', testFilePath);

      documentId = uploadResponse.body.data.id;
    });

    it('should update document metadata', async () => {
      const response = await request(app)
        .put(`/api/v1/documents/${documentId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Updated Title',
          description: 'Updated description',
          category: 'materials',
          vendor_name: 'Updated Vendor',
          amount: 75.50,
          tags: ['updated', 'test'],
          is_favorite: true
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.title).toBe('Updated Title');
      expect(response.body.data.description).toBe('Updated description');
      expect(response.body.data.category).toBe('materials');
      expect(response.body.data.vendor_name).toBe('Updated Vendor');
      expect(response.body.data.amount).toBe(75.5);
      expect(response.body.data.tags).toEqual(['updated', 'test']);
      expect(response.body.data.is_favorite).toBe(true);
    });

    it('should return 404 for non-existent document update', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';
      
      const response = await request(app)
        .put(`/api/v1/documents/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ title: 'New Title' })
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Document not found');
    });
  });

  describe('Document Deletion', () => {
    beforeEach(async () => {
      // Upload a test document for deletion tests
      const testFilePath = createTestFile('delete-test.pdf');
      
      const uploadResponse = await request(app)
        .post('/api/v1/documents/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .field('title', 'Document to Delete')
        .field('document_type', 'receipt')
        .field('property_id', propertyId)
        .attach('document', testFilePath);

      documentId = uploadResponse.body.data.id;
    });

    it('should soft delete a document', async () => {
      const response = await request(app)
        .delete(`/api/v1/documents/${documentId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.message).toBe('Document deleted successfully');

      // Verify document is not returned in active documents
      const listResponse = await request(app)
        .get('/api/v1/documents')
        .set('Authorization', `Bearer ${authToken}`);

      const deletedDoc = listResponse.body.data.documents.find(doc => doc.id === documentId);
      expect(deletedDoc).toBeUndefined();
    });

    it('should return 404 for non-existent document deletion', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';
      
      const response = await request(app)
        .delete(`/api/v1/documents/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Document not found');
    });
  });

  describe('Access Control', () => {
    let otherUserToken;
    let otherUserPropertyId;

    beforeEach(async () => {
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

      otherUserToken = otherUserResponse.body.data.token;

      // Create property for other user
      const otherPropertyResponse = await request(app)
        .post('/api/v1/properties')
        .set('Authorization', `Bearer ${otherUserToken}`)
        .send({
          name: 'Other Property',
          address: '456 Other St',
          type: 'residential'
        });

      otherUserPropertyId = otherPropertyResponse.body.data.id;

      // Upload a document for the first user
      const testFilePath = createTestFile('access-test.pdf');
      
      const uploadResponse = await request(app)
        .post('/api/v1/documents/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .field('title', 'Private Document')
        .field('document_type', 'receipt')
        .field('property_id', propertyId)
        .attach('document', testFilePath);

      documentId = uploadResponse.body.data.id;
    });

    it('should prevent other users from accessing private documents', async () => {
      const response = await request(app)
        .get(`/api/v1/documents/${documentId}`)
        .set('Authorization', `Bearer ${otherUserToken}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Access denied to this document');
    });

    it('should prevent uploading to other users properties', async () => {
      const testFilePath = createTestFile('unauthorized-upload.pdf');

      const response = await request(app)
        .post('/api/v1/documents/upload')
        .set('Authorization', `Bearer ${otherUserToken}`)
        .field('title', 'Unauthorized Document')
        .field('document_type', 'receipt')
        .field('property_id', propertyId) // Other user's property
        .attach('document', testFilePath)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toBe('Access denied to the specified property or project');
    });

    it('should show only accessible documents in list', async () => {
      // Other user uploads their own document
      const testFilePath = createTestFile('other-user-doc.pdf');
      
      await request(app)
        .post('/api/v1/documents/upload')
        .set('Authorization', `Bearer ${otherUserToken}`)
        .field('title', 'Other User Document')
        .field('document_type', 'receipt')
        .field('property_id', otherUserPropertyId)
        .attach('document', testFilePath);

      // First user should only see their documents
      const response = await request(app)
        .get('/api/v1/documents')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      const otherUserDoc = response.body.data.documents.find(doc => doc.title === 'Other User Document');
      expect(otherUserDoc).toBeUndefined();
    });
  });

  describe('Document Organization Features', () => {
    beforeEach(async () => {
      const testFilePath = createTestFile('organization-test.pdf');
      
      // Upload documents with expiry dates for testing
      const warrantyResponse = await request(app)
        .post('/api/v1/documents/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .field('title', 'Expiring Warranty')
        .field('document_type', 'warranty')
        .field('expiry_date', new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]) // 15 days from now
        .field('property_id', propertyId)
        .attach('document', testFilePath);

      documentId = warrantyResponse.body.data.id;
    });

    it('should identify expiring documents', async () => {
      const response = await request(app)
        .get('/api/v1/documents?expiring_soon=true')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      const expiringDoc = response.body.data.documents.find(doc => doc.id === documentId);
      expect(expiringDoc).toBeDefined();
      expect(expiringDoc.title).toBe('Expiring Warranty');
    });

    it('should mark documents as favorites', async () => {
      const response = await request(app)
        .put(`/api/v1/documents/${documentId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ is_favorite: true })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.is_favorite).toBe(true);
    });

    it('should track document view counts', async () => {
      // View the document multiple times
      await request(app)
        .get(`/api/v1/documents/${documentId}`)
        .set('Authorization', `Bearer ${authToken}`);

      await request(app)
        .get(`/api/v1/documents/${documentId}`)
        .set('Authorization', `Bearer ${authToken}`);

      const response = await request(app)
        .get(`/api/v1/documents/${documentId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.view_count).toBe(3);
    });

    it('should support pagination', async () => {
      const response = await request(app)
        .get('/api/v1/documents?page=1&limit=5')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.pagination.page).toBe(1);
      expect(response.body.data.pagination.limit).toBe(5);
      expect(response.body.data.pagination.total).toBeGreaterThanOrEqual(0);
    });

    it('should support sorting', async () => {
      const response = await request(app)
        .get('/api/v1/documents?sort_by=created_at&sort_order=asc')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.documents).toBeInstanceOf(Array);
      
      // Verify sorting if there are multiple documents
      if (response.body.data.documents.length > 1) {
        const firstDate = new Date(response.body.data.documents[0].created_at);
        const lastDate = new Date(response.body.data.documents[response.body.data.documents.length - 1].created_at);
        expect(firstDate.getTime()).toBeLessThanOrEqual(lastDate.getTime());
      }
    });
  });
});