# 🗄️ Modelo de Datos

> Esquema completo de PostgreSQL para Supabase.

---

## Diagrama Entidad-Relación

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   barberias     │     │     profiles    │     │  auth.users     │
├─────────────────┤     ├─────────────────┤     │  (supabase)     │
│ id (PK)         │◄────┤ id (PK, FK)     │────►├─────────────────┤
│ nombre          │     │ barberia_id(FK) │     │ ...             │
│ telefono        │     │ rol             │     └─────────────────┘
│ direccion       │     │ nombre          │
│ logo_url        │     │ created_at      │
│ config_puntos   │     └─────────────────┘
│ created_at      │
└─────────────────┘
         │
         │ 1:N
         ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    clientes     │     │     visitas     │     │   barberos      │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│ id (PK)         │◄────┤ id (PK)         │     │ id (PK)         │
│ barberia_id(FK) │     │ cliente_id(FK)  │     │ barberia_id(FK) │
│ nombre          │     │ barbero_id(FK)  │────►│ nombre          │
│ telefono (UQ)   │     │ fecha           │     │ especialidad    │
│ fecha_nacimiento│     │ servicio        │     │ foto_url        │
│ barbero_fav_id  │────►│ monto           │     │ activo          │
│ estado          │     │ puntos_otorgados│     │ created_at      │
│ frecuencia_calc │     │ created_at      │     └─────────────────┘
│ created_at      │     └─────────────────┘
└─────────────────┘
         │
         │ 1:1
         ▼
┌─────────────────┐
│  puntos_cliente │
├─────────────────┤
│ cliente_id (PK) │
│ puntos_actuales │
│ updated_at      │
└─────────────────┘
         │
         │ 1:N
         ▼
┌─────────────────┐
│movimientos_puntos
├─────────────────┤
│ id (PK)         │
│ cliente_id(FK)  │
│ tipo            │  -- 'ganado' | 'canjeado' | 'expirado'
│ puntos          │
│ descripcion     │
│ referencia_id   │  -- id de visita o recompensa
│ created_at      │
└─────────────────┘

┌─────────────────┐     ┌─────────────────┐
│  recompensas    │     │    reservas     │
├─────────────────┤     ├─────────────────┤
│ id (PK)         │     │ id (PK)         │
│ barberia_id(FK) │     │ cliente_id(FK)  │
│ nombre          │     │ barbero_id(FK)  │
│ puntos_req      │     │ fecha           │
│ tipo            │     │ hora            │
│ valor           │     │ servicio        │
│ activa          │     │ estado          │  -- 'pendiente' | 'completada' | 'cancelada' | 'no_show'
│ created_at      │     │ notas           │
└─────────────────┘     │ created_at      │
                        └─────────────────┘
