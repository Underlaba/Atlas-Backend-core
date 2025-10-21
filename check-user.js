const db = require('./src/config/database');

async function checkUser() {
  try {
    const result = await db.query(`
      SELECT id, email, role, created_at 
      FROM users 
      ORDER BY created_at 
      LIMIT 1
    `);
    
    console.log('\n📋 Usuario en Base de Datos:');
    console.log('─────────────────────────────');
    console.log(JSON.stringify(result.rows[0], null, 2));
    console.log('─────────────────────────────');
    
    // Verificar específicamente el rol
    const user = result.rows[0];
    console.log(`\n✅ Email: ${user.email}`);
    console.log(`✅ Role: ${user.role}`);
    console.log(`✅ ID: ${user.id}`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

checkUser();
