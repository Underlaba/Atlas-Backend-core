const ActivityLog = require('../models/ActivityLog');
const json2csv = require('json2csv').parse;

const logsController = {
  /**
   * GET /api/logs
   * Get all logs with filters and pagination
   */
  async getLogs(req, res, next) {
    try {
      const {
        page = 1,
        limit = 20,
        startDate,
        endDate,
        userId,
        action,
        targetType,
        search
      } = req.query;

      const filters = {
        page: parseInt(page),
        limit: parseInt(limit),
        startDate,
        endDate,
        userId,
        action,
        targetType,
        search
      };

      const result = await ActivityLog.findAll(filters);

      res.json({
        success: true,
        data: result.data,
        pagination: result.pagination
      });
    } catch (error) {
      console.error('Error fetching logs:', error);
      next(error);
    }
  },

  /**
   * GET /api/logs/:id
   * Get a single log by ID
   */
  async getLogById(req, res, next) {
    try {
      const { id } = req.params;

      const log = await ActivityLog.findById(id);

      if (!log) {
        return res.status(404).json({
          success: false,
          message: 'Log not found'
        });
      }

      res.json({
        success: true,
        data: log
      });
    } catch (error) {
      console.error('Error fetching log:', error);
      next(error);
    }
  },

  /**
   * POST /api/logs
   * Create a new activity log
   */
  async createLog(req, res, next) {
    try {
      const {
        userId,
        userName,
        userEmail,
        action,
        targetType,
        targetId,
        targetName,
        details,
        metadata
      } = req.body;

      // Validar campos requeridos
      if (!userId || !userName || !userEmail || !action || !targetType) {
        return res.status(400).json({
          success: false,
          message: 'userId, userName, userEmail, action, and targetType are required'
        });
      }

      // Obtener IP y User-Agent del request
      const ipAddress = req.ip || req.connection.remoteAddress;
      const userAgent = req.get('user-agent');

      const log = await ActivityLog.create({
        userId,
        userName,
        userEmail,
        action,
        targetType,
        targetId,
        targetName,
        details,
        metadata,
        ipAddress,
        userAgent
      });

      res.status(201).json({
        success: true,
        data: log,
        message: 'Activity log created successfully'
      });
    } catch (error) {
      console.error('Error creating log:', error);
      next(error);
    }
  },

  /**
   * GET /api/logs/export
   * Export logs to CSV or JSON
   */
  async exportLogs(req, res, next) {
    try {
      const {
        format = 'json',
        startDate,
        endDate,
        userId,
        action,
        targetType,
        search
      } = req.query;

      const filters = {
        startDate,
        endDate,
        userId,
        action,
        targetType,
        search,
        limit: 10000 // Max 10k records for export
      };

      const result = await ActivityLog.findAll(filters);
      const logs = result.data;

      if (format === 'csv') {
        // Convert to CSV
        const fields = [
          'id',
          'user_name',
          'user_email',
          'action',
          'target_type',
          'target_id',
          'target_name',
          'details',
          'ip_address',
          'timestamp'
        ];

        try {
          const csv = json2csv(logs, { fields });
          
          res.setHeader('Content-Type', 'text/csv');
          res.setHeader('Content-Disposition', `attachment; filename=activity_logs_${Date.now()}.csv`);
          res.send(csv);
        } catch (csvError) {
          console.error('Error converting to CSV:', csvError);
          return res.status(500).json({
            success: false,
            message: 'Error generating CSV'
          });
        }
      } else {
        // Return as JSON
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Content-Disposition', `attachment; filename=activity_logs_${Date.now()}.json`);
        res.json(logs);
      }
    } catch (error) {
      console.error('Error exporting logs:', error);
      next(error);
    }
  },

  /**
   * GET /api/logs/stats
   * Get activity statistics
   */
  async getStats(req, res, next) {
    try {
      const { period = 'week' } = req.query;

      if (!['day', 'week', 'month'].includes(period)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid period. Must be "day", "week", or "month"'
        });
      }

      const stats = await ActivityLog.getStats(period);

      res.json({
        success: true,
        data: stats
      });
    } catch (error) {
      console.error('Error fetching stats:', error);
      next(error);
    }
  },

  /**
   * DELETE /api/logs
   * Delete old logs (admin only)
   */
  async deleteLogs(req, res, next) {
    try {
      const { beforeDate } = req.query;

      if (!beforeDate) {
        return res.status(400).json({
          success: false,
          message: 'beforeDate query parameter is required'
        });
      }

      // Validar que el usuario es admin
      if (req.user.role !== 'admin') {
        return res.status(403).json({
          success: false,
          message: 'Only admins can delete logs'
        });
      }

      const deletedCount = await ActivityLog.deleteBeforeDate(beforeDate);

      res.json({
        success: true,
        message: `Successfully deleted ${deletedCount} logs`,
        deletedCount
      });
    } catch (error) {
      console.error('Error deleting logs:', error);
      next(error);
    }
  }
};

module.exports = logsController;
