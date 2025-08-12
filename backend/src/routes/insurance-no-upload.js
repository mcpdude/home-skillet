const express = require('express');
const { authenticate } = require('../middleware/auth');
const db = require('../config/database');
const { v4: uuidv4 } = require('uuid');
const { 
  createResponse, 
  createErrorResponse
} = require('../utils/helpers');

const router = express.Router();

// Helper function to validate property access
async function validatePropertyAccess(userId, propertyId) {
  if (!propertyId) return true; // Property is optional

  const property = await db('properties')
    .where('id', propertyId)
    .where('user_id', userId)
    .first();

  return !!property;
}

// Create insurance item
router.post('/items', authenticate, async (req, res) => {
  try {
    const {
      property_id,
      name,
      category,
      room_location,
      brand,
      model,
      serial_number,
      purchase_date,
      purchase_price,
      replacement_cost,
      condition = 'good',
      is_insured = false,
      notes,
      tags
    } = req.body;

    // Validate required fields
    if (!name || !category) {
      return res.status(400).json(createErrorResponse('Name and category are required'));
    }

    // Validate property access if property_id provided
    if (property_id && !(await validatePropertyAccess(req.user.id, property_id))) {
      return res.status(403).json(createErrorResponse('Access denied to this property'));
    }

    const itemData = {
      id: uuidv4(),
      property_id: property_id || null,
      user_id: req.user.id,
      name,
      category,
      room_location: room_location || null,
      brand: brand || null,
      model: model || null,
      serial_number: serial_number || null,
      purchase_date: purchase_date || null,
      purchase_price: purchase_price || null,
      replacement_cost: replacement_cost || null,
      condition,
      is_insured,
      notes: notes || null,
      tags: tags ? JSON.stringify(tags) : null,
      created_at: new Date(),
      updated_at: new Date()
    };

    await db('insurance_items').insert(itemData);

    return res.status(201).json(createResponse(itemData, 'Insurance item created successfully'));
  } catch (error) {
    console.error('Error creating insurance item:', error);
    return res.status(500).json(createErrorResponse('Failed to create insurance item'));
  }
});

// Get insurance items
router.get('/items', authenticate, async (req, res) => {
  try {
    const {
      property_id,
      category,
      room_location,
      condition,
      is_insured,
      search,
      limit = 50,
      offset = 0
    } = req.query;

    let query = db('insurance_items')
      .where('user_id', req.user.id)
      .orderBy('created_at', 'desc')
      .limit(parseInt(limit))
      .offset(parseInt(offset));

    // Apply filters
    if (property_id) {
      query = query.where('property_id', property_id);
    }

    if (category) {
      query = query.where('category', category);
    }

    if (room_location) {
      query = query.where('room_location', room_location);
    }

    if (condition) {
      query = query.where('condition', condition);
    }

    if (is_insured !== undefined) {
      query = query.where('is_insured', is_insured === 'true');
    }

    if (search) {
      query = query.where(function() {
        this.where('name', 'ilike', `%${search}%`)
          .orWhere('brand', 'ilike', `%${search}%`)
          .orWhere('model', 'ilike', `%${search}%`)
          .orWhere('serial_number', 'ilike', `%${search}%`);
      });
    }

    const items = await query;

    // Get total count for pagination
    let countQuery = db('insurance_items')
      .where('user_id', req.user.id)
      .count('id as total');

    // Apply same filters to count
    if (property_id) countQuery = countQuery.where('property_id', property_id);
    if (category) countQuery = countQuery.where('category', category);
    if (room_location) countQuery = countQuery.where('room_location', room_location);
    if (condition) countQuery = countQuery.where('condition', condition);
    if (is_insured !== undefined) countQuery = countQuery.where('is_insured', is_insured === 'true');
    if (search) {
      countQuery = countQuery.where(function() {
        this.where('name', 'ilike', `%${search}%`)
          .orWhere('brand', 'ilike', `%${search}%`)
          .orWhere('model', 'ilike', `%${search}%`)
          .orWhere('serial_number', 'ilike', `%${search}%`);
      });
    }

    const totalResult = await countQuery.first();
    const total = parseInt(totalResult.total);

    return res.json(createResponse({
      items,
      pagination: {
        total,
        limit: parseInt(limit),
        offset: parseInt(offset),
        pages: Math.ceil(total / parseInt(limit))
      }
    }, 'Insurance items retrieved successfully'));
  } catch (error) {
    console.error('Error fetching insurance items:', error);
    return res.status(500).json(createErrorResponse('Failed to fetch insurance items'));
  }
});

