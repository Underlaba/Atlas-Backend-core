# Atlas Backend Core API

RESTful API backend for the Hybrid Influence Platform built with Node.js, Express, PostgreSQL, and JWT authentication.

## 🚀 Features

- ✅ **Express.js** - Fast, unopinionated web framework
- ✅ **PostgreSQL** - Powerful relational database
- ✅ **JWT Authentication** - Secure token-based authentication
- ✅ **Role-based Access Control** - User, Agent, Admin roles
- ✅ **Input Validation** - Express validator middleware
- ✅ **Security** - Helmet, CORS, Rate limiting
- ✅ **Clean Architecture** - Organized folder structure
- ✅ **Error Handling** - Centralized error middleware

## 📁 Project Structure

```
backend-core/
├── src/
│   ├── config/          # Configuration files
│   │   ├── database.js  # PostgreSQL connection
│   │   └── index.js     # App configuration
│   ├── controllers/     # Route controllers
│   │   └── authController.js
│   ├── middleware/      # Custom middleware
│   │   ├── auth.js      # JWT verification
│   │   ├── error.js     # Error handling
│   │   └── validation.js
│   ├── models/          # Database models
│   │   └── User.js
│   ├── routes/          # API routes
│   │   ├── auth.js
│   │   └── index.js
│   ├── services/        # Business logic
│   ├── utils/           # Utility functions
│   │   └── jwt.js
│   ├── database/
│   │   └── migrations/  # Database migrations
│   └── server.js        # Express app entry point
├── .env.example         # Environment variables template
├── .gitignore
├── package.json
└── README.md
```

## 🛠️ Installation

### Prerequisites
- Node.js (v16 or higher)
- PostgreSQL (v12 or higher)
- npm or yarn

### Steps

1. **Clone the repository**
   ```bash
   cd backend-core
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Setup environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` with your configuration:
   ```env
   PORT=3000
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=atlas_db
   DB_USER=postgres
   DB_PASSWORD=your_password
   JWT_SECRET=your-secret-key
   ```

4. **Create PostgreSQL database**
   ```bash
   psql -U postgres
   CREATE DATABASE atlas_db;
   \q
   ```

5. **Run database migrations**
   ```bash
   npm run migrate
   ```

6. **Start the server**
   ```bash
   # Development mode
   npm run dev
   
   # Production mode
   npm start
   ```

## 📡 API Endpoints

### Authentication

#### Register User
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe"
}
```

#### Login
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

#### Get Profile (Protected)
```http
GET /api/v1/auth/profile
Authorization: Bearer <access_token>
```

#### Refresh Token
```http
POST /api/v1/auth/refresh-token
Content-Type: application/json

{
  "refreshToken": "<refresh_token>"
}
```

### Health Check
```http
GET /api/v1/health
```

## 🔐 Authentication

The API uses JWT (JSON Web Tokens) for authentication:

1. Register or login to receive `accessToken` and `refreshToken`
2. Include the `accessToken` in the Authorization header:
   ```
   Authorization: Bearer <your_access_token>
   ```
3. Access tokens expire in 24 hours
4. Use the refresh token endpoint to get a new access token

## 👥 User Roles

- **user** - Basic user access
- **agent** - Field agent access
- **admin** - Administrator access

Use the `checkRole` middleware to protect routes:
```javascript
router.get('/admin', authMiddleware, checkRole('admin'), controller);
```

## 🗄️ Database Schema

### Users Table
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  role VARCHAR(50) DEFAULT 'user',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🧪 Testing

```bash
npm test
```

## 📝 Scripts

- `npm start` - Start production server
- `npm run dev` - Start development server with nodemon
- `npm run migrate` - Run database migrations
- `npm test` - Run tests

## 🔒 Security Features

- **Helmet** - Sets security HTTP headers
- **CORS** - Cross-origin resource sharing
- **Rate Limiting** - Prevents brute force attacks
- **bcrypt** - Password hashing
- **JWT** - Secure token-based authentication
- **Input Validation** - Express validator

## 🌐 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Environment (development/production) | development |
| `PORT` | Server port | 3000 |
| `DB_HOST` | PostgreSQL host | localhost |
| `DB_PORT` | PostgreSQL port | 5432 |
| `DB_NAME` | Database name | atlas_db |
| `DB_USER` | Database user | postgres |
| `DB_PASSWORD` | Database password | - |
| `JWT_SECRET` | JWT secret key | - |
| `JWT_EXPIRES_IN` | Access token expiry | 24h |
| `JWT_REFRESH_SECRET` | Refresh token secret | - |
| `JWT_REFRESH_EXPIRES_IN` | Refresh token expiry | 7d |

## 🚀 Deployment

1. Set `NODE_ENV=production`
2. Configure production database
3. Set strong JWT secrets
4. Enable HTTPS
5. Configure CORS_ORIGIN to your frontend URL

## 📄 License

MIT

## 👥 Author

Underlaba - Atlas Platform Team
