const Joi = require('joi');

// User validation schemas
const userSchemas = {
  register: Joi.object({
    email: Joi.string().email().required().messages({
      'string.email': 'Please provide a valid email address',
      'any.required': 'Email is required'
    }),
    password: Joi.string()
      .min(8)
      .pattern(new RegExp('^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]'))
      .required()
      .messages({
        'string.min': 'Password must be at least 8 characters long',
        'string.pattern.base': 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character',
        'any.required': 'Password is required'
      }),
    firstName: Joi.string().trim().min(1).max(50).required().messages({
      'string.min': 'First name is required',
      'string.max': 'First name cannot exceed 50 characters',
      'any.required': 'First name is required'
    }),
    lastName: Joi.string().trim().min(1).max(50).required().messages({
      'string.min': 'Last name is required',
      'string.max': 'Last name cannot exceed 50 characters',
      'any.required': 'Last name is required'
    }),
    userType: Joi.string()
      .valid('property_owner', 'family_member', 'contractor', 'tenant', 'realtor')
      .required()
      .messages({
        'any.only': 'User type must be one of: property_owner, family_member, contractor, tenant, realtor',
        'any.required': 'User type is required'
      })
  }),

  login: Joi.object({
    email: Joi.string().email().required().messages({
      'string.email': 'Please provide a valid email address',
      'any.required': 'Email is required'
    }),
    password: Joi.string().required().messages({
      'any.required': 'Password is required'
    })
  }),

  update: Joi.object({
    firstName: Joi.string().trim().min(1).max(50).messages({
      'string.min': 'First name cannot be empty',
      'string.max': 'First name cannot exceed 50 characters'
    }),
    lastName: Joi.string().trim().min(1).max(50).messages({
      'string.min': 'Last name cannot be empty',
      'string.max': 'Last name cannot exceed 50 characters'
    }),
    userType: Joi.string()
      .valid('property_owner', 'family_member', 'contractor', 'tenant', 'realtor')
      .messages({
        'any.only': 'User type must be one of: property_owner, family_member, contractor, tenant, realtor'
      })
  }).min(1).messages({
    'object.min': 'At least one field is required for update'
  })
};

