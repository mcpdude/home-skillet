const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { userSchemas } = require('../utils/validation');
const { 
  formatValidationError, 
  createResponse, 
  createErrorResponse, 
  sanitizeUser 
} = require('../utils/helpers');
const { generateToken, authenticate } = require('../middleware/auth');

const router = express.Router();

// Test endpoint to check database connectivity
router.get('/test-db', async (req, res) => {
  try {
    console.log('Testing database connection...');
    const result = await db('users').count('id as count').first();
    console.log('Database test result:', result);
    return res.json({
      success: true,
      message: 'Database connected',
      userCount: result.count
    });
  } catch (error) {
    console.error('Database test error:', error);
    return res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * POST /api/v1/auth/register
 * Register a new user
 */
router.post('/register', async (req, res) => {
  try {
    // Validate request body
    const { error, value } = userSchemas.register.validate(req.body);
    if (error) {
      const validationError = formatValidationError(error);
      const { error: errorObj, statusCode } = createErrorResponse(validationError.message, 400, validationError.details);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const { email, password, firstName, lastName, userType } = value;

    // Check if user already exists
    const existingUser = await db('users')
      .where(db.raw('LOWER(email) = LOWER(?)', [email]))
      .first();
    if (existingUser) {
      const { error: errorObj, statusCode } = createErrorResponse('User with this email already exists', 409);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Hash password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Create new user
    const [newUser] = await db('users')
      .insert({
        email: email.toLowerCase(),
        password: hashedPassword,
        first_name: firstName,
        last_name: lastName,
        user_type: userType
      })
      .returning(['id', 'email', 'first_name', 'last_name', 'user_type', 'created_at', 'updated_at']);
    
    // Transform to match expected format
    const userForToken = {
      id: newUser.id,
      email: newUser.email,
      firstName: newUser.first_name,
      lastName: newUser.last_name,
      userType: newUser.user_type,
      createdAt: newUser.created_at,
      updatedAt: newUser.updated_at
    };

    // Generate JWT token
    const token = generateToken(userForToken);

    // Return response
    const responseData = {
      user: sanitizeUser(userForToken),
      token
    };

    return res.status(201).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Registration error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * POST /api/v1/auth/login
 * Authenticate user and return JWT token
 */
router.post('/login', async (req, res) => {
  try {
    console.log('Login attempt:', { email: req.body.email, hasPassword: !!req.body.password });
    
    // Validate request body
    const { error, value } = userSchemas.login.validate(req.body);
    if (error) {
      console.log('Validation error:', error.details);
      const validationError = formatValidationError(error);
      const { error: errorObj, statusCode } = createErrorResponse(validationError.message, 400, validationError.details);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const { email, password } = value;
    console.log('Validated input:', { email, hasPassword: !!password });

    // Find user by email
    console.log('Querying database for user:', email);
    const dbUser = await db('users')
      .where(db.raw('LOWER(email) = LOWER(?)', [email]))
      .first();
    console.log('Database query result:', { found: !!dbUser, userId: dbUser?.id });
    
    if (!dbUser) {
      console.log('User not found in database');
      const { error: errorObj, statusCode } = createErrorResponse('Invalid credentials', 401);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }
    
    // Transform to expected format
    const user = {
      id: dbUser.id,
      email: dbUser.email,
      password: dbUser.password,
      firstName: dbUser.first_name,
      lastName: dbUser.last_name,
      userType: dbUser.user_type,
      createdAt: dbUser.created_at,
      updatedAt: dbUser.updated_at
    };

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      const { error: errorObj, statusCode } = createErrorResponse('Invalid credentials', 401);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Generate JWT token
    const token = generateToken(user);

    // Update last login
    await db('users')
      .where('id', user.id)
      .update({ last_login_at: new Date() });
    user.lastLoginAt = new Date().toISOString();

    // Return response
    const responseData = {
      user: sanitizeUser(user),
      token
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Login error - Full details:', error);
    console.error('Error stack:', error.stack);
    console.error('Error message:', error.message);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * GET /api/v1/auth/me
 * Get current user profile
 */
router.get('/me', authenticate, async (req, res) => {
  try {
    const responseData = {
      user: req.user
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Profile retrieval error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * PUT /api/v1/auth/me
 * Update current user profile
 */
router.put('/me', authenticate, async (req, res) => {
  try {
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
    
    const [updatedDbUser] = await db('users')
      .where('id', req.user.id)
      .update(updateData)
      .returning(['id', 'email', 'first_name', 'last_name', 'user_type', 'created_at', 'updated_at']);
    
    if (!updatedDbUser) {
      const { error: errorObj, statusCode } = createErrorResponse('User not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }
    
    // Transform to expected format
    const updatedUser = {
      id: updatedDbUser.id,
      email: updatedDbUser.email,
      firstName: updatedDbUser.first_name,
      lastName: updatedDbUser.last_name,
      userType: updatedDbUser.user_type,
      createdAt: updatedDbUser.created_at,
      updatedAt: updatedDbUser.updated_at
    };

    // Return response
    const responseData = {
      user: sanitizeUser(updatedUser)
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Profile update error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * POST /api/v1/auth/logout
 * Logout user (client-side token removal)
 */
router.post('/logout', authenticate, async (req, res) => {
  try {
    // In a real application, you might want to blacklist the token
    // For this MVP, logout is handled client-side by removing the token
    
    const responseData = {
      message: 'Logged out successfully'
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Logout error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

module.exports = router;