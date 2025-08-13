const { createClient } = require('@supabase/supabase-js');

// Initialize Supabase client with service role for storage operations
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  }
);

// Storage bucket names
const STORAGE_BUCKETS = {
  INSURANCE_PHOTOS: 'insurance-photos',
  DOCUMENTS: 'documents',
  PROPERTY_PHOTOS: 'property-photos'
};

/**
 * Initialize storage buckets if they don't exist
 */
async function initializeStorageBuckets() {
  try {
    const { data: buckets, error } = await supabase.storage.listBuckets();
    
    if (error) {
      console.error('Error listing buckets:', error);
      return;
    }

    // Create insurance-photos bucket if it doesn't exist
    const insurancePhotoBucket = buckets.find(bucket => bucket.name === STORAGE_BUCKETS.INSURANCE_PHOTOS);
    if (!insurancePhotoBucket) {
      const { error: createError } = await supabase.storage.createBucket(STORAGE_BUCKETS.INSURANCE_PHOTOS, {
        public: true, // Make bucket public for easy access
        allowedMimeTypes: ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'],
        fileSizeLimit: 25 * 1024 * 1024 // 25MB limit
      });

      if (createError) {
        console.error('Error creating insurance-photos bucket:', createError);
      } else {
        console.log('✅ Created insurance-photos storage bucket');
      }
    }

    // Create documents bucket if it doesn't exist
    const documentsBucket = buckets.find(bucket => bucket.name === STORAGE_BUCKETS.DOCUMENTS);
    if (!documentsBucket) {
      const { error: createError } = await supabase.storage.createBucket(STORAGE_BUCKETS.DOCUMENTS, {
        public: true,
        fileSizeLimit: 50 * 1024 * 1024 // 50MB limit
      });

      if (createError) {
        console.error('Error creating documents bucket:', createError);
      } else {
        console.log('✅ Created documents storage bucket');
      }
    }

    // Create property-photos bucket if it doesn't exist
    const propertyPhotosBucket = buckets.find(bucket => bucket.name === STORAGE_BUCKETS.PROPERTY_PHOTOS);
    if (!propertyPhotosBucket) {
      const { error: createError } = await supabase.storage.createBucket(STORAGE_BUCKETS.PROPERTY_PHOTOS, {
        public: true,
        allowedMimeTypes: ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'],
        fileSizeLimit: 25 * 1024 * 1024 // 25MB limit
      });

      if (createError) {
        console.error('Error creating property-photos bucket:', createError);
      } else {
        console.log('✅ Created property-photos storage bucket');
      }
    }

  } catch (error) {
    console.error('Error initializing storage buckets:', error);
  }
}

/**
 * Image optimization disabled - using direct uploads
 * Sharp module removed to eliminate Railway deployment issues
 */
async function optimizeImage(buffer, options = {}) {
  // Return original buffer - no server-side image processing
  return buffer;
}

/**
 * Upload file to Supabase Storage
 */
async function uploadToSupabase(file, bucketName, path, options = {}) {
  try {
    let fileBuffer = file.buffer;
    let contentType = file.mimetype;

    // Optimize images before upload
    if (file.mimetype.startsWith('image/') && options.optimize !== false) {
      fileBuffer = await optimizeImage(fileBuffer, options.imageOptions);
    }

    // Upload file to Supabase Storage
    const { data, error } = await supabase.storage
      .from(bucketName)
      .upload(path, fileBuffer, {
        contentType,
        cacheControl: '3600', // Cache for 1 hour
        upsert: options.upsert || false
      });

    if (error) {
      throw error;
    }

    // Get public URL for the uploaded file
    const { data: urlData } = supabase.storage
      .from(bucketName)
      .getPublicUrl(path);

    return {
      success: true,
      data: {
        path: data.path,
        fullPath: data.fullPath,
        publicUrl: urlData.publicUrl,
        size: fileBuffer.length
      }
    };
  } catch (error) {
    return {
      success: false,
      error: error.message || 'Upload failed'
    };
  }
}

/**
 * Delete file from Supabase Storage
 */
async function deleteFromSupabase(bucketName, path) {
  try {
    const { error } = await supabase.storage
      .from(bucketName)
      .remove([path]);

    if (error) {
      throw error;
    }

    return { success: true };
  } catch (error) {
    return {
      success: false,
      error: error.message || 'Delete failed'
    };
  }
}

/**
 * Get signed URL for private files (if needed)
 */
async function getSignedUrl(bucketName, path, expiresIn = 3600) {
  try {
    const { data, error } = await supabase.storage
      .from(bucketName)
      .createSignedUrl(path, expiresIn);

    if (error) {
      throw error;
    }

    return {
      success: true,
      signedUrl: data.signedUrl
    };
  } catch (error) {
    return {
      success: false,
      error: error.message || 'Failed to get signed URL'
    };
  }
}

/**
 * Get transformed image URL (resize, crop, etc.)
 */
function getTransformedImageUrl(bucketName, path, transformOptions = {}) {
  const { data } = supabase.storage
    .from(bucketName)
    .getPublicUrl(path, {
      transform: transformOptions
    });

  return data.publicUrl;
}

/**
 * Generate unique file path for storage
 */
function generateStoragePath(prefix, originalName, itemId = null) {
  const timestamp = Date.now();
  const randomSuffix = Math.random().toString(36).substring(2, 8);
  const extension = originalName.split('.').pop();
  
  if (itemId) {
    return `${prefix}/${itemId}/${timestamp}-${randomSuffix}.${extension}`;
  } else {
    return `${prefix}/${timestamp}-${randomSuffix}.${extension}`;
  }
}

module.exports = {
  supabase,
  STORAGE_BUCKETS,
  initializeStorageBuckets,
  uploadToSupabase,
  deleteFromSupabase,
  getSignedUrl,
  getTransformedImageUrl,
  generateStoragePath,
  optimizeImage
};