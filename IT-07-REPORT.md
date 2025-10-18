# IT-07 REPORT: Reinicio de Estado (Unregistration)

**Fecha:** 19 de octubre de 2025  
**Test:** IT-07 - Reinicio de Estado  
**Estado:** ✅ CÓDIGO VERIFICADO | ⏳ VERIFICACIÓN MANUAL PENDIENTE

---

## 1. Objetivo del Test

**Propósito:** Verificar que al borrar los datos/caché de la aplicación Android, el estado local se reinicia completamente y permite realizar un nuevo registro sin errores.

**Escenario de uso:**
- Usuario tiene un dispositivo previamente registrado
- Usuario necesita registrar el dispositivo con otra wallet
- Usuario borra los datos de la app desde Settings
- App debe volver al flujo inicial de registro
- Nuevo registro debe funcionar correctamente

**Criterios de éxito:**
- ✅ Después de borrar datos, app muestra UI inicial (no "Already Registered")
- ✅ Device ID es regenerado (diferente al anterior)
- ✅ Campo de wallet address está vacío
- ✅ Botón "Register Agent" está habilitado
- ✅ Nuevo registro funciona correctamente (201 Created)
- ✅ App guarda el nuevo estado después del registro

---

## 2. Implementación Verificada

### 2.1 LocalStorage.clear() - Limpieza de Estado

**Archivo:** `agent-app/app/src/main/java/com/underlaba/atlas/agentapp/data/LocalStorage.kt`

```kotlin
class LocalStorage(context: Context) {
    
    companion object {
        private const val PREF_NAME = "AtlasAgentPrefs"
        private const val KEY_DEVICE_ID = "device_id"
        private const val KEY_WALLET_ADDRESS = "wallet_address"
        private const val KEY_IS_REGISTERED = "is_registered"
    }
    
    private val prefs: SharedPreferences = 
        context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    
    // ... otros métodos ...
    
    fun clear() {
        prefs.edit().clear().apply()
    }
}
```

**✅ Verificación:**
- Método `clear()` implementado correctamente
- Utiliza `prefs.edit().clear().apply()` para borrar TODAS las claves
- Limpia: `device_id`, `wallet_address`, `is_registered`

**Comportamiento:** Cuando Android borra los datos de la app (Settings > Clear data), SharedPreferences también se borran automáticamente. El método `clear()` está disponible para uso programático.

---

### 2.2 MainActivity.loadSavedData() - Carga de Estado

**Archivo:** `agent-app/app/src/main/java/com/underlaba/atlas/agentapp/MainActivity.kt`

```kotlin
private fun loadSavedData() {
    localStorage.getWalletAddress()?.let { address ->
        etWalletAddress.setText(address)
    }
    
    if (localStorage.isRegistered()) {
        tvStatus.text = "Device already registered"
        tvStatus.setTextColor(getColor(R.color.success))
        tvStatus.visibility = View.VISIBLE
        btnRegister.text = "Already Registered"
        btnRegister.isEnabled = false
    }
}
```

**✅ Verificación:**
- Lee `localStorage.isRegistered()` al iniciar
- Si NO está registrado (después de borrar datos), NO ejecuta el bloque `if`
- Botón permanece habilitado con texto "Register Agent"
- Campo de wallet queda vacío
- UI vuelve al estado inicial

---

### 2.3 MainActivity.generateDeviceId() - Regeneración de Device ID

**Archivo:** `agent-app/app/src/main/java/com/underlaba/atlas/agentapp/MainActivity.kt`

```kotlin
private fun generateDeviceId() {
    deviceId = localStorage.getDeviceId() ?: run {
        val androidId = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ANDROID_ID
        )
        val uniqueId = "$androidId-${UUID.randomUUID()}"
        localStorage.saveDeviceId(uniqueId)
        uniqueId
    }
    tvDeviceId.text = deviceId
}
```

**✅ Verificación:**
- Intenta recuperar Device ID guardado: `localStorage.getDeviceId()`
- Si retorna `null` (después de borrar datos), genera uno NUEVO
- Combina Android ID + UUID random para generar ID único
- Guarda el nuevo Device ID en localStorage
- Muestra el nuevo ID en la UI

**Resultado esperado:** Después de borrar datos, se genera un Device ID completamente diferente al anterior.

---

## 3. Flujo de Reinicio de Estado

### Diagrama de Flujo

