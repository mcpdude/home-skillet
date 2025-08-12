const { v4: uuidv4 } = require('uuid');

/**
 * Generate a unique ID
 */
const generateId = () => {
  return uuidv4();
};

/**
 * Format validation error details from Joi
 */
const formatValidationError = (error) => {
  const details = error.details.map(detail => ({
    field: detail.path.join('.'),
    message: detail.message,
    value: detail.context?.value
  }));

  return {
    message: 'Validation failed',
    details
  };
};

/**
 * Create a standardized API response
 */
const createResponse = (success, data = null, error = null) => {
  const response = { success };
  
  if (success && data) {
    response.data = data;
  }
  
  if (!success && error) {
    response.error = error;
  }
  
  return response;
};

/**
 * Create error response with standard format
 */
const createErrorResponse = (message, statusCode = 500, details = null) => {
  const error = { message };
  if (details) {
    error.details = details;
  }
  return { error, statusCode };
};

/**
 * Remove sensitive fields from user object
 */
const sanitizeUser = (user) => {
  if (!user) return null;
  
  const { password, ...sanitizedUser } = user;
  return sanitizedUser;
};

/**
 * Check if user has access to property
 */
const hasPropertyAccess = (userId, property, userPropertyRoles = []) => {
  // Owner has full access
  if (property.ownerId === userId) {
    return true;
  }
  
  // Check if user has been granted access through permissions
  const userRole = userPropertyRoles.find(
    role => role.userId === userId && role.propertyId === property.id
  );
  
  return !!userRole;
};

/**
 * Check if user has permission for specific action on property
 */
const hasPermission = (userId, property, action, userPropertyRoles = []) => {
  // Owner has all permissions
  if (property.ownerId === userId) {
    return true;
  }
  
  // Find user's role for this property
  const userRole = userPropertyRoles.find(
    role => role.userId === userId && role.propertyId === property.id
  );
  
  if (!userRole) {
    return false;
  }
  
  // Check specific permission
  return userRole.permissions[action] === true;
};

/**
 * Check if user has access to project
 */
const hasProjectAccess = (userId, project, properties = [], userPropertyRoles = [], projectAssignments = []) => {
  // Find the property this project belongs to
  const property = properties.find(p => p.id === project.propertyId);
  if (!property) {
    return false;
  }
  
  // Property owner has access
  if (property.ownerId === userId) {
    return true;
  }
  
  // Check if user is assigned to this project
  const isAssigned = projectAssignments.some(
    assignment => assignment.userId === userId && assignment.projectId === project.id
  );
  
  if (isAssigned) {
    return true;
  }
  
  // Check property-level permissions
  return hasPropertyAccess(userId, property, userPropertyRoles);
};

/**
 * Check if user has access to maintenance schedule
 */
const hasMaintenanceAccess = (userId, schedule, properties = [], userPropertyRoles = []) => {
  // Find the property this schedule belongs to
  const property = properties.find(p => p.id === schedule.propertyId);
  if (!property) {
    return false;
  }
  
  // Property owner has access
  if (property.ownerId === userId) {
    return true;
  }
  
  // Check property-level permissions
  return hasPropertyAccess(userId, property, userPropertyRoles);
};

/**
 * Filter objects by query parameters
 */
const filterByQuery = (items, query) => {
  if (!query || Object.keys(query).length === 0) {
    return items;
  }
  
  return items.filter(item => {
    return Object.entries(query).every(([key, value]) => {
      if (value === undefined || value === null) {
        return true;
      }
      
      // Handle boolean values
      if (typeof value === 'string' && (value.toLowerCase() === 'true' || value.toLowerCase() === 'false')) {
        return item[key] === (value.toLowerCase() === 'true');
      }
      
      // Handle string matching
      if (typeof item[key] === 'string') {
        return item[key].toLowerCase().includes(value.toLowerCase());
      }
      
      // Handle exact matching
      return item[key] === value;
    });
  });
};

/**
 * Sort items by specified field and direction
 */
const sortItems = (items, sortBy = 'createdAt', sortOrder = 'desc') => {
  return [...items].sort((a, b) => {
    let aValue = a[sortBy];
    let bValue = b[sortBy];
    
    // Handle date strings
    if (typeof aValue === 'string' && Date.parse(aValue)) {
      aValue = new Date(aValue);
    }
    if (typeof bValue === 'string' && Date.parse(bValue)) {
      bValue = new Date(bValue);
    }
    
    // Handle comparison
    if (aValue < bValue) {
      return sortOrder === 'asc' ? -1 : 1;
    }
    if (aValue > bValue) {
      return sortOrder === 'asc' ? 1 : -1;
    }
    return 0;
  });
};

/**
 * Paginate results
 */
const paginateResults = (items, page = 1, limit = 50) => {
  const startIndex = (page - 1) * limit;
  const endIndex = startIndex + limit;
  
  return {
    items: items.slice(startIndex, endIndex),
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total: items.length,
      pages: Math.ceil(items.length / limit)
    }
  };
};

/**
 * Calculate next due date based on frequency
 */
const calculateNextDueDate = (frequency, currentDate = new Date()) => {
  const date = new Date(currentDate);
  
  switch (frequency) {
    case 'daily':
      date.setDate(date.getDate() + 1);
      break;
    case 'weekly':
      date.setDate(date.getDate() + 7);
      break;
    case 'biweekly':
      date.setDate(date.getDate() + 14);
      break;
    case 'monthly':
      date.setMonth(date.getMonth() + 1);
      break;
    case 'quarterly':
      date.setMonth(date.getMonth() + 3);
      break;
    case 'biannual':
      date.setMonth(date.getMonth() + 6);
      break;
    case 'yearly':
      date.setFullYear(date.getFullYear() + 1);
      break;
    case 'seasonal':
      date.setMonth(date.getMonth() + 3);
      break;
    case 'as_needed':
    default:
      return null; // No automatic next due date
  }
  
  return date;
};

/**
 * Deep clone an object
 */
const deepClone = (obj) => {
  return JSON.parse(JSON.stringify(obj));
};

module.exports = {
  generateId,
  formatValidationError,
  createResponse,
  createErrorResponse,
  sanitizeUser,
  hasPropertyAccess,
  hasPermission,
  hasProjectAccess,
  hasMaintenanceAccess,
  filterByQuery,
  sortItems,
  paginateResults,
  calculateNextDueDate,
  deepClone
};