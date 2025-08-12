const jwt = require('jsonwebtoken');
const db = require('../config/database');
const { createResponse, createErrorResponse, sanitizeUser } = require('../utils/helpers');

/**
 * Generate JWT token for user
 */
const generateToken = (user) => {
  const payload = {
    id: user.id,
    email: user.email,
    userType: user.userType
  };
  
  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d'
  });
};

/**
 * Verify JWT token
 */
const verifyToken = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_SECRET);
  } catch (error) {
    return null;
  }
};

/**
 * Authentication middleware
 */
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      const { error, statusCode } = createErrorResponse('Access token is required', 401);
      return res.status(statusCode).json(createResponse(false, null, error));
    }
    
    const token = authHeader.substring(7); // Remove 'Bearer ' prefix
    const decoded = verifyToken(token);
    
    if (!decoded) {
      const { error, statusCode } = createErrorResponse('Invalid or expired token', 401);
      return res.status(statusCode).json(createResponse(false, null, error));
    }
    
    // Find user in database
    const dbUser = await db('users').where('id', decoded.id).first();
    
    if (!dbUser) {
      const { error, statusCode } = createErrorResponse('User not found', 401);
      return res.status(statusCode).json(createResponse(false, null, error));
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
    
    // Attach user to request
    req.user = sanitizeUser(user);
    next();
  } catch (error) {
    console.error('Authentication error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Authentication failed', 401);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
};

/**
 * Middleware to check if user has property owner role
 */
const requirePropertyOwner = (req, res, next) => {
  if (req.user.userType !== 'property_owner') {
    const { error, statusCode } = createErrorResponse('Property owner access required', 403);
    return res.status(statusCode).json(createResponse(false, null, error));
  }
  next();
};

/**
 * Middleware to check if user has admin privileges (property owner only for now)
 */
const requireAdmin = (req, res, next) => {
  if (req.user.userType !== 'property_owner') {
    const { error, statusCode } = createErrorResponse('Admin access required', 403);
    return res.status(statusCode).json(createResponse(false, null, error));
  }
  next();
};

/**
 * Middleware to validate property access
 */
