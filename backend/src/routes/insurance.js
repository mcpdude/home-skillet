const express = require('express');
const { authenticate } = require('../middleware/auth');
const db = require('../config/database');
const { v4: uuidv4 } = require('uuid');
const { 
  createResponse, 
  createErrorResponse
} = require('../utils/helpers');
const { uploadInsurancePhotos } = require('../middleware/supabaseUpload');
const { deleteFromSupabase, STORAGE_BUCKETS, getTransformedImageUrl } = require('../config/supabaseStorage');

const router = express.Router();

// Helper function to validate property access
async function validatePropertyAccess(userId, propertyId) {
  const property = await db('properties')
    .where('id', propertyId)
    .where(function() {
      this.where('owner_id', userId)
        .orWhereExists(function() {
          this.select('*')
            .from('property_permissions')
            .where('property_id', propertyId)
            .where('user_id', userId);
        });
    })
    .first();
  return !!property;
}

// Helper function to validate item access
async function validateItemAccess(userId, itemId) {
  const item = await db('insurance_items')
    .join('properties', 'insurance_items.property_id', 'properties.id')
    .where('insurance_items.id', itemId)
    .where(function() {
      this.where('properties.owner_id', userId)
        .orWhereExists(function() {
          this.select('*')
            .from('property_permissions')
            .whereRaw('property_permissions.property_id = properties.id')
            .where('property_permissions.user_id', userId);
        });
    })
    .select('insurance_items.*', 'properties.owner_id')
    .first();
  return item;
}

/**
 * POST /api/v1/insurance/items
 * Create a new insurance item
 */
