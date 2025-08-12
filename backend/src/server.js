const app = require('./app');
const { initializeStorageBuckets } = require('./config/supabaseStorage');

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, '0.0.0.0', async () => {
  console.log(`🚀 Home Skillet API server running on port ${PORT}`);
  console.log(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🌐 Health check: http://localhost:${PORT}/health`);
  console.log(`📚 API base URL: http://localhost:${PORT}/api/${process.env.API_VERSION || 'v1'}`);
  
  // Initialize Supabase Storage buckets (with timeout for Railway)
  try {
    const timeoutPromise = new Promise((_, reject) => 
      setTimeout(() => reject(new Error('Storage initialization timeout')), 30000)
    );
    
    await Promise.race([
      initializeStorageBuckets(),
      timeoutPromise
    ]);
    
    console.log('✅ Supabase Storage initialized successfully');
  } catch (error) {
    console.warn('⚠️  Storage initialization failed, continuing without buckets:', error.message);
    // Don't fail the startup if storage initialization fails
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