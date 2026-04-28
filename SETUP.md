# 💈 Barbería Fidelización - Setup

## 1. Configurar Supabase

Tu proyecto ya está conectado con estas credenciales (configúralas como variables de entorno o dart-define):
- **URL:** `https://gzrncvukxfaejcozffut.supabase.co`
- **Anon Key:** *(ver tu proyecto de Supabase)*

### Ejecutar migraciones SQL

1. Ve a tu proyecto en [Supabase Dashboard](https://app.supabase.com/project/gzrncvukxfaejcozffut)
2. Abre **SQL Editor** (izquierda)
3. Crea un **New query**
4. Copia TODO el contenido de `supabase/migrations/00001_initial_schema.sql`
5. Pega y ejecuta con **Run**

### Verificar Auth Settings

1. Ve a **Authentication → URL Configuration**
2. En **Site URL** pon: `http://localhost:8080` (para desarrollo local)
3. En **Redirect URLs** agrega:
   - `http://localhost:8080/**`
   - `https://tu-dominio-vercel.vercel.app/**` (cuando deployes)

## 2. Instalar dependencias Flutter

```bash
flutter pub get
```

## 3. Correr en modo web (desarrollo)

```bash
flutter run -d chrome --web-port 8080
```

## 4. Datos de prueba (opcional)

Después de registrarte en la app:

1. Ve a **Table Editor → barberias** en Supabase
2. Copia el `id` de la barbería creada
3. Ve a **Table Editor → profiles**
4. Verifica que tu usuario tenga `rol = 'dueño'`
5. Copia tu `user_id` (UUID) desde **Authentication → Users**
6. Edita `supabase/seed.sql`:
   - Reemplaza `'TU_BARBERIA_UUID'` con el ID real de tu barbería
   - Reemplaza `'TU_USER_UUID'` con tu user_id
7. Ejecuta el seed.sql en SQL Editor

## 5. Deploy a Vercel

```bash
flutter build web --release
```

Sube la carpeta `build/web/` a Vercel.

No olvides configurar las variables de entorno en Vercel:
- `SUPABASE_URL=https://gzrncvukxfaejcozffut.supabase.co`
- `SUPABASE_ANON_KEY=`*(tu Anon Key)*

**Importante:** Mueve las credenciales a variables de entorno antes de hacer el repo público.
