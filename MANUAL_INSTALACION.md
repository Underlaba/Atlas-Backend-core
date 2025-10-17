# Manual de Instalacion Completa - Atlas Backend

## Paso 1: Instalar Node.js

### Opcion A: Descarga Manual (Recomendado)
1. Ve a: https://nodejs.org/
2. Descarga el instalador LTS (Long Term Support)
3. Ejecuta el instalador .msi
4. Sigue el asistente (deja todas las opciones por defecto)
5. Reinicia PowerShell despues de instalar

### Opcion B: Ejecutar script de instalacion
Ejecuta en PowerShell:
```powershell
cd d:\Users\alexj\Proyectos\Atlas\backend-core
.\install-nodejs.ps1
```

## Paso 2: Verificar Instalacion

Abre una NUEVA ventana de PowerShell y ejecuta:
```powershell
node --version
npm --version
```

Deberias ver algo como:
```
v20.10.0
10.2.3
```

## Paso 3: Instalar Dependencias del Backend

```powershell
cd d:\Users\alexj\Proyectos\Atlas\backend-core
npm install
```

Esto instalara todas las dependencias listadas en package.json:
- express
- pg (PostgreSQL client)
- jsonwebtoken
- bcryptjs
- dotenv
- cors
- helmet
- express-validator
- morgan
- compression
- express-rate-limit
- nodemon (dev)

## Paso 4: Instalar PostgreSQL

### Opcion A: Descarga oficial
1. Ve a: https://www.postgresql.org/download/windows/
2. Descarga el instalador
3. Durante la instalacion:
   - Anota la contraseña del usuario postgres
   - Puerto por defecto: 5432
   - Instala pgAdmin (interfaz grafica)

### Opcion B: Usar Docker (si lo tienes instalado)
```powershell
docker run --name atlas-postgres -e POSTGRES_PASSWORD=tu_password -e POSTGRES_DB=atlas_db -p 5432:5432 -d postgres:15
```

## Paso 5: Crear Base de Datos

### Usando psql:
```powershell
psql -U postgres
```

Luego en el prompt de PostgreSQL:
```sql
CREATE DATABASE atlas_db;
\q
```

### Usando pgAdmin:
1. Abre pgAdmin
2. Click derecho en "Databases"
3. Create > Database
4. Nombre: atlas_db
5. Save

## Paso 6: Configurar Variables de Entorno

```powershell
cd d:\Users\alexj\Proyectos\Atlas\backend-core
cp .env.example .env
notepad .env
```

Edita el archivo .env con tus credenciales:
```env
NODE_ENV=development
PORT=3000

DB_HOST=localhost
DB_PORT=5432
DB_NAME=atlas_db
DB_USER=postgres
DB_PASSWORD=TU_PASSWORD_AQUI

JWT_SECRET=tu-clave-secreta-muy-segura-cambiala
JWT_EXPIRES_IN=24h
JWT_REFRESH_SECRET=tu-clave-refresh-muy-segura-cambiala
JWT_REFRESH_EXPIRES_IN=7d

CORS_ORIGIN=http://localhost:3000
```

## Paso 7: Ejecutar Migraciones

```powershell
npm run migrate
```

Esto creara la tabla de usuarios en la base de datos.

## Paso 8: Iniciar el Servidor

### Modo desarrollo (con auto-reload):
```powershell
npm run dev
```

### Modo produccion:
```powershell
npm start
```

Deberias ver:
```
Server is running!
Environment: development
Port: 3000
API: http://localhost:3000/api/v1
```

## Paso 9: Probar la API

### Usando curl (si esta instalado):
```powershell
# Health check
curl http://localhost:3000/api/v1/health

# Registrar usuario
curl -X POST http://localhost:3000/api/v1/auth/register -H "Content-Type: application/json" -d '{\"email\":\"test@atlas.com\",\"password\":\"test123\",\"firstName\":\"Test\",\"lastName\":\"User\"}'
```

### Usando PowerShell:
```powershell
# Health check
Invoke-RestMethod -Uri "http://localhost:3000/api/v1/health" -Method Get

# Registrar usuario
$body = @{
    email = "test@atlas.com"
    password = "test123"
    firstName = "Test"
    lastName = "User"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/register" -Method Post -Body $body -ContentType "application/json"
```

### Usando navegador:
Abre en tu navegador:
- http://localhost:3000 (info de la API)
- http://localhost:3000/api/v1/health (health check)

### Usando Postman o Insomnia (Recomendado):
1. Descarga Postman: https://www.postman.com/downloads/
2. Importa las rutas desde API_README.md

## Resumen de Comandos Rapidos

Despues de instalar Node.js y PostgreSQL:

```powershell
# Navegar al proyecto
cd d:\Users\alexj\Proyectos\Atlas\backend-core

# Instalar dependencias
npm install

# Configurar entorno
cp .env.example .env
notepad .env

# Crear base de datos (en psql)
psql -U postgres -c "CREATE DATABASE atlas_db;"

# Ejecutar migraciones
npm run migrate

# Iniciar servidor
npm run dev
```

## Solucionar Problemas Comunes

### Error: "npm no se reconoce"
- Reinicia PowerShell despues de instalar Node.js
- O cierra y abre Visual Studio Code

### Error: "Cannot connect to database"
- Verifica que PostgreSQL este corriendo
- Verifica las credenciales en .env
- Verifica que la base de datos atlas_db exista

### Error: "Port 3000 is already in use"
- Cambia el puerto en .env: PORT=3001
- O detén el otro proceso usando el puerto

### Error en las migraciones
- Verifica la conexion a la base de datos
- Asegurate de que la base de datos atlas_db existe

## Siguiente Paso

Una vez que el servidor este corriendo correctamente, puedes:
1. Probar los endpoints de autenticacion
2. Agregar nuevos modelos y controladores
3. Integrar con el frontend (agent-app y admin-panel)

Para mas detalles, consulta:
- API_README.md - Documentacion completa de la API
- SETUP_GUIDE.md - Guia de configuracion