```

---

## Tablas Detalladas

### `barberias`
Configuración principal de cada barbería.

| Columna | Tipo | Default | Notas |
|---------|------|---------|-------|
| `id` | uuid | gen_random_uuid() | PK |
| `nombre` | text | not null | Nombre del negocio |
| `telefono` | text | | Para WhatsApp futuro |
| `direccion` | text | | |
| `logo_url` | text | | Supabase Storage |
| `config_puntos` | jsonb | `{"por_visita": 10, "por_referido": 50, "por_monto": 1}` | Puntos por cada $1 |
| `created_at` | timestamptz | now() | |

### `profiles`
Extensión de `auth.users` para roles.

| Columna | Tipo | Default | Notas |
|---------|------|---------|-------|
| `id` | uuid | | PK, FK → auth.users |
| `barberia_id` | uuid | | FK → barberias |
| `rol` | text | 'barbero' | 'dueño' \| 'barbero' |
| `nombre` | text | not null | Nombre del usuario |
| `created_at` | timestamptz | now() | |

### `barberos`
Listado de barberos de la barbería.

| Columna | Tipo | Default | Notas |
|---------|------|---------|-------|
| `id` | uuid | gen_random_uuid() | PK |
| `barberia_id` | uuid | | FK → barberias |
| `nombre` | text | not null | |
| `especialidad` | text | | Ej: "Degradados", "Barba" |
| `foto_url` | text | | |
| `activo` | boolean | true | |
| `created_at` | timestamptz | now() | |

### `clientes`

| Columna | Tipo | Default | Notas |
|---------|------|---------|-------|
| `id` | uuid | gen_random_uuid() | PK |
| `barberia_id` | uuid | | FK → barberias |
| `nombre` | text | not null | |
| `telefono` | text | not null | Único por barbería |
| `fecha_nacimiento` | date | | Para promos de cumpleaños |
| `barbero_favorito_id` | uuid | | FK → barberos |
| `estado` | text | 'activo' | 'activo' \| 'inactivo' |
| `frecuencia_visitas` | int | | Calculado: días promedio entre visitas |
| `ultima_visita` | date | | Auto-actualizado por trigger |
| `total_visitas` | int | 0 | Contador |
| `created_at` | timestamptz | now() | |

**Constraint única:** `(barberia_id, telefono)` - Un mismo teléfono puede existir en otra barbería, pero no en la misma.

### `visitas`

| Columna | Tipo | Default | Notas |
|---------|------|---------|-------|
| `id` | uuid | gen_random_uuid() | PK |
| `cliente_id` | uuid | not null | FK → clientes |
| `barbero_id` | uuid | | FK → barberos |
| `fecha` | timestamptz | now() | |
| `servicio` | text | not null | Ej: "Corte + Barba" |
| `monto` | decimal(10,2) | not null | |
| `puntos_otorgados` | int | 0 | Auto-calculado |
| `notas` | text | | |
| `created_at` | timestamptz | now() | |

### `puntos_cliente`

| Columna | Tipo | Default | Notas |
|---------|------|---------|-------|
| `cliente_id` | uuid | | PK, FK → clientes |
| `puntos_actuales` | int | 0 | |
| `total_ganados` | int | 0 | Histórico |
| `total_canjeados` | int | 0 | Histórico |
| `updated_at` | timestamptz | now() | |

### `movimientos_puntos`

| Columna | Tipo | Default | Notas |
|---------|------|---------|-------|
| `id` | uuid | gen_random_uuid() | PK |
| `cliente_id` | uuid | not null | FK → clientes |
| `tipo` | text | not null | 'ganado' \| 'canjeado' \| 'expirado' \| 'ajuste' |
| `puntos` | int | not null | Positivo o negativo |
| `descripcion` | text | not null | Ej: "Visita #45" |
| `referencia_tipo` | text | | 'visita' \| 'recompensa' \| 'manual' |
| `referencia_id` | uuid | | ID de la visita/recompensa relacionada |
| `created_at` | timestamptz | now() | |

### `recompensas`

| Columna | Tipo | Default | Notas |
|---------|------|---------|-------|
| `id` | uuid | gen_random_uuid() | PK |
| `barberia_id` | uuid | not null | FK → barberias |
| `nombre` | text | not null | Ej: "Corte Gratis" |
| `puntos_requeridos` | int | not null | |
| `tipo` | text | 'servicio' | 'servicio' \| 'descuento' \| 'producto' |
| `valor` | text | | Ej: "Corte" o "20%" |
| `activa` | boolean | true | |
| `stock_limitado` | boolean | false | |
| `stock_actual` | int | null | |
| `created_at` | timestamptz | now() | |

### `reservas`

| Columna | Tipo | Default | Notas |
|---------|------|---------|-------|
| `id` | uuid | gen_random_uuid() | PK |
| `cliente_id` | uuid | not null | FK → clientes |
| `barbero_id` | uuid | | FK → barberos |
| `fecha` | date | not null | |
| `hora` | time | not null | |
| `servicio` | text | not null | |
| `estado` | text | 'pendiente' | 'pendiente' \| 'completada' \| 'cancelada' \| 'no_show' |
| `notas` | text | | |
| `created_at` | timestamptz | now() | |
| `updated_at` | timestamptz | now() | |

---

## Triggers y Funciones SQL

### 1. Auto-actualizar `ultima_visita` y `total_visitas` del cliente
```sql
-- Al insertar una visita, actualizar cliente
CREATE OR REPLACE FUNCTION actualizar_stats_cliente()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE clientes
  SET 
    ultima_visita = NEW.fecha::date,
    total_visitas = total_visitas + 1,
    -- Recalcular frecuencia promedio si hay más de 1 visita
    frecuencia_visitas = CASE 
      WHEN total_visitas > 0 THEN 
        EXTRACT(DAY FROM (NEW.fecha - created_at)) / (total_visitas + 1)
      ELSE NULL 
    END
  WHERE id = NEW.cliente_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### 2. Otorgar puntos automáticamente al crear visita
