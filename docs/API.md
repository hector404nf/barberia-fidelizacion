# 🔌 API y Funciones

> Endpoints, funciones RPC y flujos de datos entre frontend y Supabase.

---

## Arquitectura de Comunicación

Flutter usa exclusivamente el SDK `supabase_flutter`. **No hay REST API custom.**

```dart
// Ejemplo de uso
final clientes = await supabase
  .from('clientes')
  .select()
  .eq('barberia_id', barberiaId)
  .order('nombre');
```

---

## Tablas → Operaciones CRUD

### Clientes

| Operación | Supabase SDK | Notas |
|-----------|-------------|-------|
| Listar | `.from('clientes').select()` | Con filtros de búsqueda |
| Obtener | `.from('clientes').select().eq('id', id).single()` | |
| Crear | `.from('clientes').insert({...}).select().single()` | RLS valida barberia_id |
| Actualizar | `.from('clientes').update({...}).eq('id', id)` | |
| Buscar teléfono | `.from('clientes').select().eq('telefono', tel).maybeSingle()` | Clave para identificación rápida |

**Búsqueda parcial (nombre/teléfono):**
```dart
// Búsqueda por nombre (ilike = case insensitive)
supabase.from('clientes')
  .select()
  .ilike('nombre', '%$query%')
  .or('telefono.ilike.%$query%');
```

### Visitas

| Operación | Supabase SDK |
|-----------|-------------|
| Listar por cliente | `.from('visitas').select().eq('cliente_id', id).order('fecha', ascending: false)` |
| Crear | `.from('visitas').insert({...})` |
| KPIs | `.rpc('get_estadisticas', params: {'p_barberia_id': id})` |

### Puntos

| Operación | Método | Notas |
|-----------|--------|-------|
| Ver saldo | `.from('puntos_cliente').select().eq('cliente_id', id).single()` | |
| Historial | `.from('movimientos_puntos').select().eq('cliente_id', id).order('created_at', desc)` | |
| Canjear | `.rpc('canjear_recompensa', params: {...})` | Función SQL segura |

### Recompensas

| Operación | Supabase SDK |
|-----------|-------------|
| Listar activas | `.from('recompensas').select().eq('barberia_id', id).eq('activa', true)` |
| CRUD | Standard insert/update/delete |

### Reservas

| Operación | Supabase SDK |
|-----------|-------------|
| Listar por fecha | `.from('reservas').select('*, clientes(nombre)').eq('fecha', fecha).order('hora')` |
| Crear | `.from('reservas').insert({...})` |
| Actualizar estado | `.from('reservas').update({'estado': 'completada'}).eq('id', id)` |

**Realtime subscription:**
```dart
// Escuchar cambios en reservas del día
supabase.from('reservas')
  .stream(primaryKey: ['id'])
  .eq('fecha', hoy)
  .listen((data) => ref.read(reservasProvider.notifier).update(data));
```

---

## Funciones RPC (PostgreSQL)

Estas funciones viven en Supabase y se llaman desde Flutter con `.rpc()`:

### `canjear_recompensa(p_cliente_id, p_recompensa_id)`
Canje seguro de recompensa con validación de saldo.

**Retorna:**
```json
{"success": true, "recompensa": "Corte Gratis"}
// o
{"success": false, "error": "Puntos insuficientes"}
```

### `get_estadisticas(p_barberia_id, p_fecha_desde, p_fecha_hasta)`
KPIs del dashboard.

**Retorna:**
```json
{
  "clientes_activos": 45,
  "clientes_inactivos": 12,
  "visitas_periodo": 120,
  "ingreso_total": 450000.00,
  "ticket_promedio": 3750.00,
  "recompensas_canjeadas": 8,
  "nuevos_clientes": 15
}
```

### `get_clientes_inactivos(p_barberia_id, p_dias)`
Clientes sin visitas en los últimos N días.

**Retorna:** Lista de clientes con última visita.

### `get_ranking_barberos(p_barberia_id, p_fecha_desde, p_fecha_hasta)`
Barberos por visitas e ingresos.

**Retorna:**
```json
[
  {"barbero_id": "...", "nombre": "Carlos", "total_visitas": 45, "ingresos": 180000},
  ...
]
```

---

## Auth

### Registro (solo dueños)
```dart
// 1. Crear cuenta
await supabase.auth.signUp(
  email: email,
  password: password,
);

// 2. Crear barbería
await supabase.from('barberias').insert({'nombre': nombreNegocio});

// 3. Crear perfil como dueño
await supabase.from('profiles').insert({
  'id': supabase.auth.currentUser!.id,
  'rol': 'dueño',
  'nombre': nombreDueño,
});
```

### Login
```dart
await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);
```

### Magic Link (alternativa sin password)
```dart
await supabase.auth.signInWithOtp(email: email);
```

### Listener de sesión
```dart
supabase.auth.onAuthStateChange.listen((data) {
  final session = data.session;
  // Redirigir a login o dashboard
});
```

---

## Storage

### Subir foto de cliente
```dart
await supabase.storage
  .from('fotos')
  .upload('clientes/$clienteId.jpg', file);
```

### Obtener URL pública
```dart
final url = supabase.storage
  .from('fotos')
  .getPublicUrl('clientes/$clienteId.jpg');
```

---

## Integración Futura: WhatsApp

Cuando exista el microservicio, se comunicará mediante HTTP simple desde Supabase Edge Functions:

```
Flutter → Supabase Edge Function → POST → Microservicio WhatsApp
```

**Edge Function `send-whatsapp-notification`:**
```typescript
// Supabase Edge Function (Deno)
Deno.serve(async (req) => {
  const { telefono, mensaje } = await req.json();
  
  await fetch('https://whatsapp-service.fly.dev/send', {
    method: 'POST',
    headers: { 'Authorization': Deno.env.get('WHATSAPP_API_KEY') },
    body: JSON.stringify({ telefono, mensaje }),
  });
  
  return new Response(JSON.stringify({ sent: true }));
});
```

---

## Manejo de Erros

Código estándar para manejar errores de Supabase:

```dart
Future<void> crearCliente(Cliente cliente) async {
  try {
    final response = await supabase
      .from('clientes')
      .insert(cliente.toJson())
      .select()
      .single();
    
    return Cliente.fromJson(response);
  } on PostgrestException catch (e) {
    if (e.code == '23505') {
      throw 'Ya existe un cliente con ese teléfono';
    }
    throw 'Error de base de datos: ${e.message}';
  } catch (e) {
    throw 'Error inesperado: $e';
  }
}
```
