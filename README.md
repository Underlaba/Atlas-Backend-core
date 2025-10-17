# Backend Core

This module serves as the central backend infrastructure for the Hybrid Influence Platform, providing RESTful APIs, database management, authentication services, and core business logic. It handles user management, data persistence, security protocols, and serves as the primary integration point between all platform components including the agent app, admin panel, and smart contracts.

## 🚀 Tech Stack

- **Node.js** + **Express.js** - Backend framework
- **PostgreSQL** - Primary database
- **JWT** - Authentication & authorization
- **bcrypt** - Password hashing
- **Helmet** + **CORS** - Security

## 📁 Project Structure

```
src/
├── config/          # Database & app configuration
├── controllers/     # Route controllers (business logic)
├── middleware/      # Auth, validation, error handling
├── models/          # Database models
├── routes/          # API route definitions
├── services/        # Business services
├── utils/           # Helper functions (JWT, etc.)
├── database/        # Migrations
└── server.js        # Express app entry point
```

## 🎯 Features

✅ JWT-based authentication (access + refresh tokens)  
✅ Role-based access control (user, agent, admin)  
✅ PostgreSQL database with connection pooling  
✅ Input validation & sanitization  
✅ Rate limiting & security headers  
✅ Centralized error handling  
✅ Database migrations system  

## 🚀 Quick Start

1. **Install Node.js** (v16+): https://nodejs.org/
2. **Install dependencies**: `npm install`
3. **Setup database**: See `SETUP_GUIDE.md`
4. **Configure environment**: `cp .env.example .env`
5. **Run migrations**: `npm run migrate`
6. **Start server**: `npm run dev`

## 📡 API Endpoints

- `POST /api/v1/auth/register` - Register user
- `POST /api/v1/auth/login` - Login
- `GET /api/v1/auth/profile` - Get profile (protected)
- `POST /api/v1/auth/refresh-token` - Refresh token
- `GET /api/v1/health` - Health check

## 📚 Documentation

- **API_README.md** - Complete API documentation
- **SETUP_GUIDE.md** - Detailed setup instructions

## 🔐 Environment Variables

```env
PORT=3000
DB_HOST=localhost
DB_NAME=atlas_db
DB_USER=postgres
DB_PASSWORD=your_password
JWT_SECRET=your-secret-key
```

See `.env.example` for all variables.

---

**Status**: ✅ Ready for development  
**Author**: Underlaba Team
