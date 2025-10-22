const express = require('express');
const router = express.Router();
const logsController = require('../controllers/logsController');
const { authMiddleware, checkRole } = require('../middleware/auth');
const { createLoggers } = require('../middleware/activityLogger');

/**
 * @swagger
 * /logs:
 *   get:
 *     summary: Get all activity logs
 *     description: Get paginated list of activity logs with optional filters (admin only)
 *     tags: [Logs]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Items per page
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Filter logs from this date
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Filter logs until this date
 *       - in: query
 *         name: userId
 *         schema:
 *           type: string
 *         description: Filter by user ID
 *       - in: query
 *         name: action
 *         schema:
 *           type: string
 *         description: Filter by action type
 *       - in: query
 *         name: targetType
 *         schema:
 *           type: string
 *         description: Filter by target type
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search in details, user name, and email
 *     responses:
 *       200:
 *         description: List of activity logs
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin only
 */
router.get('/', authMiddleware, checkRole(['admin']), logsController.getLogs, createLoggers.logsViewed());

/**
 * @swagger
 * /logs:
 *   post:
 *     summary: Create a new activity log
 *     description: Manually create an activity log entry (admin only)
 *     tags: [Logs]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - userId
 *               - userName
 *               - userEmail
 *               - action
 *               - targetType
 *             properties:
 *               userId:
 *                 type: string
 *               userName:
 *                 type: string
 *               userEmail:
 *                 type: string
 *               action:
 *                 type: string
 *               targetType:
 *                 type: string
 *               targetId:
 *                 type: string
 *               targetName:
 *                 type: string
 *               details:
 *                 type: string
 *               metadata:
 *                 type: object
 *     responses:
 *       201:
 *         description: Log created successfully
 *       400:
 *         description: Invalid input
 *       401:
 *         description: Unauthorized
 */
router.post('/', authMiddleware, checkRole(['admin']), logsController.createLog);

/**
 * @swagger
 * /logs/export:
 *   get:
 *     summary: Export logs to CSV or JSON
 *     description: Download activity logs in CSV or JSON format (admin only)
 *     tags: [Logs]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: format
 *         schema:
 *           type: string
 *           enum: [csv, json]
 *           default: json
 *         description: Export format
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date-time
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date-time
 *       - in: query
 *         name: userId
 *         schema:
 *           type: string
 *       - in: query
 *         name: action
 *         schema:
 *           type: string
 *       - in: query
 *         name: targetType
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Exported file
 *       401:
 *         description: Unauthorized
 */
router.get('/export', authMiddleware, checkRole(['admin']), logsController.exportLogs, createLoggers.logsExported());

/**
 * @swagger
 * /logs/stats:
 *   get:
 *     summary: Get activity statistics
 *     description: Get aggregated statistics about activity logs (admin only)
 *     tags: [Logs]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [day, week, month]
 *           default: week
 *         description: Time period for statistics
 *     responses:
 *       200:
 *         description: Activity statistics
 *       401:
 *         description: Unauthorized
 */
router.get('/stats', authMiddleware, checkRole(['admin']), logsController.getStats);

/**
 * @swagger
 * /logs/{id}:
 *   get:
 *     summary: Get a single log by ID
 *     description: Retrieve details of a specific activity log (admin only)
 *     tags: [Logs]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Log ID
 *     responses:
 *       200:
 *         description: Log details
 *       404:
 *         description: Log not found
 *       401:
 *         description: Unauthorized
 */
router.get('/:id', authMiddleware, checkRole(['admin']), logsController.getLogById);

/**
 * @swagger
 * /logs:
 *   delete:
 *     summary: Delete old logs
 *     description: Delete activity logs before a specific date (admin only)
 *     tags: [Logs]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: beforeDate
 *         required: true
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Delete logs before this date
 *     responses:
 *       200:
 *         description: Logs deleted successfully
 *       400:
 *         description: Missing beforeDate parameter
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin only
 */
router.delete('/', authMiddleware, checkRole(['admin']), logsController.deleteLogs);

module.exports = router;
