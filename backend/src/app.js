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
const photoRoutes = require('./routes/photos');
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

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    data: {
      message: 'Home Skillet API is running',
      timestamp: new Date().toISOString(),
      version: process.env.API_VERSION || 'v1',
      environment: process.env.NODE_ENV || 'development'
    }
  });
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
app.use(`/api/${apiVersion}`, photoRoutes);

// Handle 404 errors
app.use(notFoundHandler);

// Global error handler
app.use(errorHandler);

module.exports = app;