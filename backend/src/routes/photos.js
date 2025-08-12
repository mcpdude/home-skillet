const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { authenticate } = require('../middleware/auth');
const db = require('../config/database');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = 'uploads/properties';
    // Create directory if it doesn't exist
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const extension = path.extname(file.originalname);
    cb(null, file.fieldname + '-' + uniqueSuffix + extension);
  }
});

// File filter to only allow images
const fileFilter = (req, file, cb) => {
  const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
  
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed (JPEG, PNG, GIF, WebP)'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  }
});

// POST /api/v1/properties/:id/photos - Upload a photo
router.post('/properties/:id/photos', authenticate, upload.single('photo'), async (req, res) => {
  try {
    const { id: propertyId } = req.params;
    const { description } = req.body;
    
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: { message: 'No photo file provided' }
      });
    }

    // Verify property exists and user owns it
    const property = await db('properties')
      .where({ id: propertyId, owner_id: req.user.id })
      .first();

    if (!property) {
      // Clean up uploaded file if property doesn't exist or user doesn't own it
      fs.unlinkSync(req.file.path);
      return res.status(403).json({
        success: false,
        error: { message: 'Access denied. Property not found or you do not own this property.' }
      });
    }

    // Save photo record to database
    const photoId = uuidv4();
    const photoData = {
      id: photoId,
      property_id: propertyId,
      filename: req.file.filename,
      original_name: req.file.originalname,
      url: `/uploads/properties/${req.file.filename}`,
      file_path: req.file.path,
      file_size: req.file.size,
      mime_type: req.file.mimetype,
      description: description || null,
      created_at: new Date(),
      updated_at: new Date()
    };

    await db('property_photos').insert(photoData);

    res.status(201).json({
      success: true,
      data: {
        id: photoId,
        url: photoData.url,
        filename: req.file.filename,
        original_name: req.file.originalname,
        file_size: req.file.size,
        mime_type: req.file.mimetype,
        description: description || null,
        property_id: propertyId,
        created_at: photoData.created_at
      }
    });

  } catch (error) {
    // Clean up uploaded file on error
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }

    console.error('Photo upload error:', error);

    if (error.message.includes('Only image files are allowed')) {
      return res.status(400).json({
        success: false,
        error: { message: error.message }
      });
    }

    res.status(500).json({
      success: false,
      error: { message: 'Internal server error' }
    });
  }
});

// GET /api/v1/properties/:id/photos - Get all photos for a property
router.get('/properties/:id/photos', authenticate, async (req, res) => {
  try {
    const { id: propertyId } = req.params;

    // Verify property exists and user owns it
    const property = await db('properties')
      .where({ id: propertyId, owner_id: req.user.id })
      .first();

    if (!property) {
      return res.status(403).json({
        success: false,
        error: { message: 'Access denied. Property not found or you do not own this property.' }
      });
    }

    const photos = await db('property_photos')
      .where({ property_id: propertyId })
      .orderBy('display_order')
      .orderBy('created_at', 'desc')
      .select([
        'id',
        'url',
        'filename',
        'original_name',
        'file_size',
        'mime_type',
        'description',
        'is_primary',
        'display_order',
        'created_at'
      ]);

    res.json({
      success: true,
      data: photos
    });

  } catch (error) {
    console.error('Get photos error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Internal server error' }
    });
  }
});

// DELETE /api/v1/properties/:propertyId/photos/:photoId - Delete a photo
router.delete('/properties/:propertyId/photos/:photoId', authenticate, async (req, res) => {
  try {
    const { propertyId, photoId } = req.params;

    // Verify property exists and user owns it
    const property = await db('properties')
      .where({ id: propertyId, owner_id: req.user.id })
      .first();

    if (!property) {
      return res.status(403).json({
        success: false,
        error: { message: 'Access denied. Property not found or you do not own this property.' }
      });
    }

    // Get photo record
    const photo = await db('property_photos')
      .where({ id: photoId, property_id: propertyId })
      .first();

    if (!photo) {
      return res.status(404).json({
        success: false,
        error: { message: 'Photo not found' }
      });
    }

    // Delete file from filesystem
    if (fs.existsSync(photo.file_path)) {
      fs.unlinkSync(photo.file_path);
    }

    // Delete record from database
    await db('property_photos').where({ id: photoId }).delete();

    res.json({
      success: true,
      data: { message: 'Photo deleted successfully' }
    });

  } catch (error) {
    console.error('Delete photo error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Internal server error' }
    });
  }
});

// PUT /api/v1/properties/:propertyId/photos/:photoId - Update photo metadata
router.put('/properties/:propertyId/photos/:photoId', authenticate, async (req, res) => {
  try {
    const { propertyId, photoId } = req.params;
    const { description, is_primary, display_order } = req.body;

    // Verify property exists and user owns it
    const property = await db('properties')
      .where({ id: propertyId, owner_id: req.user.id })
      .first();

    if (!property) {
      return res.status(403).json({
        success: false,
        error: { message: 'Access denied. Property not found or you do not own this property.' }
      });
    }

    // Verify photo exists
    const photo = await db('property_photos')
      .where({ id: photoId, property_id: propertyId })
      .first();

    if (!photo) {
      return res.status(404).json({
        success: false,
        error: { message: 'Photo not found' }
      });
    }

    // If setting as primary, unset other primary photos for this property
    if (is_primary === true) {
      await db('property_photos')
        .where({ property_id: propertyId })
        .update({ is_primary: false });
    }

    const updateData = { updated_at: new Date() };
    if (description !== undefined) updateData.description = description;
    if (is_primary !== undefined) updateData.is_primary = is_primary;
    if (display_order !== undefined) updateData.display_order = display_order;

    await db('property_photos')
      .where({ id: photoId })
      .update(updateData);

    const updatedPhoto = await db('property_photos')
      .where({ id: photoId })
      .select([
        'id',
        'url',
        'filename',
        'original_name',
        'file_size',
        'mime_type',
        'description',
        'is_primary',
        'display_order',
        'created_at',
        'updated_at'
      ])
      .first();

    res.json({
      success: true,
      data: updatedPhoto
    });

  } catch (error) {
    console.error('Update photo error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Internal server error' }
    });
  }
});

module.exports = router;