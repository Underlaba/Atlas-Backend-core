const jwt = require('jsonwebtoken');
const config = require('../config');

/**
 * Generate JWT access token
 */
const generateAccessToken = (payload) => {
  return jwt.sign(payload, config.jwt.secret, {
    expiresIn: config.jwt.expiresIn,
  });
};

/**
 * Generate JWT refresh token
 */
const generateRefreshToken = (payload) => {
  return jwt.sign(payload, config.jwt.refreshSecret, {
    expiresIn: config.jwt.refreshExpiresIn,
  });
};

/**
 * Verify JWT access token
 */
const verifyAccessToken = (token) => {
  try {
    return jwt.verify(token, config.jwt.secret);
  } catch (error) {
    throw new Error('Invalid or expired token');
  }
};

/**
 * Verify JWT refresh token
 */
const verifyRefreshToken = (token) => {
  try {
    return jwt.verify(token, config.jwt.refreshSecret);
  } catch (error) {
    throw new Error('Invalid or expired refresh token');
  }
};

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
};
