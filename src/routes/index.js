const express = require('express');
const router = express.Router();

// Import route modules
const authRoutes = require('./auth');
const agentRoutes = require('./agents');

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

module.exports = router;
