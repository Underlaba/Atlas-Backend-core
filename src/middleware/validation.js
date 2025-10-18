const { validationResult } = require('express-validator');

/**
 * Validation middleware
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array().map(err => ({
        field: err.path,
        message: err.msg,
      })),
    });
  }
  
  next();
};

/**
 * Agent registration validation
 */
const validateAgentRegistration = (req, res, next) => {
  const { deviceId, walletAddress } = req.body;

  if (!deviceId || typeof deviceId !== 'string' || deviceId.trim().length === 0) {
    return res.status(400).json({
      success: false,
      message: 'Valid device ID is required'
    });
  }

  if (!walletAddress || typeof walletAddress !== 'string') {
    return res.status(400).json({
      success: false,
      message: 'Valid wallet address is required'
    });
  }

  const walletRegex = /^0x[a-fA-F0-9]{40}$/;
  if (!walletRegex.test(walletAddress)) {
    return res.status(400).json({
      success: false,
      message: 'Invalid wallet address format. Must start with 0x and be 42 characters long'
    });
  }

  next();
};

module.exports = { validate, validateAgentRegistration };