router.post('/items', authenticate, async (req, res) => {
  try {
    const {
      property_id,
      name,
      description,
      category,
      subcategory,
      room_location,
      specific_location,
      brand,
      model,
      serial_number,
      condition,
      purchase_date,
      purchase_location,
      purchase_price,
      current_estimated_value,
      replacement_cost,
      currency,
      is_insured,
      insurance_policy_number,
      insurance_coverage_amount,
      requires_separate_coverage,
      tags,
      notes,
      custom_fields
    } = req.body;

    if (!property_id || !name || !category) {
      return res.status(400).json(createResponse(false, null, {
        message: 'Property ID, name, and category are required'
      }));
    }

    // Validate property access
    const hasAccess = await validatePropertyAccess(req.user.id, property_id);
    if (!hasAccess) {
      return res.status(403).json(createResponse(false, null, {
        message: 'Access denied to this property'
      }));
    }

    // Parse tags if provided
    let parsedTags = [];
    if (tags) {
      try {
        parsedTags = typeof tags === 'string' ? JSON.parse(tags) : tags;
      } catch (e) {
        parsedTags = [tags];
      }
    }

    // Parse custom fields if provided
    let parsedCustomFields = {};
    if (custom_fields) {
      try {
        parsedCustomFields = typeof custom_fields === 'string' ? JSON.parse(custom_fields) : custom_fields;
      } catch (e) {
        console.warn('Invalid custom_fields JSON, ignoring:', e.message);
      }
    }

    // Create insurance item
    const itemId = uuidv4();
    const itemData = {
      id: itemId,
      property_id,
      created_by: req.user.id,
      name: name.trim(),
      description: description?.trim() || null,
      category,
      subcategory: subcategory || null,
      room_location: room_location || null,
      specific_location: specific_location?.trim() || null,
      brand: brand?.trim() || null,
      model: model?.trim() || null,
      serial_number: serial_number?.trim() || null,
      condition: condition || 'good',
      purchase_date: purchase_date || null,
      purchase_location: purchase_location?.trim() || null,
      purchase_price: purchase_price ? parseFloat(purchase_price) : null,
      current_estimated_value: current_estimated_value ? parseFloat(current_estimated_value) : null,
      replacement_cost: replacement_cost ? parseFloat(replacement_cost) : null,
      currency: currency || 'USD',
      is_insured: is_insured || false,
      insurance_policy_number: insurance_policy_number?.trim() || null,
      insurance_coverage_amount: insurance_coverage_amount ? parseFloat(insurance_coverage_amount) : null,
      requires_separate_coverage: requires_separate_coverage || false,
      tags: JSON.stringify(parsedTags),
      notes: notes?.trim() || null,
      custom_fields: JSON.stringify(parsedCustomFields),
      status: 'active',
      is_favorite: false,
      priority: 3,
      created_at: new Date(),
      updated_at: new Date()
    };

    await db('insurance_items').insert(itemData);

    // Get created item with user info
    const createdItem = await db('insurance_items')
      .leftJoin('users', 'insurance_items.created_by', 'users.id')
      .where('insurance_items.id', itemId)
      .select(
        'insurance_items.*',
        'users.first_name as creator_first_name',
        'users.last_name as creator_last_name'
      )
      .first();

    // Format response
    const formattedItem = {
      ...createdItem,
      tags: JSON.parse(createdItem.tags || '[]'),
      custom_fields: JSON.parse(createdItem.custom_fields || '{}'),
      created_by: {
        id: createdItem.created_by,
        name: `${createdItem.creator_first_name} ${createdItem.creator_last_name}`
      }
    };

    // Remove redundant fields
    delete formattedItem.creator_first_name;
    delete formattedItem.creator_last_name;

    res.status(201).json(createResponse(true, formattedItem));

  } catch (error) {
    console.error('Insurance item creation error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * GET /api/v1/insurance/items
 * Get insurance items with filtering and pagination
 */
router.get('/items', authenticate, async (req, res) => {
  try {
    const {
      property_id,
      category,
      subcategory,
      room_location,
      status = 'active',
      condition,
      search,
      tags,
      min_value,
      max_value,
      high_value_only, // items with replacement_cost > threshold
      page = 1,
      limit = 20,
      sort_by = 'created_at',
      sort_order = 'desc'
    } = req.query;

    // Build query with property access control
    let query = db('insurance_items')
      .join('properties', 'insurance_items.property_id', 'properties.id')
      .leftJoin('users', 'insurance_items.created_by', 'users.id')
      .where('insurance_items.status', status)
      .where(function() {
        this.where('properties.owner_id', req.user.id)
          .orWhereExists(function() {
            this.select('*')
              .from('property_permissions')
              .whereRaw('property_permissions.property_id = properties.id')
              .where('property_permissions.user_id', req.user.id);
          });
      });

    // Apply filters
    if (property_id) {
      query.where('insurance_items.property_id', property_id);
    }

    if (category) {
      query.where('insurance_items.category', category);
    }

    if (subcategory) {
      query.where('insurance_items.subcategory', subcategory);
    }

    if (room_location) {
      query.where('insurance_items.room_location', room_location);
    }

    if (condition) {
      query.where('insurance_items.condition', condition);
    }

    if (search) {
      query.where(function() {
        this.where('insurance_items.name', 'like', `%${search}%`)
          .orWhere('insurance_items.description', 'like', `%${search}%`)
          .orWhere('insurance_items.brand', 'like', `%${search}%`)
          .orWhere('insurance_items.model', 'like', `%${search}%`)
          .orWhere('insurance_items.serial_number', 'like', `%${search}%`);
      });
    }

    if (tags) {
      const tagArray = Array.isArray(tags) ? tags : [tags];
      tagArray.forEach(tag => {
        query.whereRaw("JSON_EXTRACT(insurance_items.tags, '$') LIKE ?", [`%"${tag}"%`]);
      });
    }

    if (min_value) {
      query.where('insurance_items.replacement_cost', '>=', parseFloat(min_value));
    }

    if (max_value) {
      query.where('insurance_items.replacement_cost', '<=', parseFloat(max_value));
    }

    if (high_value_only === 'true') {
      // Items worth more than $5000 typically need special coverage
      query.where('insurance_items.replacement_cost', '>', 5000);
    }

    // Get total count for pagination
    const totalQuery = query.clone();
    const total = await totalQuery.count('insurance_items.id as count').first();
    const totalRecords = parseInt(total.count);

    // Apply sorting and pagination
    const validSortFields = ['created_at', 'updated_at', 'name', 'purchase_date', 'replacement_cost', 'category'];
    const sortField = validSortFields.includes(sort_by) ? `insurance_items.${sort_by}` : 'insurance_items.created_at';
    const sortDirection = sort_order.toLowerCase() === 'asc' ? 'asc' : 'desc';

    query.orderBy(sortField, sortDirection);

    const pageNum = Math.max(1, parseInt(page));
    const limitNum = Math.min(100, Math.max(1, parseInt(limit)));
    const offset = (pageNum - 1) * limitNum;

    query.limit(limitNum).offset(offset);

    // Select fields
    query.select(
      'insurance_items.*',
      'properties.name as property_name',
      'users.first_name as creator_first_name',
      'users.last_name as creator_last_name'
    );

    const items = await query;

    // Get photo counts for each item
    const itemIds = items.map(item => item.id);
    let photoCounts = [];
    if (itemIds.length > 0) {
      photoCounts = await db('insurance_item_photos')
        .whereIn('item_id', itemIds)
        .select('item_id')
        .count('* as photo_count')
        .groupBy('item_id');
    }

    const photoCountMap = {};
    photoCounts.forEach(pc => {
      photoCountMap[pc.item_id] = parseInt(pc.photo_count);
    });

    // Format response
    const formattedItems = items.map(item => ({
      id: item.id,
      property_id: item.property_id,
      property_name: item.property_name,
      name: item.name,
      description: item.description,
      category: item.category,
      subcategory: item.subcategory,
      room_location: item.room_location,
      specific_location: item.specific_location,
      brand: item.brand,
      model: item.model,
      serial_number: item.serial_number,
      condition: item.condition,
      purchase_date: item.purchase_date,
      purchase_location: item.purchase_location,
      purchase_price: item.purchase_price,
      current_estimated_value: item.current_estimated_value,
      replacement_cost: item.replacement_cost,
      currency: item.currency,
      is_insured: item.is_insured,
      insurance_policy_number: item.insurance_policy_number,
      insurance_coverage_amount: item.insurance_coverage_amount,
      requires_separate_coverage: item.requires_separate_coverage,
      tags: JSON.parse(item.tags || '[]'),
      notes: item.notes,
      status: item.status,
      is_favorite: item.is_favorite,
      priority: item.priority,
      photo_count: photoCountMap[item.id] || 0,
      created_by: {
        id: item.created_by,
        name: `${item.creator_first_name} ${item.creator_last_name}`
      },
      created_at: item.created_at,
      updated_at: item.updated_at
    }));

    const totalPages = Math.ceil(totalRecords / limitNum);

    res.json(createResponse(true, {
      items: formattedItems,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total: totalRecords,
        total_pages: totalPages,
        has_next: pageNum < totalPages,
        has_prev: pageNum > 1
      }
    }));

  } catch (error) {
    console.error('Insurance items retrieval error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * GET /api/v1/insurance/items/:id
 * Get a specific insurance item with photos and documents
 */
router.get('/items/:id', authenticate, async (req, res) => {
  try {
    const itemId = req.params.id;

    // Validate access and get item
    const item = await validateItemAccess(req.user.id, itemId);
    if (!item) {
      return res.status(404).json(createResponse(false, null, {
        message: 'Insurance item not found or access denied'
      }));
    }

    // Get item details with creator info
    const itemDetails = await db('insurance_items')
      .leftJoin('users', 'insurance_items.created_by', 'users.id')
      .leftJoin('properties', 'insurance_items.property_id', 'properties.id')
      .where('insurance_items.id', itemId)
      .select(
        'insurance_items.*',
        'users.first_name as creator_first_name',
        'users.last_name as creator_last_name',
        'properties.name as property_name',
        'properties.address as property_address'
      )
      .first();

    // Get photos
    const photos = await db('insurance_item_photos')
      .where('item_id', itemId)
      .orderBy('is_primary', 'desc')
      .orderBy('display_order')
      .orderBy('created_at')
      .select('*');

    // Get linked documents
    const linkedDocuments = await db('insurance_item_documents')
      .join('documents', 'insurance_item_documents.document_id', 'documents.id')
      .where('insurance_item_documents.item_id', itemId)
      .where('documents.status', 'active')
      .select(
        'insurance_item_documents.relationship_type',
        'insurance_item_documents.notes as link_notes',
        'insurance_item_documents.linked_at',
        'documents.id as document_id',
        'documents.title',
        'documents.document_type',
        'documents.file_url',
        'documents.original_filename',
        'documents.file_size'
      )
      .orderBy('insurance_item_documents.linked_at', 'desc');

    // Get recent valuations
    const recentValuations = await db('insurance_valuations')
      .where('item_id', itemId)
      .orderBy('valuation_date', 'desc')
      .orderBy('is_current', 'desc')
      .limit(5)
      .select('*');

    // Format response
    const formattedItem = {
      id: itemDetails.id,
      property: {
        id: itemDetails.property_id,
        name: itemDetails.property_name,
        address: itemDetails.property_address
      },
      name: itemDetails.name,
      description: itemDetails.description,
      category: itemDetails.category,
      subcategory: itemDetails.subcategory,
      room_location: itemDetails.room_location,
      specific_location: itemDetails.specific_location,
      brand: itemDetails.brand,
      model: itemDetails.model,
      serial_number: itemDetails.serial_number,
      condition: itemDetails.condition,
      purchase_date: itemDetails.purchase_date,
      purchase_location: itemDetails.purchase_location,
      purchase_price: itemDetails.purchase_price,
      current_estimated_value: itemDetails.current_estimated_value,
      replacement_cost: itemDetails.replacement_cost,
      currency: itemDetails.currency,
      last_appraised_date: itemDetails.last_appraised_date,
      appraisal_type: itemDetails.appraisal_type,
      is_insured: itemDetails.is_insured,
      insurance_policy_number: itemDetails.insurance_policy_number,
      insurance_coverage_amount: itemDetails.insurance_coverage_amount,
      requires_separate_coverage: itemDetails.requires_separate_coverage,
      tags: JSON.parse(itemDetails.tags || '[]'),
      custom_fields: JSON.parse(itemDetails.custom_fields || '{}'),
      notes: itemDetails.notes,
      status: itemDetails.status,
      is_favorite: itemDetails.is_favorite,
      priority: itemDetails.priority,
      photos,
      linked_documents: linkedDocuments,
      valuations: recentValuations,
      created_by: {
        id: itemDetails.created_by,
        name: `${itemDetails.creator_first_name} ${itemDetails.creator_last_name}`
      },
      created_at: itemDetails.created_at,
      updated_at: itemDetails.updated_at
    };

    res.json(createResponse(true, formattedItem));

  } catch (error) {
    console.error('Insurance item retrieval error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * PUT /api/v1/insurance/items/:id
 * Update insurance item details
 */
router.put('/items/:id', authenticate, async (req, res) => {
  try {
    const itemId = req.params.id;
    const updateFields = [
      'name', 'description', 'category', 'subcategory', 'room_location', 'specific_location',
      'brand', 'model', 'serial_number', 'condition', 'purchase_date', 'purchase_location',
      'purchase_price', 'current_estimated_value', 'replacement_cost', 'currency',
      'is_insured', 'insurance_policy_number', 'insurance_coverage_amount', 
      'requires_separate_coverage', 'tags', 'notes', 'custom_fields', 'is_favorite', 'priority'
    ];

    // Validate access
    const item = await validateItemAccess(req.user.id, itemId);
    if (!item) {
      return res.status(404).json(createResponse(false, null, {
        message: 'Insurance item not found or access denied'
      }));
    }

    // Prepare update data
    const updateData = { updated_at: new Date() };
    
    updateFields.forEach(field => {
      if (req.body[field] !== undefined) {
        let value = req.body[field];
        
        // Handle special fields
        if (['tags', 'custom_fields'].includes(field)) {
          try {
            value = JSON.stringify(typeof value === 'string' ? JSON.parse(value) : value);
          } catch (e) {
            if (field === 'tags') value = JSON.stringify([value]);
          }
        } else if (['purchase_price', 'current_estimated_value', 'replacement_cost', 'insurance_coverage_amount'].includes(field)) {
          value = value ? parseFloat(value) : null;
        } else if (typeof value === 'string') {
          value = value.trim() || null;
        }
        
        updateData[field] = value;
      }
    });

    // Update item
    await db('insurance_items')
      .where('id', itemId)
      .update(updateData);

    // Get updated item
    const updatedItem = await db('insurance_items')
      .leftJoin('users', 'insurance_items.created_by', 'users.id')
      .leftJoin('properties', 'insurance_items.property_id', 'properties.id')
      .where('insurance_items.id', itemId)
      .select(
        'insurance_items.*',
        'users.first_name as creator_first_name',
        'users.last_name as creator_last_name',
        'properties.name as property_name'
      )
      .first();

    // Format response
    const formattedItem = {
      ...updatedItem,
      property_name: updatedItem.property_name,
      tags: JSON.parse(updatedItem.tags || '[]'),
      custom_fields: JSON.parse(updatedItem.custom_fields || '{}'),
      created_by: {
        id: updatedItem.created_by,
        name: `${updatedItem.creator_first_name} ${updatedItem.creator_last_name}`
      }
    };

    // Remove redundant fields
    delete formattedItem.creator_first_name;
    delete formattedItem.creator_last_name;

    res.json(createResponse(true, formattedItem));

  } catch (error) {
    console.error('Insurance item update error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * DELETE /api/v1/insurance/items/:id
 * Delete insurance item (soft delete)
 */
router.delete('/items/:id', authenticate, async (req, res) => {
  try {
    const itemId = req.params.id;

    // Validate access
    const item = await validateItemAccess(req.user.id, itemId);
    if (!item) {
      return res.status(404).json(createResponse(false, null, {
        message: 'Insurance item not found or access denied'
      }));
    }

    // Soft delete
    await db('insurance_items')
      .where('id', itemId)
      .update({
        status: 'deleted',
        updated_at: new Date()
      });

    res.json(createResponse(true, {
      message: 'Insurance item deleted successfully'
    }));

  } catch (error) {
    console.error('Insurance item deletion error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * POST /api/v1/insurance/items/:id/photos
 * Upload photos for an insurance item to Supabase Storage
 */
router.post('/items/:id/photos', authenticate, uploadInsurancePhotos, async (req, res) => {
  try {
    const itemId = req.params.id;
    const { photo_types, descriptions, titles } = req.body;

    // Validate access
    const item = await validateItemAccess(req.user.id, itemId);
    if (!item) {
      return res.status(404).json(createResponse(false, null, {
        message: 'Insurance item not found or access denied'
      }));
    }

    // Parse photo types, descriptions and titles if provided as JSON arrays
    let parsedPhotoTypes = [];
    let parsedDescriptions = [];
    let parsedTitles = [];
    
    if (photo_types) {
      try {
        parsedPhotoTypes = typeof photo_types === 'string' ? JSON.parse(photo_types) : photo_types;
      } catch (e) {
        parsedPhotoTypes = [photo_types];
      }
    }
    
    if (descriptions) {
      try {
        parsedDescriptions = typeof descriptions === 'string' ? JSON.parse(descriptions) : descriptions;
      } catch (e) {
        parsedDescriptions = [descriptions];
      }
    }
    
    if (titles) {
      try {
        parsedTitles = typeof titles === 'string' ? JSON.parse(titles) : titles;
      } catch (e) {
        parsedTitles = [titles];
      }
    }

    const uploadedPhotos = [];
    
    // Process each uploaded file (already uploaded to Supabase by middleware)
    for (let i = 0; i < req.uploadedPhotos.length; i++) {
      const uploadedPhoto = req.uploadedPhotos[i];
      const photoId = uuidv4();
      
      const photoData = {
        id: photoId,
        item_id: itemId,
        uploaded_by: req.user.id,
        photo_type: parsedPhotoTypes[i] || 'overview',
        title: parsedTitles[i] || uploadedPhoto.originalname,
        description: parsedDescriptions[i] || null,
        filename: uploadedPhoto.filename,
        original_filename: uploadedPhoto.originalname,
        file_path: uploadedPhoto.file_path,
        file_url: uploadedPhoto.file_url,
        file_size: uploadedPhoto.file_size,
        mime_type: uploadedPhoto.mime_type,
        display_order: i,
        is_primary: i === 0, // First photo is primary by default
        created_at: new Date(),
        updated_at: new Date()
      };

      await db('insurance_item_photos').insert(photoData);
      uploadedPhotos.push({
        id: photoId,
        photo_type: photoData.photo_type,
        title: photoData.title,
        description: photoData.description,
        file_url: photoData.file_url,
        filename: photoData.filename,
        original_filename: photoData.original_filename,
        file_size: photoData.file_size,
        mime_type: photoData.mime_type,
        is_primary: photoData.is_primary,
        display_order: photoData.display_order,
        created_at: photoData.created_at
      });
    }

    res.status(201).json(createResponse(true, {
      uploaded_photos: uploadedPhotos,
      total_uploaded: uploadedPhotos.length,
      message: `Successfully uploaded ${uploadedPhotos.length} photos to cloud storage`
    }));

  } catch (error) {
    console.error('Insurance photo upload error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * GET /api/v1/insurance/items/:id/photos
 * Get all photos for an insurance item
 */
router.get('/items/:id/photos', authenticate, async (req, res) => {
  try {
    const itemId = req.params.id;

    // Validate access
    const item = await validateItemAccess(req.user.id, itemId);
    if (!item) {
      return res.status(404).json(createResponse(false, null, {
        message: 'Insurance item not found or access denied'
      }));
    }

    const photos = await db('insurance_item_photos')
      .where('item_id', itemId)
      .orderBy('is_primary', 'desc')
      .orderBy('display_order')
      .orderBy('created_at')
      .select('*');

    res.json(createResponse(true, { photos }));

  } catch (error) {
    console.error('Insurance item photos retrieval error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * PUT /api/v1/insurance/photos/:photoId
 * Update photo metadata
 */
router.put('/photos/:photoId', authenticate, async (req, res) => {
  try {
    const photoId = req.params.photoId;
    const { title, description, photo_type, is_primary, display_order } = req.body;

    // Get photo and validate access through item
    const photo = await db('insurance_item_photos')
      .where('insurance_item_photos.id', photoId)
      .first();

    if (!photo) {
      return res.status(404).json(createResponse(false, null, {
        message: 'Photo not found'
      }));
    }

    // Validate item access
    const item = await validateItemAccess(req.user.id, photo.item_id);
    if (!item) {
      return res.status(403).json(createResponse(false, null, {
        message: 'Access denied'
      }));
    }

    // If setting as primary, unset other primary photos for this item
    if (is_primary === true) {
      await db('insurance_item_photos')
        .where('item_id', photo.item_id)
        .update({ is_primary: false });
    }

    const updateData = { updated_at: new Date() };
    if (title !== undefined) updateData.title = title;
    if (description !== undefined) updateData.description = description;
    if (photo_type !== undefined) updateData.photo_type = photo_type;
    if (is_primary !== undefined) updateData.is_primary = is_primary;
    if (display_order !== undefined) updateData.display_order = display_order;

    await db('insurance_item_photos')
      .where('id', photoId)
      .update(updateData);

    const updatedPhoto = await db('insurance_item_photos')
      .where('id', photoId)
      .first();

    res.json(createResponse(true, updatedPhoto));

  } catch (error) {
    console.error('Insurance photo update error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * DELETE /api/v1/insurance/photos/:photoId
 * Delete a photo
 */
router.delete('/photos/:photoId', authenticate, async (req, res) => {
  try {
    const photoId = req.params.photoId;

    // Get photo and validate access
    const photo = await db('insurance_item_photos')
      .where('insurance_item_photos.id', photoId)
      .first();

    if (!photo) {
      return res.status(404).json(createResponse(false, null, {
        message: 'Photo not found'
      }));
    }

    // Validate item access
    const item = await validateItemAccess(req.user.id, photo.item_id);
    if (!item) {
      return res.status(403).json(createResponse(false, null, {
        message: 'Access denied'
      }));
    }

    // Delete file from filesystem
    if (fs.existsSync(photo.file_path)) {
      fs.unlinkSync(photo.file_path);
    }

    // Delete record from database
    await db('insurance_item_photos').where('id', photoId).delete();

    res.json(createResponse(true, {
      message: 'Photo deleted successfully'
    }));

  } catch (error) {
    console.error('Insurance photo deletion error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * GET /api/v1/insurance/summary
 * Get insurance inventory summary statistics
 */
router.get('/summary', authenticate, async (req, res) => {
  try {
    const { property_id } = req.query;

    // Build base query with access control
    let query = db('insurance_items')
      .join('properties', 'insurance_items.property_id', 'properties.id')
      .where('insurance_items.status', 'active')
      .where(function() {
        this.where('properties.owner_id', req.user.id)
          .orWhereExists(function() {
            this.select('*')
              .from('property_permissions')
              .whereRaw('property_permissions.property_id = properties.id')
              .where('property_permissions.user_id', req.user.id);
          });
      });

    if (property_id) {
      query.where('insurance_items.property_id', property_id);
    }

    // Get summary statistics
    const [
      totalStats,
      categoryBreakdown,
      roomBreakdown,
      conditionBreakdown,
      highValueItems,
      uninsuredItems,
      recentItems
    ] = await Promise.all([
      // Total statistics
      query.clone()
        .select(
          db.raw('COUNT(*) as total_items'),
          db.raw('SUM(replacement_cost) as total_value'),
          db.raw('AVG(replacement_cost) as avg_value'),
          db.raw('SUM(CASE WHEN is_insured = 1 THEN 1 ELSE 0 END) as insured_count'),
          db.raw('SUM(CASE WHEN requires_separate_coverage = 1 THEN 1 ELSE 0 END) as special_coverage_count')
        )
        .first(),

      // By category
      query.clone()
        .select('category')
        .count('* as count')
        .sum('replacement_cost as total_value')
        .groupBy('category')
        .orderBy('count', 'desc'),

      // By room
      query.clone()
        .select('room_location')
        .count('* as count')
        .sum('replacement_cost as total_value')
        .whereNotNull('room_location')
        .groupBy('room_location')
        .orderBy('count', 'desc'),

      // By condition
      query.clone()
        .select('condition')
        .count('* as count')
        .groupBy('condition')
        .orderBy('count', 'desc'),

      // High value items (>$5000)
      query.clone()
        .where('replacement_cost', '>', 5000)
        .count('* as count')
        .sum('replacement_cost as total_value')
        .first(),

      // Uninsured items
      query.clone()
        .where('is_insured', false)
        .count('* as count')
        .sum('replacement_cost as total_value')
        .first(),

      // Recent items (last 30 days)
      query.clone()
        .where('insurance_items.created_at', '>=', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000))
        .count('* as count')
        .first()
    ]);

    res.json(createResponse(true, {
      overview: {
        total_items: parseInt(totalStats.total_items || 0),
        total_value: parseFloat(totalStats.total_value || 0),
        average_value: parseFloat(totalStats.avg_value || 0),
        insured_items: parseInt(totalStats.insured_count || 0),
        special_coverage_items: parseInt(totalStats.special_coverage_count || 0),
        insurance_coverage_rate: totalStats.total_items > 0 ? 
          Math.round((totalStats.insured_count / totalStats.total_items) * 100) : 0
      },
      breakdown: {
        by_category: categoryBreakdown.map(c => ({
          category: c.category,
          count: parseInt(c.count),
          total_value: parseFloat(c.total_value || 0)
        })),
        by_room: roomBreakdown.map(r => ({
          room: r.room_location,
          count: parseInt(r.count),
          total_value: parseFloat(r.total_value || 0)
        })),
        by_condition: conditionBreakdown.map(c => ({
          condition: c.condition,
          count: parseInt(c.count)
        }))
      },
      alerts: {
        high_value_items: {
          count: parseInt(highValueItems.count || 0),
          total_value: parseFloat(highValueItems.total_value || 0)
        },
        uninsured_items: {
          count: parseInt(uninsuredItems.count || 0),
          total_value: parseFloat(uninsuredItems.total_value || 0)
        },
        recent_additions: parseInt(recentItems.count || 0)
      }
    }));

  } catch (error) {
    console.error('Insurance summary error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * POST /api/v1/insurance/items/:id/documents
 * Link existing documents to an insurance item
 */
router.post('/items/:id/documents', authenticate, async (req, res) => {
  try {
    const itemId = req.params.id;
    const { document_ids, relationship_type = 'receipt', notes } = req.body;

    if (!document_ids || (!Array.isArray(document_ids) && typeof document_ids !== 'string')) {
      return res.status(400).json(createResponse(false, null, {
        message: 'document_ids is required (array or single ID)'
      }));
    }

    // Validate item access
    const item = await validateItemAccess(req.user.id, itemId);
    if (!item) {
      return res.status(404).json(createResponse(false, null, {
        message: 'Insurance item not found or access denied'
      }));
    }

    const documentIds = Array.isArray(document_ids) ? document_ids : [document_ids];
    const linkedDocuments = [];
    
    for (const documentId of documentIds) {
      // Verify document exists and user has access
      const document = await db('documents')
        .join('properties', function() {
          this.on(function() {
            this.on('documents.property_id', '=', 'properties.id')
              .orOn('documents.project_id', '=', db.raw('(SELECT projects.id FROM projects WHERE projects.property_id = properties.id)'));
          });
        })
        .where('documents.id', documentId)
        .where('documents.status', 'active')
        .where(function() {
          this.where('properties.owner_id', req.user.id)
            .orWhereExists(function() {
              this.select('*')
                .from('property_permissions')
                .whereRaw('property_permissions.property_id = properties.id')
                .where('property_permissions.user_id', req.user.id);
            });
        })
        .select('documents.*')
        .first();

      if (!document) {
        return res.status(403).json(createResponse(false, null, {
          message: `Access denied or document not found: ${documentId}`
        }));
      }

      // Check if link already exists
      const existingLink = await db('insurance_item_documents')
        .where({ item_id: itemId, document_id: documentId })
        .first();

      if (!existingLink) {
        const linkData = {
          id: uuidv4(),
          item_id: itemId,
          document_id: documentId,
          linked_by: req.user.id,
          relationship_type,
          notes: notes || null
        };

        await db('insurance_item_documents').insert(linkData);
        
        linkedDocuments.push({
          ...linkData,
          document_title: document.title,
          document_type: document.document_type,
          file_url: document.file_url
        });
      }
    }

    res.status(201).json(createResponse(true, {
      linked_documents: linkedDocuments,
      total_linked: linkedDocuments.length
    }));

  } catch (error) {
    console.error('Document linking error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * DELETE /api/v1/insurance/items/:id/documents/:documentId
 * Unlink a document from an insurance item
 */
router.delete('/items/:id/documents/:documentId', authenticate, async (req, res) => {
  try {
    const { id: itemId, documentId } = req.params;

    // Validate item access
    const item = await validateItemAccess(req.user.id, itemId);
    if (!item) {
      return res.status(404).json(createResponse(false, null, {
        message: 'Insurance item not found or access denied'
      }));
    }

    // Remove the link
    const deletedRows = await db('insurance_item_documents')
      .where({ item_id: itemId, document_id: documentId })
      .delete();

    if (deletedRows === 0) {
      return res.status(404).json(createResponse(false, null, {
        message: 'Document link not found'
      }));
    }

    res.json(createResponse(true, {
      message: 'Document unlinked successfully'
    }));

  } catch (error) {
    console.error('Document unlinking error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * GET /api/v1/insurance/items/:id/documents
 * Get all documents linked to an insurance item
 */
router.get('/items/:id/documents', authenticate, async (req, res) => {
  try {
    const itemId = req.params.id;

    // Validate item access
    const item = await validateItemAccess(req.user.id, itemId);
    if (!item) {
      return res.status(404).json(createResponse(false, null, {
        message: 'Insurance item not found or access denied'
      }));
    }

    const linkedDocuments = await db('insurance_item_documents')
      .join('documents', 'insurance_item_documents.document_id', 'documents.id')
      .leftJoin('users', 'insurance_item_documents.linked_by', 'users.id')
      .where('insurance_item_documents.item_id', itemId)
      .where('documents.status', 'active')
      .select(
        'insurance_item_documents.*',
        'documents.title as document_title',
        'documents.document_type',
        'documents.file_url',
        'documents.original_filename',
        'documents.file_size',
        'documents.created_at as document_created_at',
        'users.first_name as linked_by_first_name',
        'users.last_name as linked_by_last_name'
      )
      .orderBy('insurance_item_documents.linked_at', 'desc');

    const formattedDocuments = linkedDocuments.map(doc => ({
      link_id: doc.id,
      document_id: doc.document_id,
      relationship_type: doc.relationship_type,
      notes: doc.notes,
      linked_at: doc.linked_at,
      linked_by: {
        id: doc.linked_by,
        name: `${doc.linked_by_first_name} ${doc.linked_by_last_name}`
      },
      document: {
        title: doc.document_title,
        document_type: doc.document_type,
        file_url: doc.file_url,
        original_filename: doc.original_filename,
        file_size: doc.file_size,
        created_at: doc.document_created_at
      }
    }));

    res.json(createResponse(true, {
      linked_documents: formattedDocuments,
      total_count: formattedDocuments.length
    }));

  } catch (error) {
    console.error('Linked documents retrieval error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * GET /api/v1/insurance/export/claim-report/:propertyId
 * Generate and export insurance claim report for a property
 */
router.get('/export/claim-report/:propertyId', authenticate, async (req, res) => {
  try {
    const propertyId = req.params.propertyId;
    const { 
      format = 'json', 
      include_photos = 'true',
      room_filter,
      category_filter,
      min_value,
      high_value_only 
    } = req.query;

    // Validate property access
    const hasAccess = await validatePropertyAccess(req.user.id, propertyId);
    if (!hasAccess) {
      return res.status(403).json(createResponse(false, null, {
        message: 'Access denied to this property'
      }));
    }

    // Get property info
    const property = await db('properties')
      .where('id', propertyId)
      .select('name', 'address')
      .first();

    // Build query for items
    let itemsQuery = db('insurance_items')
      .where('property_id', propertyId)
      .where('status', 'active');

    // Apply filters
    if (room_filter) {
      itemsQuery.where('room_location', room_filter);
    }
    if (category_filter) {
      itemsQuery.where('category', category_filter);
    }
    if (min_value) {
      itemsQuery.where('replacement_cost', '>=', parseFloat(min_value));
    }
    if (high_value_only === 'true') {
      itemsQuery.where('replacement_cost', '>', 5000);
    }

    const items = await itemsQuery
      .orderBy('replacement_cost', 'desc')
      .orderBy('room_location')
      .orderBy('name');

    // Get photos for each item if requested
    let itemsWithPhotos = items;
    if (include_photos === 'true') {
      const itemIds = items.map(item => item.id);
      let photos = [];
      
      if (itemIds.length > 0) {
        photos = await db('insurance_item_photos')
          .whereIn('item_id', itemIds)
          .where('is_primary', true)
          .select('item_id', 'file_url', 'title');
      }

      const photoMap = {};
      photos.forEach(photo => {
        photoMap[photo.item_id] = photo;
      });

      itemsWithPhotos = items.map(item => ({
        ...item,
        tags: JSON.parse(item.tags || '[]'),
        primary_photo: photoMap[item.id] || null
      }));
    }

    // Calculate summary statistics
    const totalValue = items.reduce((sum, item) => sum + (item.replacement_cost || 0), 0);
    const totalItems = items.length;
    const insuredItems = items.filter(item => item.is_insured).length;
    const highValueItems = items.filter(item => (item.replacement_cost || 0) > 5000).length;

    // Group by room and category
    const byRoom = {};
    const byCategory = {};

    items.forEach(item => {
      const room = item.room_location || 'Unassigned';
      const category = item.category;

      if (!byRoom[room]) byRoom[room] = { count: 0, total_value: 0, items: [] };
      if (!byCategory[category]) byCategory[category] = { count: 0, total_value: 0 };

      byRoom[room].count++;
      byRoom[room].total_value += (item.replacement_cost || 0);
      byRoom[room].items.push(item.name);

      byCategory[category].count++;
      byCategory[category].total_value += (item.replacement_cost || 0);
    });

    const reportData = {
      property: {
        id: propertyId,
        name: property.name,
        address: property.address
      },
      generated: {
        date: new Date().toISOString(),
        by_user_id: req.user.id,
        filters_applied: {
          room_filter,
          category_filter,
          min_value,
          high_value_only
        }
      },
      summary: {
        total_items: totalItems,
        total_estimated_value: totalValue,
        average_item_value: totalItems > 0 ? totalValue / totalItems : 0,
        insured_items: insuredItems,
        insurance_coverage_rate: totalItems > 0 ? Math.round((insuredItems / totalItems) * 100) : 0,
        high_value_items: highValueItems
      },
      breakdown: {
        by_room: Object.keys(byRoom).map(room => ({
          room,
          count: byRoom[room].count,
          total_value: byRoom[room].total_value,
          sample_items: byRoom[room].items.slice(0, 5) // First 5 items as examples
        })),
        by_category: Object.keys(byCategory).map(category => ({
          category,
          count: byCategory[category].count,
          total_value: byCategory[category].total_value
        }))
      },
      items: itemsWithPhotos
    };

    // For now, return JSON format (PDF generation can be added later)
    if (format === 'json') {
      res.json(createResponse(true, reportData));
    } else {
      // Future: Generate PDF using puppeteer or similar
      res.json(createResponse(false, null, {
        message: 'PDF export coming soon - currently only JSON format is supported'
      }));
    }

  } catch (error) {
    console.error('Insurance claim report error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

module.exports = router;