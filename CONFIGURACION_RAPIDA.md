# Configuracion Rapida del Backend

## Estado Actual

Node.js v22.20.0 - INSTALADO
npm v10.9.3 - INSTALADO
Dependencias del proyecto - INSTALADAS
Archivo .env - CREADO

## Paso 1: Actualizar archivo .env

Abre el archivo .env y actualiza estas lineas con las claves generadas:

```env
JWT_SECRET=7492defa20e5584a153b6baa8042d63e6e33c8667de26d05f4035ab90e73921985c094fcde08351281ca3cda78af1309210355f467fb88ac1a6c189d31a75bac

JWT_REFRESH_SECRET=5df3cb6abf144baa5f814a33cfa4c6891a78d5f850525f4375b0d9ed7cef0495223de2d70537644fa390398cf38258039c81e1bd15f1633ff143770052d0e637
```

Editar el archivo:
```powershell
notepad .env
```

## Paso 2: Instalar PostgreSQL

### Opcion A: Docker (Rapido - Recomendado si tienes Docker)
```powershell
docker run --name atlas-postgres -e POSTGRES_PASSWORD=atlas2024 -e POSTGRES_DB=atlas_db -p 5432:5432 -d postgres:15
```

Luego actualiza en .env:
```env
DB_PASSWORD=atlas2024
```

### Opcion B: Instalacion Nativa
1. Descarga PostgreSQL desde: https://www.postgresql.org/download/windows/
2. Ejecuta el instalador
3. Durante la instalacion:
   - Usuario: postgres
   - Contraseña: (elige una y anotala)
   - Puerto: 5432
4. Actualiza .env con tu contraseña

Despues de instalar, crea la base de datos:
```powershell
# Si instalaste PostgreSQL nativo
psql -U postgres -c "CREATE DATABASE atlas_db;"
```

## Paso 3: Ejecutar Migraciones

Una vez que PostgreSQL este corriendo y configurado:

```powershell
npm run migrate
```

Esto creara la tabla de usuarios en la base de datos.

## Paso 4: Iniciar el Servidor

```powershell
npm run dev
```

Deberias ver:
```
Server is running!
Environment: development
Port: 3000
API: http://localhost:3000/api/v1
```

## Paso 5: Probar la API

### Usando PowerShell:
```powershell
# Health check
Invoke-RestMethod -Uri "http://localhost:3000/api/v1/health"

# Registrar usuario
$body = @{
    email = "admin@atlas.com"
    password = "Admin123!"
    firstName = "Admin"
    lastName = "User"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/register" -Method Post -Body $body -ContentType "application/json"
```

### Usando el navegador:
- http://localhost:3000
- http://localhost:3000/api/v1/health

## Resumen de Comandos

```powershell
# Ya ejecutados:
npm install                  # COMPLETADO
Copy-Item .env.example .env  # COMPLETADO
node generate-secrets.js     # COMPLETADO

# Pendientes:
notepad .env                 # Actualizar JWT_SECRET y DB_PASSWORD
# Instalar PostgreSQL (Docker o nativo)
npm run migrate              # Crear tabla de usuarios
npm run dev                  # Iniciar servidor
```

## Siguiente Paso

Elige como quieres instalar PostgreSQL:
1. Docker (mas rapido)
2. Instalacion nativa (mas control)

Luego ejecuta los comandos pendientes listados arriba.
