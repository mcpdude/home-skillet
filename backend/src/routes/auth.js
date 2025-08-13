const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { createClient } = require('@supabase/supabase-js');
const { userSchemas } = require('../utils/validation');
const { 
  formatValidationError, 
  createResponse, 
  createErrorResponse, 
  sanitizeUser 
} = require('../utils/helpers');
const { generateToken, authenticate } = require('../middleware/auth');

const router = express.Router();

// Initialize Supabase client for direct API calls with validation
let supabase = null;
try {
  if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
    console.warn('Missing Supabase environment variables, will fallback to direct DB');
  } else {
    console.log('Initializing Supabase client...');
    console.log('SUPABASE_URL:', process.env.SUPABASE_URL ? 'Set' : 'Missing');
    console.log('SERVICE_ROLE_KEY length:', process.env.SUPABASE_SERVICE_ROLE_KEY?.length || 0);
    
    supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    console.log('Supabase client initialized successfully');
  }
} catch (error) {
  console.error('Failed to initialize Supabase client:', error);
}

// Test endpoint to check database connectivity (disabled in production)
router.get('/test-db', async (req, res) => {
  // Skip database test in production to avoid connection pool issues
  if (process.env.NODE_ENV === 'production') {
    return res.json({
      success: true,
      message: 'Database test disabled in production',
      environment: 'production'
    });
  }
  
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

    // Check if user already exists - try Supabase first, fallback to direct DB
    let existingUser = null;
    let useDirectDB = false;
    
    if (supabase) {
      try {
        console.log('Checking existing user with Supabase:', email);
        const { data: users, error: supabaseError } = await supabase
          .from('users')
          .select('id, email')
          .ilike('email', email)
          .limit(1);
        
        if (supabaseError) {
          console.error('Supabase user check error:', supabaseError);
          console.log('Falling back to direct database connection...');
          useDirectDB = true;
        } else if (users && users.length > 0) {
          existingUser = users[0];
        }
      } catch (error) {
        console.error('Supabase client error:', error);
        console.log('Falling back to direct database connection...');
        useDirectDB = true;
      }
    } else {
      useDirectDB = true;
    }
    
    // Fallback to direct database connection if needed
    if (!existingUser && useDirectDB) {
      console.log('Using direct database connection to check existing user:', email);
      try {
        existingUser = await db('users')
          .where(db.raw('LOWER(email) = LOWER(?)', [email]))
          .first();
      } catch (dbError) {
        console.error('Direct database query failed:', dbError);
        const { error: errorObj, statusCode } = createErrorResponse('Database error', 500);
        return res.status(statusCode).json(createResponse(false, null, errorObj));
      }
    }
    
    if (existingUser) {
      const { error: errorObj, statusCode } = createErrorResponse('User with this email already exists', 409);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Hash password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Create new user - try Supabase first, fallback to direct DB
    let newUser = null;
    
    if (supabase) {
      try {
        console.log('Creating user with Supabase:', email);
        const { data, error: supabaseError } = await supabase
          .from('users')
          .insert({
            email: email.toLowerCase(),
            password: hashedPassword,
            first_name: firstName,
            last_name: lastName,
            user_type: userType
          })
          .select('id, email, first_name, last_name, user_type, created_at, updated_at')
          .single();
        
        if (supabaseError) {
          console.error('Supabase user creation error:', supabaseError);
          console.log('Falling back to direct database connection...');
        } else {
          newUser = data;
        }
      } catch (error) {
        console.error('Supabase client error during user creation:', error);
        console.log('Falling back to direct database connection...');
      }
    }
    
    // Fallback to direct database connection if Supabase failed
    if (!newUser) {
      console.log('Using direct database connection to create user:', email);
      try {
        const [createdUser] = await db('users')
          .insert({
            email: email.toLowerCase(),
            password: hashedPassword,
            first_name: firstName,
            last_name: lastName,
            user_type: userType
          })
          .returning(['id', 'email', 'first_name', 'last_name', 'user_type', 'created_at', 'updated_at']);
        newUser = createdUser;
      } catch (dbError) {
        console.error('Direct database user creation failed:', dbError);
        const { error: errorObj, statusCode } = createErrorResponse('Database error', 500);
        return res.status(statusCode).json(createResponse(false, null, errorObj));
      }
    }
    
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

    // Try Supabase client first, fallback to direct DB if needed
    let dbUser = null;
    
    if (supabase) {
      try {
        console.log('Querying Supabase for user:', email);
        const { data: users, error: supabaseError } = await supabase
          .from('users')
          .select('*')
          .ilike('email', email)
          .limit(1);
        
        if (supabaseError) {
          console.error('Supabase query error:', supabaseError);
          console.log('Falling back to direct database connection...');
        } else {
          console.log('Supabase query result:', { found: users?.length > 0, userId: users?.[0]?.id });
          if (users && users.length > 0) {
            dbUser = users[0];
          }
        }
      } catch (error) {
        console.error('Supabase client error:', error);
        console.log('Falling back to direct database connection...');
      }
    }
    
    // Fallback to direct database connection if Supabase failed
    if (!dbUser) {
      console.log('Using direct database connection for user:', email);
      try {
        dbUser = await db('users')
          .where(db.raw('LOWER(email) = LOWER(?)', [email]))
          .first();
        console.log('Direct DB query result:', { found: !!dbUser, userId: dbUser?.id });
      } catch (dbError) {
        console.error('Direct database query failed:', dbError);
        const { error: errorObj, statusCode } = createErrorResponse('Database error', 500);
        return res.status(statusCode).json(createResponse(false, null, errorObj));
      }
    }
    
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

    // Update last login with fallback mechanism
    try {
      if (supabase) {
        const { error: updateError } = await supabase
          .from('users')
          .update({ last_login_at: new Date().toISOString() })
          .eq('id', user.id);
        
        if (updateError) {
          console.warn('Supabase update failed, trying direct DB:', updateError);
          await db('users')
            .where('id', user.id)
            .update({ last_login_at: new Date() });
        }
      } else {
        await db('users')
          .where('id', user.id)
          .update({ last_login_at: new Date() });
      }
    } catch (updateError) {
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
 * POST /api/v1/auth/forgot-password
 * Request password reset (generates reset token)
 */
router.post('/forgot-password', async (req, res) => {
  try {
    const { error, value } = userSchemas.forgotPassword?.validate?.(req.body) || { value: req.body };
    if (error) {
      const validationError = formatValidationError(error);
      const { error: errorObj, statusCode } = createErrorResponse(validationError.message, 400, validationError.details);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const { email } = value;
    console.log('Password reset requested for:', email);

    // Find user - try Supabase first, fallback to direct DB
    let user = null;
    let useDirectDB = false;
    
    if (supabase) {
      try {
        const { data: users, error: supabaseError } = await supabase
          .from('users')
          .select('id, email, first_name')
          .ilike('email', email)
          .limit(1);
        
        if (supabaseError) {
          console.error('Supabase user lookup error:', supabaseError);
          useDirectDB = true;
        } else if (users && users.length > 0) {
          user = users[0];
        }
      } catch (error) {
        console.error('Supabase client error:', error);
        useDirectDB = true;
      }
    } else {
      useDirectDB = true;
    }
    
    if (!user && useDirectDB) {
      try {
        const dbUser = await db('users')
          .where(db.raw('LOWER(email) = LOWER(?)', [email]))
          .select('id', 'email', 'first_name')
          .first();
        if (dbUser) {
          user = dbUser;
        }
      } catch (dbError) {
        console.error('Direct database query failed:', dbError);
        // Still return success for security - don't reveal if email exists
      }
    }

    // Always return success for security (don't reveal if email exists)
    const responseData = {
      message: 'If an account with this email exists, a password reset link has been sent.'
    };

    // If user exists, generate reset token (in real app, send email here)
    if (user) {
      const resetToken = require('crypto').randomBytes(32).toString('hex');
      const resetExpires = new Date(Date.now() + 3600000); // 1 hour from now

      // Store reset token - try Supabase first, fallback to direct DB
      try {
        if (supabase) {
          const { error: updateError } = await supabase
            .from('users')
            .update({
              reset_password_token: resetToken,
              reset_password_expires: resetExpires.toISOString()
            })
            .eq('id', user.id);
          
          if (updateError) {
            console.error('Supabase reset token update failed:', updateError);
            // Fallback to direct DB
            await db('users')
              .where('id', user.id)
              .update({
                reset_password_token: resetToken,
                reset_password_expires: resetExpires
              });
          }
        } else {
          await db('users')
            .where('id', user.id)
            .update({
              reset_password_token: resetToken,
              reset_password_expires: resetExpires
            });
        }

        console.log(`Password reset token generated for user ${user.id}`);
        // In production: Send email with reset link containing the token
        // For development: Log the reset token (remove this in production!)
        if (process.env.NODE_ENV !== 'production') {
          console.log(`🔑 Password reset token for ${email}: ${resetToken}`);
        }
      } catch (updateError) {
        console.error('Failed to store reset token:', updateError);
      }
    }

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Forgot password error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * POST /api/v1/auth/reset-password
 * Reset password using token
 */
router.post('/reset-password', async (req, res) => {
  try {
    const { error, value } = userSchemas.resetPassword?.validate?.(req.body) || { value: req.body };
    if (error) {
      const validationError = formatValidationError(error);
      const { error: errorObj, statusCode } = createErrorResponse(validationError.message, 400, validationError.details);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const { token, newPassword } = value;
    console.log('Password reset attempt with token');

    // Find user by reset token - try Supabase first, fallback to direct DB
    let user = null;
    let useDirectDB = false;
    
    if (supabase) {
      try {
        const { data: users, error: supabaseError } = await supabase
          .from('users')
          .select('id, email, reset_password_token, reset_password_expires')
          .eq('reset_password_token', token)
          .limit(1);
        
        if (supabaseError) {
          console.error('Supabase token lookup error:', supabaseError);
          useDirectDB = true;
        } else if (users && users.length > 0) {
          user = users[0];
        }
      } catch (error) {
        console.error('Supabase client error:', error);
        useDirectDB = true;
      }
    } else {
      useDirectDB = true;
    }
    
    if (!user && useDirectDB) {
      try {
        user = await db('users')
          .where('reset_password_token', token)
          .select('id', 'email', 'reset_password_token', 'reset_password_expires')
          .first();
      } catch (dbError) {
        console.error('Direct database query failed:', dbError);
        const { error: errorObj, statusCode } = createErrorResponse('Database error', 500);
        return res.status(statusCode).json(createResponse(false, null, errorObj));
      }
    }

    if (!user || !user.reset_password_token) {
      const { error: errorObj, statusCode } = createErrorResponse('Invalid or expired reset token', 400);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Check if token is expired
    const tokenExpires = new Date(user.reset_password_expires);
    if (tokenExpires < new Date()) {
      const { error: errorObj, statusCode } = createErrorResponse('Reset token has expired', 400);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Hash new password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

    // Update password and clear reset token - try Supabase first, fallback to direct DB
    try {
      if (supabase) {
        const { error: updateError } = await supabase
          .from('users')
          .update({
            password: hashedPassword,
            reset_password_token: null,
            reset_password_expires: null,
            updated_at: new Date().toISOString()
          })
          .eq('id', user.id);
        
        if (updateError) {
          console.error('Supabase password update failed:', updateError);
          // Fallback to direct DB
          await db('users')
            .where('id', user.id)
            .update({
              password: hashedPassword,
              reset_password_token: null,
              reset_password_expires: null,
              updated_at: new Date()
            });
        }
      } else {
        await db('users')
          .where('id', user.id)
          .update({
            password: hashedPassword,
            reset_password_token: null,
            reset_password_expires: null,
            updated_at: new Date()
          });
      }

      console.log(`Password successfully reset for user ${user.id}`);
      
      const responseData = {
        message: 'Password has been successfully reset'
      };

      return res.status(200).json(createResponse(true, responseData));

    } catch (updateError) {
      console.error('Failed to update password:', updateError);
      const { error: errorObj, statusCode } = createErrorResponse('Failed to reset password', 500);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

  } catch (error) {
    console.error('Reset password error:', error);
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