```sql
CREATE OR REPLACE FUNCTION otorgar_puntos_por_visita()
RETURNS TRIGGER AS $$
DECLARE
  config jsonb;
  puntos_por_monto decimal;
  puntos_a_otorgar int;
BEGIN
  -- Obtener config de la barbería del cliente
  SELECT b.config_puntos INTO config
  FROM barberias b
  JOIN clientes c ON c.barberia_id = b.id
  WHERE c.id = NEW.cliente_id;

  puntos_por_monto := (config->>'por_monto')::decimal;
  puntos_a_otorgar := COALESCE((config->>'por_visita')::int, 10) + 
                      FLOOR(NEW.monto * puntos_por_monto)::int;

  -- Actualizar puntos del cliente
  INSERT INTO puntos_cliente (cliente_id, puntos_actuales, total_ganados)
  VALUES (NEW.cliente_id, puntos_a_otorgar, puntos_a_otorgar)
  ON CONFLICT (cliente_id) 
  DO UPDATE SET 
    puntos_actuales = puntos_cliente.puntos_actuales + puntos_a_otorgar,
    total_ganados = puntos_cliente.total_ganados + puntos_a_otorgar,
    updated_at = now();

  -- Registrar movimiento
  INSERT INTO movimientos_puntos (cliente_id, tipo, puntos, descripcion, referencia_tipo, referencia_id)
  VALUES (NEW.cliente_id, 'ganado', puntos_a_otorgar, 
          'Puntos por visita: ' || NEW.servicio, 'visita', NEW.id);

  -- Actualizar puntos_otorgados en la visita
  NEW.puntos_otorgados := puntos_a_otorgar;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### 3. Canje de recompensa (función RPC)
```sql
CREATE OR REPLACE FUNCTION canjear_recompensa(
  p_cliente_id uuid,
  p_recompensa_id uuid
)
RETURNS jsonb AS $$
DECLARE
  v_puntos_cliente int;
  v_puntos_req int;
  v_nombre_recompensa text;
BEGIN
  -- Obtener puntos actuales
  SELECT puntos_actuales INTO v_puntos_cliente
  FROM puntos_cliente WHERE cliente_id = p_cliente_id;

  -- Obtener datos de recompensa
  SELECT puntos_requeridos, nombre 
  INTO v_puntos_req, v_nombre_recompensa
  FROM recompensas WHERE id = p_recompensa_id;

  IF v_puntos_cliente < v_puntos_req THEN
    RETURN jsonb_build_object('success', false, 'error', 'Puntos insuficientes');
  END IF;

  -- Restar puntos
  UPDATE puntos_cliente
  SET puntos_actuales = puntos_actuales - v_puntos_req,
      total_canjeados = total_canjeados + v_puntos_req,
      updated_at = now()
  WHERE cliente_id = p_cliente_id;

  -- Registrar movimiento
  INSERT INTO movimientos_puntos (cliente_id, tipo, puntos, descripcion, referencia_tipo, referencia_id)
  VALUES (p_cliente_id, 'canjeado', -v_puntos_req, 
          'Canje: ' || v_nombre_recompensa, 'recompensa', p_recompensa_id);

  RETURN jsonb_build_object('success', true, 'recompensa', v_nombre_recompensa);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Políticas RLS (Ejemplos)

```sql
-- Clientes: solo ver los de tu barbería
CREATE POLICY "clientes_barberia" ON clientes
  FOR ALL USING (
    barberia_id IN (
      SELECT barberia_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Reservas: barberos solo ven las suyas (si no son dueños)
CREATE POLICY "reservas_acceso" ON reservas
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() 
      AND (rol = 'dueño' OR barbero_id = reservas.barbero_id)
    )
  );
```
