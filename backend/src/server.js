// Main Server File
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');

const { connectMongoDB } = require('./config/database');
const mqttManager = require('./config/mqtt');
const EarthquakeEvent = require('./models/EarthquakeEvent');
const Device = require('./models/Device');

// Import routes
const authRoutes = require('./routes/auth');
const deviceRoutes = require('./routes/devices');
const eventRoutes = require('./routes/events');

// Import services
const notificationService = require('./services/notificationService');

// Initialize Express
const app = express();
const PORT = process.env.PORT || 3000;
const API_VERSION = process.env.API_VERSION || 'v1';

// Middleware
app.use(helmet()); // Security headers
app.use(compression()); // Compress responses
app.use(morgan('combined')); // Logging

// CORS Configuration
const corsOptions = {
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true,
  optionsSuccessStatus: 200
};
app.use(cors(corsOptions));

// Body Parser
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate Limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    success: false,
    message: 'Too many requests, please try again later'
  }
});
app.use(`/api/${API_VERSION}`, limiter);

// Health Check
app.get('/health', (req, res) => {
  res.json({
    success: true,
    status: 'healthy',
    timestamp: new Date().toISOString(),
    mqtt: mqttManager.isConnected ? 'connected' : 'disconnected',
    version: API_VERSION
  });
});

// API Routes
app.use(`/api/${API_VERSION}/auth`, authRoutes);
app.use(`/api/${API_VERSION}/devices`, deviceRoutes);
app.use(`/api/${API_VERSION}/events`, eventRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'eQNode Backend API',
    version: API_VERSION,
    endpoints: {
      health: '/health',
      auth: `/api/${API_VERSION}/auth`,
      devices: `/api/${API_VERSION}/devices`,
      events: `/api/${API_VERSION}/events`
    }
  });
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found'
  });
});

// Error Handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// MQTT Event Handlers
mqttManager.on('connected', () => {
  console.log('✅ MQTT Manager connected and ready');
});

mqttManager.on('earthquake', async (data) => {
  try {
    console.log('🌍 Earthquake data received:', {
      deviceId: data.deviceId,
      magnitude: data.magnitude,
      severity: data.severity,
    });
    
    // Save to database
    const event = await EarthquakeEvent.create({
      deviceId: data.deviceId,
      magnitude: data.magnitude,
      location: data.location,
      latitude: data.location?.latitude || 0,
      longitude: data.location?.longitude || 0,
      type: 'earthquake',
      severity: data.severity,
      rawData: data
    });

    // Update device last seen
    await Device.updateStatus(data.deviceId, 'active', new Date());

    console.log('✅ Earthquake event saved:', event.id);
  } catch (error) {
    console.error('Error processing earthquake data:', error);
  }
});

// Handle earthquake alerts (magnitude >= 3.0)
mqttManager.on('alert', async ({ earthquakeData, notification }) => {
  try {
    console.log('🚨 Earthquake Alert:', {
      magnitude: earthquakeData.magnitude,
      severity: earthquakeData.severity,
      deviceId: earthquakeData.deviceId,
    });
    
    // Send push notification
    await notificationService.sendEarthquakeAlert(earthquakeData, notification);
    
    console.log('✅ Alert notification sent');
  } catch (error) {
    console.error('Error sending alert:', error);
  }
});

mqttManager.on('deviceStatus', async (data) => {
  try {
    console.log('📱 Device status update:', data);
    
    if (data.deviceId) {
      await Device.updateStatus(data.deviceId, data.status || 'active', new Date());
    }
  } catch (error) {
    console.error('Error processing device status:', error);
  }
});

mqttManager.on('error', (error) => {
  console.error('❌ MQTT Error:', error);
});

// Initialize Database and Start Server
const startServer = async () => {
  try {
    // Connect to MongoDB (optional - for logs)
    await connectMongoDB();

    // Connect to MQTT Broker
    mqttManager.connect();

    // Start Express Server
    app.listen(PORT, () => {
      console.log('');
      console.log('=================================');
      console.log('🚀 eQNode Backend Server Started');
      console.log('=================================');
      console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`Port: ${PORT}`);
      console.log(`API Version: ${API_VERSION}`);
      console.log(`API URL: http://localhost:${PORT}/api/${API_VERSION}`);
      console.log(`Health Check: http://localhost:${PORT}/health`);
      console.log('=================================');
      console.log('');
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  mqttManager.disconnect();
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully...');
  mqttManager.disconnect();
  process.exit(0);
});

// Start the server
startServer();

module.exports = app;
