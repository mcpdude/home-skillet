const multer = require('multer');
const { 
  uploadToSupabase, 
  STORAGE_BUCKETS, 
  generateStoragePath 
} = require('../config/supabaseStorage');

// Configure multer to use memory storage (files will be uploaded to Supabase)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 25 * 1024 * 1024, // 25MB limit
    files: 10 // Maximum 10 files at once
  },
  fileFilter: (req, file, cb) => {
    // Check if file is an image
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

/**
 * Middleware to upload insurance photos to Supabase Storage
 */
function uploadInsurancePhotos(req, res, next) {
  // Use multer to handle the multipart form data
  upload.array('photos', 10)(req, res, async (err) => {
    if (err) {
      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return res.status(400).json({
            success: false,
            error: { message: 'File size too large. Maximum size is 25MB per file.' }
          });
        } else if (err.code === 'LIMIT_FILE_COUNT') {
          return res.status(400).json({
            success: false,
            error: { message: 'Too many files. Maximum 10 files allowed.' }
          });
        }
      }
      return res.status(400).json({
        success: false,
        error: { message: err.message || 'Invalid file type. Only images are allowed.' }
      });
    }

    // Check if files were uploaded
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        error: { message: 'No files uploaded' }
      });
    }

    try {
      const itemId = req.params.id;
      const uploadedPhotos = [];
      const uploadPromises = [];

      // Process each uploaded file
      for (let i = 0; i < req.files.length; i++) {
        const file = req.files[i];
        const storagePath = generateStoragePath('insurance', file.originalname, itemId);
        
        // Upload to Supabase Storage
        const uploadPromise = uploadToSupabase(file, STORAGE_BUCKETS.INSURANCE_PHOTOS, storagePath, {
          optimize: true,
          imageOptions: {
            width: 1920,
            height: 1080,
            quality: 85,
            format: 'jpeg'
          }
        });

        uploadPromises.push(uploadPromise);
      }

      // Wait for all uploads to complete
      const uploadResults = await Promise.all(uploadPromises);

      // Process upload results
      for (let i = 0; i < uploadResults.length; i++) {
        const result = uploadResults[i];
        const file = req.files[i];

        if (!result.success) {
          throw new Error(`Failed to upload ${file.originalname}: ${result.error}`);
        }

        uploadedPhotos.push({
          originalname: file.originalname,
          filename: result.data.path.split('/').pop(), // Extract filename from path
          file_path: result.data.path,
          file_url: result.data.publicUrl,
          file_size: result.data.size,
          mime_type: file.mimetype
        });
      }

      // Attach uploaded photos to request object for use in route handler
      req.uploadedPhotos = uploadedPhotos;
      next();

    } catch (error) {
      console.error('Error uploading photos to Supabase:', error);
      return res.status(500).json({
        success: false,
        error: { message: 'Failed to upload photos to cloud storage' }
      });
    }
  });
}

/**
 * Middleware to upload single insurance photo to Supabase Storage
 */
function uploadSingleInsurancePhoto(req, res, next) {
  upload.single('photo')(req, res, async (err) => {
    if (err) {
      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return res.status(400).json({
            success: false,
            error: { message: 'File size too large. Maximum size is 25MB.' }
          });
        }
      }
      return res.status(400).json({
        success: false,
        error: { message: err.message || 'Invalid file type. Only images are allowed.' }
      });
    }

    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: { message: 'No file uploaded' }
      });
    }

    try {
      const itemId = req.params.id;
      const file = req.file;
      const storagePath = generateStoragePath('insurance', file.originalname, itemId);

      // Upload to Supabase Storage
      const result = await uploadToSupabase(file, STORAGE_BUCKETS.INSURANCE_PHOTOS, storagePath, {
        optimize: true,
        imageOptions: {
          width: 1920,
          height: 1080,
          quality: 85,
          format: 'jpeg'
        }
      });

      if (!result.success) {
        throw new Error(result.error);
      }

      req.uploadedPhoto = {
        originalname: file.originalname,
        filename: result.data.path.split('/').pop(),
        file_path: result.data.path,
        file_url: result.data.publicUrl,
        file_size: result.data.size,
        mime_type: file.mimetype
      };

      next();

    } catch (error) {
      console.error('Error uploading photo to Supabase:', error);
      return res.status(500).json({
        success: false,
        error: { message: 'Failed to upload photo to cloud storage' }
      });
    }
  });
}

/**
 * Middleware to upload document to Supabase Storage
 */
function uploadDocument(req, res, next) {
  // Configure multer for documents (different file types allowed)
  const documentUpload = multer({
    storage: multer.memoryStorage(),
    limits: {
      fileSize: 50 * 1024 * 1024, // 50MB limit for documents
    },
    fileFilter: (req, file, cb) => {
      const allowedTypes = [
        'application/pdf',
        'image/jpeg',
        'image/jpg', 
        'image/png',
        'image/gif',
        'image/webp',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'text/plain',
        'text/csv'
      ];
      
      if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
      } else {
        cb(new Error('File type not allowed. Supported types: PDF, Images, Word, Excel, Text, CSV'), false);
      }
    }
  });

  documentUpload.single('document')(req, res, async (err) => {
    if (err) {
      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return res.status(400).json({
            success: false,
            error: { message: 'File size too large. Maximum size is 50MB.' }
          });
        }
      }
      return res.status(400).json({
        success: false,
        error: { message: err.message }
      });
    }

    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: { message: 'No document file provided' }
      });
    }

    try {
      const file = req.file;
      const storagePath = generateStoragePath('documents', file.originalname);

      // Upload to Supabase Storage (no optimization for documents)
      const result = await uploadToSupabase(file, STORAGE_BUCKETS.DOCUMENTS, storagePath, {
        optimize: false // Don't optimize documents
      });

      if (!result.success) {
        throw new Error(result.error);
      }

      // Calculate file hash for duplicate detection
      const crypto = require('crypto');
      const hashSum = crypto.createHash('sha256');
      hashSum.update(file.buffer);
      const fileHash = hashSum.digest('hex');

      req.uploadedDocument = {
        originalname: file.originalname,
        filename: result.data.path.split('/').pop(),
        file_path: result.data.path,
        file_url: result.data.publicUrl,
        file_size: result.data.size,
        mime_type: file.mimetype,
        file_hash: fileHash
      };

      next();

    } catch (error) {
      console.error('Error uploading document to Supabase:', error);
      return res.status(500).json({
        success: false,
        error: { message: 'Failed to upload document to cloud storage' }
      });
    }
  });
}

module.exports = {
  uploadInsurancePhotos,
  uploadSingleInsurancePhoto,
  uploadDocument
};