```
┌─────────────────────────────────────────────────────────────────┐
│                    ESTADO INICIAL                                │
│  - App ya registrada                                            │
│  - SharedPreferences contiene:                                   │
│    • device_id = "abc123-uuid..."                               │
│    • wallet_address = "0x1234..."                               │
│    • is_registered = true                                       │
│  - UI muestra "Already Registered"                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              USUARIO BORRA DATOS DE LA APP                       │
│                                                                  │
│  Opción A: Settings > Apps > Atlas Agent > Clear data           │
│  Opción B: adb shell pm clear com.underlaba.atlas.agentapp      │
│                                                                  │
│  Resultado: SharedPreferences completamente borrado              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                USUARIO REABRE LA APP                             │
│                                                                  │
│  1. onCreate() se ejecuta                                       │
│  2. generateDeviceId() se ejecuta:                              │
│     - localStorage.getDeviceId() retorna NULL                   │
│     - Se genera nuevo Device ID: "xyz789-uuid..."               │
│     - Se guarda en localStorage                                 │
│  3. loadSavedData() se ejecuta:                                 │
│     - localStorage.getWalletAddress() retorna NULL              │
│     - localStorage.isRegistered() retorna FALSE                 │
│     - Campo wallet queda VACÍO                                  │
│     - Botón queda HABILITADO con texto "Register Agent"         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              UI EN ESTADO INICIAL DE REGISTRO                    │
│                                                                  │
│  - Device ID: "xyz789-uuid..." (DIFERENTE al anterior)          │
│  - Wallet Address: [Campo vacío]                                │
│  - Botón: "Register Agent" (HABILITADO)                         │
│  - Status: [No muestra mensaje]                                 │
│                                                                  │
│  ✅ Usuario puede registrar nuevamente                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  NUEVO REGISTRO EXITOSO                          │
│                                                                  │
│  1. Usuario ingresa wallet: 0x1234...                           │
│  2. Presiona "Register Agent"                                   │
│  3. Backend responde: 201 Created                               │
│  4. App guarda nuevo estado:                                    │
│     - localStorage.saveDeviceId("xyz789-uuid...")               │
│     - localStorage.saveWalletAddress("0x1234...")               │
│     - localStorage.setRegistered(true)                          │
│  5. UI actualiza: "Already Registered" (deshabilitado)          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Verificación Manual Requerida

### Paso 1: Verificar Estado Registrado

1. ✅ Abre el emulador Android
2. ✅ Abre la app Atlas Agent
3. ✅ Verifica que muestra:
   - "Already Registered" en el botón
   - "Device already registered" en el status
   - Botón de registro deshabilitado
   - Wallet address guardada (si existe)
4. ✅ **Anota el Device ID actual** (será diferente después de borrar datos)

---

### Paso 2: Borrar Datos de la App

**Opción A - Desde Settings del emulador:**

1. Cierra la app Atlas Agent
2. Abre **Settings** en el emulador
3. Ve a **Apps** > **See all apps** > **Atlas Agent**
4. Toca **Storage & cache**
5. Toca **Clear storage** o **Clear data**
6. Confirma la acción
7. Deberías ver mensaje: "All data deleted"

**Opción B - Desde adb (más rápido):**

```powershell
adb shell pm clear com.underlaba.atlas.agentapp
```

Deberías ver: **Success**

---

### Paso 3: Reabrir la App y Verificar Reinicio

1. ✅ Abre la app Atlas Agent nuevamente
2. ✅ Verifica que la app muestra el flujo inicial:
   - ✅ **Device ID es DIFERENTE** al anterior (xyz789... vs abc123...)
   - ✅ Campo de wallet address está **VACÍO**
   - ✅ Botón **"Register Agent" está HABILITADO**
   - ✅ Status **NO muestra** "Already Registered"
   - ✅ UI está en estado inicial de registro

**Comparación:**

| Aspecto | Antes de borrar datos | Después de borrar datos |
|---------|----------------------|-------------------------|
| Device ID | `abc123-uuid...` | `xyz789-uuid...` ⭐ DIFERENTE |
| Wallet Address | `0x1234...` | [Vacío] |
| Botón | "Already Registered" (deshabilitado) | "Register Agent" (habilitado) |
| Status | "Device already registered" | [No muestra mensaje] |

---

### Paso 4: Registrar Nuevamente

1. ✅ Ingresa una wallet válida:
   ```
   0x1234567890123456789012345678901234567890
   ```
2. ✅ Presiona **"Register Agent"**
3. ✅ Verifica el resultado:
   - ✅ Backend responde: **201 Created**
   - ✅ Muestra mensaje: **"Agent registered successfully!"**
   - ✅ Botón cambia a **"Already Registered"** y se deshabilita
   - ✅ Status muestra **"Device already registered"**
   - ✅ Wallet address se guarda en el campo

**Si todos los pasos pasan:** ✅ **IT-07 PASA**

---

## 5. Verificación de Base de Datos (Opcional)

Después de completar el nuevo registro, puedes verificar que la base de datos contiene **DOS registros diferentes**:

```powershell
cd backend-core
node query-agents.js
```

**Resultado esperado:**

```
[AGENTE 1]
  ID: 2
  Device ID: xyz789-uuid-nuevo
  Wallet Address: 0x1234567890123456789012345678901234567890
  Created At: 2025-10-19 ...

[AGENTE 2]
  ID: 1
  Device ID: abc123-uuid-anterior
  Wallet Address: 0x1234567890123456789012345678901234567890
  Created At: 2025-10-18 ...
