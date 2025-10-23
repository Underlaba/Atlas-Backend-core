const db = require('../config/database');

/**
 * Get agents growth analytics
 * Returns data for charts showing agent registration over time
 */
exports.getAgentsGrowth = async (req, res, next) => {
  try {
    const { period = 'month', limit = 30 } = req.query;

    let dateFormat, intervalText;
    
    // Determine date grouping based on period
    switch (period) {
      case 'day':
        dateFormat = 'YYYY-MM-DD';
        intervalText = '30 days';
        break;
      case 'week':
        dateFormat = 'IYYY-IW'; // ISO week
        intervalText = '12 weeks';
        break;
      case 'month':
        dateFormat = 'YYYY-MM';
        intervalText = '12 months';
        break;
      case 'year':
        dateFormat = 'YYYY';
        intervalText = '5 years';
        break;
      default:
        dateFormat = 'YYYY-MM-DD';
        intervalText = '30 days';
    }

    // Get agent registrations grouped by period
    const growthQuery = `
      SELECT 
        TO_CHAR(created_at, $1) as period,
        COUNT(*) as count,
        COUNT(*) FILTER (WHERE status = 'active') as active_count
      FROM agents
      WHERE created_at >= NOW() - INTERVAL '${intervalText}'
      GROUP BY period
      ORDER BY period ASC
    `;

    const growthResult = await db.query(growthQuery, [dateFormat]);

    // Get total and active agents count
    const statsQuery = `
      SELECT 
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE status = 'active') as active,
        COUNT(*) FILTER (WHERE status = 'inactive') as inactive,
        COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '7 days') as new_last_week
      FROM agents
    `;

    const statsResult = await db.query(statsQuery);
    const stats = statsResult.rows[0];

    // Get percentage change compared to previous period
    const previousPeriodQuery = `
      SELECT COUNT(*) as count
      FROM agents
      WHERE created_at >= NOW() - INTERVAL '${intervalText}' * 2
        AND created_at < NOW() - INTERVAL '${intervalText}'
    `;

    const previousResult = await db.query(previousPeriodQuery);
    const previousCount = parseInt(previousResult.rows[0].count);
    const currentCount = growthResult.rows.reduce((sum, row) => sum + parseInt(row.count), 0);
    
    const percentageChange = previousCount > 0 
      ? ((currentCount - previousCount) / previousCount * 100).toFixed(2)
      : 100;

    res.json({
      success: true,
      data: {
        period,
        growth: growthResult.rows.map(row => ({
          period: row.period,
          total: parseInt(row.count),
          active: parseInt(row.active_count)
        })),
        stats: {
          total: parseInt(stats.total),
          active: parseInt(stats.active),
          inactive: parseInt(stats.inactive),
          newLastWeek: parseInt(stats.new_last_week),
          percentageChange: parseFloat(percentageChange)
        }
      }
    });
  } catch (error) {
    console.error('Error fetching agents growth:', error);
    next(error);
  }
};

/**
 * Get users growth analytics
 */
exports.getUsersGrowth = async (req, res, next) => {
  try {
    const { period = 'month' } = req.query;

    let dateFormat, intervalText;
    
    switch (period) {
      case 'day':
        dateFormat = 'YYYY-MM-DD';
        intervalText = '30 days';
        break;
      case 'week':
        dateFormat = 'IYYY-IW';
        intervalText = '12 weeks';
        break;
      case 'month':
        dateFormat = 'YYYY-MM';
        intervalText = '12 months';
        break;
      default:
        dateFormat = 'YYYY-MM-DD';
        intervalText = '30 days';
    }

    const growthQuery = `
      SELECT 
        TO_CHAR(created_at, $1) as period,
        COUNT(*) as count,
        COUNT(*) FILTER (WHERE is_active = true) as active_count,
        COUNT(*) FILTER (WHERE role = 'admin') as admin_count,
        COUNT(*) FILTER (WHERE role = 'agent') as agent_count,
        COUNT(*) FILTER (WHERE role = 'user') as user_count
      FROM users
      WHERE created_at >= NOW() - INTERVAL '${intervalText}'
      GROUP BY period
      ORDER BY period ASC
    `;

    const result = await db.query(growthQuery, [dateFormat]);

    res.json({
      success: true,
      data: {
        period,
        growth: result.rows.map(row => ({
          period: row.period,
          total: parseInt(row.count),
          active: parseInt(row.active_count),
          byRole: {
            admin: parseInt(row.admin_count),
            agent: parseInt(row.agent_count),
            user: parseInt(row.user_count)
          }
        }))
      }
    });
  } catch (error) {
    console.error('Error fetching users growth:', error);
    next(error);
  }
};

