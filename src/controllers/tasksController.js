/**
 * Tasks Controller
 * Handles CRUD operations for agent tasks
 */

const Task = require('../models/Task');
const Agent = require('../models/Agent');

/**
 * @swagger
 * /api/v1/tasks:
 *   get:
 *     summary: Get all tasks
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: agentWallet
 *         schema:
 *           type: string
 *         description: Filter by agent wallet address
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, in_progress, completed, cancelled]
 *       - in: query
 *         name: priority
 *         schema:
 *           type: string
 *           enum: [low, medium, high, urgent]
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *         description: Page number (default 1)
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *         description: Items per page (default 50)
 *     responses:
 *       200:
 *         description: List of tasks
 */
exports.getAllTasks = async (req, res, next) => {
  try {
    const {
      agentWallet,
      status,
      priority,
      page = 1,
      limit = 50
    } = req.query;

    const offset = (page - 1) * limit;

    const filters = {
      agentWallet,
      status,
      priority,
      limit: parseInt(limit),
      offset: parseInt(offset)
    };

    // If user is an agent, only show their tasks
    if (req.user.role === 'agent' && req.user.walletAddress) {
      filters.agentWallet = req.user.walletAddress;
    }

    const [tasks, total] = await Promise.all([
      Task.findAll(filters),
      Task.count({ agentWallet: filters.agentWallet, status, priority })
    ]);

    res.json({
      success: true,
      data: tasks,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @swagger
 * /api/v1/tasks/{id}:
 *   get:
 *     summary: Get task by ID
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 */
exports.getTaskById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const task = await Task.findById(id);

    if (!task) {
      return res.status(404).json({
        success: false,
        message: 'Task not found'
      });
    }

    // Check authorization
    if (req.user.role === 'agent' && task.agent_wallet !== req.user.walletAddress) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    res.json({
      success: true,
      data: task
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @swagger
 * /api/v1/tasks/agent/{walletAddress}:
 *   get:
 *     summary: Get tasks for specific agent
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 */
exports.getTasksByAgent = async (req, res, next) => {
  try {
    const { walletAddress } = req.params;
    const { status, priority, page = 1, limit = 50 } = req.query;

    // Check if agent exists
    const agent = await Agent.findByWallet(walletAddress);
    if (!agent) {
      return res.status(404).json({
        success: false,
        message: 'Agent not found'
      });
    }

    // Check authorization
    if (req.user.role === 'agent' && walletAddress !== req.user.walletAddress) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const offset = (page - 1) * limit;

    const [tasks, total] = await Promise.all([
      Task.findByAgent(walletAddress, {
        status,
        priority,
        limit: parseInt(limit),
        offset: parseInt(offset)
      }),
      Task.count({ agentWallet: walletAddress, status, priority })
    ]);

    res.json({
      success: true,
      data: tasks,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @swagger
 * /api/v1/tasks:
 *   post:
 *     summary: Create a new task
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 */
exports.createTask = async (req, res, next) => {
  try {
    const { title, description, agentWallet, status, priority, dueDate } = req.body;

    // Validation
    if (!title || !agentWallet) {
      return res.status(400).json({
        success: false,
        message: 'Title and agent wallet are required'
      });
    }

    // Check if agent exists
    const agent = await Agent.findByWallet(agentWallet);
    if (!agent) {
      return res.status(404).json({
        success: false,
        message: 'Agent not found'
      });
    }

    const taskData = {
      title,
      description,
      agentWallet,
      assignedBy: req.user.id,
      status: status || 'pending',
      priority: priority || 'medium',
      dueDate
    };

    const task = await Task.create(taskData);

    res.status(201).json({
      success: true,
      message: 'Task created successfully',
      data: task
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @swagger
 * /api/v1/tasks/{id}:
 *   put:
 *     summary: Update task
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 */
exports.updateTask = async (req, res, next) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    // Check if task exists
    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({
        success: false,
        message: 'Task not found'
      });
    }

    // Check authorization
    if (req.user.role === 'agent' && task.agent_wallet !== req.user.walletAddress) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Agents can only update status
    if (req.user.role === 'agent') {
      const allowedFields = ['status'];
      Object.keys(updates).forEach(key => {
        if (!allowedFields.includes(key)) {
          delete updates[key];
        }
      });
    }

    const updatedTask = await Task.update(id, updates);

    res.json({
      success: true,
      message: 'Task updated successfully',
      data: updatedTask
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @swagger
 * /api/v1/tasks/{id}/start:
 *   post:
 *     summary: Mark task as in progress
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 */
exports.startTask = async (req, res, next) => {
  try {
    const { id } = req.params;

    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({
        success: false,
        message: 'Task not found'
      });
    }

    // Check authorization
    if (req.user.role === 'agent' && task.agent_wallet !== req.user.walletAddress) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    if (task.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Task must be in pending status to start'
      });
    }

    const updatedTask = await Task.markInProgress(id);

    res.json({
      success: true,
      message: 'Task started successfully',
      data: updatedTask
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @swagger
 * /api/v1/tasks/{id}/complete:
 *   post:
 *     summary: Mark task as completed
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 */
exports.completeTask = async (req, res, next) => {
  try {
    const { id } = req.params;

    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({
        success: false,
        message: 'Task not found'
      });
    }

    // Check authorization
    if (req.user.role === 'agent' && task.agent_wallet !== req.user.walletAddress) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    if (task.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Task is already completed'
      });
    }

    const updatedTask = await Task.markCompleted(id);

    res.json({
      success: true,
      message: 'Task completed successfully',
      data: updatedTask
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @swagger
 * /api/v1/tasks/{id}:
 *   delete:
 *     summary: Delete task
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 */
exports.deleteTask = async (req, res, next) => {
  try {
    const { id } = req.params;

    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({
        success: false,
        message: 'Task not found'
      });
    }

    await Task.delete(id);

    res.json({
      success: true,
      message: 'Task deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @swagger
 * /api/v1/tasks/stats:
 *   get:
 *     summary: Get task statistics
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 */
exports.getTaskStats = async (req, res, next) => {
  try {
    const { agentWallet } = req.query;

    const filters = {};
    
    // If user is an agent, only show their stats
    if (req.user.role === 'agent' && req.user.walletAddress) {
      filters.agentWallet = req.user.walletAddress;
    } else if (agentWallet) {
      filters.agentWallet = agentWallet;
    }

    const stats = await Task.getStats(filters);

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    next(error);
  }
};
