#!/bin/bash
set -e

echo "=========================================="
echo " Barberia Fidelizacion - Deploy a Vercel"
echo "=========================================="
echo ""

# Verificar Flutter
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter no esta instalado."
    echo "Instala desde: https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "[1/3] Compilando Flutter Web..."
flutter build web --release

echo ""
echo "[2/3] Verificando build..."
if [ ! -f "build/web/index.html" ]; then
    echo "ERROR: build/web/index.html no encontrado"
    exit 1
fi

echo ""
echo "[3/3] Deployando a Vercel..."
vercel --prod --scope hector404nfs-projects

echo ""
echo "=========================================="
echo " Deploy completado!"
echo " URL: https://barberia-fidelizacion.vercel.app"
echo "=========================================="
