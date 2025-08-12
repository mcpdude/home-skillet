const express = require('express');
const { authenticate } = require('../middleware/auth');
const { createClient } = require('@supabase/supabase-js');
const { v4: uuidv4 } = require('uuid');
const { 
  createResponse, 
  createErrorResponse
} = require('../utils/helpers');

const router = express.Router();

// Initialize Supabase client
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// Generate signed URL for document upload
router.post('/document/signed-url', authenticate, async (req, res) => {
  try {
    const { filename, contentType, fileSize } = req.body;

    if (!filename || !contentType) {
      return res.status(400).json(createErrorResponse('Filename and contentType are required'));
    }

    // Validate file size (max 25MB)
    if (fileSize && fileSize > 25 * 1024 * 1024) {
      return res.status(400).json(createErrorResponse('File size too large (max 25MB)'));
    }

    // Validate file type
    const allowedTypes = [
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
      'text/plain',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    ];

    if (!allowedTypes.includes(contentType)) {
      return res.status(400).json(createErrorResponse('Unsupported file type'));
    }

    // Generate unique file path
    const fileExtension = filename.split('.').pop();
    const uniqueFilename = `${uuidv4()}.${fileExtension}`;
    const filePath = `users/${req.user.id}/documents/${uniqueFilename}`;

    // Generate signed URL for upload
    const { data, error } = await supabase.storage
      .from('documents')
      .createSignedUploadUrl(filePath);

    if (error) {
      console.error('Supabase upload URL error:', error);
      return res.status(500).json(createErrorResponse('Failed to generate upload URL'));
    }

    return res.json(createResponse({
      uploadUrl: data.signedUrl,
      filePath: filePath,
      publicUrl: supabase.storage.from('documents').getPublicUrl(filePath).data.publicUrl,
      expiresIn: 3600 // 1 hour
    }, 'Signed URL generated successfully'));

  } catch (error) {
    console.error('Error generating signed URL:', error);
    return res.status(500).json(createErrorResponse('Failed to generate upload URL'));
  }
});

// Generate signed URL for insurance photo upload
router.post('/insurance-photo/signed-url', authenticate, async (req, res) => {
  try {
    const { filename, contentType, fileSize, photoType = 'overview' } = req.body;

    if (!filename || !contentType) {
      return res.status(400).json(createErrorResponse('Filename and contentType are required'));
    }

    // Validate file size (max 25MB)
    if (fileSize && fileSize > 25 * 1024 * 1024) {
      return res.status(400).json(createErrorResponse('File size too large (max 25MB)'));
    }

    // Validate image type
    const allowedImageTypes = [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp'
    ];

    if (!allowedImageTypes.includes(contentType)) {
      return res.status(400).json(createErrorResponse('Only image files are allowed'));
    }

    // Validate photo type
    const allowedPhotoTypes = ['overview', 'detail', 'serial_number', 'damage', 'packaging', 'receipt'];
    if (!allowedPhotoTypes.includes(photoType)) {
      return res.status(400).json(createErrorResponse('Invalid photo type'));
    }

    // Generate unique file path
    const fileExtension = filename.split('.').pop();
    const uniqueFilename = `${uuidv4()}.${fileExtension}`;
    const filePath = `users/${req.user.id}/insurance-photos/${photoType}/${uniqueFilename}`;

    // Generate signed URL for upload
    const { data, error } = await supabase.storage
      .from('insurance-photos')
      .createSignedUploadUrl(filePath);

    if (error) {
      console.error('Supabase upload URL error:', error);
      return res.status(500).json(createErrorResponse('Failed to generate upload URL'));
    }

    return res.json(createResponse({
      uploadUrl: data.signedUrl,
      filePath: filePath,
      publicUrl: supabase.storage.from('insurance-photos').getPublicUrl(filePath).data.publicUrl,
      photoType: photoType,
      expiresIn: 3600 // 1 hour
    }, 'Signed URL generated successfully'));

  } catch (error) {
    console.error('Error generating signed URL:', error);
    return res.status(500).json(createErrorResponse('Failed to generate upload URL'));
  }
});

// Generate signed URL for property photo upload
router.post('/property-photo/signed-url', authenticate, async (req, res) => {
  try {
    const { filename, contentType, fileSize } = req.body;

    if (!filename || !contentType) {
      return res.status(400).json(createErrorResponse('Filename and contentType are required'));
    }

    // Validate file size (max 25MB)
    if (fileSize && fileSize > 25 * 1024 * 1024) {
      return res.status(400).json(createErrorResponse('File size too large (max 25MB)'));
    }

    // Validate image type
    const allowedImageTypes = [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp'
    ];

    if (!allowedImageTypes.includes(contentType)) {
      return res.status(400).json(createErrorResponse('Only image files are allowed'));
    }

    // Generate unique file path
    const fileExtension = filename.split('.').pop();
    const uniqueFilename = `${uuidv4()}.${fileExtension}`;
    const filePath = `users/${req.user.id}/property-photos/${uniqueFilename}`;

    // Generate signed URL for upload
    const { data, error } = await supabase.storage
      .from('property-photos')
      .createSignedUploadUrl(filePath);

    if (error) {
      console.error('Supabase upload URL error:', error);
      return res.status(500).json(createErrorResponse('Failed to generate upload URL'));
    }

    return res.json(createResponse({
      uploadUrl: data.signedUrl,
      filePath: filePath,
      publicUrl: supabase.storage.from('property-photos').getPublicUrl(filePath).data.publicUrl,
      expiresIn: 3600 // 1 hour
    }, 'Signed URL generated successfully'));

  } catch (error) {
    console.error('Error generating signed URL:', error);
    return res.status(500).json(createErrorResponse('Failed to generate upload URL'));
  }
});

// Confirm upload and save metadata
router.post('/confirm-upload', authenticate, async (req, res) => {
  try {
    const { filePath, originalFilename, fileSize, contentType, uploadType, metadata = {} } = req.body;

    if (!filePath || !uploadType) {
      return res.status(400).json(createErrorResponse('FilePath and uploadType are required'));
    }

    // Verify file exists in Supabase Storage
    const bucketName = uploadType === 'document' ? 'documents' : 
                      uploadType === 'insurance-photo' ? 'insurance-photos' : 'property-photos';
    
    const { data, error } = await supabase.storage
      .from(bucketName)
      .list(filePath.split('/').slice(0, -1).join('/'), {
        search: filePath.split('/').pop()
      });

    if (error || !data || data.length === 0) {
      return res.status(400).json(createErrorResponse('File upload not confirmed in storage'));
    }

    const publicUrl = supabase.storage.from(bucketName).getPublicUrl(filePath).data.publicUrl;

    return res.json(createResponse({
      filePath,
      publicUrl,
      confirmed: true,
      metadata: {
        originalFilename,
        fileSize,
        contentType,
        uploadedAt: new Date().toISOString(),
        ...metadata
      }
    }, 'Upload confirmed successfully'));

  } catch (error) {
    console.error('Error confirming upload:', error);
    return res.status(500).json(createErrorResponse('Failed to confirm upload'));
  }
});

module.exports = router;