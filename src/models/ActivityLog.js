const { query } = require('../config/database');

class ActivityLog {
  /**
   * Create a new activity log entry
   */
  static async create({
    userId,
    userName,
    userEmail,
    action,
    targetType,
    targetId = null,
    targetName = null,
    details = null,
    metadata = null,
    ipAddress = null,
    userAgent = null
  }) {
    const queryText = `
      INSERT INTO activity_logs (
        user_id, user_name, user_email, action, target_type,
        target_id, target_name, details, metadata,
        ip_address, user_agent, timestamp, created_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), NOW())
      RETURNING *
    `;
    
    const result = await query(queryText, [
      userId,
      userName,
      userEmail,
      action,
      targetType,
      targetId,
      targetName,
      details,
      metadata ? JSON.stringify(metadata) : null,
      ipAddress,
      userAgent
    ]);
    
    return result.rows[0];
  }

  /**
   * Get all logs with pagination and filters
   */
  static async findAll({
    page = 1,
    limit = 20,
    startDate = null,
    endDate = null,
    userId = null,
    action = null,
    targetType = null,
    search = null
  } = {}) {
    const offset = (page - 1) * limit;
    const conditions = [];
    const params = [];
    let paramIndex = 1;

    // Build WHERE clause dynamically
    if (startDate) {
      conditions.push(`timestamp >= $${paramIndex++}`);
      params.push(startDate);
    }

    if (endDate) {
      conditions.push(`timestamp <= $${paramIndex++}`);
      params.push(endDate);
    }

    if (userId) {
      conditions.push(`user_id = $${paramIndex++}`);
      params.push(userId);
    }

    if (action) {
      conditions.push(`action = $${paramIndex++}`);
      params.push(action);
    }

    if (targetType) {
      conditions.push(`target_type = $${paramIndex++}`);
      params.push(targetType);
    }

    if (search) {
      conditions.push(`(details ILIKE $${paramIndex++} OR user_name ILIKE $${paramIndex} OR user_email ILIKE $${paramIndex})`);
      params.push(`%${search}%`);
      paramIndex++;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    // Get total count
    const countQuery = `SELECT COUNT(*) FROM activity_logs ${whereClause}`;
    const countResult = await query(countQuery, params);
    const total = parseInt(countResult.rows[0].count);

    // Get paginated results
    const dataQuery = `
      SELECT * FROM activity_logs
      ${whereClause}
      ORDER BY timestamp DESC
      LIMIT $${paramIndex++} OFFSET $${paramIndex}
    `;
    
    const dataResult = await query(dataQuery, [...params, limit, offset]);

    return {
      data: dataResult.rows,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit)
      }
    };
  }

  /**
   * Find a single log by ID
   */
  static async findById(id) {
    const queryText = 'SELECT * FROM activity_logs WHERE id = $1';
    const result = await query(queryText, [id]);
    return result.rows[0];
  }

  /**
   * Get logs by user
   */
  static async findByUser(userId, { page = 1, limit = 20 } = {}) {
    return this.findAll({ userId, page, limit });
  }

  /**
   * Get logs by action
   */
  static async findByAction(action, { page = 1, limit = 20 } = {}) {
    return this.findAll({ action, page, limit });
  }

  /**
   * Get logs by date range
   */
  static async findByDateRange(startDate, endDate, { page = 1, limit = 20 } = {}) {
    return this.findAll({ startDate, endDate, page, limit });
  }

  /**
   * Get activity statistics
   */
  static async getStats(period = 'week') {
    let dateFilter = '';
    
    switch (period) {
      case 'day':
        dateFilter = "timestamp >= NOW() - INTERVAL '1 day'";
        break;
      case 'week':
        dateFilter = "timestamp >= NOW() - INTERVAL '7 days'";
        break;
      case 'month':
        dateFilter = "timestamp >= NOW() - INTERVAL '30 days'";
        break;
      default:
        dateFilter = "timestamp >= NOW() - INTERVAL '7 days'";
    }

    // Total activities
    const totalQuery = `SELECT COUNT(*) as total FROM activity_logs WHERE ${dateFilter}`;
    const totalResult = await query(totalQuery);

    // By action
    const byActionQuery = `
      SELECT action, COUNT(*) as count
      FROM activity_logs
      WHERE ${dateFilter}
      GROUP BY action
      ORDER BY count DESC
    `;
    const byActionResult = await query(byActionQuery);

    // By user
    const byUserQuery = `
      SELECT user_name, user_email, COUNT(*) as count
      FROM activity_logs
      WHERE ${dateFilter}
      GROUP BY user_name, user_email
      ORDER BY count DESC
      LIMIT 10
    `;
    const byUserResult = await query(byUserQuery);

    // Timeline
    const timelineQuery = `
      SELECT DATE(timestamp) as date, COUNT(*) as count
      FROM activity_logs
      WHERE ${dateFilter}
      GROUP BY DATE(timestamp)
      ORDER BY date ASC
    `;
    const timelineResult = await query(timelineQuery);

    return {
      totalActivities: parseInt(totalResult.rows[0].total),
      byAction: byActionResult.rows.reduce((acc, row) => {
        acc[row.action] = parseInt(row.count);
        return acc;
      }, {}),
      byUser: byUserResult.rows.reduce((acc, row) => {
        acc[`${row.user_name} (${row.user_email})`] = parseInt(row.count);
        return acc;
      }, {}),
      timeline: timelineResult.rows.map(row => ({
        date: row.date,
        count: parseInt(row.count)
      }))
    };
  }

  /**
   * Delete old logs (for cleanup)
   */
  static async deleteBeforeDate(beforeDate) {
    const queryText = 'DELETE FROM activity_logs WHERE timestamp < $1';
    const result = await query(queryText, [beforeDate]);
    return result.rowCount;
  }

  /**
   * Export logs to JSON
   */
  static async exportToJSON(filters = {}) {
    const result = await this.findAll({ ...filters, limit: 10000 }); // Max 10k records
    return result.data;
  }
}

module.exports = ActivityLog;