// Get single insurance item
router.get('/items/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;

    const item = await db('insurance_items')
      .where({ id, user_id: req.user.id })
      .first();

    if (!item) {
      return res.status(404).json(createErrorResponse('Insurance item not found'));
    }

    // Get associated photos
    const photos = await db('insurance_item_photos')
      .where('item_id', id)
      .orderBy('created_at', 'desc');

    // Get associated documents
    const documents = await db('insurance_item_documents as iid')
      .join('documents as d', 'iid.document_id', 'd.id')
      .where('iid.item_id', id)
      .select('d.*', 'iid.document_type', 'iid.created_at as linked_at')
      .orderBy('iid.created_at', 'desc');

    const itemWithDetails = {
      ...item,
      photos,
      documents
    };

    return res.json(createResponse(itemWithDetails, 'Insurance item retrieved successfully'));
  } catch (error) {
    console.error('Error fetching insurance item:', error);
    return res.status(500).json(createErrorResponse('Failed to fetch insurance item'));
  }
});

// Update insurance item
router.put('/items/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const {
      property_id,
      name,
      category,
      room_location,
      brand,
      model,
      serial_number,
      purchase_date,
      purchase_price,
      replacement_cost,
      condition,
      is_insured,
      notes,
      tags
    } = req.body;

    // Check if item exists and belongs to user
    const existingItem = await db('insurance_items')
      .where({ id, user_id: req.user.id })
      .first();

    if (!existingItem) {
      return res.status(404).json(createErrorResponse('Insurance item not found'));
    }

    // Validate property access if property_id provided
    if (property_id && !(await validatePropertyAccess(req.user.id, property_id))) {
      return res.status(403).json(createErrorResponse('Access denied to this property'));
    }

    const updateData = {
      updated_at: new Date()
    };

    // Only update provided fields
    if (property_id !== undefined) updateData.property_id = property_id;
    if (name !== undefined) updateData.name = name;
    if (category !== undefined) updateData.category = category;
    if (room_location !== undefined) updateData.room_location = room_location;
    if (brand !== undefined) updateData.brand = brand;
    if (model !== undefined) updateData.model = model;
    if (serial_number !== undefined) updateData.serial_number = serial_number;
    if (purchase_date !== undefined) updateData.purchase_date = purchase_date;
    if (purchase_price !== undefined) updateData.purchase_price = purchase_price;
    if (replacement_cost !== undefined) updateData.replacement_cost = replacement_cost;
    if (condition !== undefined) updateData.condition = condition;
    if (is_insured !== undefined) updateData.is_insured = is_insured;
    if (notes !== undefined) updateData.notes = notes;
    if (tags !== undefined) updateData.tags = tags ? JSON.stringify(tags) : null;

    await db('insurance_items').where({ id, user_id: req.user.id }).update(updateData);

    const updatedItem = await db('insurance_items')
      .where({ id, user_id: req.user.id })
      .first();

    return res.json(createResponse(updatedItem, 'Insurance item updated successfully'));
  } catch (error) {
    console.error('Error updating insurance item:', error);
    return res.status(500).json(createErrorResponse('Failed to update insurance item'));
  }
});