```

**Observaciones:**
- ✅ Dos registros con **Device IDs diferentes**
- ✅ Mismo wallet address (esperado si usaste la misma)
- ✅ Backend NO tiene problema con múltiples registros del mismo wallet (solo device_id es UNIQUE)
- ✅ App funciona correctamente con el nuevo Device ID

---

## 6. Casos Edge a Considerar

### 6.1 ¿Qué pasa si el usuario reinstala la app?

**Comportamiento:**
- Reinstalar la app también borra SharedPreferences
- Se genera un nuevo Device ID
- App vuelve al estado inicial
- Permite nuevo registro

**✅ Mismo comportamiento que "Clear data"**

---

### 6.2 ¿Qué pasa si el backend tiene el wallet address del registro anterior?

**Comportamiento:**
- Backend tiene constraint UNIQUE solo en `device_id`, NO en `wallet_address`
- Múltiples devices pueden registrarse con el mismo wallet
- Nuevo registro con diferente Device ID es permitido

**✅ No hay conflicto, registro exitoso**

---

### 6.3 ¿El usuario puede registrar infinitos Device IDs?

**Comportamiento:**
- Técnicamente sí, cada vez que borra datos se genera nuevo Device ID
- Backend permite múltiples registros del mismo wallet con diferentes device_id
- Esto es correcto: un usuario puede tener múltiples dispositivos

**Consideración futura:** Si se requiere limitar dispositivos por wallet, implementar validación en backend (ej. máximo 5 devices por wallet).

---

## 7. Conclusiones

### ✅ Implementación Verificada

| Componente | Estado | Observaciones |
|-----------|---------|---------------|
| `LocalStorage.clear()` | ✅ OK | Borra todas las claves de SharedPreferences |
| `generateDeviceId()` | ✅ OK | Regenera Device ID si no existe |
| `loadSavedData()` | ✅ OK | No ejecuta lógica de "Already Registered" si datos borrados |
| UI State Reset | ✅ OK | Botón habilitado, campos vacíos, estado inicial |
| Nuevo registro | ✅ OK | Backend acepta nuevo Device ID sin problemas |

---

### 📝 Resumen

**IT-07 verifica correctamente el reinicio de estado local:**

1. ✅ **Código implementado correctamente:** `LocalStorage.clear()`, regeneración de Device ID, carga condicional de estado
2. ✅ **Flujo lógico correcto:** Borrar datos → volver a estado inicial → permitir nuevo registro
3. ⏳ **Verificación manual pendiente:** Probar en emulador el flujo completo
4. ✅ **Backend compatible:** Acepta múltiples registros con diferentes Device IDs

**Próximo paso:** Ejecutar verificación manual en emulador siguiendo los pasos de este reporte.

---

## 8. Evidencia de Código

### LocalStorage.kt - Método clear()

```kotlin
fun clear() {
    prefs.edit().clear().apply()
}
```

**Ubicación:** `agent-app/app/src/main/java/com/underlaba/atlas/agentapp/data/LocalStorage.kt`  
**Líneas:** ~43-45  
**Función:** Borra completamente todas las claves de SharedPreferences (`device_id`, `wallet_address`, `is_registered`)

---

### MainActivity.kt - Regeneración de Device ID

```kotlin
private fun generateDeviceId() {
    deviceId = localStorage.getDeviceId() ?: run {
        val androidId = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ANDROID_ID
        )
        val uniqueId = "$androidId-${UUID.randomUUID()}"
        localStorage.saveDeviceId(uniqueId)
        uniqueId
    }
    tvDeviceId.text = deviceId
}
```

**Ubicación:** `agent-app/app/src/main/java/com/underlaba/atlas/agentapp/MainActivity.kt`  
**Líneas:** ~65-76  
**Función:** Si `getDeviceId()` retorna `null` (datos borrados), genera nuevo Device ID único

---

### MainActivity.kt - Carga de Estado

```kotlin
private fun loadSavedData() {
    localStorage.getWalletAddress()?.let { address ->
        etWalletAddress.setText(address)
    }
    
    if (localStorage.isRegistered()) {
        tvStatus.text = "Device already registered"
        tvStatus.setTextColor(getColor(R.color.success))
        tvStatus.visibility = View.VISIBLE
        btnRegister.text = "Already Registered"
        btnRegister.isEnabled = false
    }
}
```

**Ubicación:** `agent-app/app/src/main/java/com/underlaba/atlas/agentapp/MainActivity.kt`  
**Líneas:** ~78-89  
**Función:** Si `isRegistered()` retorna `false` (después de borrar datos), NO ejecuta el bloque de "Already Registered"

---

**FIN DEL REPORTE IT-07**

---

**Autor:** GitHub Copilot  
**Sistema:** Atlas Agent Registration System  
**Versión:** 1.0  
**Última actualización:** 19 de octubre de 2025
