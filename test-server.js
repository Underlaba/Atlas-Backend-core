const http = require('http');

const PORT = 3000;

const server = http.createServer((req, res) => {
  console.log(`Request received: ${req.method} ${req.url}`);
  
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Content-Type', 'application/json');
  
  // Handle OPTIONS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }
  
  // Health check
  if (req.url === '/api/v1/health' && req.method === 'GET') {
    res.writeHead(200);
    res.end(JSON.stringify({
      success: true,
      message: 'Test server is running',
      timestamp: new Date().toISOString()
    }));
    return;
  }
  
  // Agent registration
  if (req.url === '/api/v1/agents/register' && req.method === 'POST') {
    let body = '';
    
    req.on('data', chunk => {
      body += chunk.toString();
    });
    
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        console.log('Registration data:', data);
        
        res.writeHead(200);
        res.end(JSON.stringify({
          success: true,
          message: 'Agent registered successfully',
          data: {
            id: Math.floor(Math.random() * 1000),
            deviceId: data.deviceId,
            walletAddress: data.walletAddress,
            createdAt: new Date().toISOString()
          }
        }));
      } catch (error) {
        console.error('Error parsing body:', error);
        res.writeHead(400);
        res.end(JSON.stringify({
          success: false,
          message: 'Invalid request body'
        }));
      }
    });
    return;
  }
  
  // 404 for other routes
  res.writeHead(404);
  res.end(JSON.stringify({
    success: false,
    message: 'Not found'
  }));
});

server.listen(PORT, '0.0.0.0', () => {
  console.log('='.repeat(50));
  console.log(`TEST SERVER RUNNING`);
  console.log(`Port: ${PORT}`);
  console.log(`Health: http://localhost:${PORT}/api/v1/health`);
  console.log(`Register: http://localhost:${PORT}/api/v1/agents/register`);
  console.log('='.repeat(50));
});

server.on('error', (error) => {
  console.error('SERVER ERROR:', error);
  if (error.code === 'EADDRINUSE') {
    console.error(`Port ${PORT} is already in use!`);
    process.exit(1);
  }
});

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\nShutting down server...');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});