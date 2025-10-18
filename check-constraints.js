// Script para verificar constraints en la tabla agents
const { Pool } = require('pg');

const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'atlas_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'Alex87032623302'
});

async function checkConstraints() {
    try {
        console.log('\n========================================');
        console.log('  CONSTRAINTS EN TABLA AGENTS');
        console.log('========================================\n');
        
        // Verificar todos los constraints
        const result = await pool.query(`
            SELECT 
                tc.constraint_name,
                tc.constraint_type,
                kcu.column_name
            FROM information_schema.table_constraints tc
            LEFT JOIN information_schema.key_column_usage kcu
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            WHERE tc.table_name = 'agents'
            ORDER BY tc.constraint_type, tc.constraint_name
        `);
        
        if (result.rows.length > 0) {
            console.log('Constraints encontrados:\n');
            
            result.rows.forEach((row, index) => {
                console.log(`[${index + 1}] ${row.constraint_type}`);
                console.log(`    Nombre: ${row.constraint_name}`);
                console.log(`    Columna: ${row.column_name || 'N/A'}`);
                console.log('');
            });
            
            // Verificar específicamente UNIQUE en device_id
            const uniqueDeviceId = result.rows.find(
                row => row.constraint_type === 'UNIQUE' && 
                       row.column_name === 'device_id'
            );
            
            if (uniqueDeviceId) {
                console.log('✓ CONSTRAINT UNIQUE en device_id: ENCONTRADO');
            } else {
                console.log('✗ CONSTRAINT UNIQUE en device_id: NO ENCONTRADO');
            }
        } else {
            console.log('No se encontraron constraints en la tabla agents.');
        }
        
        process.exit(0);
    } catch (error) {
        console.error('Error al consultar constraints:', error.message);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

checkConstraints();
