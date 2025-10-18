const { query } = require('../config/database');

class Agent {
  static async create({ deviceId, walletAddress }) {
    const queryText = `
      INSERT INTO agents (device_id, wallet_address, created_at, updated_at)
      VALUES ($1, $2, NOW(), NOW())
      RETURNING id, device_id, wallet_address, status, created_at, updated_at
    `;
    
    const result = await query(queryText, [deviceId, walletAddress]);
    return result.rows[0];
  }

  static async findByDeviceId(deviceId) {
    const queryText = 'SELECT * FROM agents WHERE device_id = $1';
    const result = await query(queryText, [deviceId]);
    return result.rows[0];
  }

  static async findByWalletAddress(walletAddress) {
    const queryText = 'SELECT * FROM agents WHERE wallet_address = $1';
    const result = await query(queryText, [walletAddress]);
    return result.rows[0];
  }

  static async findById(id) {
    const queryText = 'SELECT * FROM agents WHERE id = $1';
    const result = await query(queryText, [id]);
    return result.rows[0];
  }

  static async findAll({ limit = 100, offset = 0 } = {}) {
    const queryText = `
      SELECT * FROM agents 
      ORDER BY created_at DESC 
      LIMIT $1 OFFSET $2
    `;
    const result = await query(queryText, [limit, offset]);
    return result.rows;
  }

  static async updateStatus(id, status) {
    const queryText = `
      UPDATE agents 
      SET status = $1, updated_at = NOW() 
      WHERE id = $2 
      RETURNING *
    `;
    const result = await query(queryText, [status, id]);
    return result.rows[0];
  }

  static async delete(id) {
    const queryText = 'DELETE FROM agents WHERE id = $1 RETURNING *';
    const result = await query(queryText, [id]);
    return result.rows[0];
  }

  static async count() {
    const queryText = 'SELECT COUNT(*) as total FROM agents';
    const result = await query(queryText);
    return parseInt(result.rows[0].total);
  }
}

module.exports = Agent;
