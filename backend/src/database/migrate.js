// Database Migration Script
require('dotenv').config();
const { pgPool } = require('../config/database');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');

async function runMigration() {
  try {
    console.log('🔄 Starting database migration...');

    // Read schema file
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');

    // Execute schema
    await pgPool.query(schema);
    console.log('✅ Database schema created successfully');

    // Create test user with proper password hash
    const testPassword = await bcrypt.hash('password123', 10);
    
    const insertUserQuery = `
      INSERT INTO users (name, email, password, phone, address)
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (email) DO UPDATE 
      SET password = EXCLUDED.password
      RETURNING id, email
    `;
    
    const result = await pgPool.query(insertUserQuery, [
      'ผู้ใช้ทดสอบ',
      'user@eqnode.com',
      testPassword,
      '090-000-0000',
      'Test Address, Bangkok, Thailand'
    ]);

    console.log('✅ Test user created/updated:', result.rows[0].email);
    console.log('   Email: user@eqnode.com');
    console.log('   Password: password123');

    console.log('');
    console.log('✅ Migration completed successfully!');
    console.log('');

    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

runMigration();
