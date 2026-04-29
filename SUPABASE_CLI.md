# 🗃️ Supabase CLI - Guía Rápida

## Prerrequisitos

1. **Instalar Supabase CLI** (global):
   ```powershell
   npm install -g supabase
   # o con scoop
   scoop install supabase
   ```

2. **Login** (una sola vez):
   ```powershell
   supabase login
   ```
   Te va a pedir abrir el navegador y autenticarte con tu cuenta de Supabase.

## Scripts disponibles

Ya está configurado el `package.json` con scripts. Desde la raíz del proyecto:

```powershell
# Aplicar migraciones pendientes a tu proyecto en la nube
npm run sb:db-push

# Ver estado del proyecto local (si usas start)
npm run sb:status

# Resetear DB local (cuidado, borra datos)
npm run sb:db-reset

# Deploy de Edge Functions
npm run sb:deploy-func

# Ver logs del proyecto
npm run sb:logs
```

## Flujo de trabajo con migraciones

1. Creamos/modificamos archivos `.sql` en `supabase/migrations/`
2. Ejecutamos:
   ```powershell
   npm run sb:db-push
   ```
3. Supabase CLI detecta las migraciones nuevas y las aplica automáticamente.

## Estructura de migraciones

```
supabase/
├── migrations/
│   ├── 00001_initial_schema.sql
│   ├── 00002_registro_rpc.sql
│   └── 00003_portal_clientes.sql
└── seed.sql
```

## Troubleshooting

### "Project not linked"
Si ves este error, el proyecto ya está linkeado (archivo `supabase/.temp/project-ref`), pero si por alguna razón se pierde:
```powershell
npm run sb:link
```

### Migraciones fallan
Si una migración falla, podés ver el estado:
```powershell
supabase migration list
```

Y para marcar una como aplicada manualmente (si la ejecutaste ya en SQL Editor):
```powershell
supabase migration repair --status applied 00003_portal_clientes
```

## Proyecto vinculado

- **Project Ref:** `gzrncvukxfaejcozffut`
- **URL:** https://gzrncvukxfaejcozffut.supabase.co
