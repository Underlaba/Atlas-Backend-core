const express = require('express');
const router = express.Router();
const agentController = require('../controllers/agentController');
const { authMiddleware, checkRole } = require('../middleware/auth');
const { validateAgentRegistration } = require('../middleware/validation');

// Ruta pública para registro de agentes
router.post('/register', validateAgentRegistration, agentController.register);

// Rutas protegidas para agentes (requieren JWT de agente)
router.post('/assign-task', authMiddleware, agentController.assignTask);

// Rutas protegidas (requieren autenticación)
router.get('/', authMiddleware, agentController.getAll);
router.get('/:id', authMiddleware, agentController.getById);

// Rutas de administración (requieren rol admin)
router.put('/:id/status', authMiddleware, checkRole('admin'), agentController.updateStatus);
router.delete('/:id', authMiddleware, checkRole('admin'), agentController.delete);

module.exports = router;
