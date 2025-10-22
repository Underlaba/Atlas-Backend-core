const express = require('express');
const router = express.Router();

// Import route modules
const authRoutes = require('./auth');
const agentRoutes = require('./agents');
const logsRoutes = require('./logs');
const usersRoutes = require('./users');

/**
 * @swagger
 * /health:
 *   get:
 *     summary: Verifica el estado del servidor
 *     description: Endpoint para verificar que la API está funcionando correctamente
 *     tags: [Health]
 *     responses:
 *       200:
 *         description: Servidor funcionando correctamente
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/HealthCheck'
 *             example:
 *               success: true
 *               message: API is running
 *               timestamp: 2025-10-20T22:00:00.000Z
 */
// Health check
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'API is running',
    timestamp: new Date().toISOString(),
  });
});

// Mount routes
router.use('/auth', authRoutes);
router.use('/agents', agentRoutes);
router.use('/logs', logsRoutes);
router.use('/users', usersRoutes);

module.exports = router;
