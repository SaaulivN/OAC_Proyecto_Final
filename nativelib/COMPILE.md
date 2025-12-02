# Guía de Compilación: MASM x86 + JNI para game.dll

## Requisitos Previos

1. **Visual Studio C++ Build Tools** o **Visual Studio Community** (para MSVC, ML.exe, link.exe)
   - Instala la carga de trabajo "Desktop development with C++"
   - Necesitas: `cl.exe`, `ml.exe` (MASM x86 32-bit), `link.exe`

2. **Java Development Kit (JDK)** 
   - Debes tener `%JAVA_HOME%` configurado
   - El wrapper JNI necesita `jni.h` desde `%JAVA_HOME%\include`

3. **PowerShell 5.1+** (ya tienes en Windows)

## Estructura de Directorios

```
OAC_ProyectoFinal/
├── app/
│   └── src/main/java/oac_proyectofinal/
│       ├── GameNative.java
│       ├── ... (otros archivos Java)
├── nativelib/
│   ├── game.asm            (lógica en MASM x86)
│   ├── game_wrapper.c      (wrapper JNI)
│   ├── compile.ps1         (script de compilación - ESTE ARCHIVO)
│   └── build/              (generado, contiene .obj, .dll, etc.)
```

## Pasos de Compilación (Manual o Automático)

### Opción 1: Script Automático (Recomendado)

```powershell
# En PowerShell, desde el directorio nativelib/
.\compile.ps1
```

### Opción 2: Compilación Manual Paso a Paso

#### Paso 1: Compilar MASM x86 a .obj

Abre **Developer Command Prompt for Visual Studio** (importante: es una terminal especial con variables de entorno preconfiguradas).

```cmd
cd C:\Users\saulr\Documents\UABC\7mo semestre\Organización y arquitectura de computadoras\OAC_ProyectoFinal\nativelib
ml.exe /c /Fo build\game.obj game.asm
```

Si todo va bien, verás: `Assembling: game.asm` y se creará `build\game.obj`.

#### Paso 2: Compilar Wrapper C a .obj

```cmd
cl.exe /c /Fo build\game_wrapper.obj ^
  /I"%JAVA_HOME%\include" ^
  /I"%JAVA_HOME%\include\win32" ^
  game_wrapper.c
```

Esto genera `build\game_wrapper.obj`.

#### Paso 3: Enlazar a DLL

```cmd
link.exe /DLL /OUT:build\game.dll build\game.obj build\game_wrapper.obj
```

Resultado: `build\game.dll`

#### Paso 4: Copiar DLL a Ubicación Accesible por Java

```cmd
copy build\game.dll ..\app\build\classes\java\main\
```

O simplemente colócala en un directorio en el `PATH` de Windows o en la carpeta del proyecto.

## Verificación

1. **Verifica que la DLL se generó:**
   ```powershell
   ls build\game.dll
   ```

2. **Ejecuta el proyecto Java:**
   ```powershell
   .\gradlew.bat run
   # O desde la carpeta app:
   java -cp "build\classes\java\main" oac_proyectofinal.GameFrame
   ```

3. **Comprueba que no hay errores de UnsatisfiedLinkError:**
   - Si ves "No se pudo cargar la librería nativa 'game.dll'", verifica que:
     - La DLL está en el `PATH` del sistema o en la carpeta de ejecución
     - La arquitectura coincide (32-bit Java con 32-bit DLL)
     - Las funciones exportadas coinciden con los nombres de `GameNative.java`

## Troubleshooting

| Problema | Solución |
|----------|----------|
| `ml.exe` no encontrado | Asegúrate de usar "Developer Command Prompt for Visual Studio" |
| `jni.h` no encontrado | Configura `%JAVA_HOME%` correctamente |
| "UnsatisfiedLinkError" en Java | Verifica que la DLL esté en el `PATH` y es arquitectura x86 32-bit |
| "Invalid DEF file" en link.exe | Usa sintaxis correcta; verifica símbolos exportados |

## Arquitectura Técnica

- **MASM x86 32-bit** (game.asm): Implementa `game_init`, `game_tick`, `game_set_input`, `game_get_score`, `game_is_game_over`
- **JNI Wrapper** (game_wrapper.c): Convierte llamadas JNI a llamadas C __cdecl
- **Java Native Interface** (GameNative.java): Expone métodos `native` para Java
- **Convención de llamada**: __cdecl x86 32-bit (parámetros en stack, return en EAX)

## Próximos Pasos

1. Compila manualmente o ejecuta `compile.ps1`
2. Integra `GameNative` en `GamePanel.java` para usar las funciones nativas
3. Prueba el movimiento de la serpiente controlado por código MASM
4. Expande la lógica en MASM según sea necesario

---

**Nota**: Este es un prototipo mínimo. La lógica completa (colisión, crecimiento, IA de comida, etc.) se puede expandir incrementalmente en MASM.
