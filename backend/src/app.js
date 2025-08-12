require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

// Middleware
const { requestLogger } = require('./middleware/requestLogger');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

// Routes
const authRoutes = require('./routes/auth');
const propertyRoutes = require('./routes/properties');
const projectRoutes = require('./routes/projects');
const taskRoutes = require('./routes/tasks');
const userRoutes = require('./routes/users');
const maintenanceRoutes = require('./routes/maintenance');
// const photoRoutes = require('./routes/photos'); // Temporarily disabled for Railway deployment
const reportRoutes = require('./routes/reports');
const documentRoutes = require('./routes/documents');
const insuranceRoutes = require('./routes/insurance');

const app = express();

// Security middleware
app.use(helmet());

// CORS configuration
const corsOptions = {
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://yourdomain.com'] // Replace with actual domain
    : true, // Allow all origins in development
  credentials: true,
  optionsSuccessStatus: 200,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
};

app.use(cors(corsOptions));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: process.env.NODE_ENV === 'test' ? 1000 : 100, // Higher limit for tests
  message: {
    success: false,
    error: {
      message: 'Too many requests from this IP, please try again later.',
    }
  },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use(limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Serve static files (uploaded photos and documents)
app.use('/uploads', express.static('uploads'));

// Request logging (only in development)
if (process.env.NODE_ENV === 'development') {
  app.use(requestLogger);
}

// Health check endpoints - completely minimal, no dependencies
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: Date.now() });
});

// Database connectivity test endpoint
app.get('/health/db-test', async (req, res) => {
  try {
    const { Client } = require('pg');
    const client = new Client({
      host: 'db.yrkbpbwwewjjdmsspifl.supabase.co',
      port: 5432,
      database: 'postgres',
      user: 'postgres',
      password: 'lk5FPenvv8yk4nqY',
      ssl: { rejectUnauthorized: false }
    });
    
    await client.connect();
    const result = await client.query('SELECT NOW() as current_time, version() as pg_version');
    await client.end();
    
    res.json({
      status: 'connected',
      timestamp: Date.now(),
      database: {
        current_time: result.rows[0].current_time,
        version: result.rows[0].pg_version
      }
    });
  } catch (error) {
    res.status(500).json({
      status: 'failed',
      error: error.message,
      timestamp: Date.now()
    });
  }
});

// Migration endpoint for Railway deployment
app.post('/migrate', async (req, res) => {
  try {
    const { runMigrations } = require('../railway-migrate');
    await runMigrations();
    res.json({
      status: 'success',
      message: 'Database migrations completed successfully',
      timestamp: Date.now()
    });
  } catch (error) {
    res.status(500).json({
      status: 'failed',
      error: error.message,
      timestamp: Date.now()
    });
  }
});

// Root endpoint for Railway health checks
app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Home Skillet API is running',
    timestamp: new Date().toISOString(),
    endpoints: {
      health: '/health',
      'health-db': '/health/db',
      api: `/api/${process.env.API_VERSION || 'v1'}`
    }
  });
});

// Database health check endpoint
app.get('/health/db', async (req, res) => {
  console.log('🩺 Database health check requested');
  try {
    // Test database connection
    const db = require('./config/database');
    await db.raw('SELECT 1');
    
    res.status(200).json({
      success: true,
      status: 'healthy',
      database: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Database health check failed:', error);
    res.status(503).json({
      success: false,
      status: 'unhealthy',
      database: 'disconnected',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Simple database connection test endpoint 
app.get('/health/db-simple', async (req, res) => {
  console.log('🩺 Simple database connection test');
  try {
    // Test connection using pg directly (bypassing Knex) with IPv4
    const { Client } = require('pg');
    const client = new Client({
      host: 'db.yrkbpbwwewjjdmsspifl.supabase.co',
      port: 5432,
      database: 'postgres',
      user: 'postgres',
      password: 'lk5FPenvv8yk4nqY',
      ssl: { rejectUnauthorized: false }
    });
    
    await client.connect();
    const result = await client.query('SELECT NOW()');
    await client.end();
    
    res.status(200).json({
      success: true,
      status: 'connected',
      timestamp: new Date().toISOString(),
      db_time: result.rows[0].now
    });
  } catch (error) {
    console.error('❌ Simple database test failed:', error);
    res.status(503).json({
      success: false,
      status: 'failed',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// API routes
const apiVersion = process.env.API_VERSION || 'v1';
app.use(`/api/${apiVersion}/auth`, authRoutes);
app.use(`/api/${apiVersion}/properties`, propertyRoutes);
app.use(`/api/${apiVersion}/projects`, projectRoutes);
app.use(`/api/${apiVersion}/tasks`, taskRoutes);
app.use(`/api/${apiVersion}/users`, userRoutes);
app.use(`/api/${apiVersion}/maintenance-schedules`, maintenanceRoutes);
app.use(`/api/${apiVersion}/reports`, reportRoutes);
app.use(`/api/${apiVersion}/documents`, documentRoutes);
app.use(`/api/${apiVersion}/insurance`, insuranceRoutes);
// app.use(`/api/${apiVersion}`, photoRoutes); // Temporarily disabled

// Handle 404 errors
app.use(notFoundHandler);

// Global error handler
app.use(errorHandler);

module.exports = app;