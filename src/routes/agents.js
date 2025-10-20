const express = require('express');
const router = express.Router();
const agentController = require('../controllers/agentController');
const { authMiddleware, checkRole } = require('../middleware/auth');
const { validateAgentRegistration } = require('../middleware/validation');

/**
 * @swagger
 * /agents/register:
 *   post:
 *     summary: Registra un nuevo agente
 *     description: Endpoint público para registrar un dispositivo como agente del sistema Atlas
 *     tags: [Agents]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - device_id
 *               - wallet_address
 *             properties:
 *               device_id:
 *                 type: string
 *                 description: Identificador único del dispositivo
 *                 example: android_device_12345
 *               wallet_address:
 *                 type: string
 *                 pattern: '^0x[a-fA-F0-9]{40}$'
 *                 description: Dirección de wallet Ethereum (42 caracteres)
 *                 example: 0x742d35Cc6634C0532925a3b844Bc454e4438f44e
 *     responses:
 *       201:
 *         description: Agente registrado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Agente registrado exitosamente
 *                 data:
 *                   $ref: '#/components/schemas/Agent'
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
// Ruta pública para registro de agentes
router.post('/register', validateAgentRegistration, agentController.register);

/**
 * @swagger
 * /agents:
 *   get:
 *     summary: Obtiene la lista de todos los agentes
 *     description: Endpoint protegido para obtener todos los agentes registrados (requiere autenticación)
 *     tags: [Agents]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [active, inactive, suspended]
 *         description: Filtrar agentes por estado
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 100
 *         description: Número máximo de resultados
 *       - in: query
 *         name: offset
 *         schema:
 *           type: integer
 *           default: 0
 *         description: Número de resultados a saltar (paginación)
 *     responses:
 *       200:
 *         description: Lista de agentes obtenida exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Agent'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
// Rutas protegidas (requieren autenticación)
router.get('/', authMiddleware, agentController.getAll);

/**
 * @swagger
 * /agents/{id}:
 *   get:
 *     summary: Obtiene un agente por ID
 *     description: Endpoint protegido para obtener información detallada de un agente específico
 *     tags: [Agents]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: ID único del agente (UUID)
 *     responses:
 *       200:
 *         description: Información del agente obtenida exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Agent'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/:id', authMiddleware, agentController.getById);

// Rutas protegidas para agentes (requieren JWT de agente)
router.post('/assign-task', authMiddleware, agentController.assignTask);

/**
 * @swagger
 * /agents/{id}/status:
 *   put:
 *     summary: Actualiza el estado de un agente
 *     description: Endpoint de administración para cambiar el estado de un agente (requiere rol admin)
 *     tags: [Agents]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: ID único del agente
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [active, inactive, suspended]
 *                 description: Nuevo estado del agente
 *                 example: suspended
 *     responses:
 *       200:
 *         description: Estado actualizado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Estado actualizado exitosamente
 *                 data:
 *                   $ref: '#/components/schemas/Agent'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: Acceso denegado - Se requiere rol de administrador
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
// Rutas de administración (requieren rol admin)
router.put('/:id/status', authMiddleware, checkRole('admin'), agentController.updateStatus);

/**
 * @swagger
 * /agents/{id}:
 *   delete:
 *     summary: Elimina un agente
 *     description: Endpoint de administración para eliminar un agente del sistema (requiere rol admin)
 *     tags: [Agents]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: ID único del agente
 *     responses:
 *       200:
 *         description: Agente eliminado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Agente eliminado exitosamente
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: Acceso denegado - Se requiere rol de administrador
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.delete('/:id', authMiddleware, checkRole('admin'), agentController.delete);

module.exports = router;
