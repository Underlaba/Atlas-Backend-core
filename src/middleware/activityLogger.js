const ActivityLog = require('../models/ActivityLog');

/**
 * Middleware to automatically log user activities
 * This middleware should be used after authentication middleware
 * so that req.user is available
 */
const activityLogger = (action, targetType) => {
  return async (req, res, next) => {
    // Store original res.json to intercept response
    const originalJson = res.json.bind(res);

    res.json = function(body) {
      // Only log if request was successful
      if (body.success !== false && res.statusCode < 400) {
        // Log asynchronously without blocking response
        setImmediate(async () => {
          try {
            const user = req.user;
            if (!user) {
              console.warn('Activity logger: No user found in request');
              return;
            }

            let targetId = null;
            let targetName = null;
            let details = null;

            // Extract target information based on the response body
            if (body.data) {
              if (body.data.id) {
                targetId = body.data.id;
              }
              if (body.data.deviceId) {
                targetName = body.data.deviceId;
              }
              if (body.data.walletAddress) {
                details = `Wallet: ${body.data.walletAddress}`;
              }
              if (body.data.status) {
                details = details 
                  ? `${details}, Status: ${body.data.status}`
                  : `Status: ${body.data.status}`;
              }
            }

            // Extract from request body if not in response
            if (!targetId && req.body && req.body.id) {
              targetId = req.body.id;
            }
            if (!targetName && req.params && req.params.id) {
              targetId = req.params.id;
            }

            // Get IP address
            const ipAddress = req.ip || 
                            req.connection.remoteAddress || 
                            req.socket.remoteAddress ||
                            (req.connection.socket ? req.connection.socket.remoteAddress : null);

            // Get user agent
            const userAgent = req.get('user-agent');

            await ActivityLog.create({
              userId: user.id ? user.id.toString() : user.email,
              userName: user.firstName && user.lastName 
                ? `${user.firstName} ${user.lastName}` 
                : user.email,
              userEmail: user.email,
              action,
              targetType,
              targetId,
              targetName,
              details,
              metadata: {
                method: req.method,
                path: req.path,
                statusCode: res.statusCode
              },
              ipAddress,
              userAgent
            });
          } catch (error) {
            console.error('Error logging activity:', error);
            // Don't throw - logging should not break the application
          }
        });
      }

      // Call original res.json
      return originalJson(body);
    };

    next();
  };
};

/**
 * Helper function to create specific loggers for common actions
 */
const createLoggers = {
  // Authentication loggers
  login: () => activityLogger('login', 'auth'),
  logout: () => activityLogger('logout', 'auth'),
  loginFailed: () => activityLogger('login_failed', 'auth'),

  // Agent loggers
  agentCreated: () => activityLogger('agent_created', 'agent'),
  agentUpdated: () => activityLogger('agent_updated', 'agent'),
  agentDeleted: () => activityLogger('agent_deleted', 'agent'),
  agentStatusChanged: () => activityLogger('agent_status_changed', 'agent'),
  agentViewed: () => activityLogger('agent_viewed', 'agent'),

  // User loggers
  userCreated: () => activityLogger('user_created', 'user'),
  userUpdated: () => activityLogger('user_updated', 'user'),
  userDeleted: () => activityLogger('user_deleted', 'user'),
  userRoleChanged: () => activityLogger('user_role_changed', 'user'),

  // System loggers
  settingsChanged: () => activityLogger('settings_changed', 'system'),
  logsExported: () => activityLogger('logs_exported', 'system'),
  logsViewed: () => activityLogger('logs_viewed', 'system')
};

module.exports = {
  activityLogger,
  createLoggers
};
