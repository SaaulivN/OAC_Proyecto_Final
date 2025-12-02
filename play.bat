@echo off
:: Forzar directorio actual
cd /d "%~dp0"
setlocal

echo ================================================
echo      CONSTRUCTOR LINEAL (SIN BLOQUES)
echo ================================================

:: -----------------------------------------------------------------------
:: RUTA DE VISUAL STUDIO
:: -----------------------------------------------------------------------
set "VS_PATH=C:\Program Files\Microsoft Visual Studio\18\Professional\VC\Auxiliary\Build\vcvars32.bat"

:: Cargar herramientas
if exist "%VS_PATH%" call "%VS_PATH%" >nul

:: Limpieza inicial
if exist game.dll del game.dll
del app\src\main\java\oac_proyectofinal\*.class 2>nul

:: --- PASO 1: NATIVELIB ---
echo.
echo [1/4] Entrando a nativelib...
if not exist "nativelib" goto fail_folder
cd nativelib

echo [2/4] Compilando C y ASM...

:: 1. Compilar Wrapper C
cl /c /nologo /I"..\jdk32\include" /I"..\jdk32\include\win32" game_wrapper.c
if errorlevel 1 goto fail_compile_c

:: 2. Ensamblar ASM
ml /c /coff /nologo game.asm
if errorlevel 1 goto fail_asm

:: 3. Enlazar DLL
link /DLL /OUT:game.dll /NOLOGO game.obj game_wrapper.obj
if errorlevel 1 goto fail_link

:: 4. Copiar y subir
copy /Y game.dll .. >nul
echo    - DLL creada exitosamente.
cd ..

:: --- PASO 2: JAVA ---
echo.
echo [3/4] Compilando JAVA...
"jdk32\bin\javac.exe" -encoding UTF-8 app\src\main\java\oac_proyectofinal\*.java
if errorlevel 1 goto fail_java

:: --- PASO 3: EJECUTAR ---
echo.
echo [4/4] INICIANDO JUEGO...
echo ================================================
"jdk32\bin\java.exe" -Dsun.java2d.opengl=true -Djava.library.path=. -cp app\src\main\java oac_proyectofinal.GameFrame
goto end

:: --- SECCION DE ERRORES (GOTO) ---

:fail_folder
echo [ERROR] No encuentro la carpeta 'nativelib'.
pause
exit /b

:fail_compile_c
echo [ERROR] Fallo al compilar game_wrapper.c
cd ..
pause
exit /b

:fail_asm
echo [ERROR] Fallo al ensamblar game.asm (Revisa tu codigo)
cd ..
pause
exit /b

:fail_link
echo [ERROR] Fallo al enlazar la DLL (Linker)
cd ..
pause
exit /b

:fail_java
echo [ERROR] Fallo al compilar Java
pause
exit /b

:end
echo.
:: Pausa final por si el juego se cierra solo
pause