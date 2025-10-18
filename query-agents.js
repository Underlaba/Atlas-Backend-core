// Script para consultar todos los agentes registrados en PostgreSQL
const { Pool } = require('pg');

const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'atlas_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'Alex87032623302'
});

async function queryAgents() {
    try {
        console.log('\n========================================');
        console.log('  AGENTES REGISTRADOS EN POSTGRESQL');
        console.log('========================================\n');
        
        const result = await pool.query(
            'SELECT * FROM agents ORDER BY created_at DESC LIMIT 10'
        );
        
        if (result.rows.length > 0) {
            console.log(`Total de agentes encontrados: ${result.rows.length}\n`);
            
            result.rows.forEach((agent, index) => {
                console.log(`[AGENTE ${index + 1}]`);
                console.log(`  ID: ${agent.id}`);
                console.log(`  Device ID: ${agent.device_id}`);
                console.log(`  Wallet Address: ${agent.wallet_address}`);
                console.log(`  Created At: ${agent.created_at}`);
                console.log(`  Updated At: ${agent.updated_at}`);
                console.log('');
            });
        } else {
            console.log('No se encontraron agentes registrados.');
        }
        
        process.exit(0);
    } catch (error) {
        console.error('Error al consultar base de datos:', error.message);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

queryAgents();