// Property validation schemas
const propertySchemas = {
  create: Joi.object({
    name: Joi.string().trim().min(1).max(100).required().messages({
      'string.min': 'Property name is required',
      'string.max': 'Property name cannot exceed 100 characters',
      'any.required': 'Property name is required'
    }),
    address: Joi.object({
      street: Joi.string().trim().min(1).max(200).required().messages({
        'string.min': 'Street address is required',
        'string.max': 'Street address cannot exceed 200 characters',
        'any.required': 'Street address is required'
      }),
      city: Joi.string().trim().min(1).max(100).required().messages({
        'string.min': 'City is required',
        'string.max': 'City cannot exceed 100 characters',
        'any.required': 'City is required'
      }),
      state: Joi.string().trim().min(1).max(50).required().messages({
        'string.min': 'State is required',
        'string.max': 'State cannot exceed 50 characters',
        'any.required': 'State is required'
      }),
      zipCode: Joi.string().trim().min(1).max(20).required().messages({
        'string.min': 'ZIP code is required',
        'string.max': 'ZIP code cannot exceed 20 characters',
        'any.required': 'ZIP code is required'
      }),
      country: Joi.string().trim().min(1).max(50).required().messages({
        'string.min': 'Country is required',
        'string.max': 'Country cannot exceed 50 characters',
        'any.required': 'Country is required'
      })
    }).required(),
    propertyType: Joi.string()
      .valid('single_family', 'condo', 'townhouse', 'apartment', 'mobile_home', 'other')
      .required()
      .messages({
        'any.only': 'Property type must be one of: single_family, condo, townhouse, apartment, mobile_home, other',
        'any.required': 'Property type is required'
      }),
    yearBuilt: Joi.number().integer().min(1800).max(new Date().getFullYear()).messages({
      'number.min': 'Year built cannot be earlier than 1800',
      'number.max': `Year built cannot be later than ${new Date().getFullYear()}`
    }),
    squareFootage: Joi.number().positive().messages({
      'number.positive': 'Square footage must be a positive number'
    }),
    bedrooms: Joi.number().integer().min(0).messages({
      'number.min': 'Bedrooms cannot be negative'
    }),
    bathrooms: Joi.number().min(0).messages({
      'number.min': 'Bathrooms cannot be negative'
    }),
    description: Joi.string().max(1000).messages({
      'string.max': 'Description cannot exceed 1000 characters'
    })
  }),

  update: Joi.object({
    name: Joi.string().trim().min(1).max(100).messages({
      'string.min': 'Property name cannot be empty',
      'string.max': 'Property name cannot exceed 100 characters'
    }),
    address: Joi.object({
      street: Joi.string().trim().min(1).max(200).messages({
        'string.min': 'Street address cannot be empty',
        'string.max': 'Street address cannot exceed 200 characters'
      }),
      city: Joi.string().trim().min(1).max(100).messages({
        'string.min': 'City cannot be empty',
        'string.max': 'City cannot exceed 100 characters'
      }),
      state: Joi.string().trim().min(1).max(50).messages({
        'string.min': 'State cannot be empty',
        'string.max': 'State cannot exceed 50 characters'
      }),
      zipCode: Joi.string().trim().min(1).max(20).messages({
        'string.min': 'ZIP code cannot be empty',
        'string.max': 'ZIP code cannot exceed 20 characters'
      }),
      country: Joi.string().trim().min(1).max(50).messages({
        'string.min': 'Country cannot be empty',
        'string.max': 'Country cannot exceed 50 characters'
      })
    }),
    propertyType: Joi.string()
      .valid('single_family', 'condo', 'townhouse', 'apartment', 'mobile_home', 'other')
      .messages({
        'any.only': 'Property type must be one of: single_family, condo, townhouse, apartment, mobile_home, other'
      }),
    yearBuilt: Joi.number().integer().min(1800).max(new Date().getFullYear()).messages({
      'number.min': 'Year built cannot be earlier than 1800',
      'number.max': `Year built cannot be later than ${new Date().getFullYear()}`
    }),
    squareFootage: Joi.number().positive().messages({
      'number.positive': 'Square footage must be a positive number'
    }),
    bedrooms: Joi.number().integer().min(0).messages({
      'number.min': 'Bedrooms cannot be negative'
    }),
    bathrooms: Joi.number().min(0).messages({
      'number.min': 'Bathrooms cannot be negative'
    }),
    description: Joi.string().max(1000).messages({
      'string.max': 'Description cannot exceed 1000 characters'
    })
  }).min(1).messages({
    'object.min': 'At least one field is required for update'
  })
};

