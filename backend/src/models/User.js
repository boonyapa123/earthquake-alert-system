// User Model
const { pgPool } = require('../config/database');
const bcrypt = require('bcryptjs');

class User {
  static async create({ name, email, password, phone, address }) {
    const hashedPassword = await bcrypt.hash(password, parseInt(process.env.BCRYPT_ROUNDS) || 10);
    
    const query = `
      INSERT INTO users (name, email, password, phone, address, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
      RETURNING id, name, email, phone, address, created_at
    `;
    
    const values = [name, email, hashedPassword, phone, address];
    const result = await pgPool.query(query, values);
    return result.rows[0];
  }

  static async findByEmail(email) {
    const query = 'SELECT * FROM users WHERE email = $1';
    const result = await pgPool.query(query, [email]);
    return result.rows[0];
  }

  static async findById(id) {
    const query = 'SELECT id, name, email, phone, address, created_at, updated_at FROM users WHERE id = $1';
    const result = await pgPool.query(query, [id]);
    return result.rows[0];
  }

  static async update(id, { name, phone, address }) {
    const query = `
      UPDATE users 
      SET name = $1, phone = $2, address = $3, updated_at = NOW()
      WHERE id = $4
      RETURNING id, name, email, phone, address, updated_at
    `;
    
    const values = [name, phone, address, id];
    const result = await pgPool.query(query, values);
    return result.rows[0];
  }

  static async updatePassword(id, newPassword) {
    const hashedPassword = await bcrypt.hash(newPassword, parseInt(process.env.BCRYPT_ROUNDS) || 10);
    
    const query = 'UPDATE users SET password = $1, updated_at = NOW() WHERE id = $2';
    await pgPool.query(query, [hashedPassword, id]);
    return true;
  }

  static async verifyPassword(plainPassword, hashedPassword) {
    return await bcrypt.compare(plainPassword, hashedPassword);
  }

  static async delete(id) {
    const query = 'DELETE FROM users WHERE id = $1';
    await pgPool.query(query, [id]);
    return true;
  }

  static async getDeviceCount(userId) {
    const query = 'SELECT COUNT(*) as count FROM devices WHERE owner_id = $1';
    const result = await pgPool.query(query, [userId]);
    return parseInt(result.rows[0].count);
  }
}

module.exports = User;
