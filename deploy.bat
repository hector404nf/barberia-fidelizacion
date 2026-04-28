@echo off
echo ==========================================
echo  Barberia Fidelizacion - Deploy a Vercel
echo ==========================================
echo.

REM Verificar que Flutter este instalado
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter no esta instalado o no esta en el PATH.
    echo Por favor instala Flutter desde: https://docs.flutter.dev/get-started/install
    exit /b 1
)

echo [1/3] Compilando Flutter Web...
flutter build web --release

if %errorlevel% neq 0 (
    echo ERROR: La compilacion fallo.
    exit /b 1
)

echo.
echo [2/3] Verificando build...
if not exist "build\web\index.html" (
    echo ERROR: No se encontro build/web/index.html
    exit /b 1
)

echo.
echo [3/3] Deployando a Vercel...
vercel --prod --scope hector404nfs-projects

echo.
echo ==========================================
echo  Deploy completado!
echo  URL: https://barberia-fidelizacion.vercel.app
echo ==========================================