// Project validation schemas
const projectSchemas = {
  create: Joi.object({
    title: Joi.string().trim().min(1).max(200).required().messages({
      'string.min': 'Project title is required',
      'string.max': 'Project title cannot exceed 200 characters',
      'any.required': 'Project title is required'
    }),
    description: Joi.string().trim().min(1).max(2000).required().messages({
      'string.min': 'Project description is required',
      'string.max': 'Project description cannot exceed 2000 characters',
      'any.required': 'Project description is required'
    }),
    category: Joi.string()
      .valid('plumbing', 'electrical', 'hvac', 'interior', 'exterior', 'cosmetic', 'landscaping', 'other')
      .required()
      .messages({
        'any.only': 'Category must be one of: plumbing, electrical, hvac, interior, exterior, cosmetic, landscaping, other',
        'any.required': 'Category is required'
      }),
    priority: Joi.string()
      .valid('low', 'medium', 'high', 'urgent')
      .default('medium')
      .messages({
        'any.only': 'Priority must be one of: low, medium, high, urgent'
      }),
    propertyId: Joi.string().required().messages({
      'any.required': 'Property ID is required'
    }),
    status: Joi.string()
      .valid('not_started', 'in_progress', 'completed', 'on_hold', 'cancelled')
      .default('not_started')
      .messages({
        'any.only': 'Status must be one of: not_started, in_progress, completed, on_hold, cancelled'
      }),
    estimatedCompletionDate: Joi.date().messages({
      'date.base': 'Estimated completion date must be a valid date'
    }),
    actualCompletionDate: Joi.date().messages({
      'date.base': 'Actual completion date must be a valid date'
    }),
    tasks: Joi.array().items(
      Joi.object({
        title: Joi.string().trim().min(1).max(200).required().messages({
          'string.min': 'Task title is required',
          'string.max': 'Task title cannot exceed 200 characters',
          'any.required': 'Task title is required'
        }),
        description: Joi.string().max(500).messages({
          'string.max': 'Task description cannot exceed 500 characters'
        }),
        completed: Joi.boolean().default(false),
        completedDate: Joi.date().messages({
          'date.base': 'Completed date must be a valid date'
        })
      })
    ).messages({
      'array.base': 'Tasks must be an array'
    })
  }),

  update: Joi.object({
    title: Joi.string().trim().min(1).max(200).messages({
      'string.min': 'Project title cannot be empty',
      'string.max': 'Project title cannot exceed 200 characters'
    }),
    description: Joi.string().trim().min(1).max(2000).messages({
      'string.min': 'Project description cannot be empty',
      'string.max': 'Project description cannot exceed 2000 characters'
    }),
    category: Joi.string()
      .valid('plumbing', 'electrical', 'hvac', 'interior', 'exterior', 'cosmetic', 'landscaping', 'other')
      .messages({
        'any.only': 'Category must be one of: plumbing, electrical, hvac, interior, exterior, cosmetic, landscaping, other'
      }),
    priority: Joi.string()
      .valid('low', 'medium', 'high', 'urgent')
      .messages({
        'any.only': 'Priority must be one of: low, medium, high, urgent'
      }),
    status: Joi.string()
      .valid('not_started', 'in_progress', 'completed', 'on_hold', 'cancelled')
      .messages({
        'any.only': 'Status must be one of: not_started, in_progress, completed, on_hold, cancelled'
      }),
    estimatedCompletionDate: Joi.date().messages({
      'date.base': 'Estimated completion date must be a valid date'
    }),
    actualCompletionDate: Joi.date().messages({
      'date.base': 'Actual completion date must be a valid date'
    }),
    tasks: Joi.array().items(
      Joi.object({
        title: Joi.string().trim().min(1).max(200).required().messages({
          'string.min': 'Task title is required',
          'string.max': 'Task title cannot exceed 200 characters',
          'any.required': 'Task title is required'
        }),
        description: Joi.string().max(500).messages({
          'string.max': 'Task description cannot exceed 500 characters'
        }),
        completed: Joi.boolean().default(false),
        completedDate: Joi.date().messages({
          'date.base': 'Completed date must be a valid date'
        })
      })
    ).messages({
      'array.base': 'Tasks must be an array'
    })
  }).min(1).messages({
    'object.min': 'At least one field is required for update'
  }),

  assign: Joi.object({
    userId: Joi.string().required().messages({
      'any.required': 'User ID is required'
    }),
    role: Joi.string()
      .valid('assignee', 'contractor', 'supervisor')
      .required()
      .messages({
        'any.only': 'Role must be one of: assignee, contractor, supervisor',
        'any.required': 'Role is required'
      })
  })
};

