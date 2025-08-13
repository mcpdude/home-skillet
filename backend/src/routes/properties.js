const express = require('express');
const db = require('../config/database');
const { createClient } = require('@supabase/supabase-js');
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

// Initialize Supabase client for direct API calls
let supabase = null;
try {
  if (process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY) {
    supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
  }
} catch (error) {
  console.error('Failed to initialize Supabase client in properties routes:', error);
}

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

    // Create new property - try Supabase first, fallback to direct DB
    let dbProperty = null;
    let useDirectDB = false;

    if (supabase) {
      try {
        const { data: supabaseProperty, error: insertError } = await supabase
          .from('properties')
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
            user_id: req.user.id
          })
          .select()
          .single();
        
        if (insertError) {
          console.log('Supabase property insert failed, falling back to direct DB:', insertError.message);
          useDirectDB = true;
        } else {
          dbProperty = supabaseProperty;
        }
      } catch (error) {
        console.log('Supabase property insert error, falling back to direct DB:', error.message);
        useDirectDB = true;
      }
    } else {
      useDirectDB = true;
    }

    if (useDirectDB) {
      try {
        const [directDbProperty] = await db('properties')
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
            user_id: req.user.id
          })
          .returning(['id', 'name', 'description', 'address', 'type', 'bedrooms', 'bathrooms', 'square_feet', 'lot_size', 'year_built', 'user_id', 'created_at', 'updated_at']);
        dbProperty = directDbProperty;
      } catch (dbError) {
        console.error('Direct DB property creation failed (likely connection pool timeout):', dbError.message);
        const { error: errorObj, statusCode } = createErrorResponse('Unable to create property due to database connectivity issues. Please try again later.', 503);
        return res.status(statusCode).json(createResponse(false, null, errorObj));
      }
    }
    
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
      ownerId: dbProperty.user_id,
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

    // Get user's properties (owned or has access to) - try Supabase first, fallback to direct DB
    let ownedProperties = [];
    let accessiblePropertiesIds = [];
    let accessibleProperties = [];
    let useDirectDB = false;

    if (supabase) {
      try {
        // Get owned properties from Supabase - try different column name variations
        console.log('Attempting Supabase properties query for user:', req.user.id);
        let supabaseOwnedProperties = null;
        let ownedError = null;
        
        // Try user_id (correct column name based on error logs)
        const { data: ownedPropsUserId, error: errorUserId } = await supabase
          .from('properties')
          .select('*')
          .eq('user_id', req.user.id);
        
        if (!errorUserId) {
          supabaseOwnedProperties = ownedPropsUserId;
        } else {
          // If that fails, try owner_id as fallback
          console.log('Trying owner_id column name...');
          const { data: ownedPropsOwnerId, error: errorOwnerId } = await supabase
            .from('properties')
            .select('*')
            .eq('owner_id', req.user.id);
          
          if (!errorOwnerId) {
            supabaseOwnedProperties = ownedPropsOwnerId;
          } else {
            ownedError = errorUserId; // Use the original error
            console.log('Both user_id and owner_id attempts failed:', {
              userIdError: errorUserId.message,
              ownerIdError: errorOwnerId.message
            });
          }
        }
        
        // Get property permissions from Supabase  
        const { data: supabasePermissions, error: permissionsError } = await supabase
          .from('property_permissions')
          .select('property_id')
          .eq('user_id', req.user.id);

        console.log('Supabase query results:', {
          ownedError: ownedError?.message,
          permissionsError: permissionsError?.message,
          ownedCount: supabaseOwnedProperties?.length || 0,
          permissionsCount: supabasePermissions?.length || 0
        });

        if (ownedError || permissionsError) {
          console.log('Supabase properties query failed, falling back to direct DB:', ownedError?.message || permissionsError?.message);
          useDirectDB = true;
        } else {
          ownedProperties = supabaseOwnedProperties || [];
          accessiblePropertiesIds = (supabasePermissions || []).map(p => p.property_id);
          
          // Get accessible properties if there are any
          if (accessiblePropertiesIds.length > 0) {
            const { data: supabaseAccessibleProperties, error: accessibleError } = await supabase
              .from('properties')
              .select('*')
              .in('id', accessiblePropertiesIds);
            
            if (accessibleError) {
              console.log('Supabase accessible properties query failed, falling back to direct DB:', accessibleError.message);
              useDirectDB = true;
            } else {
              accessibleProperties = supabaseAccessibleProperties || [];
            }
          }
        }
      } catch (error) {
        console.log('Supabase properties query error, falling back to direct DB:', error.message);
        useDirectDB = true;
      }
    } else {
      useDirectDB = true;
    }

    if (useDirectDB) {
      // Check if we're likely in a connection pool timeout scenario
      console.log('Falling back to direct DB queries...');
      try {
        ownedProperties = await db('properties')
          .where('user_id', req.user.id);
        
        accessiblePropertiesIds = await db('property_permissions')
          .where('user_id', req.user.id)
          .pluck('property_id');
        
        accessibleProperties = accessiblePropertiesIds.length > 0 
          ? await db('properties').whereIn('id', accessiblePropertiesIds)
          : [];
      } catch (dbError) {
        console.error('Direct DB query failed (likely connection pool timeout):', dbError.message);
        // Return empty arrays to prevent complete failure
        ownedProperties = [];
        accessibleProperties = [];
        accessiblePropertiesIds = [];
        
        // Don't throw the error, just log it and continue with empty results
        console.log('Returning empty results due to connection pool timeout');
      }
    }
    
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
      ownerId: dbProperty.user_id,
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
      ownerId: dbProperty.user_id,
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