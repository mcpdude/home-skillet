const express = require('express');
const { authenticate } = require('../middleware/auth');
const db = require('../config/database');
const { v4: uuidv4 } = require('uuid');
const { 
  createResponse, 
  createErrorResponse
} = require('../utils/helpers');

const router = express.Router();

// List all documents for a user
router.get('/', authenticate, async (req, res) => {
  try {
    const { property_id, project_id, category, limit = 50, offset = 0 } = req.query;
    
    let query = db('documents')
      .where('user_id', req.user.id)
      .orderBy('created_at', 'desc')
      .limit(parseInt(limit))
      .offset(parseInt(offset));

    if (property_id) {
      query = query.where('property_id', property_id);
    }

    if (project_id) {
      query = query.where('project_id', project_id);
    }

    if (category) {
      query = query.where('category', category);
    }

    const documents = await query;

    return res.json(createResponse(documents, 'Documents retrieved successfully'));
  } catch (error) {
    console.error('Error fetching documents:', error);
    return res.status(500).json(createErrorResponse('Failed to fetch documents'));
  }
});

// Get a specific document
router.get('/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;

    const document = await db('documents')
      .where({ id, user_id: req.user.id })
      .first();

    if (!document) {
      return res.status(404).json(createErrorResponse('Document not found'));
    }

    return res.json(createResponse(document, 'Document retrieved successfully'));
  } catch (error) {
    console.error('Error fetching document:', error);
    return res.status(500).json(createErrorResponse('Failed to fetch document'));
  }
});

// Create document metadata (without file upload)
router.post('/', authenticate, async (req, res) => {
  try {
    const {
      property_id,
      project_id,
      filename,
      original_filename,
      file_url,
      file_size,
      mime_type,
      category = 'general',
      description,
      tags
    } = req.body;

    // Validate required fields
    if (!filename || !file_url) {
      return res.status(400).json(createErrorResponse('Filename and file_url are required'));
    }

    const documentData = {
      id: uuidv4(),
      user_id: req.user.id,
      property_id: property_id || null,
      project_id: project_id || null,
      filename,
      original_filename: original_filename || filename,
      file_url,
      file_size: file_size || null,
      mime_type: mime_type || null,
      category,
      description: description || null,
      tags: tags ? JSON.stringify(tags) : null,
      created_at: new Date(),
      updated_at: new Date()
    };

    await db('documents').insert(documentData);

    return res.status(201).json(createResponse(
      documentData,
      'Document metadata created successfully'
    ));
  } catch (error) {
    console.error('Error creating document:', error);
    return res.status(500).json(createErrorResponse('Failed to create document'));
  }
});

// Update document metadata
router.put('/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const {
      property_id,
      project_id,
      category,
      description,
      tags
    } = req.body;

    // Check if document exists and belongs to user
    const existingDocument = await db('documents')
      .where({ id, user_id: req.user.id })
      .first();

    if (!existingDocument) {
      return res.status(404).json(createErrorResponse('Document not found'));
    }

    const updateData = {
      updated_at: new Date()
    };

    if (property_id !== undefined) updateData.property_id = property_id;
    if (project_id !== undefined) updateData.project_id = project_id;
    if (category !== undefined) updateData.category = category;
    if (description !== undefined) updateData.description = description;
    if (tags !== undefined) updateData.tags = tags ? JSON.stringify(tags) : null;

    await db('documents').where({ id, user_id: req.user.id }).update(updateData);

    const updatedDocument = await db('documents')
      .where({ id, user_id: req.user.id })
      .first();

    return res.json(createResponse(updatedDocument, 'Document updated successfully'));
  } catch (error) {
    console.error('Error updating document:', error);
    return res.status(500).json(createErrorResponse('Failed to update document'));
  }
});

// Delete document
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;

    // Check if document exists and belongs to user
    const document = await db('documents')
      .where({ id, user_id: req.user.id })
      .first();

    if (!document) {
      return res.status(404).json(createErrorResponse('Document not found'));
    }

    await db('documents').where({ id, user_id: req.user.id }).del();

    return res.json(createResponse(null, 'Document deleted successfully'));
  } catch (error) {
    console.error('Error deleting document:', error);
    return res.status(500).json(createErrorResponse('Failed to delete document'));
  }
});

// Get document categories
router.get('/meta/categories', authenticate, async (req, res) => {
  try {
    const categories = await db('documents')
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