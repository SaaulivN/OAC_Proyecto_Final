# Script de compilación automático para MASM x86 + JNI
# Ejecutar desde PowerShell como administrador o desde Developer Command Prompt for VS

$ErrorActionPreference = "Stop"

Write-Host "=== Compilación MASM x86 + JNI para game.dll ===" -ForegroundColor Cyan

# 1. Configurar variables de entorno
$JAVA_HOME = $env:JAVA_HOME
$nativeDir = Get-Location
$buildDir = Join-Path $nativeDir "build"

if (-not $JAVA_HOME) {
    Write-Host "ERROR: JAVA_HOME no está configurado" -ForegroundColor Red
    exit 1
}

Write-Host "JAVA_HOME: $JAVA_HOME" -ForegroundColor Green
Write-Host "Directorio nativo: $nativeDir" -ForegroundColor Green

# 2. Crear directorio build si no existe
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
    Write-Host "Creado directorio: $buildDir" -ForegroundColor Green
}

# 3. Compilar MASM x86 a .obj
Write-Host "`n[1/3] Compilando game.asm (MASM x86)..." -ForegroundColor Yellow
$gameObjPath = Join-Path $buildDir "game.obj"

# Intentar usar ml.exe (puede no estar en PATH en PowerShell normal)
try {
    & ml.exe /c /Fo "$gameObjPath" game.asm
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR en compilación de MASM" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ game.obj creado" -ForegroundColor Green
} catch {
    Write-Host "ERROR: No se pudo ejecutar ml.exe" -ForegroundColor Red
    Write-Host "SOLUCIÓN: Ejecuta este script desde 'Developer Command Prompt for Visual Studio'" -ForegroundColor Yellow
    exit 1
}

# 4. Compilar Wrapper C a .obj
Write-Host "`n[2/3] Compilando game_wrapper.c (JNI)..." -ForegroundColor Yellow
$wrapperObjPath = Join-Path $buildDir "game_wrapper.obj"

try {
    $jniInclude = Join-Path $JAVA_HOME "include"
    $jniWin32Include = Join-Path $jniInclude "win32"
    
    & cl.exe /c /Fo "$wrapperObjPath" `
             /I "$jniInclude" `
             /I "$jniWin32Include" `
             game_wrapper.c
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR en compilación de C" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ game_wrapper.obj creado" -ForegroundColor Green
} catch {
    Write-Host "ERROR: No se pudo ejecutar cl.exe" -ForegroundColor Red
    Write-Host "SOLUCIÓN: Ejecuta este script desde 'Developer Command Prompt for Visual Studio'" -ForegroundColor Yellow
    exit 1
}

# 5. Enlazar a DLL
Write-Host "`n[3/3] Enlazando a game.dll..." -ForegroundColor Yellow
$dllPath = Join-Path $buildDir "game.dll"

try {
    & link.exe /DLL /OUT:"$dllPath" "$gameObjPath" "$wrapperObjPath"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR en enlazado" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ game.dll creado" -ForegroundColor Green
} catch {
    Write-Host "ERROR: No se pudo ejecutar link.exe" -ForegroundColor Red
    exit 1
}

# 6. Copiar DLL a carpeta accesible por Java
Write-Host "`n[4/4] Copiando game.dll..." -ForegroundColor Yellow

$appBuildDir = Join-Path (Split-Path $nativeDir -Parent) "app\build\classes\java\main"

if (Test-Path $appBuildDir) {
    Copy-Item $dllPath $appBuildDir -Force
    Write-Host "✓ game.dll copiado a: $appBuildDir" -ForegroundColor Green
} else {
    Write-Host "ADVERTENCIA: No se encontró directorio app/build/classes/java/main" -ForegroundColor Yellow
    Write-Host "SOLUCIÓN: Ejecuta 'gradlew build' desde el directorio raíz del proyecto" -ForegroundColor Yellow
}

# 7. Verificación final
Write-Host "`n=== COMPILACIÓN COMPLETADA ===" -ForegroundColor Green
Write-Host "game.dll ubicación: $dllPath" -ForegroundColor Cyan
Write-Host "`nPróximos pasos:" -ForegroundColor Yellow
Write-Host "1. Ejecuta: .\gradlew.bat build"
Write-Host "2. Ejecuta: java -cp `"app\build\classes\java\main`" oac_proyectofinal.GameFrame"
Write-Host "`nNota: Asegúrate de ejecutar este script desde 'Developer Command Prompt for Visual Studio'" -ForegroundColor Yellow
