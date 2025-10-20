const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const swaggerUi = require('swagger-ui-express');
require('dotenv').config();

const config = require('./config');
const routes = require('./routes');
const swaggerSpec = require('./config/swagger');
const { errorHandler, notFound } = require('./middleware/error');

// Initialize Express app
const app = express();

// Security middleware - Modified for Swagger UI
app.use(helmet({
  contentSecurityPolicy: false, // Desactivar CSP para Swagger UI
  hsts: false, // Desactivar HSTS para permitir HTTP sin redirección forzada
}));
app.use(cors(config.cors));

// Rate limiting
const limiter = rateLimit(config.rateLimit);
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Compression middleware
app.use(compression());

// Logging middleware
if (config.server.env === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// API Routes
app.use('/api/v1', routes);

// Swagger Documentation
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'Atlas API Documentation',
}));

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Atlas Backend Core API',
    version: '1.0.0',
    documentation: '/api-docs',
    endpoints: {
      health: '/api/v1/health',
      auth: '/api/v1/auth',
      agents: '/api/v1/agents',
    },
  });
});

// 404 handler
app.use(notFound);

// Error handling middleware
app.use(errorHandler);

// Start server
const PORT = config.server.port;

app.listen(PORT, () => {
  console.log(`
    🚀 Server is running!
    🔧 Environment: ${config.server.env}
    🌍 Port: ${PORT}
    📡 API: http://localhost:${PORT}/api/v1
  `);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  console.error('❌ Unhandled Rejection:', err);
  process.exit(1);
});

module.exports = app;
