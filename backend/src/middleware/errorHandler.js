const { createResponse, createErrorResponse } = require('../utils/helpers');

/**
 * Global error handling middleware
 */
const errorHandler = (err, req, res, next) => {
  console.error('Global error handler:', err);

  // Handle different types of errors
  let statusCode = 500;
  let message = 'Internal server error';
  let details = null;

  // Validation errors
  if (err.name === 'ValidationError') {
    statusCode = 400;
    message = 'Validation failed';
    details = err.details || null;
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    statusCode = 401;
    message = 'Invalid token';
  }

  if (err.name === 'TokenExpiredError') {
    statusCode = 401;
    message = 'Token expired';
  }

  // MongoDB/Database errors (for future implementation)
  if (err.name === 'CastError') {
    statusCode = 400;
    message = 'Invalid ID format';
  }

  if (err.code === 11000) { // Duplicate key error
    statusCode = 409;
    message = 'Resource already exists';
  }

  // Custom API errors
  if (err.statusCode) {
    statusCode = err.statusCode;
    message = err.message;
    details = err.details || null;
  }

  const { error } = createErrorResponse(message, statusCode, details);
  return res.status(statusCode).json(createResponse(false, null, error));
};

/**
 * Handle 404 errors for unknown routes
 */
const notFoundHandler = (req, res, next) => {
  const { error, statusCode } = createErrorResponse(
    `Route ${req.method} ${req.originalUrl} not found`,
    404
  );
  return res.status(statusCode).json(createResponse(false, null, error));
};

module.exports = {
  errorHandler,
  notFoundHandler
};