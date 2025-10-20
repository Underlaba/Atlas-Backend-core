const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Atlas Backend API',
      version: '1.0.0',
      description: 'API REST para el sistema Atlas - Gestión de agentes y autenticación',
      contact: {
        name: 'Underlaba',
        url: 'https://github.com/Underlaba',
      },
      license: {
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT',
      },
    },
    servers: [
      {
        url: 'http://localhost:3000/api/v1',
        description: 'Servidor de desarrollo',
      },
      {
        url: 'http://54.176.126.78/api/v1',
        description: 'Servidor de producción (AWS EC2)',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Token JWT de autenticación',
        },
      },
      schemas: {
        Agent: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'ID único del agente (UUID)',
              example: '123e4567-e89b-12d3-a456-426614174000',
            },
            device_id: {
              type: 'string',
              description: 'Identificador único del dispositivo',
              example: 'android_device_12345',
            },
            wallet_address: {
              type: 'string',
              pattern: '^0x[a-fA-F0-9]{40}$',
              description: 'Dirección de wallet Ethereum (42 caracteres)',
              example: '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
            },
            status: {
              type: 'string',
              enum: ['active', 'inactive', 'suspended'],
              description: 'Estado del agente',
              example: 'active',
            },
            created_at: {
              type: 'string',
              format: 'date-time',
              description: 'Fecha de creación del registro',
              example: '2025-10-20T22:00:00.000Z',
            },
            updated_at: {
              type: 'string',
              format: 'date-time',
              description: 'Fecha de última actualización',
              example: '2025-10-20T22:00:00.000Z',
            },
          },
        },
        User: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'ID único del usuario',
              example: '987e6543-e21b-98d7-c654-321098765432',
            },
            email: {
              type: 'string',
              format: 'email',
              description: 'Email del usuario',
              example: 'admin@atlas.com',
            },
            role: {
              type: 'string',
              enum: ['admin', 'user'],
              description: 'Rol del usuario',
              example: 'admin',
            },
          },
        },
        Error: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: false,
            },
            message: {
              type: 'string',
              description: 'Mensaje de error',
              example: 'Error en la operación',
            },
            error: {
              type: 'string',
              description: 'Detalles del error',
              example: 'Validation failed',
            },
          },
        },
        HealthCheck: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: true,
            },
            message: {
              type: 'string',
              example: 'API is running',
            },
            timestamp: {
              type: 'string',
              format: 'date-time',
              example: '2025-10-20T22:00:00.000Z',
            },
          },
        },
      },
      responses: {
        UnauthorizedError: {
          description: 'Token de autenticación faltante o inválido',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error',
              },
              example: {
                success: false,
                message: 'No autorizado',
                error: 'Token inválido o expirado',
              },
            },
          },
        },
        BadRequestError: {
          description: 'Solicitud inválida o datos incorrectos',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error',
              },
              example: {
                success: false,
                message: 'Datos inválidos',
                error: 'Validation error',
              },
            },
          },
        },
        NotFoundError: {
          description: 'Recurso no encontrado',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error',
              },
              example: {
                success: false,
                message: 'No encontrado',
                error: 'El recurso solicitado no existe',
              },
            },
          },
        },
        ServerError: {
          description: 'Error interno del servidor',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error',
              },
              example: {
                success: false,
                message: 'Error del servidor',
                error: 'Internal server error',
              },
            },
          },
        },
      },
    },
    tags: [
      {
        name: 'Health',
        description: 'Endpoints de verificación del estado del servidor',
      },
      {
        name: 'Authentication',
        description: 'Endpoints de autenticación y gestión de usuarios',
      },
      {
        name: 'Agents',
        description: 'Endpoints de gestión de agentes del sistema Atlas',
      },
    ],
  },
  apis: ['./src/routes/*.js', './src/controllers/*.js'],
};

const swaggerSpec = swaggerJsdoc(options);

module.exports = swaggerSpec;