/**
 * Get activity logs statistics
 */
exports.getActivityStats = async (req, res, next) => {
  try {
    const { period = 'day', limit = 7 } = req.query;

    let dateFormat, intervalText;
    
    switch (period) {
      case 'hour':
        dateFormat = 'YYYY-MM-DD HH24:00';
        intervalText = '24 hours';
        break;
      case 'day':
        dateFormat = 'YYYY-MM-DD';
        intervalText = `${limit} days`;
        break;
      case 'week':
        dateFormat = 'IYYY-IW';
        intervalText = '12 weeks';
        break;
      default:
        dateFormat = 'YYYY-MM-DD';
        intervalText = '7 days';
    }

    // Get activity by period
    const activityQuery = `
      SELECT 
        TO_CHAR(timestamp, $1) as period,
        COUNT(*) as total,
        COUNT(DISTINCT user_id) as unique_users
      FROM activity_logs
      WHERE timestamp >= NOW() - INTERVAL '${intervalText}'
      GROUP BY period
      ORDER BY period ASC
    `;

    const activityResult = await db.query(activityQuery, [dateFormat]);

    // Get top actions
    const topActionsQuery = `
      SELECT 
        action,
        COUNT(*) as count
      FROM activity_logs
      WHERE timestamp >= NOW() - INTERVAL '${intervalText}'
      GROUP BY action
      ORDER BY count DESC
      LIMIT 10
    `;

    const topActionsResult = await db.query(topActionsQuery);

    res.json({
      success: true,
      data: {
        period,
        activity: activityResult.rows.map(row => ({
          period: row.period,
          total: parseInt(row.total),
          uniqueUsers: parseInt(row.unique_users)
        })),
        topActions: topActionsResult.rows.map(row => ({
          action: row.action,
          count: parseInt(row.count)
        }))
      }
    });
  } catch (error) {
    console.error('Error fetching activity stats:', error);
    next(error);
  }
};

/**
 * Get dashboard overview
 */
exports.getDashboardOverview = async (req, res, next) => {
  try {
    // Get all counts in parallel
    const [agents, users, logs, recentActivity] = await Promise.all([
      // Agents stats
      db.query(`
        SELECT 
          COUNT(*) as total,
          COUNT(*) FILTER (WHERE status = 'active') as active,
          COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '7 days') as new_this_week,
          COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days') as new_this_month
        FROM agents
      `),
      
      // Users stats
      db.query(`
        SELECT 
          COUNT(*) as total,
          COUNT(*) FILTER (WHERE is_active = true) as active,
          COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '7 days') as new_this_week,
          COUNT(*) FILTER (WHERE role = 'admin') as admins,
          COUNT(*) FILTER (WHERE role = 'agent') as agent_users,
          COUNT(*) FILTER (WHERE role = 'user') as regular_users
        FROM users
      `),
      
      // Logs stats
      db.query(`
        SELECT 
          COUNT(*) as total,
          COUNT(*) FILTER (WHERE timestamp >= NOW() - INTERVAL '24 hours') as last_24h,
          COUNT(*) FILTER (WHERE timestamp >= NOW() - INTERVAL '7 days') as last_7d
        FROM activity_logs
      `),
      
      // Recent activity
      db.query(`
        SELECT 
          action,
          COUNT(*) as count
        FROM activity_logs
        WHERE timestamp >= NOW() - INTERVAL '24 hours'
        GROUP BY action
        ORDER BY count DESC
        LIMIT 5
      `)
    ]);

    res.json({
      success: true,
      data: {
        agents: {
          total: parseInt(agents.rows[0].total),
          active: parseInt(agents.rows[0].active),
          newThisWeek: parseInt(agents.rows[0].new_this_week),
          newThisMonth: parseInt(agents.rows[0].new_this_month)
        },
        users: {
          total: parseInt(users.rows[0].total),
          active: parseInt(users.rows[0].active),
          newThisWeek: parseInt(users.rows[0].new_this_week),
          byRole: {
            admins: parseInt(users.rows[0].admins),
            agents: parseInt(users.rows[0].agent_users),
            users: parseInt(users.rows[0].regular_users)
          }
        },
        logs: {
          total: parseInt(logs.rows[0].total),
          last24h: parseInt(logs.rows[0].last_24h),
          last7d: parseInt(logs.rows[0].last_7d)
        },
        recentActivity: recentActivity.rows.map(row => ({
          action: row.action,
          count: parseInt(row.count)
        }))
      }
    });
  } catch (error) {
    console.error('Error fetching dashboard overview:', error);
    next(error);
  }
};
