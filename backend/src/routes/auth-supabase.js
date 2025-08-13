const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const bcrypt = require('bcryptjs');
const { userSchemas } = require('../utils/validation');
const { 
  formatValidationError, 
  createResponse, 
  createErrorResponse, 
  sanitizeUser 
} = require('../utils/helpers');
const { generateToken, authenticate } = require('../middleware/auth');

const router = express.Router();

// Initialize Supabase client for direct API calls
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

/**
 * POST /api/v1/auth/login-supabase
 * Authenticate user using Supabase client instead of Knex
 */
router.post('/login-supabase', async (req, res) => {
  try {
    console.log('Supabase login attempt:', { email: req.body.email, hasPassword: !!req.body.password });
    
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

    // Find user by email using Supabase client
    console.log('Querying Supabase for user:', email);
    const { data: users, error: supabaseError } = await supabase
      .from('users')
      .select('*')
      .ilike('email', email)
      .limit(1);
    
    if (supabaseError) {
      console.error('Supabase query error:', supabaseError);
      const { error: errorObj, statusCode } = createErrorResponse('Database error', 500);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }
    
    console.log('Supabase query result:', { found: users?.length > 0, userId: users?.[0]?.id });
    
    if (!users || users.length === 0) {
      console.log('User not found in database');
      const { error: errorObj, statusCode } = createErrorResponse('Invalid credentials', 401);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }
    
    const dbUser = users[0];
    
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

    // Update last login using Supabase client
    const { error: updateError } = await supabase
      .from('users')
      .update({ last_login_at: new Date().toISOString() })
      .eq('id', user.id);
    
    if (updateError) {
      console.warn('Failed to update last login:', updateError);
      // Don't fail the login for this
    }
    
    user.lastLoginAt = new Date().toISOString();

    // Return response
    const responseData = {
      user: sanitizeUser(user),
      token
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Supabase login error - Full details:', error);
    console.error('Error stack:', error.stack);
    console.error('Error message:', error.message);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

module.exports = router;