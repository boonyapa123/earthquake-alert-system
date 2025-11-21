// Earthquake Event Model
const { pgPool } = require('../config/database');

class EarthquakeEvent {
  static async create({ deviceId, magnitude, location, latitude, longitude, type, severity, rawData }) {
    const query = `
      INSERT INTO earthquake_events 
      (device_id, magnitude, location, latitude, longitude, type, severity, raw_data, timestamp, processed, notification_sent)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), true, false)
      RETURNING *
    `;
    
    const values = [
      deviceId, 
      magnitude, 
      location, 
      latitude, 
      longitude, 
      type || 'earthquake',
      severity || this.calculateSeverity(magnitude),
      rawData ? JSON.stringify(rawData) : null
    ];
    
    const result = await pgPool.query(query, values);
    return result.rows[0];
  }

  static async findById(id) {
    const query = 'SELECT * FROM earthquake_events WHERE id = $1';
    const result = await pgPool.query(query, [id]);
    return result.rows[0];
  }

  static async findAll({ page = 1, limit = 20, deviceId, startDate, endDate, minMagnitude }) {
    let query = `
      SELECT e.*, d.name as device_name, d.owner_id
      FROM earthquake_events e
      LEFT JOIN devices d ON e.device_id = d.device_id
      WHERE 1=1
    `;
    
    const values = [];
    let paramCount = 1;

    if (deviceId) {
      query += ` AND e.device_id = $${paramCount}`;
      values.push(deviceId);
      paramCount++;
    }

    if (startDate) {
      query += ` AND e.timestamp >= $${paramCount}`;
      values.push(startDate);
      paramCount++;
    }

    if (endDate) {
      query += ` AND e.timestamp <= $${paramCount}`;
      values.push(endDate);
      paramCount++;
    }

    if (minMagnitude) {
      query += ` AND e.magnitude >= $${paramCount}`;
      values.push(minMagnitude);
      paramCount++;
    }

    // Get total count
    const countQuery = `SELECT COUNT(*) as total FROM (${query}) as count_query`;
    const countResult = await pgPool.query(countQuery, values);
    const total = parseInt(countResult.rows[0].total);

    // Add pagination
    const offset = (page - 1) * limit;
    query += ` ORDER BY e.timestamp DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    values.push(limit, offset);

    const result = await pgPool.query(query, values);

    return {
      events: result.rows,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit)
      }
    };
  }

  static async findByDevice(deviceId, limit = 50) {
    const query = `
      SELECT * FROM earthquake_events 
      WHERE device_id = $1 
      ORDER BY timestamp DESC 
      LIMIT $2
    `;
    const result = await pgPool.query(query, [deviceId, limit]);
    return result.rows;
  }

  static async markAsNotified(id) {
    const query = `
      UPDATE earthquake_events 
      SET notification_sent = true, updated_at = NOW()
      WHERE id = $1
      RETURNING *
    `;
    const result = await pgPool.query(query, [id]);
    return result.rows[0];
  }

  static async reportFalsePositive(id) {
    const query = `
      UPDATE earthquake_events 
      SET false_positive = true, updated_at = NOW()
      WHERE id = $1
      RETURNING *
    `;
    const result = await pgPool.query(query, [id]);
    return result.rows[0];
  }

  static calculateSeverity(magnitude) {
    if (magnitude >= 6.0) return 'critical';
    if (magnitude >= 5.0) return 'high';
    if (magnitude >= 4.0) return 'moderate';
    if (magnitude >= 3.0) return 'low';
    return 'minor';
  }

  static async getRecentAlerts(limit = 10) {
    const query = `
      SELECT e.*, d.name as device_name, d.location as device_location
      FROM earthquake_events e
      LEFT JOIN devices d ON e.device_id = d.device_id
      WHERE e.magnitude >= 3.0
      ORDER BY e.timestamp DESC
      LIMIT $1
    `;
    const result = await pgPool.query(query, [limit]);
    return result.rows;
  }
}

module.exports = EarthquakeEvent;
