const db = require('../config/database');

/**
 * Get current system settings
 */
exports.getSettings = async (req, res, next) => {
  try {
    // Por ahora, retornamos configuración por defecto
    // En el futuro, esto vendría de una tabla de configuración
    const settings = {
      siteName: 'Atlas Admin',
      siteDescription: 'Administrative control panel for Atlas',
      language: 'en',
      theme: 'light',
      timezone: 'UTC',
      emailNotifications: true,
      pushNotifications: false,
      maintenanceMode: false,
      registrationEnabled: false,
      twoFactorRequired: false,
      sessionTimeout: 3600,
      maxLoginAttempts: 5,
      passwordMinLength: 8
    };

    res.json({
      success: true,
      data: settings
    });
  } catch (error) {
    console.error('Error fetching settings:', error);
    next(error);
  }
};

/**
 * Update system settings
 */
exports.updateSettings = async (req, res, next) => {
  try {
    const updates = req.body;

    // Por ahora, solo validamos y retornamos los datos actualizados
    // En el futuro, esto se guardaría en la base de datos
    const settings = {
      ...updates,
      updatedAt: new Date().toISOString(),
      updatedBy: req.user.email
    };

    res.json({
      success: true,
      data: settings,
      message: 'Settings updated successfully'
    });
  } catch (error) {
    console.error('Error updating settings:', error);
    next(error);
  }
};

/**
 * Get system statistics
 */
exports.getStats = async (req, res, next) => {
  try {
    // Obtener estadísticas de usuarios
    const usersResult = await db.query('SELECT COUNT(*) as count FROM users');
    const activeUsersResult = await db.query('SELECT COUNT(*) as count FROM users WHERE is_active = true');
    
    // Obtener estadísticas de agentes
    const agentsResult = await db.query('SELECT COUNT(*) as count FROM agents');
    const activeAgentsResult = await db.query('SELECT COUNT(*) as count FROM agents WHERE status = $1', ['active']);
    
    // Obtener estadísticas de logs
    const logsResult = await db.query('SELECT COUNT(*) as count FROM activity_logs');
    const logsLast24hResult = await db.query(
      "SELECT COUNT(*) as count FROM activity_logs WHERE timestamp >= NOW() - INTERVAL '24 hours'"
    );

    // Información del sistema
    const stats = {
      users: {
        total: parseInt(usersResult.rows[0].count),
        active: parseInt(activeUsersResult.rows[0].count)
      },
      agents: {
        total: parseInt(agentsResult.rows[0].count),
        active: parseInt(activeAgentsResult.rows[0].count)
      },
      logs: {
        total: parseInt(logsResult.rows[0].count),
        last24h: parseInt(logsLast24hResult.rows[0].count)
      },
      system: {
        version: '1.0.0',
        uptime: process.uptime(),
        memoryUsage: process.memoryUsage(),
        nodeVersion: process.version,
        platform: process.platform
      }
    };

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Error fetching stats:', error);
    next(error);
  }
};

/**
 * Export system data
 */
exports.exportData = async (req, res, next) => {
  try {
    const {
      format = 'json',
      includeAgents = true,
      includeUsers = true,
      includeLogs = true,
      dateFrom,
      dateTo
    } = req.query;

    const exportData = {};

    // Exportar usuarios
    if (includeUsers === 'true') {
      const usersResult = await db.query(
        'SELECT id, email, first_name, last_name, role, is_active, created_at FROM users ORDER BY created_at DESC'
      );
      exportData.users = usersResult.rows;
    }

    // Exportar agentes
    if (includeAgents === 'true') {
      const agentsResult = await db.query(
        'SELECT * FROM agents ORDER BY created_at DESC'
      );
      exportData.agents = agentsResult.rows;
    }

    // Exportar logs
    if (includeLogs === 'true') {
      let logsQuery = 'SELECT * FROM activity_logs WHERE 1=1';
      const params = [];
      let paramIndex = 1;

      if (dateFrom) {
        logsQuery += ` AND timestamp >= $${paramIndex++}`;
        params.push(dateFrom);
      }

      if (dateTo) {
        logsQuery += ` AND timestamp <= $${paramIndex++}`;
        params.push(dateTo);
      }

      logsQuery += ' ORDER BY timestamp DESC LIMIT 10000';

      const logsResult = await db.query(logsQuery, params);
      exportData.logs = logsResult.rows;
    }

    // Metadata de exportación
    exportData.exportedAt = new Date().toISOString();
    exportData.exportedBy = req.user.email;
    exportData.format = format;

    if (format === 'json') {
      res.setHeader('Content-Type', 'application/json');
      res.setHeader('Content-Disposition', `attachment; filename=atlas_export_${Date.now()}.json`);
      res.json(exportData);
    } else {
      // Para CSV, necesitaríamos implementar la conversión
      res.status(501).json({
        success: false,
        message: 'CSV export not implemented yet'
      });
    }
  } catch (error) {
    console.error('Error exporting data:', error);
    next(error);
  }
};

/**
 * Reset settings to default
 */
exports.resetSettings = async (req, res, next) => {
  try {
    // Configuración por defecto
    const defaultSettings = {
      siteName: 'Atlas Admin',
      siteDescription: 'Administrative control panel for Atlas',
      language: 'en',
      theme: 'light',
      timezone: 'UTC',
      emailNotifications: true,
      pushNotifications: false,
      maintenanceMode: false,
      registrationEnabled: false,
      twoFactorRequired: false,
      sessionTimeout: 3600,
      maxLoginAttempts: 5,
      passwordMinLength: 8
    };

    res.json({
      success: true,
      data: defaultSettings,
      message: 'Settings reset to defaults'
    });
  } catch (error) {
    console.error('Error resetting settings:', error);
    next(error);
  }
};

/**
 * Test email configuration
 */
exports.testEmail = async (req, res, next) => {
  try {
    const { recipient } = req.body;

    if (!recipient) {
      return res.status(400).json({
        success: false,
        message: 'Recipient email is required'
      });
    }

    // Por ahora, solo simulamos el envío
    // En el futuro, aquí se implementaría el envío real con nodemailer
    res.json({
      success: true,
      message: `Test email would be sent to ${recipient} (not implemented yet)`
    });
  } catch (error) {
    console.error('Error testing email:', error);
    next(error);
  }
};
