const express = require('express');
const router = express.Router();
const settingsController = require('../controllers/settingsController');
const { authMiddleware, checkRole } = require('../middleware/auth');

/**
 * @swagger
 * /settings:
 *   get:
 *     summary: Get system settings
 *     tags: [Settings]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Current system settings
 */
router.get('/', authMiddleware, checkRole('admin'), settingsController.getSettings);

/**
 * @swagger
 * /settings:
 *   put:
 *     summary: Update system settings
 *     tags: [Settings]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Settings updated
 */
router.put('/', authMiddleware, checkRole('admin'), settingsController.updateSettings);

/**
 * @swagger
 * /settings/stats:
 *   get:
 *     summary: Get system statistics
 *     tags: [Settings]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: System statistics
 */
router.get('/stats', authMiddleware, checkRole('admin'), settingsController.getStats);

/**
 * @swagger
 * /settings/export:
 *   get:
 *     summary: Export system data
 *     tags: [Settings]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Exported data
 */
router.get('/export', authMiddleware, checkRole('admin'), settingsController.exportData);

/**
 * @swagger
 * /settings/reset:
 *   post:
 *     summary: Reset settings to default
 *     tags: [Settings]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Settings reset
 */
router.post('/reset', authMiddleware, checkRole('admin'), settingsController.resetSettings);

/**
 * @swagger
 * /settings/test-email:
 *   post:
 *     summary: Test email configuration
 *     tags: [Settings]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Test email sent
 */
router.post('/test-email', authMiddleware, checkRole('admin'), settingsController.testEmail);

module.exports = router;
