// Database Configuration
const { Pool } = require('pg');
const mongoose = require('mongoose');

// PostgreSQL Connection Pool
const pgPool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'eqnode_dev',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Test PostgreSQL connection
pgPool.on('connect', () => {
  console.log('✅ PostgreSQL connected');
});

pgPool.on('error', (err) => {
  console.error('❌ PostgreSQL connection error:', err);
});

// MongoDB Connection
const connectMongoDB = async () => {
  try {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/eqnode_logs';
    await mongoose.connect(mongoUri);
    console.log('✅ MongoDB connected');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    // Don't exit - MongoDB is optional for logs
  }
};

module.exports = {
  pgPool,
  connectMongoDB,
};
