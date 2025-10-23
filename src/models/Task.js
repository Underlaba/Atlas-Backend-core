/**
 * Task Model
 * Handles task management for agents
 */

const db = require('../config/database');

class Task {
  /**
   * Get all tasks with filters
   */
  static async findAll(filters = {}) {
    const { agentWallet, status, priority, assignedBy, limit = 50, offset = 0 } = filters;
    
    let query = `
      SELECT 
        t.*,
        a.device_id as agent_device_id,
        u.email as assigned_by_email,
        CONCAT(u.first_name, ' ', u.last_name) as assigned_by_name
      FROM tasks t
      LEFT JOIN agents a ON t.agent_wallet = a.wallet_address
      LEFT JOIN users u ON t.assigned_by = u.id
      WHERE 1=1
    `;
    
    const params = [];
    let paramCount = 1;

    if (agentWallet) {
      query += ` AND t.agent_wallet = $${paramCount}`;
      params.push(agentWallet);
      paramCount++;
    }

    if (status) {
      query += ` AND t.status = $${paramCount}`;
      params.push(status);
      paramCount++;
    }

    if (priority) {
      query += ` AND t.priority = $${paramCount}`;
      params.push(priority);
      paramCount++;
    }

    if (assignedBy) {
      query += ` AND t.assigned_by = $${paramCount}`;
      params.push(assignedBy);
      paramCount++;
    }

    query += ` ORDER BY 
      CASE t.priority
        WHEN 'urgent' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
      END,
      t.due_date ASC NULLS LAST,
      t.created_at DESC
      LIMIT $${paramCount} OFFSET $${paramCount + 1}
    `;
    
    params.push(limit, offset);

    const result = await db.query(query, params);
    return result.rows;
  }

  /**
   * Get tasks for a specific agent
   */
  static async findByAgent(agentWallet, filters = {}) {
    return this.findAll({ ...filters, agentWallet });
  }

  /**
   * Get task by ID
   */
  static async findById(id) {
    const query = `
      SELECT 
        t.*,
        a.device_id as agent_device_id,
        u.email as assigned_by_email,
        CONCAT(u.first_name, ' ', u.last_name) as assigned_by_name
      FROM tasks t
      LEFT JOIN agents a ON t.agent_wallet = a.wallet_address
      LEFT JOIN users u ON t.assigned_by = u.id
      WHERE t.id = $1
    `;
    
    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  /**
   * Create a new task
   */
  static async create(taskData) {
    const {
      title,
      description,
      agentWallet,
      assignedBy,
      status = 'pending',
      priority = 'medium',
      dueDate
    } = taskData;

    const query = `
      INSERT INTO tasks (
        title, description, agent_wallet, assigned_by, status, priority, due_date
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `;

    const values = [title, description, agentWallet, assignedBy, status, priority, dueDate];
    const result = await db.query(query, values);
    return result.rows[0];
  }

  /**
   * Update task
   */
  static async update(id, updates) {
    const allowedFields = ['title', 'description', 'status', 'priority', 'due_date', 'started_at', 'completed_at'];
    const fields = [];
    const values = [];
    let paramCount = 1;

    // Map camelCase to snake_case
    const fieldMapping = {
      title: 'title',
      description: 'description',
      status: 'status',
      priority: 'priority',
      dueDate: 'due_date',
      startedAt: 'started_at',
      completedAt: 'completed_at'
    };

    Object.keys(updates).forEach(key => {
      const dbField = fieldMapping[key];
      if (dbField && allowedFields.includes(dbField)) {
        fields.push(`${dbField} = $${paramCount}`);
        values.push(updates[key]);
        paramCount++;
      }
    });

    if (fields.length === 0) {
      throw new Error('No valid fields to update');
    }

    values.push(id);

    const query = `
      UPDATE tasks
      SET ${fields.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await db.query(query, values);
    return result.rows[0];
  }

  /**
   * Mark task as in progress
   */
  static async markInProgress(id) {
    const query = `
      UPDATE tasks
      SET status = 'in_progress',
          started_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `;
    
    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  /**
   * Mark task as completed
   */
  static async markCompleted(id) {
    const query = `
      UPDATE tasks
      SET status = 'completed',
          completed_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `;
    
    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  /**
   * Delete task
   */
  static async delete(id) {
    const query = 'DELETE FROM tasks WHERE id = $1 RETURNING *';
    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  /**
   * Get task statistics
   */
  static async getStats(filters = {}) {
    const { agentWallet, assignedBy } = filters;
    
    let query = `
      SELECT 
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE status = 'pending') as pending,
        COUNT(*) FILTER (WHERE status = 'in_progress') as in_progress,
        COUNT(*) FILTER (WHERE status = 'completed') as completed,
        COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled,
        COUNT(*) FILTER (WHERE priority = 'urgent') as urgent,
        COUNT(*) FILTER (WHERE priority = 'high') as high,
        COUNT(*) FILTER (WHERE priority = 'medium') as medium,
        COUNT(*) FILTER (WHERE priority = 'low') as low,
        COUNT(*) FILTER (WHERE due_date < CURRENT_TIMESTAMP AND status NOT IN ('completed', 'cancelled')) as overdue
      FROM tasks
      WHERE 1=1
    `;
    
    const params = [];
    let paramCount = 1;

    if (agentWallet) {
      query += ` AND agent_wallet = $${paramCount}`;
      params.push(agentWallet);
      paramCount++;
    }

    if (assignedBy) {
      query += ` AND assigned_by = $${paramCount}`;
      params.push(assignedBy);
      paramCount++;
    }

    const result = await db.query(query, params);
    return result.rows[0];
  }

  /**
   * Get count of tasks
   */
  static async count(filters = {}) {
    const { agentWallet, status, priority } = filters;
    
    let query = 'SELECT COUNT(*) FROM tasks WHERE 1=1';
    const params = [];
    let paramCount = 1;

    if (agentWallet) {
      query += ` AND agent_wallet = $${paramCount}`;
      params.push(agentWallet);
      paramCount++;
    }

    if (status) {
      query += ` AND status = $${paramCount}`;
      params.push(status);
      paramCount++;
    }

    if (priority) {
      query += ` AND priority = $${paramCount}`;
      params.push(priority);
      paramCount++;
    }

    const result = await db.query(query, params);
    return parseInt(result.rows[0].count);
  }
}

module.exports = Task;
