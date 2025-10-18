const { pool } = require('../../config/database');

async function createAgentsTable() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    console.log('Creating agents table...');
    
    // Crear tabla de agentes
    await client.query(`
      CREATE TABLE IF NOT EXISTS agents (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        device_id VARCHAR(255) NOT NULL UNIQUE,
        wallet_address VARCHAR(42) NOT NULL UNIQUE,
        status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    console.log('Creating indexes on agents table...');
    
    // Crear índices
    await client.query(`
      CREATE INDEX IF NOT EXISTS agents_device_id_idx ON agents(device_id)
    `);
    
    await client.query(`
      CREATE INDEX IF NOT EXISTS agents_wallet_address_idx ON agents(wallet_address)
    `);
    
    await client.query(`
      CREATE INDEX IF NOT EXISTS agents_status_idx ON agents(status)
    `);
    
    await client.query(`
      CREATE INDEX IF NOT EXISTS agents_created_at_idx ON agents(created_at)
    `);
    
    await client.query('COMMIT');
    console.log('Agents table created successfully!');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error creating agents table:', error);
    throw error;
  } finally {
    client.release();
  }
}

async function run() {
  try {
    console.log('Starting agents table migration...');
    await createAgentsTable();
    console.log('Migration completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

// Solo ejecutar si es el archivo principal
if (require.main === module) {
  run();
}

module.exports = { createAgentsTable };
