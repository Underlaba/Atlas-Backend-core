const User = require('../models/User');
const bcrypt = require('bcryptjs');

/**
 * Get all users
 */
exports.getAllUsers = async (req, res, next) => {
  try {
    const { role, status, search } = req.query;
    
    let query = 'SELECT id, email, first_name, last_name, role, is_active, created_at, updated_at FROM users WHERE 1=1';
    const params = [];
    let paramIndex = 1;

    // Filter by role
    if (role && role !== 'all') {
      query += ` AND role = $${paramIndex}`;
      params.push(role);
      paramIndex++;
    }

    // Filter by status
    if (status !== undefined) {
      query += ` AND is_active = $${paramIndex}`;
      params.push(status === 'true' || status === true);
      paramIndex++;
    }

    // Search by name or email
    if (search) {
      query += ` AND (LOWER(email) LIKE $${paramIndex} OR LOWER(first_name) LIKE $${paramIndex} OR LOWER(last_name) LIKE $${paramIndex})`;
      params.push(`%${search.toLowerCase()}%`);
      paramIndex++;
    }

    query += ' ORDER BY created_at DESC';

    const result = await User.query(query, params);

    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get user by ID
 */
exports.getUserById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const user = await User.findById(id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Remove password from response
    delete user.password;

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Create new user
 */
exports.createUser = async (req, res, next) => {
  try {
    const { email, password, firstName, lastName, role, isActive } = req.body;

    // Check if user already exists
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists'
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const newUser = await User.create({
      email,
      password: hashedPassword,
      first_name: firstName,
      last_name: lastName,
      role: role || 'user',
      is_active: isActive !== undefined ? isActive : true
    });

    // Remove password from response
    delete newUser.password;

    res.status(201).json({
      success: true,
      data: newUser,
      message: 'User created successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update user
 */
exports.updateUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { email, password, firstName, lastName, role, isActive } = req.body;

    // Check if user exists
    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Prepare update data
    const updateData = {
      first_name: firstName,
      last_name: lastName,
      role,
      is_active: isActive
    };

    // Only update email if provided and different
    if (email && email !== user.email) {
      const existingUser = await User.findByEmail(email);
      if (existingUser && existingUser.id !== parseInt(id)) {
        return res.status(400).json({
          success: false,
          message: 'Email already in use'
        });
      }
      updateData.email = email;
    }

    // Only update password if provided
    if (password) {
      updateData.password = await bcrypt.hash(password, 10);
    }

    const updatedUser = await User.update(id, updateData);

    // Remove password from response
    delete updatedUser.password;

    res.json({
      success: true,
      data: updatedUser,
      message: 'User updated successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Delete user
 */
exports.deleteUser = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Check if user exists
    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Prevent deleting yourself
    if (req.user && req.user.id === parseInt(id)) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete your own account'
      });
    }

    await User.delete(id);

    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update user role
 */
exports.updateUserRole = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { role } = req.body;

    if (!['user', 'agent', 'admin'].includes(role)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid role'
      });
    }

    const updatedUser = await User.update(id, { role });
    delete updatedUser.password;

    res.json({
      success: true,
      data: updatedUser,
      message: 'User role updated successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Toggle user status
 */
exports.toggleUserStatus = async (req, res, next) => {
  try {
    const { id } = req.params;

    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Prevent deactivating yourself
    if (req.user && req.user.id === parseInt(id)) {
      return res.status(400).json({
        success: false,
        message: 'Cannot deactivate your own account'
      });
    }

    const updatedUser = await User.update(id, { is_active: !user.is_active });
    delete updatedUser.password;

    res.json({
      success: true,
      data: updatedUser,
      message: `User ${updatedUser.is_active ? 'activated' : 'deactivated'} successfully`
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get users by role
 */
exports.getUsersByRole = async (req, res, next) => {
  try {
    const { role } = req.params;

    const query = 'SELECT id, email, first_name, last_name, role, is_active, created_at FROM users WHERE role = $1 ORDER BY created_at DESC';
    const result = await User.query(query, [role]);

    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get active users
 */
exports.getActiveUsers = async (req, res, next) => {
  try {
    const query = 'SELECT id, email, first_name, last_name, role, created_at FROM users WHERE is_active = true ORDER BY created_at DESC';
    const result = await User.query(query);

    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length
    });
  } catch (error) {
    next(error);
  }
};