// Maintenance schedule validation schemas
const maintenanceSchemas = {
  create: Joi.object({
    title: Joi.string().trim().min(1).max(200).required().messages({
      'string.min': 'Schedule title is required',
      'string.max': 'Schedule title cannot exceed 200 characters',
      'any.required': 'Schedule title is required'
    }),
    description: Joi.string().trim().min(1).max(2000).required().messages({
      'string.min': 'Schedule description is required',
      'string.max': 'Schedule description cannot exceed 2000 characters',
      'any.required': 'Schedule description is required'
    }),
    category: Joi.string()
      .valid('hvac', 'plumbing', 'electrical', 'exterior', 'interior', 'appliances', 'safety', 'landscaping', 'other')
      .required()
      .messages({
        'any.only': 'Category must be one of: hvac, plumbing, electrical, exterior, interior, appliances, safety, landscaping, other',
        'any.required': 'Category is required'
      }),
    propertyId: Joi.string().required().messages({
      'any.required': 'Property ID is required'
    }),
    frequency: Joi.string()
      .valid('daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'biannual', 'yearly', 'seasonal', 'as_needed')
      .required()
      .messages({
        'any.only': 'Frequency must be one of: daily, weekly, biweekly, monthly, quarterly, biannual, yearly, seasonal, as_needed',
        'any.required': 'Frequency is required'
      }),
    priority: Joi.string()
      .valid('low', 'medium', 'high', 'urgent')
      .default('medium')
      .messages({
        'any.only': 'Priority must be one of: low, medium, high, urgent'
      }),
    estimatedDuration: Joi.number().positive().messages({
      'number.positive': 'Estimated duration must be a positive number (in minutes)'
    }),
    instructions: Joi.string().max(2000).messages({
      'string.max': 'Instructions cannot exceed 2000 characters'
    }),
    nextDueDate: Joi.date().messages({
      'date.base': 'Next due date must be a valid date'
    }),
    isActive: Joi.boolean().default(true)
  }),

  update: Joi.object({
    title: Joi.string().trim().min(1).max(200).messages({
      'string.min': 'Schedule title cannot be empty',
      'string.max': 'Schedule title cannot exceed 200 characters'
    }),
    description: Joi.string().trim().min(1).max(2000).messages({
      'string.min': 'Schedule description cannot be empty',
      'string.max': 'Schedule description cannot exceed 2000 characters'
    }),
    category: Joi.string()
      .valid('hvac', 'plumbing', 'electrical', 'exterior', 'interior', 'appliances', 'safety', 'landscaping', 'other')
      .messages({
        'any.only': 'Category must be one of: hvac, plumbing, electrical, exterior, interior, appliances, safety, landscaping, other'
      }),
    frequency: Joi.string()
      .valid('daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'biannual', 'yearly', 'seasonal', 'as_needed')
      .messages({
        'any.only': 'Frequency must be one of: daily, weekly, biweekly, monthly, quarterly, biannual, yearly, seasonal, as_needed'
      }),
    priority: Joi.string()
      .valid('low', 'medium', 'high', 'urgent')
      .messages({
        'any.only': 'Priority must be one of: low, medium, high, urgent'
      }),
    estimatedDuration: Joi.number().positive().messages({
      'number.positive': 'Estimated duration must be a positive number (in minutes)'
    }),
    instructions: Joi.string().max(2000).messages({
      'string.max': 'Instructions cannot exceed 2000 characters'
    }),
    nextDueDate: Joi.date().messages({
      'date.base': 'Next due date must be a valid date'
    }),
    isActive: Joi.boolean()
  }).min(1).messages({
    'object.min': 'At least one field is required for update'
  }),

  complete: Joi.object({
    completedDate: Joi.date().required().messages({
      'date.base': 'Completed date must be a valid date',
      'any.required': 'Completed date is required'
    }),
    notes: Joi.string().max(1000).messages({
      'string.max': 'Notes cannot exceed 1000 characters'
    }),
    actualDuration: Joi.number().positive().messages({
      'number.positive': 'Actual duration must be a positive number (in minutes)'
    }),
    nextDueDate: Joi.date().messages({
      'date.base': 'Next due date must be a valid date'
    })
  })
};

// Permission validation schemas
const permissionSchemas = {
  grant: Joi.object({
    userId: Joi.string().required().messages({
      'any.required': 'User ID is required'
    }),
    role: Joi.string()
      .valid('viewer', 'editor', 'admin', 'contractor', 'tenant')
      .required()
      .messages({
        'any.only': 'Role must be one of: viewer, editor, admin, contractor, tenant',
        'any.required': 'Role is required'
      }),
    permissions: Joi.object({
      viewProjects: Joi.boolean().default(false),
      createProjects: Joi.boolean().default(false),
      editProjects: Joi.boolean().default(false),
      deleteProjects: Joi.boolean().default(false),
      viewMaintenance: Joi.boolean().default(false),
      manageMaintenance: Joi.boolean().default(false),
      viewFinancials: Joi.boolean().default(false),
      manageVendors: Joi.boolean().default(false)
    })
  }),

  update: Joi.object({
    role: Joi.string()
      .valid('viewer', 'editor', 'admin', 'contractor', 'tenant')
      .messages({
        'any.only': 'Role must be one of: viewer, editor, admin, contractor, tenant'
      }),
    permissions: Joi.object({
      viewProjects: Joi.boolean(),
      createProjects: Joi.boolean(),
      editProjects: Joi.boolean(),
      deleteProjects: Joi.boolean(),
      viewMaintenance: Joi.boolean(),
      manageMaintenance: Joi.boolean(),
      viewFinancials: Joi.boolean(),
      manageVendors: Joi.boolean()
    })
  }).min(1).messages({
    'object.min': 'At least one field is required for update'
  })
};

module.exports = {
  userSchemas,
  propertySchemas,
  projectSchemas,
  maintenanceSchemas,
  permissionSchemas
};