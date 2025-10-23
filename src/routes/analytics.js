const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analyticsController');
const { authMiddleware, checkRole } = require('../middleware/auth');

/**
 * @swagger
 * /analytics/agents/growth:
 *   get:
 *     summary: Get agents growth analytics
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [day, week, month, year]
 *           default: month
 *     responses:
 *       200:
 *         description: Agents growth data
 */
router.get('/agents/growth', authMiddleware, checkRole('admin'), analyticsController.getAgentsGrowth);

/**
 * @swagger
 * /analytics/users/growth:
 *   get:
 *     summary: Get users growth analytics
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [day, week, month]
 *     responses:
 *       200:
 *         description: Users growth data
 */
router.get('/users/growth', authMiddleware, checkRole('admin'), analyticsController.getUsersGrowth);

/**
 * @swagger
 * /analytics/activity:
 *   get:
 *     summary: Get activity logs statistics
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Activity statistics
 */
router.get('/activity', authMiddleware, checkRole('admin'), analyticsController.getActivityStats);

/**
 * @swagger
 * /analytics/overview:
 *   get:
 *     summary: Get dashboard overview with all metrics
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Dashboard overview data
 */
router.get('/overview', authMiddleware, checkRole('admin'), analyticsController.getDashboardOverview);

module.exports = router;
