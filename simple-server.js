const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware básico
app.use(cors());
app.use(express.json());

// Health check
app.get('/api/v1/health', (req, res) => {
  res.json({
    success: true,
    message: 'API is running',
    timestamp: new Date().toISOString(),
  });
});

// Registro de agente (simplificado)
app.post('/api/v1/agents/register', (req, res) => {
  const { deviceId, walletAddress } = req.body;
  
  console.log('Registration request:', { deviceId, walletAddress });
  
  // Validación básica
  if (!deviceId || !walletAddress) {
    return res.status(400).json({
      success: false,
      message: 'deviceId and walletAddress are required'
    });
  }
  
  if (!walletAddress.startsWith('0x') || walletAddress.length !== 42) {
    return res.status(400).json({
      success: false,
      message: 'Invalid wallet address format'
    });
  }
  
  // Simular registro exitoso
  res.json({
    success: true,
    message: 'Agent registered successfully',
    data: {
      id: Math.floor(Math.random() * 1000),
      deviceId,
      walletAddress,
      createdAt: new Date().toISOString()
    }
  });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`
    🚀 Atlas Backend (Simple) is running!
    🌍 Port: ${PORT}
    📡 Health: http://localhost:${PORT}/api/v1/health
    📱 Register: http://localhost:${PORT}/api/v1/agents/register
  `);
});

module.exports = app;