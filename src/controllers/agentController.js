const Agent = require('../models/Agent');
const { generateAccessToken } = require('../utils/jwt');

const agentController = {
  async register(req, res, next) {
    try {
      const { deviceId, walletAddress } = req.body;

      // Validar campos requeridos
      if (!deviceId || !walletAddress) {
        return res.status(400).json({
          success: false,
          message: 'Device ID and wallet address are required'
        });
      }

      // Validar formato de wallet address
      const walletRegex = /^0x[a-fA-F0-9]{40}$/;
      if (!walletRegex.test(walletAddress)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid wallet address format. Must be 0x followed by 40 hexadecimal characters'
        });
      }

      // Verificar si el device ID ya existe
      const existingDevice = await Agent.findByDeviceId(deviceId);
      if (existingDevice) {
        return res.status(409).json({
          success: false,
          message: 'Device already registered',
          data: {
            id: existingDevice.id,
            deviceId: existingDevice.device_id,
            walletAddress: existingDevice.wallet_address,
            status: existingDevice.status,
            createdAt: existingDevice.created_at
          }
        });
      }

      // Verificar si la wallet ya existe
      const existingWallet = await Agent.findByWalletAddress(walletAddress);
      if (existingWallet) {
        return res.status(409).json({
          success: false,
          message: 'Wallet address already registered',
          data: {
            id: existingWallet.id,
            deviceId: existingWallet.device_id,
            walletAddress: existingWallet.wallet_address,
            status: existingWallet.status,
            createdAt: existingWallet.created_at
          }
        });
      }

      // Crear nuevo agente
      const agent = await Agent.create({
        deviceId,
        walletAddress
      });

      // Generar JWT para el agente
      const token = generateAccessToken({
        id: agent.id,
        deviceId: agent.device_id,
        walletAddress: agent.wallet_address,
        role: 'agent'
      });

      console.log(`[JWT] Token generated for agent ${agent.device_id}: ${token.substring(0, 20)}...`);

      res.status(201).json({
        success: true,
        message: 'Agent registered successfully',
        data: {
          id: agent.id,
          deviceId: agent.device_id,
          walletAddress: agent.wallet_address,
          status: agent.status,
          createdAt: agent.created_at,
          token: token
        }
      });
    } catch (error) {
      next(error);
    }
  },

  async getAll(req, res, next) {
    try {
      const { limit = 100, offset = 0 } = req.query;
      
      const agents = await Agent.findAll({ 
        limit: parseInt(limit), 
        offset: parseInt(offset) 
      });
      
      const total = await Agent.count();

      res.json({
        success: true,
        data: agents.map(agent => ({
          id: agent.id,
          deviceId: agent.device_id,
          walletAddress: agent.wallet_address,
          status: agent.status,
          createdAt: agent.created_at,
          updatedAt: agent.updated_at
        })),
        pagination: {
          total,
          limit: parseInt(limit),
          offset: parseInt(offset),
          hasMore: (parseInt(offset) + parseInt(limit)) < total
        }
      });
    } catch (error) {
      next(error);
    }
  },

  async getById(req, res, next) {
    try {
      const { id } = req.params;
      
      const agent = await Agent.findById(id);
      
      if (!agent) {
        return res.status(404).json({
          success: false,
          message: 'Agent not found'
        });
      }

      res.json({
        success: true,
        data: {
          id: agent.id,
          deviceId: agent.device_id,
          walletAddress: agent.wallet_address,
          status: agent.status,
          createdAt: agent.created_at,
          updatedAt: agent.updated_at
        }
      });
    } catch (error) {
      next(error);
    }
  },

  async updateStatus(req, res, next) {
    try {
      const { id } = req.params;
      const { status } = req.body;

      if (!status) {
        return res.status(400).json({
          success: false,
          message: 'Status is required'
        });
      }

      const validStatuses = ['active', 'inactive', 'suspended'];
      if (!validStatuses.includes(status)) {
        return res.status(400).json({
          success: false,
          message: `Status must be one of: ${validStatuses.join(', ')}`
        });
      }

      const agent = await Agent.updateStatus(id, status);
      
      if (!agent) {
        return res.status(404).json({
          success: false,
          message: 'Agent not found'
        });
      }

      res.json({
        success: true,
        message: 'Agent status updated successfully',
        data: {
          id: agent.id,
          deviceId: agent.device_id,
          walletAddress: agent.wallet_address,
          status: agent.status,
          updatedAt: agent.updated_at
        }
      });
    } catch (error) {
      next(error);
    }
  },

  async delete(req, res, next) {
    try {
      const { id } = req.params;
      
      const agent = await Agent.delete(id);
      
      if (!agent) {
        return res.status(404).json({
          success: false,
          message: 'Agent not found'
        });
      }

      res.json({
        success: true,
        message: 'Agent deleted successfully',
        data: {
          id: agent.id,
          deviceId: agent.device_id
        }
      });
    } catch (error) {
      next(error);
    }
  },

  async assignTask(req, res, next) {
    try {
      const { taskId, description } = req.body;

      // Verificar que el usuario autenticado es un agente
      if (req.user.role !== 'agent') {
        return res.status(403).json({
          success: false,
          message: 'Only agents can be assigned tasks'
        });
      }

      console.log(`[ASSIGN-TASK] Task ${taskId} assigned to agent ${req.user.deviceId}`);

      res.json({
        success: true,
        message: 'Task assigned successfully',
        data: {
          agentId: req.user.id,
          deviceId: req.user.deviceId,
          taskId: taskId || 'TASK-' + Date.now(),
          description: description || 'Sample task description',
          status: 'assigned',
          assignedAt: new Date().toISOString()
        }
      });
    } catch (error) {
      next(error);
    }
  }
};

module.exports = agentController;
