// Device Model
const { pgPool } = require('../config/database');

class Device {
  static async create({ deviceId, name, type, location, latitude, longitude, ownerId }) {
    const query = `
      INSERT INTO devices (device_id, name, type, location, latitude, longitude, owner_id, status, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, 'active', NOW(), NOW())
      RETURNING *
    `;
    
    const values = [deviceId, name, type || 'earthquake', location, latitude, longitude, ownerId];
    const result = await pgPool.query(query, values);
    return result.rows[0];
  }

  static async findById(id) {
    const query = 'SELECT * FROM devices WHERE id = $1';
    const result = await pgPool.query(query, [id]);
    return result.rows[0];
  }

  static async findByDeviceId(deviceId) {
    const query = 'SELECT * FROM devices WHERE device_id = $1';
    const result = await pgPool.query(query, [deviceId]);
    return result.rows[0];
  }

  static async findByOwner(ownerId) {
    const query = `
      SELECT * FROM devices 
      WHERE owner_id = $1 
      ORDER BY created_at DESC
    `;
    const result = await pgPool.query(query, [ownerId]);
    return result.rows;
  }

  static async update(id, { name, location, latitude, longitude }) {
    const query = `
      UPDATE devices 
      SET name = $1, location = $2, latitude = $3, longitude = $4, updated_at = NOW()
      WHERE id = $5
      RETURNING *
    `;
    
    const values = [name, location, latitude, longitude, id];
    const result = await pgPool.query(query, values);
    return result.rows[0];
  }

  static async updateStatus(deviceId, status, lastSeen = new Date()) {
    const query = `
      UPDATE devices 
      SET status = $1, last_seen = $2, updated_at = NOW()
      WHERE device_id = $3
      RETURNING *
    `;
    
    const values = [status, lastSeen, deviceId];
    const result = await pgPool.query(query, values);
    return result.rows[0];
  }

  static async transferOwnership(id, newOwnerId) {
    const query = `
      UPDATE devices 
      SET owner_id = $1, updated_at = NOW()
      WHERE id = $2
      RETURNING *
    `;
    
    const values = [newOwnerId, id];
    const result = await pgPool.query(query, values);
    return result.rows[0];
  }

  static async delete(id) {
    const query = 'DELETE FROM devices WHERE id = $1';
    await pgPool.query(query, [id]);
    return true;
  }

  static async getStatistics(deviceId, startDate, endDate) {
    const query = `
      SELECT 
        COUNT(*) as total_events,
        AVG(magnitude) as avg_magnitude,
        MAX(magnitude) as max_magnitude,
        MIN(magnitude) as min_magnitude
      FROM earthquake_events
      WHERE device_id = $1
        AND ($2::timestamp IS NULL OR timestamp >= $2)
        AND ($3::timestamp IS NULL OR timestamp <= $3)
    `;
    
    const values = [deviceId, startDate, endDate];
    const result = await pgPool.query(query, values);
    return result.rows[0];
  }
}

module.exports = Device;
