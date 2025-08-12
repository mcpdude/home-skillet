const express = require('express');
const db = require('../config/database');
const { userSchemas, permissionSchemas } = require('../utils/validation');
const { 
  formatValidationError, 
  createResponse, 
  createErrorResponse,
  sanitizeUser,
  filterByQuery,
  sortItems,
  paginateResults
} = require('../utils/helpers');
const { authenticate, requireAdmin, validatePropertyAccess } = require('../middleware/auth');

const router = express.Router();

/**
 * Helper function to get permissions for a role
 */
const getPermissionsForRole = (role) => {
  const defaultPermissions = {
    viewer: {
      viewProjects: true,
      createProjects: false,
      editProjects: false,
      deleteProjects: false,
      viewMaintenance: true,
      manageMaintenance: false,
      viewFinancials: false,
      manageVendors: false
    },
    editor: {
      viewProjects: true,
      createProjects: true,
      editProjects: true,
      deleteProjects: false,
      viewMaintenance: true,
      manageMaintenance: true,
      viewFinancials: false,
      manageVendors: false
    },
    admin: {
      viewProjects: true,
      createProjects: true,
      editProjects: true,
      deleteProjects: true,
      viewMaintenance: true,
      manageMaintenance: true,
      viewFinancials: true,
      manageVendors: true
    },
    contractor: {
      viewProjects: true,
      createProjects: false,
      editProjects: true,
      deleteProjects: false,
      viewMaintenance: true,
      manageMaintenance: true,
      viewFinancials: false,
      manageVendors: false
    },
    tenant: {
      viewProjects: true,
      createProjects: false,
      editProjects: false,
      deleteProjects: false,
      viewMaintenance: true,
      manageMaintenance: false,
      viewFinancials: false,
      manageVendors: false
    },
    manager: {
      viewProjects: true,
      createProjects: true,
      editProjects: true,
      deleteProjects: true,
      viewMaintenance: true,
      manageMaintenance: true,
      viewFinancials: true,
      manageVendors: true
    }
  };
  
  return defaultPermissions[role] || defaultPermissions.viewer;
};

/**
 * GET /api/v1/users
 * Get all users (admin only for now)
 */
