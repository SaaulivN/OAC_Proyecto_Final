# Integración MASM x86 con Java - Snake Game

## Descripción General

Este proyecto combina:
- **Lógica del juego en MASM x86 32-bit**: Toda la lógica de movimiento, colisiones y física
- **Interfaz gráfica en Java/Swing**: Renderizado, input del usuario y UI
- **Integración JNI**: Java llama funciones nativas compiladas a DLL

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                      Java Swing UI                          │
│        (GamePanel, Renderer, GameFrame, GameLoop)           │
└────────────────────┬────────────────────────────────────────┘
                     │ ByteBuffer (GameState)
                     ▼
┌─────────────────────────────────────────────────────────────┐
│             Java Native Interface (JNI)                     │
│         (GameNative.java - métodos native)                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│           game.dll (DLL compilada)                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  game_wrapper.c (JNI wrapper, convención C)         │   │
│  └─────────────────┬──────────────────────────────────┘   │
│                    │                                        │
│  ┌─────────────────▼──────────────────────────────────┐   │
│  │  game.asm (MASM x86 32-bit)                        │   │
│  │  - game_init   (inicializa estado)                 │   │
│  │  - game_tick   (actualiza lógica)                  │   │
│  │  - game_set_input (procesa input)                  │   │
│  │  - game_get_score / game_is_game_over (consulta)   │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Archivos Creados

### 1. Java (`app/src/main/java/oac_proyectofinal/`)

- **GameNative.java**: Clase con métodos `native` que exponen la API nativa
  - Carga `game.dll` automáticamente
  - Métodos: `gameInit`, `gameTick`, `gameSetInput`, `gameGetScore`, `gameIsGameOver`

### 2. Nativa (`nativelib/`)

- **game.asm**: Código MASM x86 32-bit con la lógica del juego
  - Estructura `GameState` en memoria compartida (ByteBuffer desde Java)
  - Funciones: `game_init`, `game_tick`, `game_set_input`, `game_get_score`, `game_is_game_over`
  - Convención: __cdecl x86 (parámetros en stack, return en EAX)

- **game_wrapper.c**: Wrapper JNI que convierte llamadas JNI a C __cdecl
  - Usa `GetDirectBufferAddress` para acceder al ByteBuffer directo desde Java
  - Funciones generadas automáticamente por JNI: `Java_oac_1proyectofinal_GameNative_*`

- **compile.ps1**: Script PowerShell para compilar automáticamente
  - Compila MASM → .obj
  - Compila C wrapper → .obj
  - Enlaza a .dll

- **COMPILE.md**: Guía completa de compilación (manual y automática)

## Configuración e Instalación

### Prerequisitos

1. **Visual Studio C++ Build Tools** (o Visual Studio Community)
   - Instala: Desktop development with C++
   - Necesitas: `cl.exe` (compilador C), `ml.exe` (MASM x86), `link.exe` (enlazador)

2. **Java Development Kit (JDK)** 32-bit o 64-bit
   - `%JAVA_HOME%` debe estar configurado
   - Necesita: `jni.h` desde `%JAVA_HOME%\include`

3. **PowerShell 5.1+** (ya incluido en Windows)

### Compilación de game.dll

#### Opción A: Automática (Recomendado)

1. Abre **Developer Command Prompt for Visual Studio** (IMPORTANTE: es una terminal especial con variables preconfiguradas)
   - En Windows 10/11: Busca "Developer Command Prompt" en el menú Inicio

2. Navega a `nativelib/`:
   ```cmd
   cd C:\Users\saulr\Documents\UABC\7mo semestre\Organización y arquitectura de computadoras\OAC_ProyectoFinal\nativelib
   ```

3. Ejecuta PowerShell:
   ```cmd
   powershell
   ```

4. Ejecuta el script:
   ```powershell
   .\compile.ps1
   ```

#### Opción B: Manual

Ver detalles en `nativelib/COMPILE.md`

### Compilación del Proyecto Java

```powershell
# Desde raíz del proyecto
.\gradlew.bat build
```

### Ejecución

```powershell
# Desde raíz del proyecto
java -cp "app\build\classes\java\main" oac_proyectofinal.GameFrame
```

