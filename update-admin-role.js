const db = require('./src/config/database');

async function updateUserRole() {
  try {
    console.log('🔧 Actualizando rol de usuario a ADMIN...\n');
    
    // Actualizar el primer usuario (el que creaste) a admin
    await db.query(`
      UPDATE users 
      SET role = 'admin' 
      WHERE email = (SELECT email FROM users ORDER BY created_at LIMIT 1)
    `);
    
    console.log('✅ Usuario actualizado exitosamente\n');
    
    // Mostrar usuarios
    const result = await db.query('SELECT id, email, role, created_at FROM users ORDER BY created_at');
    
    console.log('📋 Usuarios en la base de datos:');
    console.log('─────────────────────────────────────────────────────');
    result.rows.forEach(user => {
      console.log(`📧 Email: ${user.email}`);
      console.log(`👤 Rol:   ${user.role.toUpperCase()}`);
      console.log(`📅 Fecha: ${user.created_at}`);
      console.log('─────────────────────────────────────────────────────');
    });
    
    console.log('\n✨ Ahora puedes:');
    console.log('   1. Cierra sesión en el Admin Panel');
    console.log('   2. Vuelve a iniciar sesión');
    console.log('   3. Prueba "Set Inactive" nuevamente\n');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

updateUserRole();