router.get('/', authenticate, async (req, res) => {
  try {
    const { page, limit, sortBy, sortOrder, ...filters } = req.query;

    // Get all users (sanitized)
    const dbUsers = await db('users').select('*');
    let users = dbUsers.map(dbUser => {
      const user = {
        id: dbUser.id,
        email: dbUser.email,
        firstName: dbUser.first_name,
        lastName: dbUser.last_name,
        userType: dbUser.user_type,
        createdAt: dbUser.created_at,
        updatedAt: dbUser.updated_at
      };
      return sanitizeUser(user);
    });

    // Apply filters
    users = filterByQuery(users, filters);

    // Apply sorting
    users = sortItems(users, sortBy, sortOrder);

    // Apply pagination
    const result = paginateResults(users, page, limit);

    // Return response
    const responseData = {
      users: result.items,
      pagination: result.pagination
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Users retrieval error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * GET /api/v1/users/:id
 * Get a specific user by ID
 */
router.get('/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;

    // Find user
    const dbUser = await db('users').where('id', id).first();
    if (!dbUser) {
      const { error: errorObj, statusCode } = createErrorResponse('User not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }
    
    // Transform to expected format
    const user = {
      id: dbUser.id,
      email: dbUser.email,
      firstName: dbUser.first_name,
      lastName: dbUser.last_name,
      userType: dbUser.user_type,
      createdAt: dbUser.created_at,
      updatedAt: dbUser.updated_at
    };

    // Return response
    const responseData = {
      user: sanitizeUser(user)
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('User retrieval error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * PUT /api/v1/users/:id
 * Update a specific user
 */
router.put('/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;

    // Check if user can update this profile
    // Users can update their own profile, property owners can update any user
    const canUpdate = req.user.id === id || req.user.userType === 'property_owner';

    if (!canUpdate) {
      const { error: errorObj, statusCode } = createErrorResponse('Permission denied to update this user', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Validate request body
    const { error, value } = userSchemas.update.validate(req.body);
    if (error) {
      const validationError = formatValidationError(error);
      const { error: errorObj, statusCode } = createErrorResponse(validationError.message, 400, validationError.details);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Update user in database
    const updateData = {
      updated_at: new Date()
    };
    
    // Map frontend field names to database column names
    if (value.firstName) updateData.first_name = value.firstName;
    if (value.lastName) updateData.last_name = value.lastName;
    if (value.userType) updateData.user_type = value.userType;
    if (value.email) updateData.email = value.email;
    
    const [dbUser] = await db('users')
      .where('id', id)
      .update(updateData)
      .returning(['id', 'email', 'first_name', 'last_name', 'user_type', 'created_at', 'updated_at']);
    
    if (!dbUser) {
      const { error: errorObj, statusCode } = createErrorResponse('User not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }
    
    // Transform to expected format
    const updatedUser = {
      id: dbUser.id,
      email: dbUser.email,
      firstName: dbUser.first_name,
      lastName: dbUser.last_name,
      userType: dbUser.user_type,
      createdAt: dbUser.created_at,
      updatedAt: dbUser.updated_at
    };

    // Return response
    const responseData = {
      user: sanitizeUser(updatedUser)
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('User update error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * POST /api/v1/properties/:propertyId/permissions
 * Grant permissions to a user for a specific property
 */
router.post('/properties/:propertyId/permissions', authenticate, validatePropertyAccess, async (req, res) => {
  try {
    // Only property owner can grant permissions
    if (req.property.ownerId !== req.user.id) {
      const { error: errorObj, statusCode } = createErrorResponse('Only property owner can grant permissions', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Validate request body
    const { error, value } = permissionSchemas.grant.validate(req.body);
    if (error) {
      const validationError = formatValidationError(error);
      const { error: errorObj, statusCode } = createErrorResponse(validationError.message, 400, validationError.details);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const { userId, role, permissions = {} } = value;

    // Check if user exists
    const userToGrant = await db('users').where('id', userId).first();
    if (!userToGrant) {
      const { error: errorObj, statusCode } = createErrorResponse('User not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Set default permissions based on role
    const defaultPermissions = {
      viewer: {
        viewProjects: true,
        createProjects: false,
        editProjects: false,
        deleteProjects: false,
        viewMaintenance: true,
        manageMaintenance: false,
        viewFinancials: false,
        manageVendors: false
      },
      editor: {
        viewProjects: true,
        createProjects: true,
        editProjects: true,
        deleteProjects: false,
        viewMaintenance: true,
        manageMaintenance: true,
        viewFinancials: false,
        manageVendors: false
      },
      admin: {
        viewProjects: true,
        createProjects: true,
        editProjects: true,
        deleteProjects: true,
        viewMaintenance: true,
        manageMaintenance: true,
        viewFinancials: true,
        manageVendors: true
      },
      contractor: {
        viewProjects: true,
        createProjects: false,
        editProjects: true,
        deleteProjects: false,
        viewMaintenance: true,
        manageMaintenance: true,
        viewFinancials: false,
        manageVendors: false
      },
      tenant: {
        viewProjects: true,
        createProjects: false,
        editProjects: false,
        deleteProjects: false,
        viewMaintenance: true,
        manageMaintenance: false,
        viewFinancials: false,
        manageVendors: false
      }
    };

    // Merge default permissions with provided ones
    const finalPermissions = {
      ...defaultPermissions[role],
      ...permissions
    };

    // Check if permission already exists
    const existingPermission = await db('property_permissions')
      .where({
        user_id: userId,
        property_id: req.params.propertyId
      })
      .first();

    if (existingPermission) {
      // Update existing permission
      const [updatedPermission] = await db('property_permissions')
        .where('id', existingPermission.id)
        .update({
          role,
          updated_at: new Date()
        })
        .returning(['id', 'property_id', 'user_id', 'role', 'created_at', 'updated_at']);

      const responseData = {
        permission: {
          id: updatedPermission.id,
          userId: updatedPermission.user_id,
          propertyId: updatedPermission.property_id,
          role: updatedPermission.role,
          permissions: finalPermissions,
          createdAt: updatedPermission.created_at,
          updatedAt: updatedPermission.updated_at
        }
      };

      return res.status(200).json(createResponse(true, responseData));
    } else {
      // Create new permission
      const [newPermission] = await db('property_permissions')
        .insert({
          user_id: userId,
          property_id: req.params.propertyId,
          role
        })
        .returning(['id', 'property_id', 'user_id', 'role', 'created_at', 'updated_at']);

      // Return response
      const responseData = {
        permission: {
          id: newPermission.id,
          userId: newPermission.user_id,
          propertyId: newPermission.property_id,
          role: newPermission.role,
          permissions: finalPermissions,
          grantedBy: req.user.id,
          createdAt: newPermission.created_at,
          updatedAt: newPermission.updated_at
        }
      };

      return res.status(201).json(createResponse(true, responseData));
    }

  } catch (error) {
    console.error('Permission grant error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * GET /api/v1/properties/:propertyId/permissions
 * Get all permissions for a specific property
 */
router.get('/properties/:propertyId/permissions', authenticate, validatePropertyAccess, async (req, res) => {
  try {
    // Only property owner can view permissions
    if (req.property.ownerId !== req.user.id) {
      const { error: errorObj, statusCode } = createErrorResponse('Only property owner can view permissions', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Get permissions for this property with user information
    const propertyPermissions = await db('property_permissions')
      .join('users', 'property_permissions.user_id', 'users.id')
      .where('property_permissions.property_id', req.params.propertyId)
      .select(
        'property_permissions.id',
        'property_permissions.property_id',
        'property_permissions.user_id',
        'property_permissions.role',
        'property_permissions.created_at',
        'property_permissions.updated_at',
        'users.email',
        'users.first_name',
        'users.last_name',
        'users.user_type'
      );

    // Transform to expected format
    const enrichedPermissions = propertyPermissions.map(permission => ({
      id: permission.id,
      userId: permission.user_id,
      propertyId: permission.property_id,
      role: permission.role,
      permissions: getPermissionsForRole(permission.role),
      createdAt: permission.created_at,
      updatedAt: permission.updated_at,
      user: {
        id: permission.user_id,
        email: permission.email,
        firstName: permission.first_name,
        lastName: permission.last_name,
        userType: permission.user_type
      }
    }));

    // Return response
    const responseData = {
      permissions: enrichedPermissions
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Permissions retrieval error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * PUT /api/v1/properties/:propertyId/permissions/:userId
 * Update permissions for a user on a specific property
 */
router.put('/properties/:propertyId/permissions/:userId', authenticate, validatePropertyAccess, async (req, res) => {
  try {
    // Only property owner can update permissions
    if (req.property.ownerId !== req.user.id) {
      const { error: errorObj, statusCode } = createErrorResponse('Only property owner can update permissions', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Validate request body
    const { error, value } = permissionSchemas.update.validate(req.body);
    if (error) {
      const validationError = formatValidationError(error);
      const { error: errorObj, statusCode } = createErrorResponse(validationError.message, 400, validationError.details);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const { userId } = req.params;

    // Find and update permission
    const [updatedPermission] = await db('property_permissions')
      .where({
        user_id: userId,
        property_id: req.params.propertyId
      })
      .update({
        role: value.role,
        updated_at: new Date()
      })
      .returning(['id', 'property_id', 'user_id', 'role', 'created_at', 'updated_at']);

    if (!updatedPermission) {
      const { error: errorObj, statusCode } = createErrorResponse('Permission not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }
    
    // Transform to expected format
    const transformedPermission = {
      id: updatedPermission.id,
      userId: updatedPermission.user_id,
      propertyId: updatedPermission.property_id,
      role: updatedPermission.role,
      permissions: getPermissionsForRole(updatedPermission.role),
      createdAt: updatedPermission.created_at,
      updatedAt: updatedPermission.updated_at
    };

    // Return response
    const responseData = {
      permission: transformedPermission
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Permission update error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * DELETE /api/v1/properties/:propertyId/permissions/:userId
 * Revoke permissions for a user on a specific property
 */
router.delete('/properties/:propertyId/permissions/:userId', authenticate, validatePropertyAccess, async (req, res) => {
  try {
    // Only property owner can revoke permissions
    if (req.property.ownerId !== req.user.id) {
      const { error: errorObj, statusCode } = createErrorResponse('Only property owner can revoke permissions', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const { userId } = req.params;

    // Delete permission
    const deletedRows = await db('property_permissions')
      .where({
        user_id: userId,
        property_id: req.params.propertyId
      })
      .del();

    if (deletedRows === 0) {
      const { error: errorObj, statusCode } = createErrorResponse('Permission not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Return response
    const responseData = {
      message: 'Permission revoked successfully'
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Permission revocation error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

module.exports = router;