const db = require('./src/config/database');

console.log('Probando conexion a la base de datos...\n');

async function testConnection() {
  try {
    const result = await db.query('SELECT NOW() as current_time, version()');
    console.log('Conexion exitosa!');
    console.log('Hora actual:', result.rows[0].current_time);
    console.log('Version:', result.rows[0].version);
    
    const usersCount = await db.query('SELECT COUNT(*) as count FROM users');
    console.log('\nUsuarios en la base de datos:', usersCount.rows[0].count);
    
    process.exit(0);
  } catch (error) {
    console.error('Error de conexion:', error.message);
    process.exit(1);
  }
}

testConnection();
