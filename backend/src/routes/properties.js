const express = require('express');
const db = require('../config/database');
const { propertySchemas } = require('../utils/validation');
const { 
  formatValidationError, 
  createResponse, 
  createErrorResponse,
  filterByQuery,
  sortItems,
  paginateResults
} = require('../utils/helpers');
const { authenticate, validatePropertyAccess } = require('../middleware/auth');

const router = express.Router();

/**
 * POST /api/v1/properties
 * Create a new property
 */
router.post('/', authenticate, async (req, res) => {
  try {
    // Validate request body
    const { error, value } = propertySchemas.create.validate(req.body);
    if (error) {
      const validationError = formatValidationError(error);
      const { error: errorObj, statusCode } = createErrorResponse(validationError.message, 400, validationError.details);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Create new property
    const [dbProperty] = await db('properties')
      .insert({
        name: value.name,
        description: value.description,
        address: value.address,
        type: value.type,
        bedrooms: value.bedrooms,
        bathrooms: value.bathrooms,
        square_feet: value.squareFeet,
        lot_size: value.lotSize,
        year_built: value.yearBuilt,
        owner_id: req.user.id
      })
      .returning(['id', 'name', 'description', 'address', 'type', 'bedrooms', 'bathrooms', 'square_feet', 'lot_size', 'year_built', 'owner_id', 'created_at', 'updated_at']);
    
    // Transform to expected format
    const newProperty = {
      id: dbProperty.id,
      name: dbProperty.name,
      description: dbProperty.description,
      address: dbProperty.address,
      type: dbProperty.type,
      bedrooms: dbProperty.bedrooms,
      bathrooms: dbProperty.bathrooms,
      squareFeet: dbProperty.square_feet,
      lotSize: dbProperty.lot_size,
      yearBuilt: dbProperty.year_built,
      ownerId: dbProperty.owner_id,
      createdAt: dbProperty.created_at,
      updatedAt: dbProperty.updated_at
    };

    // Return response
    const responseData = {
      property: newProperty
    };

    return res.status(201).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Property creation error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * GET /api/v1/properties
 * Get all properties for the authenticated user
 */
router.get('/', authenticate, async (req, res) => {
  try {
    const { page, limit, sortBy, sortOrder, ...filters } = req.query;

    // Get user's properties (owned or has access to)
    const ownedProperties = await db('properties')
      .where('owner_id', req.user.id);
    
    const accessiblePropertiesIds = await db('property_permissions')
      .where('user_id', req.user.id)
      .pluck('property_id');
    
    const accessibleProperties = accessiblePropertiesIds.length > 0 
      ? await db('properties').whereIn('id', accessiblePropertiesIds)
      : [];
    
    // Combine and transform properties
    const allDbProperties = [...ownedProperties, ...accessibleProperties];
    let userProperties = allDbProperties.map(dbProperty => ({
      id: dbProperty.id,
      name: dbProperty.name,
      description: dbProperty.description,
      address: dbProperty.address,
      type: dbProperty.type,
      bedrooms: dbProperty.bedrooms,
      bathrooms: dbProperty.bathrooms,
      squareFeet: dbProperty.square_feet,
      lotSize: dbProperty.lot_size,
      yearBuilt: dbProperty.year_built,
      ownerId: dbProperty.owner_id,
      createdAt: dbProperty.created_at,
      updatedAt: dbProperty.updated_at
    }));

    // Apply filters
    userProperties = filterByQuery(userProperties, filters);

    // Apply sorting
    userProperties = sortItems(userProperties, sortBy, sortOrder);

    // Apply pagination
    const result = paginateResults(userProperties, page, limit);

    // Return response
    const responseData = {
      properties: result.items,
      pagination: result.pagination
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Properties retrieval error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * GET /api/v1/properties/:id
 * Get a specific property by ID
 */
router.get('/:id', authenticate, validatePropertyAccess, async (req, res) => {
  try {
    // Property is available in req.property from middleware
    const responseData = {
      property: req.property
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Property retrieval error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * PUT /api/v1/properties/:id
 * Update a specific property
 */
router.put('/:id', authenticate, validatePropertyAccess, async (req, res) => {
  try {
    // Only property owner can update property details
    if (req.property.ownerId !== req.user.id) {
      const { error: errorObj, statusCode } = createErrorResponse('Only property owner can update property details', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Validate request body
    const { error, value } = propertySchemas.update.validate(req.body);
    if (error) {
      const validationError = formatValidationError(error);
      const { error: errorObj, statusCode } = createErrorResponse(validationError.message, 400, validationError.details);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Update property in database
    const updateData = {
      updated_at: new Date()
    };
    
    // Map frontend field names to database column names
    if (value.name !== undefined) updateData.name = value.name;
    if (value.description !== undefined) updateData.description = value.description;
    if (value.address !== undefined) updateData.address = value.address;
    if (value.type !== undefined) updateData.type = value.type;
    if (value.bedrooms !== undefined) updateData.bedrooms = value.bedrooms;
    if (value.bathrooms !== undefined) updateData.bathrooms = value.bathrooms;
    if (value.squareFeet !== undefined) updateData.square_feet = value.squareFeet;
    if (value.lotSize !== undefined) updateData.lot_size = value.lotSize;
    if (value.yearBuilt !== undefined) updateData.year_built = value.yearBuilt;
    
    const [dbProperty] = await db('properties')
      .where('id', req.params.id)
      .update(updateData)
      .returning(['id', 'name', 'description', 'address', 'type', 'bedrooms', 'bathrooms', 'square_feet', 'lot_size', 'year_built', 'owner_id', 'created_at', 'updated_at']);
    
    if (!dbProperty) {
      const { error: errorObj, statusCode } = createErrorResponse('Property not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }
    
    // Transform to expected format
    const updatedProperty = {
      id: dbProperty.id,
      name: dbProperty.name,
      description: dbProperty.description,
      address: dbProperty.address,
      type: dbProperty.type,
      bedrooms: dbProperty.bedrooms,
      bathrooms: dbProperty.bathrooms,
      squareFeet: dbProperty.square_feet,
      lotSize: dbProperty.lot_size,
      yearBuilt: dbProperty.year_built,
      ownerId: dbProperty.owner_id,
      createdAt: dbProperty.created_at,
      updatedAt: dbProperty.updated_at
    };

    // Return response
    const responseData = {
      property: updatedProperty
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Property update error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * DELETE /api/v1/properties/:id
 * Delete a specific property
 */
router.delete('/:id', authenticate, validatePropertyAccess, async (req, res) => {
  try {
    // Only property owner can delete property
    if (req.property.ownerId !== req.user.id) {
      const { error: errorObj, statusCode } = createErrorResponse('Only property owner can delete property', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Delete property and related data (cascade will handle most)
    const deletedRows = await db('properties')
      .where('id', req.params.id)
      .del();
    
    if (deletedRows === 0) {
      const { error: errorObj, statusCode } = createErrorResponse('Property not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Return response
    const responseData = {
      message: 'Property deleted successfully'
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Property deletion error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

module.exports = router;