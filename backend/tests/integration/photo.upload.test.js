const request = require('supertest');
const app = require('../../src/app');
const path = require('path');
const fs = require('fs');

describe('Photo Upload Integration Tests', () => {
  let authToken;
  let userId;
  let propertyId;

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
        description: 'Test property for photo upload'
      });

    propertyId = propertyResponse.body.data.id;
  });

  describe('POST /api/v1/properties/:id/photos', () => {
    it('should upload a photo to a property', async () => {
      // Create a test image file
      const testImagePath = path.join(__dirname, '../fixtures/test-image.jpg');
      
      // Create test image if it doesn't exist
      if (!fs.existsSync(testImagePath)) {
        const testImageBuffer = Buffer.from('fake-image-data');
        fs.writeFileSync(testImagePath, testImageBuffer);
      }

      const response = await request(app)
        .post(`/api/v1/properties/${propertyId}/photos`)
        .set('Authorization', `Bearer ${authToken}`)
        .attach('photo', testImagePath)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('id');
      expect(response.body.data).toHaveProperty('url');
      expect(response.body.data).toHaveProperty('filename');
      expect(response.body.data.property_id).toBe(propertyId);
    });

    it('should reject non-image files', async () => {
      const testFilePath = path.join(__dirname, '../fixtures/test-document.txt');
      fs.writeFileSync(testFilePath, 'This is not an image');

      const response = await request(app)
        .post(`/api/v1/properties/${propertyId}/photos`)
        .set('Authorization', `Bearer ${authToken}`)
        .attach('photo', testFilePath)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toContain('Only image files are allowed');
    });

    it('should require authentication', async () => {
      const testImagePath = path.join(__dirname, '../fixtures/test-image.jpg');
      
      const response = await request(app)
        .post(`/api/v1/properties/${propertyId}/photos`)
        .attach('photo', testImagePath)
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toContain('No token provided');
    });

    it('should only allow property owner to upload photos', async () => {
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

      const otherToken = otherUserResponse.body.data.token;
      const testImagePath = path.join(__dirname, '../fixtures/test-image.jpg');

      const response = await request(app)
        .post(`/api/v1/properties/${propertyId}/photos`)
        .set('Authorization', `Bearer ${otherToken}`)
        .attach('photo', testImagePath)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toContain('Access denied');
    });
  });

  describe('GET /api/v1/properties/:id/photos', () => {
    it('should get all photos for a property', async () => {
      const response = await request(app)
        .get(`/api/v1/properties/${propertyId}/photos`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
    });
  });

  describe('DELETE /api/v1/properties/:propertyId/photos/:photoId', () => {
    let photoId;

    beforeEach(async () => {
      // Upload a test photo first
      const testImagePath = path.join(__dirname, '../fixtures/test-image.jpg');
      const uploadResponse = await request(app)
        .post(`/api/v1/properties/${propertyId}/photos`)
        .set('Authorization', `Bearer ${authToken}`)
        .attach('photo', testImagePath);
      
      photoId = uploadResponse.body.data.id;
    });

    it('should delete a photo', async () => {
      const response = await request(app)
        .delete(`/api/v1/properties/${propertyId}/photos/${photoId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.message).toContain('Photo deleted successfully');
    });

    it('should return 404 for non-existent photo', async () => {
      const fakePhotoId = '12345678-1234-1234-1234-123456789012';
      
      const response = await request(app)
        .delete(`/api/v1/properties/${propertyId}/photos/${fakePhotoId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toContain('Photo not found');
    });
  });
});