const app = require('./app');
const { initializeStorageBuckets } = require('./config/supabaseStorage');

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Home Skillet API server running on port ${PORT}`);
  console.log(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🌐 Health check: http://localhost:${PORT}/health`);
  console.log(`📚 API base URL: http://localhost:${PORT}/api/${process.env.API_VERSION || 'v1'}`);
  console.log(`🔗 Railway health check ready at: /health`);
  console.log(`🗄️  Database URL configured: ${process.env.SUPABASE_DB_URL ? 'Yes' : 'No'}`);
  console.log(`🪣 Supabase URL configured: ${process.env.SUPABASE_URL ? 'Yes' : 'No'}`);
  
  // Skip Supabase Storage initialization on Railway to avoid startup delays
  if (process.env.NODE_ENV !== 'test' && process.env.NODE_ENV !== 'production') {
    setTimeout(async () => {
      try {
        console.log('🔄 Initializing Supabase Storage buckets...');
        await initializeStorageBuckets();
        console.log('✅ Supabase Storage initialized successfully');
      } catch (error) {
        console.warn('⚠️  Storage initialization failed, continuing without buckets:', error.message);
        // App continues to work, storage buckets can be created manually if needed
      }
    }, 2000);
  } else if (process.env.NODE_ENV === 'production') {
    console.log('🚀 Production mode: Skipping Supabase Storage initialization during startup');
  }
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
process.on('SIGTERM', () => {
  console.log('SIGTERM received');
  if (server) {
    server.close(() => {
      console.log('HTTP server closed');
      process.exit(0);
    });
  }
});

process.on('SIGINT', () => {
  console.log('SIGINT received');
  if (server) {
    server.close(() => {
      console.log('HTTP server closed');
      process.exit(0);
    });
  }
});

module.exports = server;