// Delete insurance item
router.delete('/items/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;

    // Check if item exists and belongs to user
    const item = await db('insurance_items')
      .where({ id, user_id: req.user.id })
      .first();

    if (!item) {
      return res.status(404).json(createErrorResponse('Insurance item not found'));
    }

    // Delete associated records (cascade will handle this, but being explicit)
    await db('insurance_item_photos').where('item_id', id).del();
    await db('insurance_item_documents').where('item_id', id).del();
    await db('insurance_items').where({ id, user_id: req.user.id }).del();

    return res.json(createResponse(null, 'Insurance item deleted successfully'));
  } catch (error) {
    console.error('Error deleting insurance item:', error);
    return res.status(500).json(createErrorResponse('Failed to delete insurance item'));
  }
});

// Add photo metadata (after direct upload to Supabase)
router.post('/items/:id/photos', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { filename, file_url, photo_type = 'overview', file_size, file_hash } = req.body;

    if (!filename || !file_url) {
      return res.status(400).json(createErrorResponse('Filename and file_url are required'));
    }

    // Verify item exists and belongs to user
    const item = await db('insurance_items')
      .where({ id, user_id: req.user.id })
      .first();

    if (!item) {
      return res.status(404).json(createErrorResponse('Insurance item not found'));
    }

    const photoData = {
      id: uuidv4(),
      item_id: id,
      filename,
      file_url,
      photo_type,
      file_size: file_size || null,
      file_hash: file_hash || null,
      created_at: new Date()
    };

    await db('insurance_item_photos').insert(photoData);

    return res.status(201).json(createResponse(photoData, 'Photo added successfully'));
  } catch (error) {
    console.error('Error adding photo:', error);
    return res.status(500).json(createErrorResponse('Failed to add photo'));
  }
});

// Get item photos
router.get('/items/:id/photos', authenticate, async (req, res) => {
  try {
    const { id } = req.params;

    // Verify item exists and belongs to user
    const item = await db('insurance_items')
      .where({ id, user_id: req.user.id })
      .first();

    if (!item) {
      return res.status(404).json(createErrorResponse('Insurance item not found'));
    }

    const photos = await db('insurance_item_photos')
      .where('item_id', id)
      .orderBy('created_at', 'desc');

    return res.json(createResponse(photos, 'Photos retrieved successfully'));
  } catch (error) {
    console.error('Error fetching photos:', error);
    return res.status(500).json(createErrorResponse('Failed to fetch photos'));
  }
});

// Link document to insurance item
router.post('/items/:id/documents', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { document_id, document_type = 'receipt' } = req.body;

    if (!document_id) {
      return res.status(400).json(createErrorResponse('Document ID is required'));
    }

    // Verify item exists and belongs to user
    const item = await db('insurance_items')
      .where({ id, user_id: req.user.id })
      .first();

    if (!item) {
      return res.status(404).json(createErrorResponse('Insurance item not found'));
    }

    // Verify document exists and belongs to user
    const document = await db('documents')
      .where({ id: document_id, user_id: req.user.id })
      .first();

    if (!document) {
      return res.status(404).json(createErrorResponse('Document not found'));
    }

    const linkData = {
      id: uuidv4(),
      item_id: id,
      document_id,
      document_type,
      created_at: new Date()
    };

    await db('insurance_item_documents').insert(linkData);

    return res.status(201).json(createResponse(linkData, 'Document linked successfully'));
  } catch (error) {
    console.error('Error linking document:', error);
    return res.status(500).json(createErrorResponse('Failed to link document'));
  }
});

// Get insurance categories
router.get('/categories', authenticate, async (req, res) => {
  try {
    const categories = await db('insurance_items')
      .where('user_id', req.user.id)
      .distinct('category')
      .whereNotNull('category')
      .orderBy('category');

    const categoryList = categories.map(row => row.category);

    return res.json(createResponse(categoryList, 'Categories retrieved successfully'));
  } catch (error) {
    console.error('Error fetching categories:', error);
    return res.status(500).json(createErrorResponse('Failed to fetch categories'));
  }
});

module.exports = router;