/**
 * Tasks Routes
 * Endpoints for task management
 */

const express = require('express');
const router = express.Router();
const tasksController = require('../controllers/tasksController');
const authMiddleware = require('../middleware/auth');
const { checkRole } = require('../middleware/auth');

/**
 * @swagger
 * tags:
 *   name: Tasks
 *   description: Task management for agents
 */

// Get all tasks (with filters)
router.get(
  '/',
  authMiddleware,
  tasksController.getAllTasks
);

// Get task statistics
router.get(
  '/stats',
  authMiddleware,
  tasksController.getTaskStats
);

// Get tasks for specific agent
router.get(
  '/agent/:walletAddress',
  authMiddleware,
  tasksController.getTasksByAgent
);

// Get task by ID
router.get(
  '/:id',
  authMiddleware,
  tasksController.getTaskById
);

// Create new task (admin only)
router.post(
  '/',
  authMiddleware,
  checkRole('admin'),
  tasksController.createTask
);

// Update task
router.put(
  '/:id',
  authMiddleware,
  tasksController.updateTask
);

// Mark task as in progress
router.post(
  '/:id/start',
  authMiddleware,
  tasksController.startTask
);

// Mark task as completed
router.post(
  '/:id/complete',
  authMiddleware,
  tasksController.completeTask
);

// Delete task (admin only)
router.delete(
  '/:id',
  authMiddleware,
  checkRole('admin'),
  tasksController.deleteTask
);

module.exports = router;
