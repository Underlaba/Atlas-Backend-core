const crypto = require('crypto');

function generateSecret(length = 64) {
  return crypto.randomBytes(length).toString('hex');
}

console.log('\n=== Claves de Seguridad Generadas ===\n');
console.log('JWT_SECRET=' + generateSecret());
console.log('JWT_REFRESH_SECRET=' + generateSecret());
console.log('\nCopia estas claves en tu archivo .env\n');
