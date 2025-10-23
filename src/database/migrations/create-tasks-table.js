/**
 * Migration: Create tasks table
 * Purpose: Manage tasks assigned to agents
 * Sprint: 4 - Epic II
 */

const db = require('../../config/database');

async function createTasksTable() {
  console.log('🔄 Creating tasks table...');

  const createTableQuery = `
    CREATE TABLE IF NOT EXISTS tasks (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      
      -- Task information
      title VARCHAR(255) NOT NULL,
      description TEXT,
      
      -- Assignment
      agent_wallet VARCHAR(255) NOT NULL,
      assigned_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
      
      -- Status and priority
      status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
      priority VARCHAR(50) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
      
      -- Dates
      due_date TIMESTAMP,
      started_at TIMESTAMP,
      completed_at TIMESTAMP,
      
      -- Metadata
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      
      -- Constraints
      CONSTRAINT fk_agent FOREIGN KEY (agent_wallet) REFERENCES agents(wallet_address) ON DELETE CASCADE
    );
  `;

  const createIndexesQuery = `
    -- Index for agent queries (most common)
    CREATE INDEX IF NOT EXISTS idx_tasks_agent_wallet ON tasks(agent_wallet);
    
    -- Index for status filtering
    CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
    
    -- Index for priority filtering
    CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
    
    -- Index for due date sorting
    CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
    
    -- Index for assigned_by (admin tracking)
    CREATE INDEX IF NOT EXISTS idx_tasks_assigned_by ON tasks(assigned_by);
    
    -- Composite index for common queries (agent + status)
    CREATE INDEX IF NOT EXISTS idx_tasks_agent_status ON tasks(agent_wallet, status);
    
    -- Index for date range queries
    CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at);
  `;

  const createTriggerQuery = `
    -- Trigger to update updated_at timestamp
    CREATE OR REPLACE FUNCTION update_tasks_updated_at()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.updated_at = CURRENT_TIMESTAMP;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    DROP TRIGGER IF EXISTS tasks_updated_at_trigger ON tasks;
    CREATE TRIGGER tasks_updated_at_trigger
      BEFORE UPDATE ON tasks
      FOR EACH ROW
      EXECUTE FUNCTION update_tasks_updated_at();
  `;

  try {
    // Create table
    await db.query(createTableQuery);
    console.log('✅ Tasks table created successfully');

    // Create indexes
    await db.query(createIndexesQuery);
    console.log('✅ Indexes created successfully');

    // Create trigger
    await db.query(createTriggerQuery);
    console.log('✅ Trigger created successfully');

    // Insert sample tasks for testing
    const sampleTasksQuery = `
      INSERT INTO tasks (title, description, agent_wallet, assigned_by, status, priority, due_date)
      SELECT 
        'Sample Task ' || generate_series,
        'This is a sample task description for testing purposes.',
        a.wallet_address,
        u.id,
        CASE (random() * 3)::int
          WHEN 0 THEN 'pending'
          WHEN 1 THEN 'in_progress'
          WHEN 2 THEN 'completed'
          ELSE 'pending'
        END,
        CASE (random() * 3)::int
          WHEN 0 THEN 'low'
          WHEN 1 THEN 'medium'
          WHEN 2 THEN 'high'
          ELSE 'medium'
        END,
        CURRENT_TIMESTAMP + (random() * 30 || ' days')::interval
      FROM generate_series(1, 5),
           (SELECT wallet_address FROM agents LIMIT 1) a,
           (SELECT id FROM users WHERE role = 'admin' LIMIT 1) u
      ON CONFLICT DO NOTHING;
    `;

    await db.query(sampleTasksQuery);
    console.log('✅ Sample tasks inserted');

    console.log('\n🎉 Tasks table migration completed successfully!\n');
    console.log('Table: tasks');
    console.log('Indexes: 7 created');
    console.log('Trigger: update_tasks_updated_at');
    console.log('Sample data: 5 tasks inserted\n');

  } catch (error) {
    console.error('❌ Error creating tasks table:', error.message);
    throw error;
  }
}

// Run migration if called directly
if (require.main === module) {
  createTasksTable()
    .then(() => {
      console.log('Migration completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Migration failed:', error);
      process.exit(1);
    });
}

module.exports = createTasksTable;
