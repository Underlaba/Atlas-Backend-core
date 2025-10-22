const { pool } = require('../../config/database');

async function createActivityLogsTable() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    console.log('Creating activity_logs table...');
    
    // Crear tabla de logs de actividad
    await client.query(`
      CREATE TABLE IF NOT EXISTS activity_logs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id VARCHAR(255) NOT NULL,
        user_name VARCHAR(255) NOT NULL,
        user_email VARCHAR(255) NOT NULL,
        action VARCHAR(100) NOT NULL,
        target_type VARCHAR(50) NOT NULL,
        target_id VARCHAR(255),
        target_name VARCHAR(255),
        details TEXT,
        metadata JSONB,
        ip_address VARCHAR(50),
        user_agent TEXT,
        timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    console.log('Creating indexes on activity_logs table...');
    
    // Índices para búsquedas comunes
    await client.query(`
      CREATE INDEX IF NOT EXISTS activity_logs_user_id_idx ON activity_logs(user_id)
    `);
    
    await client.query(`
      CREATE INDEX IF NOT EXISTS activity_logs_action_idx ON activity_logs(action)
    `);
    
    await client.query(`
      CREATE INDEX IF NOT EXISTS activity_logs_target_type_idx ON activity_logs(target_type)
    `);
    
    await client.query(`
      CREATE INDEX IF NOT EXISTS activity_logs_timestamp_idx ON activity_logs(timestamp DESC)
    `);
    
    await client.query(`
      CREATE INDEX IF NOT EXISTS activity_logs_created_at_idx ON activity_logs(created_at DESC)
    `);
    
    // Índice compuesto para filtros comunes
    await client.query(`
      CREATE INDEX IF NOT EXISTS activity_logs_user_action_idx ON activity_logs(user_id, action)
    `);
    
    await client.query(`
      CREATE INDEX IF NOT EXISTS activity_logs_target_idx ON activity_logs(target_type, target_id)
    `);
    
    // Índice para búsqueda de texto en details
    await client.query(`
      CREATE INDEX IF NOT EXISTS activity_logs_details_idx ON activity_logs USING gin(to_tsvector('english', details))
    `);
    
    await client.query('COMMIT');
    console.log('Activity logs table created successfully!');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error creating activity logs table:', error);
    throw error;
  } finally {
    client.release();
  }
}

module.exports = createActivityLogsTable;