const validatePropertyAccess = async (req, res, next) => {
  const propertyId = req.params.propertyId || req.params.id;
  
  if (!propertyId) {
    const { error, statusCode } = createErrorResponse('Property ID is required', 400);
    return res.status(statusCode).json(createResponse(false, null, error));
  }
  
  // Find the property
  const dbProperty = await db('properties').where('id', propertyId).first();
  
  if (!dbProperty) {
    const { error, statusCode } = createErrorResponse('Property not found', 404);
    return res.status(statusCode).json(createResponse(false, null, error));
  }
  
  // Transform to expected format
  const property = {
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
  
  // Check if user is the owner
  if (property.ownerId === req.user.id) {
    req.property = property;
    return next();
  }
  
  // Check if user has been granted access
  const dbUserRole = await db('property_permissions')
    .where({
      user_id: req.user.id,
      property_id: propertyId
    })
    .first();
  
  if (!dbUserRole) {
    const { error, statusCode } = createErrorResponse('Access denied to this property', 403);
    return res.status(statusCode).json(createResponse(false, null, error));
  }
  
  // Transform to expected format
  const userRole = {
    id: dbUserRole.id,
    userId: dbUserRole.user_id,
    propertyId: dbUserRole.property_id,
    role: dbUserRole.role,
    permissions: getPermissionsForRole(dbUserRole.role),
    createdAt: dbUserRole.created_at,
    updatedAt: dbUserRole.updated_at
  };
  
  req.property = property;
  req.userRole = userRole;
  next();
};

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
 * Middleware to validate project access
 */
const validateProjectAccess = async (req, res, next) => {
  const projectId = req.params.projectId || req.params.id;
  
  if (!projectId) {
    const { error, statusCode } = createErrorResponse('Project ID is required', 400);
    return res.status(statusCode).json(createResponse(false, null, error));
  }
  
  // Find the project
  const dbProject = await db('projects').where('id', projectId).first();
  
  if (!dbProject) {
    const { error, statusCode } = createErrorResponse('Project not found', 404);
    return res.status(statusCode).json(createResponse(false, null, error));
  }
  
  // Transform to expected format
  const project = {
    id: dbProject.id,
    propertyId: dbProject.property_id,
    title: dbProject.title,
    description: dbProject.description,
    status: dbProject.status,
    priority: dbProject.priority,
    budget: dbProject.budget,
    actualCost: dbProject.actual_cost,
    startDate: dbProject.start_date,
    endDate: dbProject.end_date,
    dueDate: dbProject.due_date,
    createdBy: dbProject.created_by,
    createdAt: dbProject.created_at,
    updatedAt: dbProject.updated_at
  };
  
  // Find the property this project belongs to
  const dbProperty = await db('properties').where('id', project.propertyId).first();
  
  if (!dbProperty) {
    const { error, statusCode } = createErrorResponse('Property not found', 404);
    return res.status(statusCode).json(createResponse(false, null, error));
  }
  
  const property = {
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
  
  // Check if user is the property owner
  if (property.ownerId === req.user.id) {
    req.project = project;
    req.property = property;
    return next();
  }
  
  // Check if user is assigned to this project
  const dbProjectAssignment = await db('project_assignments')
    .where({
      user_id: req.user.id,
      project_id: projectId
    })
    .first();
  
  if (dbProjectAssignment) {
    const projectAssignment = {
      id: dbProjectAssignment.id,
      userId: dbProjectAssignment.user_id,
      projectId: dbProjectAssignment.project_id,
      role: dbProjectAssignment.role,
      assignedBy: dbProjectAssignment.assigned_by,
      createdAt: dbProjectAssignment.created_at,
      updatedAt: dbProjectAssignment.updated_at
    };
    req.project = project;
    req.property = property;
    req.projectAssignment = projectAssignment;
    return next();
  }
  
  // Check if user has property-level access
  const dbUserRole = await db('property_permissions')
    .where({
      user_id: req.user.id,
      property_id: property.id
    })
    .first();
  
  if (!dbUserRole) {
    const { error, statusCode } = createErrorResponse('Access denied to this project', 403);
    return res.status(statusCode).json(createResponse(false, null, error));
  }
  
  const userRole = {
    id: dbUserRole.id,
    userId: dbUserRole.user_id,
    propertyId: dbUserRole.property_id,
    role: dbUserRole.role,
    permissions: getPermissionsForRole(dbUserRole.role),
    createdAt: dbUserRole.created_at,
    updatedAt: dbUserRole.updated_at
  };
  
  req.project = project;
  req.property = property;
  req.userRole = userRole;
  next();
};

/**
 * Middleware to validate maintenance schedule access
 */
const validateMaintenanceAccess = async (req, res, next) => {
  const scheduleId = req.params.scheduleId || req.params.id;
  
  if (!scheduleId) {
    const { error, statusCode } = createErrorResponse('Schedule ID is required', 400);
    return res.status(statusCode).json(createResponse(false, null, error));
  }
  
  // Find the maintenance schedule
  const dbSchedule = await db('maintenance_schedules').where('id', scheduleId).first();
  
  if (!dbSchedule) {
    const { error, statusCode } = createErrorResponse('Maintenance schedule not found', 404);
    return res.status(statusCode).json(createResponse(false, null, error));
  }
  
  // Transform to expected format
  const schedule = {
    id: dbSchedule.id,
    propertyId: dbSchedule.property_id,
    title: dbSchedule.title,
    description: dbSchedule.description,
    frequency: dbSchedule.frequency,
    frequencyValue: dbSchedule.frequency_value,
    category: dbSchedule.category,
    nextDueDate: dbSchedule.next_due_date,
    lastCompletedDate: dbSchedule.last_completed_date,
    isActive: dbSchedule.is_active,
    estimatedCost: dbSchedule.estimated_cost,
    assignedTo: dbSchedule.assigned_to,
    createdBy: dbSchedule.created_by,
    createdAt: dbSchedule.created_at,
    updatedAt: dbSchedule.updated_at
  };
  
  // Find the property this schedule belongs to
  const dbProperty = await db('properties').where('id', schedule.propertyId).first();
  
  if (!dbProperty) {
    const { error, statusCode } = createErrorResponse('Property not found', 404);
    return res.status(statusCode).json(createResponse(false, null, error));
  }
  
  const property = {
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
  
  // Check if user is the property owner
  if (property.ownerId === req.user.id) {
    req.schedule = schedule;
    req.property = property;
    return next();
  }
  
  // Check if user has property-level access
  const dbUserRole = await db('property_permissions')
    .where({
      user_id: req.user.id,
      property_id: property.id
    })
    .first();
  
  if (!dbUserRole) {
    const { error, statusCode } = createErrorResponse('Access denied to this maintenance schedule', 403);
    return res.status(statusCode).json(createResponse(false, null, error));
  }
  
  const userRole = {
    id: dbUserRole.id,
    userId: dbUserRole.user_id,
    propertyId: dbUserRole.property_id,
    role: dbUserRole.role,
    permissions: getPermissionsForRole(dbUserRole.role),
    createdAt: dbUserRole.created_at,
    updatedAt: dbUserRole.updated_at
  };
  
  req.schedule = schedule;
  req.property = property;
  req.userRole = userRole;
  next();
};

module.exports = {
  generateToken,
  verifyToken,
  authenticate,
  requirePropertyOwner,
  requireAdmin,
  validatePropertyAccess,
  validateProjectAccess,
  validateMaintenanceAccess
};