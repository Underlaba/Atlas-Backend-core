/**
 * WebSocket Event Emitter Utility
 * Centralizes all WebSocket event emissions for real-time updates
 */

/**
 * Emit task created event
 * @param {Object} task - The created task object
 */
const emitTaskCreated = (task) => {
  if (global.io) {
    console.log('📡 Emitting taskCreated event:', task.id);
    global.io.emit('taskCreated', {
      event: 'taskCreated',
      timestamp: new Date().toISOString(),
      data: task,
    });
  }
};

/**
 * Emit task updated event
 * @param {Object} task - The updated task object
 */
const emitTaskUpdated = (task) => {
  if (global.io) {
    console.log('📡 Emitting taskUpdated event:', task.id);
    global.io.emit('taskUpdated', {
      event: 'taskUpdated',
      timestamp: new Date().toISOString(),
      data: task,
    });
  }
};

/**
 * Emit task completed event
 * @param {Object} task - The completed task object
 */
const emitTaskCompleted = (task) => {
  if (global.io) {
    console.log('📡 Emitting taskCompleted event:', task.id);
    global.io.emit('taskCompleted', {
      event: 'taskCompleted',
      timestamp: new Date().toISOString(),
      data: task,
    });
  }
};

/**
 * Emit task deleted event
 * @param {Number} taskId - The ID of the deleted task
 */
const emitTaskDeleted = (taskId) => {
  if (global.io) {
    console.log('📡 Emitting taskDeleted event:', taskId);
    global.io.emit('taskDeleted', {
      event: 'taskDeleted',
      timestamp: new Date().toISOString(),
      data: { id: taskId },
    });
  }
};

/**
 * Emit task assigned to specific agent
 * @param {String} agentWallet - Agent wallet address
 * @param {Object} task - The assigned task
 */
const emitTaskAssigned = (agentWallet, task) => {
  if (global.io) {
    console.log('📡 Emitting taskAssigned to agent:', agentWallet);
    global.io.emit('taskAssigned', {
      event: 'taskAssigned',
      timestamp: new Date().toISOString(),
      agentWallet,
      data: task,
    });
  }
};

module.exports = {
  emitTaskCreated,
  emitTaskUpdated,
  emitTaskCompleted,
  emitTaskDeleted,
  emitTaskAssigned,
};
