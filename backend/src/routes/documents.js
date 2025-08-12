const express = require('express');
const crypto = require('crypto');
const { authenticate } = require('../middleware/auth');
const db = require('../config/database');
const { v4: uuidv4 } = require('uuid');
const { 
  createResponse, 
  createErrorResponse
} = require('../utils/helpers');
const { uploadDocument } = require('../middleware/supabaseUpload');

const router = express.Router();

// Helper function to calculate file hash from buffer
function calculateFileHash(fileBuffer) {
  const hashSum = crypto.createHash('sha256');
  hashSum.update(fileBuffer);
  return hashSum.digest('hex');
}

// Helper function to validate user access to property/project
async function validateAccess(userId, propertyId, projectId) {
  if (propertyId) {
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

  if (projectId) {
    const project = await db('projects')
      .join('properties', 'projects.property_id', 'properties.id')
      .where('projects.id', projectId)
      .where(function() {
        this.where('properties.owner_id', userId)
          .orWhereExists(function() {
            this.select('*')
              .from('property_permissions')
              .whereRaw('property_permissions.property_id = properties.id')
              .where('property_permissions.user_id', userId);
          })
          .orWhereExists(function() {
            this.select('*')
              .from('project_assignments')
              .where('project_assignments.project_id', projectId)
              .where('project_assignments.user_id', userId);
          });
      })
      .first();
    return !!project;
  }

  return false;
}

// Helper function to log document access
async function logDocumentAccess(documentId, userId, action, req) {
  try {
    await db('document_access_log').insert({
      id: uuidv4(),
      document_id: documentId,
      user_id: userId,
      action,
      ip_address: req.ip || req.connection.remoteAddress,
      user_agent: req.get('User-Agent'),
      additional_info: JSON.stringify({ 
        referer: req.get('Referer'),
        timestamp: new Date().toISOString()
      })
    });
  } catch (error) {
    console.error('Failed to log document access:', error);
    // Don't fail the main operation if logging fails
  }
}

/**
 * POST /api/v1/documents/upload
 * Upload a new document
 */
router.post('/upload', authenticate, uploadDocument, async (req, res) => {
  try {
    const { 
      title,
      description,
      document_type,
      category,
      vendor_name,
      amount,
      currency,
      document_date,
      expiry_date,
      property_id,
      project_id,
      tags,
      metadata
    } = req.body;
    
    if (!title || !document_type) {
      return res.status(400).json(createResponse(false, null, {
        message: 'Title and document type are required'
      }));
    }

    if (!property_id && !project_id) {
      return res.status(400).json(createResponse(false, null, {
        message: 'Document must be associated with either a property or project'
      }));
    }

    // Validate user access
    const hasAccess = await validateAccess(req.user.id, property_id, project_id);
    if (!hasAccess) {
      return res.status(403).json(createResponse(false, null, {
        message: 'Access denied to the specified property or project'
      }));
    }

    // Check for existing document with same hash (already calculated by middleware)
    const fileHash = req.uploadedDocument.file_hash;
    const existingDoc = await db('documents')
      .where('file_hash', fileHash)
      .where(function() {
        if (property_id) this.where('property_id', property_id);
        if (project_id) this.where('project_id', project_id);
      })
      .first();

    if (existingDoc) {
      return res.status(409).json(createResponse(false, null, {
        message: 'A document with identical content already exists',
        existing_document: existingDoc
      }));
    }

    // Parse tags if provided
    let parsedTags = [];
    if (tags) {
      try {
        parsedTags = typeof tags === 'string' ? JSON.parse(tags) : tags;
      } catch (e) {
        parsedTags = [tags]; // Single tag as string
      }
    }

    // Parse metadata if provided
    let parsedMetadata = {};
    if (metadata) {
      try {
        parsedMetadata = typeof metadata === 'string' ? JSON.parse(metadata) : metadata;
      } catch (e) {
        console.warn('Invalid metadata JSON, ignoring:', e.message);
      }
    }

    // Save document record to database (using Supabase uploaded file data)
    const documentId = uuidv4();
    const documentData = {
      id: documentId,
      property_id: property_id || null,
      project_id: project_id || null,
      uploaded_by: req.user.id,
      title: title.trim(),
      description: description?.trim() || null,
      document_type,
      category: category || null,
      vendor_name: vendor_name?.trim() || null,
      amount: amount ? parseFloat(amount) : null,
      currency: currency || 'USD',
      document_date: document_date || null,
      expiry_date: expiry_date || null,
      metadata: JSON.stringify(parsedMetadata),
      filename: req.uploadedDocument.filename,
      original_filename: req.uploadedDocument.originalname,
      file_path: req.uploadedDocument.file_path,
      file_url: req.uploadedDocument.file_url,
      file_size: req.uploadedDocument.file_size,
      mime_type: req.uploadedDocument.mime_type,
      file_hash: fileHash,
      tags: JSON.stringify(parsedTags),
      status: 'active',
      is_favorite: false,
      view_count: 0,
      created_at: new Date(),
      updated_at: new Date()
    };

    await db('documents').insert(documentData);

    // Log the upload action
    await logDocumentAccess(documentId, req.user.id, 'upload', req);

    // Return the created document info
    const createdDocument = await db('documents')
      .leftJoin('users', 'documents.uploaded_by', 'users.id')
      .where('documents.id', documentId)
      .select(
        'documents.*',
        'users.first_name as uploader_first_name',
        'users.last_name as uploader_last_name'
      )
      .first();

    res.status(201).json(createResponse(true, {
      id: createdDocument.id,
      title: createdDocument.title,
      description: createdDocument.description,
      document_type: createdDocument.document_type,
      category: createdDocument.category,
      vendor_name: createdDocument.vendor_name,
      amount: createdDocument.amount,
      currency: createdDocument.currency,
      document_date: createdDocument.document_date,
      expiry_date: createdDocument.expiry_date,
      property_id: createdDocument.property_id,
      project_id: createdDocument.project_id,
      file_url: createdDocument.file_url,
      filename: createdDocument.filename,
      original_filename: createdDocument.original_filename,
      file_size: createdDocument.file_size,
      mime_type: createdDocument.mime_type,
      tags: JSON.parse(createdDocument.tags || '[]'),
      metadata: JSON.parse(createdDocument.metadata || '{}'),
      status: createdDocument.status,
      is_favorite: createdDocument.is_favorite,
      view_count: createdDocument.view_count,
      uploaded_by: {
        id: createdDocument.uploaded_by,
        name: `${createdDocument.uploader_first_name} ${createdDocument.uploader_last_name}`
      },
      created_at: createdDocument.created_at,
      updated_at: createdDocument.updated_at
    }));

  } catch (error) {
    console.error('Document upload error:', error);

    if (error.message.includes('File type not allowed')) {
      return res.status(400).json(createResponse(false, null, {
        message: error.message
      }));
    }

    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * GET /api/v1/documents
 * Get documents with filtering and pagination
 */
router.get('/', authenticate, async (req, res) => {
  try {
    const {
      property_id,
      project_id,
      document_type,
      category,
      status = 'active',
      search,
      tags,
      page = 1,
      limit = 20,
      sort_by = 'created_at',
      sort_order = 'desc',
      expiring_soon // Show documents expiring within 30 days
    } = req.query;

    // Build query
    let query = db('documents')
      .leftJoin('users', 'documents.uploaded_by', 'users.id')
      .where('documents.status', status);

    // Filter by access - user must have access to associated property/project
    query.where(function() {
      this.where(function() {
        // Property-associated documents
        this.whereNotNull('documents.property_id')
          .whereExists(function() {
            this.select('*')
              .from('properties')
              .whereRaw('properties.id = documents.property_id')
              .where(function() {
                this.where('properties.owner_id', req.user.id)
                  .orWhereExists(function() {
                    this.select('*')
                      .from('property_permissions')
                      .whereRaw('property_permissions.property_id = properties.id')
                      .where('property_permissions.user_id', req.user.id);
                  });
              });
          });
      }).orWhere(function() {
        // Project-associated documents  
        this.whereNotNull('documents.project_id')
          .whereExists(function() {
            this.select('*')
              .from('projects')
              .join('properties', 'projects.property_id', 'properties.id')
              .whereRaw('projects.id = documents.project_id')
              .where(function() {
                this.where('properties.owner_id', req.user.id)
                  .orWhereExists(function() {
                    this.select('*')
                      .from('property_permissions')
                      .whereRaw('property_permissions.property_id = properties.id')
                      .where('property_permissions.user_id', req.user.id);
                  })
                  .orWhereExists(function() {
                    this.select('*')
                      .from('project_assignments')
                      .whereRaw('project_assignments.project_id = projects.id')
                      .where('project_assignments.user_id', req.user.id);
                  });
              });
          });
      });
    });

    // Apply filters
    if (property_id) {
      query.where('documents.property_id', property_id);
    }

    if (project_id) {
      query.where('documents.project_id', project_id);
    }

    if (document_type) {
      query.where('documents.document_type', document_type);
    }

    if (category) {
      query.where('documents.category', category);
    }

    if (search) {
      query.where(function() {
        this.where('documents.title', 'like', `%${search}%`)
          .orWhere('documents.description', 'like', `%${search}%`)
          .orWhere('documents.vendor_name', 'like', `%${search}%`);
      });
    }

    if (tags) {
      const tagArray = Array.isArray(tags) ? tags : [tags];
      tagArray.forEach(tag => {
        query.whereRaw("JSON_EXTRACT(documents.tags, '$') LIKE ?", [`%"${tag}"%`]);
      });
    }

    if (expiring_soon === 'true') {
      const thirtyDaysFromNow = new Date();
      thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
      
      query.whereNotNull('documents.expiry_date')
        .where('documents.expiry_date', '<=', thirtyDaysFromNow)
        .where('documents.expiry_date', '>=', new Date());
    }

    // Get total count for pagination
    const totalQuery = query.clone();
    const total = await totalQuery.count('documents.id as count').first();
    const totalRecords = parseInt(total.count);

    // Apply sorting and pagination
    const validSortFields = ['created_at', 'updated_at', 'title', 'document_date', 'expiry_date', 'amount'];
    const sortField = validSortFields.includes(sort_by) ? `documents.${sort_by}` : 'documents.created_at';
    const sortDirection = sort_order.toLowerCase() === 'asc' ? 'asc' : 'desc';

    query.orderBy(sortField, sortDirection);

    const pageNum = Math.max(1, parseInt(page));
    const limitNum = Math.min(100, Math.max(1, parseInt(limit)));
    const offset = (pageNum - 1) * limitNum;

    query.limit(limitNum).offset(offset);

    // Select fields
    query.select(
      'documents.*',
      'users.first_name as uploader_first_name',
      'users.last_name as uploader_last_name'
    );

    const documents = await query;

    // Format response
    const formattedDocuments = documents.map(doc => ({
      id: doc.id,
      title: doc.title,
      description: doc.description,
      document_type: doc.document_type,
      category: doc.category,
      vendor_name: doc.vendor_name,
      amount: doc.amount,
      currency: doc.currency,
      document_date: doc.document_date,
      expiry_date: doc.expiry_date,
      property_id: doc.property_id,
      project_id: doc.project_id,
      file_url: doc.file_url,
      filename: doc.filename,
      original_filename: doc.original_filename,
      file_size: doc.file_size,
      mime_type: doc.mime_type,
      tags: JSON.parse(doc.tags || '[]'),
      status: doc.status,
      is_favorite: doc.is_favorite,
      view_count: doc.view_count,
      uploaded_by: {
        id: doc.uploaded_by,
        name: `${doc.uploader_first_name} ${doc.uploader_last_name}`
      },
      created_at: doc.created_at,
      updated_at: doc.updated_at
    }));

    const totalPages = Math.ceil(totalRecords / limitNum);

    res.json(createResponse(true, {
      documents: formattedDocuments,
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
    console.error('Documents retrieval error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * GET /api/v1/documents/:id
 * Get a specific document by ID
 */
router.get('/:id', authenticate, async (req, res) => {
  try {
    const documentId = req.params.id;

    const document = await db('documents')
      .leftJoin('users', 'documents.uploaded_by', 'users.id')
      .where('documents.id', documentId)
      .where('documents.status', 'active')
      .select(
        'documents.*',
        'users.first_name as uploader_first_name',
        'users.last_name as uploader_last_name'
      )
      .first();

    if (!document) {
      return res.status(404).json(createResponse(false, null, {
        message: 'Document not found'
      }));
    }

    // Check user access
    const hasAccess = await validateAccess(req.user.id, document.property_id, document.project_id);
    if (!hasAccess) {
      return res.status(403).json(createResponse(false, null, {
        message: 'Access denied to this document'
      }));
    }

    // Increment view count
    await db('documents')
      .where('id', documentId)
      .increment('view_count', 1)
      .update('updated_at', new Date());

    // Log the view action
    await logDocumentAccess(documentId, req.user.id, 'view', req);

    // Format response
    const formattedDocument = {
      id: document.id,
      title: document.title,
      description: document.description,
      document_type: document.document_type,
      category: document.category,
      vendor_name: document.vendor_name,
      amount: document.amount,
      currency: document.currency,
      document_date: document.document_date,
      expiry_date: document.expiry_date,
      property_id: document.property_id,
      project_id: document.project_id,
      file_url: document.file_url,
      filename: document.filename,
      original_filename: document.original_filename,
      file_size: document.file_size,
      mime_type: document.mime_type,
      tags: JSON.parse(document.tags || '[]'),
      metadata: JSON.parse(document.metadata || '{}'),
      status: document.status,
      is_favorite: document.is_favorite,
      view_count: document.view_count + 1, // Include the increment
      uploaded_by: {
        id: document.uploaded_by,
        name: `${document.uploader_first_name} ${document.uploader_last_name}`
      },
      created_at: document.created_at,
      updated_at: document.updated_at
    };

    res.json(createResponse(true, formattedDocument));

  } catch (error) {
    console.error('Document retrieval error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * PUT /api/v1/documents/:id
 * Update document metadata
 */
router.put('/:id', authenticate, async (req, res) => {
  try {
    const documentId = req.params.id;
    const {
      title,
      description,
      document_type,
      category,
      vendor_name,
      amount,
      currency,
      document_date,
      expiry_date,
      tags,
      metadata,
      is_favorite
    } = req.body;

    const document = await db('documents')
      .where('id', documentId)
      .where('status', 'active')
      .first();

    if (!document) {
      return res.status(404).json(createResponse(false, null, {
        message: 'Document not found'
      }));
    }

    // Check user access
    const hasAccess = await validateAccess(req.user.id, document.property_id, document.project_id);
    if (!hasAccess) {
      return res.status(403).json(createResponse(false, null, {
        message: 'Access denied to this document'
      }));
    }

    // Parse tags and metadata
    let parsedTags = document.tags;
    if (tags !== undefined) {
      try {
        parsedTags = JSON.stringify(typeof tags === 'string' ? JSON.parse(tags) : tags);
      } catch (e) {
        parsedTags = JSON.stringify([tags]);
      }
    }

    let parsedMetadata = document.metadata;
    if (metadata !== undefined) {
      try {
        parsedMetadata = JSON.stringify(typeof metadata === 'string' ? JSON.parse(metadata) : metadata);
      } catch (e) {
        console.warn('Invalid metadata JSON, keeping existing:', e.message);
      }
    }

    // Prepare update data
    const updateData = {
      updated_at: new Date()
    };

    if (title !== undefined) updateData.title = title.trim();
    if (description !== undefined) updateData.description = description?.trim() || null;
    if (document_type !== undefined) updateData.document_type = document_type;
    if (category !== undefined) updateData.category = category || null;
    if (vendor_name !== undefined) updateData.vendor_name = vendor_name?.trim() || null;
    if (amount !== undefined) updateData.amount = amount ? parseFloat(amount) : null;
    if (currency !== undefined) updateData.currency = currency || 'USD';
    if (document_date !== undefined) updateData.document_date = document_date || null;
    if (expiry_date !== undefined) updateData.expiry_date = expiry_date || null;
    if (tags !== undefined) updateData.tags = parsedTags;
    if (metadata !== undefined) updateData.metadata = parsedMetadata;
    if (is_favorite !== undefined) updateData.is_favorite = is_favorite;

    // Update document
    await db('documents')
      .where('id', documentId)
      .update(updateData);

    // Get updated document
    const updatedDocument = await db('documents')
      .leftJoin('users', 'documents.uploaded_by', 'users.id')
      .where('documents.id', documentId)
      .select(
        'documents.*',
        'users.first_name as uploader_first_name',
        'users.last_name as uploader_last_name'
      )
      .first();

    // Log the update action
    await logDocumentAccess(documentId, req.user.id, 'edit', req);

    // Format response
    const formattedDocument = {
      id: updatedDocument.id,
      title: updatedDocument.title,
      description: updatedDocument.description,
      document_type: updatedDocument.document_type,
      category: updatedDocument.category,
      vendor_name: updatedDocument.vendor_name,
      amount: updatedDocument.amount,
      currency: updatedDocument.currency,
      document_date: updatedDocument.document_date,
      expiry_date: updatedDocument.expiry_date,
      property_id: updatedDocument.property_id,
      project_id: updatedDocument.project_id,
      file_url: updatedDocument.file_url,
      filename: updatedDocument.filename,
      original_filename: updatedDocument.original_filename,
      file_size: updatedDocument.file_size,
      mime_type: updatedDocument.mime_type,
      tags: JSON.parse(updatedDocument.tags || '[]'),
      metadata: JSON.parse(updatedDocument.metadata || '{}'),
      status: updatedDocument.status,
      is_favorite: updatedDocument.is_favorite,
      view_count: updatedDocument.view_count,
      uploaded_by: {
        id: updatedDocument.uploaded_by,
        name: `${updatedDocument.uploader_first_name} ${updatedDocument.uploader_last_name}`
      },
      created_at: updatedDocument.created_at,
      updated_at: updatedDocument.updated_at
    };

    res.json(createResponse(true, formattedDocument));

  } catch (error) {
    console.error('Document update error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * DELETE /api/v1/documents/:id
 * Delete a document (soft delete)
 */
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const documentId = req.params.id;

    const document = await db('documents')
      .where('id', documentId)
      .where('status', 'active')
      .first();

    if (!document) {
      return res.status(404).json(createResponse(false, null, {
        message: 'Document not found'
      }));
    }

    // Check user access (only uploader or property owner can delete)
    const hasAccess = await validateAccess(req.user.id, document.property_id, document.project_id);
    const isUploader = document.uploaded_by === req.user.id;
    
    if (!hasAccess && !isUploader) {
      return res.status(403).json(createResponse(false, null, {
        message: 'Access denied to delete this document'
      }));
    }

    // Soft delete - mark as deleted but keep file and record
    await db('documents')
      .where('id', documentId)
      .update({
        status: 'deleted',
        updated_at: new Date()
      });

    // Log the delete action
    await logDocumentAccess(documentId, req.user.id, 'delete', req);

    res.json(createResponse(true, {
      message: 'Document deleted successfully'
    }));

  } catch (error) {
    console.error('Document deletion error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

/**
 * GET /api/v1/documents/categories/summary
 * Get document categories and counts for organization
 */
router.get('/categories/summary', authenticate, async (req, res) => {
  try {
    const { property_id, project_id } = req.query;

    // Build base query
    let query = db('documents')
      .where('documents.status', 'active');

    // Apply access control
    query.where(function() {
      this.where(function() {
        // Property-associated documents
        this.whereNotNull('documents.property_id')
          .whereExists(function() {
            this.select('*')
              .from('properties')
              .whereRaw('properties.id = documents.property_id')
              .where(function() {
                this.where('properties.owner_id', req.user.id)
                  .orWhereExists(function() {
                    this.select('*')
                      .from('property_permissions')
                      .whereRaw('property_permissions.property_id = properties.id')
                      .where('property_permissions.user_id', req.user.id);
                  });
              });
          });
      }).orWhere(function() {
        // Project-associated documents
        this.whereNotNull('documents.project_id')
          .whereExists(function() {
            this.select('*')
              .from('projects')
              .join('properties', 'projects.property_id', 'properties.id')
              .whereRaw('projects.id = documents.project_id')
              .where(function() {
                this.where('properties.owner_id', req.user.id)
                  .orWhereExists(function() {
                    this.select('*')
                      .from('property_permissions')
                      .whereRaw('property_permissions.property_id = properties.id')
                      .where('property_permissions.user_id', req.user.id);
                  })
                  .orWhereExists(function() {
                    this.select('*')
                      .from('project_assignments')
                      .whereRaw('project_assignments.project_id = projects.id')
                      .where('project_assignments.user_id', req.user.id);
                  });
              });
          });
      });
    });

    // Apply filters if provided
    if (property_id) {
      query.where('documents.property_id', property_id);
    }
    if (project_id) {
      query.where('documents.project_id', project_id);
    }

    // Get summary by document type
    const typesSummary = await query.clone()
      .select('document_type')
      .count('* as count')
      .sum('file_size as total_size')
      .groupBy('document_type')
      .orderBy('count', 'desc');

    // Get summary by category
    const categoriesSummary = await query.clone()
      .select('category')
      .count('* as count')
      .whereNotNull('category')
      .groupBy('category')
      .orderBy('count', 'desc');

    // Get expiring documents count (next 30 days)
    const thirtyDaysFromNow = new Date();
    thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
    
    const expiringCount = await query.clone()
      .whereNotNull('expiry_date')
      .where('expiry_date', '<=', thirtyDaysFromNow)
      .where('expiry_date', '>=', new Date())
      .count('* as count')
      .first();

    // Get recent uploads (last 7 days)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    
    const recentCount = await query.clone()
      .where('created_at', '>=', sevenDaysAgo)
      .count('* as count')
      .first();

    res.json(createResponse(true, {
      types: typesSummary.map(t => ({
        type: t.document_type,
        count: parseInt(t.count),
        total_size: parseInt(t.total_size || 0)
      })),
      categories: categoriesSummary.map(c => ({
        category: c.category,
        count: parseInt(c.count)
      })),
      summary: {
        expiring_soon: parseInt(expiringCount.count),
        recent_uploads: parseInt(recentCount.count)
      }
    }));

  } catch (error) {
    console.error('Categories summary error:', error);
    return res.status(500).json(createResponse(false, null, {
      message: 'Internal server error'
    }));
  }
});

module.exports = router;