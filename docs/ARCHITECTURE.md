# 🏗️ Arquitectura

> Decisiones técnicas y arquitectura del sistema.

---

## Diagrama General

```
┌─────────────────────────────────────────────────────────────────┐
│                         USUARIO                                 │
│                  (Dueño / Barbero)                              │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS
┌──────────────────────────▼──────────────────────────────────────┐
│  Vercel CDN                                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Flutter Web (PWA)                                      │   │
│  │  - Dart / Flutter Framework                             │   │
│  │  - supabase_flutter SDK                                 │   │
│  │  - State Management: Riverpod                           │   │
│  └─────────────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────────────┘
                           │ REST / WebSocket / Realtime
┌──────────────────────────▼──────────────────────────────────────┐
│  Supabase Cloud                                                 │
│  ┌──────────────┐ ┌──────────────┐ ┌─────────────────────────┐ │
│  │ PostgreSQL   │ │   Auth       │ │    Storage              │ │
│  │ - RLS        │ │ - Magic Link │ │    - Fotos perfil       │ │
│  │ - Triggers   │ │ - JWT        │ │    - Logos              │ │
│  └──────────────┘ └──────────────┘ └─────────────────────────┘ │
│  ┌──────────────┐ ┌─────────────────────────────────────────┐  │
│  │  Realtime    │ │  Edge Functions (Deno/TS)               │  │
│  │  - Reservas  │ │  - Webhooks (futuro)                    │  │
│  │  - Puntos    │ │  - Notificaciones push (futuro)         │  │
│  └──────────────┘ └─────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                           │ (FUTURO)
┌──────────────────────────▼──────────────────────────────────────┐
│  Microservicio WhatsApp (Node.js + Baileys)                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  - VPS/Fly.io/Oracle Cloud (siempre prendido)          │   │
│  │  - API REST interna                                     │   │
│  │  - Sesión persistente                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Seguridad

### Row Level Security (RLS)
Todas las tablas tienen RLS habilitado. Las políticas se basan en:
- `auth.uid()` para identificar el usuario logueado
- Tabla `barberias` como tenant (cada dueño tiene su barbería)
- Tabla `profiles` vincula `auth.users` con rol y barbería

### Autenticación
- Magic Links (sin contraseñas)
- JWT tokens manejados automáticamente por `supabase_flutter`
- Sesiones persistentes en localStorage

---

## Estado Global (Flutter)

Usamos **Riverpod** (Provider 2.0):

```dart
// Providers globales
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);
final barberiaProvider = FutureProvider<Barberia>(...);
final clientesProvider = StreamProvider<List<Cliente>>(...);
```

Por qué Riverpod y no Bloc:
- Menos boilerplate
- Integración nativa con Flutter
- Manejo de dependencias incorporado
- Mejor para proyectos pequeños/medios

---

## Patrón de Repositorio

Cada entidad tiene un repositorio que abstrae Supabase:

```dart
abstract class ClienteRepository {
  Future<List<Cliente>> getAll();
  Future<Cliente> getById(String id);
  Future<Cliente> create(Cliente cliente);
  Future<Cliente> update(Cliente cliente);
  Future<void> delete(String id);
  Future<Cliente?> getByTelefono(String telefono);
}

class SupabaseClienteRepository implements ClienteRepository {
  final SupabaseClient _client;
  // implementación...
}
```

---

## Convenciones de Supabase

- **Tablas:** plural, snake_case (`clientes`, `movimientos_puntos`)
- **Columnas:** snake_case
- **IDs:** UUID v4
- **Timestamps:** `created_at`, `updated_at` con defaults
- **Soft delete:** campo `estado` o `deleted_at`, nunca `DELETE` real
- **RLS:** SIEMPRE habilitado antes de `INSERT`

---

## Escalabilidad Futura

### Fase 2: WhatsApp
Se agrega un microservicio Node.js independiente. El frontend no cambia. Supabase Edge Functions actúan como puente:

```
Supabase Edge Function ──POST──► Microservicio WhatsApp
                                  (Node.js + Baileys)
```

### Fase 3: Multi-barbería
El schema ya está preparado con `barberia_id` en todas las tablas.

### Fase 4: App Mobile
Misma codebase Flutter. Se agregan `cupertino` widgets y push notifications.
