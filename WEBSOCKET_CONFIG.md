# WebSocket Configuration Guide for AWS Deployment

## Overview
This guide explains how to configure and deploy the WebSocket server (Socket.IO) on AWS with PM2 and Nginx.

## Architecture
```
Client (Admin Panel / Agent App)
    ↓ WebSocket Connection
Nginx (Reverse Proxy)
    ↓ HTTP Upgrade
PM2 Process Manager
    ↓
Node.js + Express + Socket.IO Server
```

## Backend Configuration

### 1. Socket.IO Server
Location: `backend-core/src/server.js`

The server is configured to:
- Accept WebSocket connections on the same port as HTTP API (default: 3001)
- Use CORS configuration from `config/index.js`
- Emit real-time events for task operations

### 2. WebSocket Events

#### Emitted Events (Server → Clients)

| Event | Trigger | Payload |
|-------|---------|---------|
| `taskCreated` | New task created | `{ event, timestamp, data: task }` |
| `taskUpdated` | Task edited | `{ event, timestamp, data: task }` |
| `taskCompleted` | Task marked complete | `{ event, timestamp, data: task }` |
| `taskDeleted` | Task deleted | `{ event, timestamp, data: { id } }` |
| `taskAssigned` | Task assigned to agent | `{ event, timestamp, agentWallet, data: task }` |

#### Received Events (Client → Server)

| Event | Purpose |
|-------|---------|
| `connection` | Client connects |
| `disconnect` | Client disconnects |
| `authenticate` | Optional JWT authentication |

### 3. Integration Points

**Tasks Controller** (`src/controllers/tasksController.js`):
- `createTask()` → emits `taskCreated` + `taskAssigned`
- `updateTask()` → emits `taskUpdated`
- `startTask()` → emits `taskUpdated`
- `completeTask()` → emits `taskCompleted`
- `deleteTask()` → emits `taskDeleted`

## AWS Deployment

### 1. PM2 Configuration

Update `ecosystem.config.js`:
```javascript
module.exports = {
  apps: [{
    name: 'atlas-backend',
    script: './src/server.js',
    instances: 1, // Important: Use 1 instance for WebSocket
    exec_mode: 'fork', // Use fork mode, not cluster
    env: {
      NODE_ENV: 'production',
      PORT: 3001
    }
  }]
};
```

**Important**: WebSocket requires sticky sessions. Use `fork` mode with 1 instance, or configure Socket.IO adapter for cluster mode.

### 2. Nginx Configuration

Update `/etc/nginx/sites-available/atlas`:

```nginx
upstream backend {
    server localhost:3001;
}

server {
    listen 80;
    server_name 54.176.126.78;

    # API endpoints
    location /api/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket endpoint
    location /socket.io/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;
    }

    # API Documentation
    location /api-docs {
        proxy_pass http://backend;
        proxy_set_header Host $host;
    }
}
```

### 3. Deployment Commands

```bash
# 1. Upload changes to AWS
scp -i "path/to/Atlas-keypar.pem" -r backend-core ubuntu@54.176.126.78:~/

# 2. SSH into server
ssh -i "path/to/Atlas-keypar.pem" ubuntu@54.176.126.78

# 3. Install dependencies
cd ~/backend-core
npm install

# 4. Restart PM2
pm2 restart atlas-backend
pm2 logs atlas-backend

# 5. Reload Nginx
sudo nginx -t
sudo systemctl reload nginx
```

### 4. Verification

```bash
# Check PM2 status
pm2 status

# Check logs for WebSocket messages
pm2 logs atlas-backend --lines 100

# Check Nginx status
sudo systemctl status nginx
```

## Testing WebSocket Connection

### Using wscat (Command Line)
```bash
npm install -g wscat
wscat -c ws://54.176.126.78/socket.io/?EIO=4&transport=websocket
```

### Using Browser Console
```javascript
// Connect to WebSocket
const socket = io('http://54.176.126.78');

// Listen to events
socket.on('connect', () => console.log('Connected:', socket.id));
socket.on('taskCreated', (data) => console.log('Task Created:', data));
socket.on('taskUpdated', (data) => console.log('Task Updated:', data));
socket.on('taskCompleted', (data) => console.log('Task Completed:', data));
```

## Troubleshooting

### WebSocket not connecting
1. Check Nginx configuration: `sudo nginx -t`
2. Verify proxy_pass is correct
3. Check firewall allows WebSocket connections
4. Verify PM2 process is running: `pm2 status`

### Events not emitting
1. Check PM2 logs: `pm2 logs atlas-backend`
2. Verify `global.io` is defined
3. Check if events are being called in controller

### Multiple PM2 instances issue
- Socket.IO requires sticky sessions
- Use 1 instance or configure Redis adapter for clustering

## Security Considerations

1. **Authentication**: Implement JWT verification in Socket.IO connection handler
2. **Rate Limiting**: Add rate limiting for WebSocket connections
3. **CORS**: Ensure CORS configuration matches frontend domain
4. **SSL/TLS**: Use HTTPS/WSS in production with proper certificates

## Next Steps

1. ✅ Backend WebSocket Server (Story III.1) - **COMPLETED**
2. 🔄 Frontend Integration (Story III.2) - **NEXT**
3. ⏳ Agent App Integration (Story III.3)
4. ⏳ Testing & Documentation

---

**Last Updated**: October 24, 2025
**Version**: 1.0.0
