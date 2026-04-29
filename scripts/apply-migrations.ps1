# Script para aplicar migraciones de Supabase
# Uso: .\scripts\apply-migrations.ps1

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Supabase DB Push - Barberia Fidelizacion" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que supabase CLI está instalado
try {
    $sbVersion = supabase --version
    Write-Host "✓ Supabase CLI detectado: $sbVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Supabase CLI no encontrado. Instalalo con:" -ForegroundColor Red
    Write-Host "  npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

# Verificar login
try {
    $account = supabase projects list 2>$null | Select-String "gzrncvukxfaejcozffut"
    if ($account) {
        Write-Host "✓ Sesión activa en Supabase" -ForegroundColor Green
    } else {
        Write-Host "⚠ Iniciando sesión..." -ForegroundColor Yellow
        supabase login
    }
} catch {
    Write-Host "⚠ Iniciando sesión..." -ForegroundColor Yellow
    supabase login
}

Write-Host ""
Write-Host "Aplicando migraciones..." -ForegroundColor Cyan
Write-Host ""

# Ejecutar db push
supabase db push

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ Migraciones aplicadas correctamente!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "✗ Error al aplicar migraciones" -ForegroundColor Red
    Write-Host "  Verificá los logs arriba" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Presiona cualquier tecla para salir..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