O si `game.dll` está en PATH del sistema:
```powershell
.\gradlew.bat run
```

## Flujo de Ejecución

1. **Inicio**: Java carga `game.dll` via `System.loadLibrary("game")`
2. **Init**: `GameNative.gameInit(ByteBuffer, width, height)` inicializa el estado en memoria
3. **Loop**: Cada frame lógico (p.ej., 8x/seg según `GameLoop.UPS`):
   - `GameNative.gameSetInput(ByteBuffer, direction)` (si hay input del usuario)
   - `GameNative.gameTick(ByteBuffer)` ejecuta lógica MASM: movimiento, colisiones
   - Java lee el estado (score, isGameOver, posiciones) desde el ByteBuffer
   - Renderiza la serpiente, comida, etc. usando Swing
4. **Fin**: Cuando `gameIsGameOver` retorna 1, muestra "GAME OVER"

## Estructura de GameState en Memoria

```c
struct GameState {
  int width;           // [offset 0]
  int height;          // [offset 4]
  int score;           // [offset 8]
  int isGameOver;      // [offset 12]
  int headX, headY;    // [offset 16, 20]
  int foodX, foodY;    // [offset 24, 28]
  int length;          // [offset 32] número de segmentos
  int currentDir;      // [offset 36] 0=UP, 1=DOWN, 2=LEFT, 3=RIGHT
  int nextDir;         // [offset 40] próxima dirección
  byte body[1200];     // [offset 44] array de segmentos (x,y pares)
};
```

Total: ~1300 bytes. Usa `ByteBuffer.allocateDirect(1300)` en Java.

## Convención de Llamada (MASM x86 32-bit)

- **__cdecl (C calling convention x86 32-bit)**:
  - Parámetros pasados en **stack** (derecha a izquierda)
  - Return value en **EAX** (o EDX:EAX para 64-bit)
  - Stack **4-byte aligned** antes de `call`
  - La función **no limpia el stack** (responsabilidad del llamador)
  - Preservar: EBX, ESI, EDI, EBP, ESP
  - Pueden destruir: EAX, ECX, EDX

## Expandir la Lógica MASM

Actualmente `game.asm` implementa:
- Movimiento básico de la cabeza
- Detección de colisión con pared (game over)
- Captura de comida (incrementa score)
- Manejo de dirección con evita giro de 180°

Puedes expandir en `game.asm`:
- Detección de auto-colisión (cabeza vs cuerpo)
- Generación pseudo-aleatoria de comida mejor
- Animaciones o efectos de movimiento suave
- Lógica de dificultad o velocidad variable

## Troubleshooting

| Problema | Solución |
|----------|----------|
| `UnsatisfiedLinkError: game` (no encuentra DLL) | Asegúrate de que `game.dll` esté en el mismo directorio que se ejecuta el .jar o en PATH |
| `UnsatisfiedLinkError: gameInit` (función no encontrada) | Verifica que los símbolos en `game.asm` coincidan exactamente con los nombres en `game_wrapper.c` |
| `ml.exe` no encontrado al ejecutar `compile.ps1` | Ejecuta desde **Developer Command Prompt for Visual Studio** (terminal especial de VS) |
| Arquitectura mismatch (32 vs 64 bit) | Asegúrate de que tu JVM es 32-bit si compilaste MASM x86 32-bit (o vice versa) |
| "Invalid DEF file" en link.exe | Este proyecto no usa `.def`; elimina esa opción si la añadiste |

## Próximos Pasos

1. Compila `game.dll` ejecutando `compile.ps1` desde Developer Command Prompt
2. Compila el proyecto Java: `gradlew build`
3. Ejecuta: `java -cp "app\build\classes\java\main" oac_proyectofinal.GameFrame`
4. Integra `GameNative` en `GamePanel.java` para usar la lógica MASM (actualmente aún usa la lógica Java)

## Referencias

- [Microsoft MASM Reference](https://docs.microsoft.com/en-us/cpp/assembler/masm/microsoft-macro-assembler-reference)
- [JNI Documentation](https://docs.oracle.com/javase/8/docs/technotes/jni/)
- [x86 Calling Conventions](https://en.wikipedia.org/wiki/X86_calling_conventions)
