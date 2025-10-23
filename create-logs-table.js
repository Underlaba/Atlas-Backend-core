const db = require('./src/config/database');

async function createTable() {
  try {
    console.log('Creating activity_logs table...');
    
    await db.query(`
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
    
    console.log('Creating indexes...');
    
    await db.query('CREATE INDEX IF NOT EXISTS activity_logs_user_id_idx ON activity_logs(user_id)');
    await db.query('CREATE INDEX IF NOT EXISTS activity_logs_action_idx ON activity_logs(action)');
    await db.query('CREATE INDEX IF NOT EXISTS activity_logs_target_type_idx ON activity_logs(target_type)');
    await db.query('CREATE INDEX IF NOT EXISTS activity_logs_timestamp_idx ON activity_logs(timestamp DESC)');
    await db.query('CREATE INDEX IF NOT EXISTS activity_logs_created_at_idx ON activity_logs(created_at DESC)');
    
    console.log('✅ Table and indexes created successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

createTable();
