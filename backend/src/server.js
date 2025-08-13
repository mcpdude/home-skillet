const app = require('./app');

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Home Skillet API server running on port ${PORT}`);
  console.log(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🌐 Health check: http://localhost:${PORT}/health`);
  console.log(`📚 API base URL: http://localhost:${PORT}/api/${process.env.API_VERSION || 'v1'}`);
  console.log(`🔗 Railway health check ready at: /health`);
  console.log(`🗄️  Database URL configured: ${process.env.SUPABASE_DB_URL ? 'Yes' : 'No'}`);
  console.log(`🪣 Supabase URL configured: ${process.env.SUPABASE_URL ? 'Yes' : 'No'}`);
  
  // Skip Supabase Storage initialization - using direct frontend uploads
  console.log('🚀 Supabase Storage initialization disabled - using direct frontend uploads');
});

// Handle server startup errors
server.on('error', (err) => {
  console.error('❌ Server error:', err);
  if (err.code === 'EADDRINUSE') {
    console.error(`💥 Port ${PORT} is already in use`);
  }
});

// Log when server is ready for connections
server.on('listening', () => {
  console.log(`✅ Server is ready to accept connections on port ${PORT}`);
});

// Global error handlers for Railway debugging
process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught Exception:', error);
  console.error('Stack:', error.stack);
  // Don't exit immediately in production to allow health checks
  if (process.env.NODE_ENV !== 'production') {
    process.exit(1);
  }
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  // Don't exit immediately in production to allow health checks
  if (process.env.NODE_ENV !== 'production') {
    process.exit(1);
  }
});

// Graceful shutdown handling
const gracefulShutdown = async (signal) => {
  console.log(`${signal} received`);
  
  try {
    // Close HTTP server
    if (server) {
      await new Promise((resolve) => {
        server.close(() => {
          console.log('HTTP server closed');
          resolve();
        });
      });
    }
    
    // Close database connections
    const db = require('./config/database');
    if (db && db.destroy) {
      await db.destroy();
      console.log('Database connections closed');
    }
    
    console.log('Graceful shutdown complete');
    process.exit(0);
  } catch (error) {
    console.error('Error during graceful shutdown:', error);
    process.exit(1);
  }
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

module.exports = server;