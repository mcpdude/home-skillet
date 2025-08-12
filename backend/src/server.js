const app = require('./app');
const { initializeStorageBuckets } = require('./config/supabaseStorage');

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Home Skillet API server running on port ${PORT}`);
  console.log(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🌐 Health check: http://localhost:${PORT}/health`);
  console.log(`📚 API base URL: http://localhost:${PORT}/api/${process.env.API_VERSION || 'v1'}`);
  console.log(`🔗 Railway health check ready at: /health`);
  
  // Initialize Supabase Storage buckets AFTER server is ready (non-blocking)
  if (process.env.NODE_ENV !== 'test') {
    setTimeout(async () => {
      try {
        console.log('🔄 Initializing Supabase Storage buckets...');
        await initializeStorageBuckets();
        console.log('✅ Supabase Storage initialized successfully');
      } catch (error) {
        console.warn('⚠️  Storage initialization failed, continuing without buckets:', error.message);
        // App continues to work, storage buckets can be created manually if needed
      }
    }, 1000); // Delay to ensure server is fully ready
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