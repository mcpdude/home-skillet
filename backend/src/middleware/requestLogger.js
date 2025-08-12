/**
 * Simple request logging middleware for development
 */
const requestLogger = (req, res, next) => {
  const timestamp = new Date().toISOString();
  const method = req.method;
  const url = req.originalUrl;
  const userAgent = req.get('User-Agent') || 'Unknown';
  
  // Log the request
  console.log(`[${timestamp}] ${method} ${url} - ${userAgent}`);
  
  // Continue to next middleware
  next();
};

module.exports = {
  requestLogger
};