const db = require('../config/database');
const bcrypt = require('bcryptjs');

class User {
  /**
   * Create a new user
   */
  static async create({ email, password, firstName, lastName, role = 'user' }) {
    const hashedPassword = await bcrypt.hash(password, 10);
    
    const query = `
      INSERT INTO users (email, password, first_name, last_name, role, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
      RETURNING id, email, first_name, last_name, role, created_at
    `;
    
    const values = [email, hashedPassword, firstName, lastName, role];
    const result = await db.query(query, values);
    
    return result.rows[0];
  }

  /**
   * Find user by email
   */
  static async findByEmail(email) {
    const query = 'SELECT * FROM users WHERE email = $1';
    const result = await db.query(query, [email]);
    
    return result.rows[0];
  }

  /**
   * Find user by ID
   */
  static async findById(id) {
    const query = 'SELECT id, email, first_name, last_name, role, created_at FROM users WHERE id = $1';
    const result = await db.query(query, [id]);
    
    return result.rows[0];
  }

  /**
   * Update user
   */
  static async update(id, data) {
    const fields = [];
    const values = [];
    let paramCount = 1;

    Object.keys(data).forEach(key => {
      if (data[key] !== undefined) {
        fields.push(`${key} = $${paramCount}`);
        values.push(data[key]);
        paramCount++;
      }
    });

    fields.push(`updated_at = NOW()`);
    values.push(id);

    const query = `
      UPDATE users 
      SET ${fields.join(', ')}
      WHERE id = $${paramCount}
      RETURNING id, email, first_name, last_name, role, updated_at
    `;

    const result = await db.query(query, values);
    return result.rows[0];
  }

  /**
   * Compare password
   */
  static async comparePassword(plainPassword, hashedPassword) {
    return bcrypt.compare(plainPassword, hashedPassword);
  }

  /**
   * Get all users (admin only)
   */
  static async findAll(limit = 50, offset = 0) {
    const query = `
      SELECT id, email, first_name, last_name, role, created_at 
      FROM users 
      ORDER BY created_at DESC 
      LIMIT $1 OFFSET $2
    `;
    
    const result = await db.query(query, [limit, offset]);
    return result.rows;
  }

  /**
   * Delete user
   */
  static async delete(id) {
    const query = 'DELETE FROM users WHERE id = $1 RETURNING id';
    const result = await db.query(query, [id]);
    
    return result.rows[0];
  }
}

module.exports = User;
