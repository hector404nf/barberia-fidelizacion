-- ============================================
-- MIGRACION: Esquema inicial completo
-- Barberia Fidelizacion v1.0
-- ============================================

-- Extension necesaria para UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLAS PRINCIPALES
-- ============================================

CREATE TABLE barberias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre text NOT NULL,
  telefono text,
  direccion text,
  logo_url text,
  config_puntos jsonb NOT NULL DEFAULT '{"por_visita": 10, "por_monto": 1}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  barberia_id uuid REFERENCES barberias(id) ON DELETE SET NULL,
  rol text NOT NULL DEFAULT 'barbero' CHECK (rol IN ('dueño', 'barbero')),
  nombre text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE barberos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  barberia_id uuid NOT NULL REFERENCES barberias(id) ON DELETE CASCADE,
  nombre text NOT NULL,
  especialidad text,
  foto_url text,
  activo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE clientes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  barberia_id uuid NOT NULL REFERENCES barberias(id) ON DELETE CASCADE,
  nombre text NOT NULL,
  telefono text NOT NULL,
  fecha_nacimiento date,
  barbero_favorito_id uuid REFERENCES barberos(id) ON DELETE SET NULL,
  estado text NOT NULL DEFAULT 'nuevo' CHECK (estado IN ('nuevo', 'activo', 'vip', 'inactivo')),
  frecuencia_visitas int,
  ultima_visita date,
  total_visitas int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(barberia_id, telefono)
);

CREATE TABLE puntos_cliente (
  cliente_id uuid PRIMARY KEY REFERENCES clientes(id) ON DELETE CASCADE,
  puntos_actuales int NOT NULL DEFAULT 0,
  total_ganados int NOT NULL DEFAULT 0,
  total_canjeados int NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE visitas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id uuid NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
  barbero_id uuid REFERENCES barberos(id) ON DELETE SET NULL,
  fecha timestamptz NOT NULL DEFAULT now(),
  servicio text NOT NULL,
  monto decimal(10,2) NOT NULL,
  puntos_otorgados int NOT NULL DEFAULT 0,
  notas text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE movimientos_puntos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id uuid NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
  tipo text NOT NULL CHECK (tipo IN ('ganado', 'canjeado', 'expirado', 'ajuste')),
  puntos int NOT NULL,
  descripcion text NOT NULL,
  referencia_tipo text CHECK (referencia_tipo IN ('visita', 'recompensa', 'manual')),
  referencia_id uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE recompensas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  barberia_id uuid NOT NULL REFERENCES barberias(id) ON DELETE CASCADE,
  nombre text NOT NULL,
  puntos_requeridos int NOT NULL,
  tipo text NOT NULL DEFAULT 'servicio' CHECK (tipo IN ('servicio', 'descuento', 'producto')),
  valor text,
  activa boolean NOT NULL DEFAULT true,
  stock_limitado boolean NOT NULL DEFAULT false,
  stock_actual int,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE reservas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id uuid NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
  barbero_id uuid REFERENCES barberos(id) ON DELETE SET NULL,
  fecha date NOT NULL,
  hora time NOT NULL,
  servicio text NOT NULL,
  estado text NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'completada', 'cancelada', 'no_show')),
  notas text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================
-- INDICES
-- ============================================

CREATE INDEX idx_clientes_barberia ON clientes(barberia_id);
CREATE INDEX idx_clientes_telefono ON clientes(telefono);
CREATE INDEX idx_clientes_estado ON clientes(estado);
CREATE INDEX idx_visitas_cliente ON visitas(cliente_id);
CREATE INDEX idx_visitas_fecha ON visitas(fecha DESC);
CREATE INDEX idx_movimientos_cliente ON movimientos_puntos(cliente_id);
CREATE INDEX idx_reservas_fecha ON reservas(fecha);
CREATE INDEX idx_reservas_barbero_fecha ON reservas(barbero_id, fecha);
CREATE INDEX idx_recompensas_barberia ON recompensas(barberia_id);

-- ============================================
-- TRIGGERS Y FUNCIONES
-- ============================================

-- 1. Actualizar ultima_visita y total_visitas del cliente
CREATE OR REPLACE FUNCTION actualizar_stats_cliente()
RETURNS TRIGGER AS $$
DECLARE
  dias_totales int;
BEGIN
  -- Calcular dias entre primera y ultima visita
  SELECT COALESCE(EXTRACT(DAY FROM (NEW.fecha - MIN(fecha))), 0)::int
  INTO dias_totales
  FROM visitas
  WHERE cliente_id = NEW.cliente_id;

  UPDATE clientes
  SET 
    ultima_visita = NEW.fecha::date,
    total_visitas = total_visitas + 1,
    frecuencia_visitas = CASE 
      WHEN total_visitas > 0 AND dias_totales > 0 THEN 
        dias_totales / (total_visitas + 1)
      ELSE NULL 
    END,
    estado = CASE 
      WHEN estado = 'nuevo' AND total_visitas + 1 >= 3 THEN 'activo'
      WHEN estado = 'inactivo' THEN 'activo'
      ELSE estado
    END
  WHERE id = NEW.cliente_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_stats_cliente
  AFTER INSERT ON visitas
  FOR EACH ROW
  EXECUTE FUNCTION actualizar_stats_cliente();

-- 2. Otorgar puntos automaticamente al crear visita
CREATE OR REPLACE FUNCTION otorgar_puntos_por_visita()
RETURNS TRIGGER AS $$
DECLARE
  config jsonb;
  puntos_por_monto numeric;
  puntos_por_visita int;
  puntos_a_otorgar int;
BEGIN
  -- Obtener config de la barberia del cliente
  SELECT b.config_puntos INTO config
  FROM barberias b
  JOIN clientes c ON c.barberia_id = b.id
  WHERE c.id = NEW.cliente_id;

  puntos_por_visita := COALESCE((config->>'por_visita')::int, 10);
  puntos_por_monto := COALESCE((config->>'por_monto')::numeric, 1);
  puntos_a_otorgar := puntos_por_visita + FLOOR(NEW.monto * puntos_por_monto)::int;

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

CREATE TRIGGER trigger_otorgar_puntos
  BEFORE INSERT ON visitas
  FOR EACH ROW
  EXECUTE FUNCTION otorgar_puntos_por_visita();

-- 3. Actualizar updated_at de reservas
CREATE OR REPLACE FUNCTION actualizar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_reservas_updated_at
  BEFORE UPDATE ON reservas
  FOR EACH ROW
  EXECUTE FUNCTION actualizar_updated_at();

-- 4. Detectar clientes inactivos (ejecutar periodicamente)
CREATE OR REPLACE FUNCTION marcar_clientes_inactivos()
RETURNS int AS $$
DECLARE
  afectados int;
BEGIN
  UPDATE clientes
  SET estado = 'inactivo'
  WHERE estado IN ('nuevo', 'activo', 'vip')
    AND ultima_visita IS NOT NULL
    AND ultima_visita < CURRENT_DATE - INTERVAL '30 days';

  GET DIAGNOSTICS afectados = ROW_COUNT;
  RETURN afectados;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCIONES RPC
-- ============================================

-- Canje de recompensa
CREATE OR REPLACE FUNCTION canjear_recompensa(
  p_cliente_id uuid,
  p_recompensa_id uuid
)
RETURNS jsonb AS $$
DECLARE
  v_puntos_cliente int;
  v_puntos_req int;
  v_nombre_recompensa text;
  v_stock_limitado boolean;
  v_stock_actual int;
BEGIN
  -- Obtener puntos actuales
  SELECT puntos_actuales INTO v_puntos_cliente
  FROM puntos_cliente WHERE cliente_id = p_cliente_id;

  IF v_puntos_cliente IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Cliente no encontrado');
  END IF;

  -- Obtener datos de recompensa
  SELECT puntos_requeridos, nombre, stock_limitado, stock_actual
  INTO v_puntos_req, v_nombre_recompensa, v_stock_limitado, v_stock_actual
  FROM recompensas WHERE id = p_recompensa_id;

  IF v_nombre_recompensa IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Recompensa no encontrada');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM recompensas WHERE id = p_recompensa_id AND activa = true) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Recompensa no activa');
  END IF;

  IF v_stock_limitado AND COALESCE(v_stock_actual, 0) <= 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Sin stock disponible');
  END IF;

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

  -- Descontar stock si aplica
  IF v_stock_limitado THEN
    UPDATE recompensas
    SET stock_actual = stock_actual - 1
    WHERE id = p_recompensa_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true, 
    'recompensa', v_nombre_recompensa,
    'puntos_restantes', v_puntos_cliente - v_puntos_req
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Estadisticas del dashboard
CREATE OR REPLACE FUNCTION get_estadisticas(
  p_barberia_id uuid,
  p_fecha_desde date DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_fecha_hasta date DEFAULT CURRENT_DATE
)
RETURNS jsonb AS $$
DECLARE
  v_clientes_activos int;
  v_clientes_inactivos int;
  v_visitas int;
  v_ingreso numeric;
  v_ticket_promedio numeric;
  v_recompensas int;
  v_nuevos int;
BEGIN
  SELECT COUNT(*) INTO v_clientes_activos
  FROM clientes
  WHERE barberia_id = p_barberia_id
    AND estado IN ('activo', 'vip');

  SELECT COUNT(*) INTO v_clientes_inactivos
  FROM clientes
  WHERE barberia_id = p_barberia_id
    AND estado = 'inactivo';

  SELECT COUNT(*), COALESCE(SUM(monto), 0)
  INTO v_visitas, v_ingreso
  FROM visitas v
  JOIN clientes c ON c.id = v.cliente_id
  WHERE c.barberia_id = p_barberia_id
    AND v.fecha::date BETWEEN p_fecha_desde AND p_fecha_hasta;

  v_ticket_promedio := CASE WHEN v_visitas > 0 THEN v_ingreso / v_visitas ELSE 0 END;

  SELECT COUNT(*) INTO v_recompensas
  FROM movimientos_puntos mp
  JOIN clientes c ON c.id = mp.cliente_id
  WHERE c.barberia_id = p_barberia_id
    AND mp.tipo = 'canjeado'
    AND mp.created_at::date BETWEEN p_fecha_desde AND p_fecha_hasta;

  SELECT COUNT(*) INTO v_nuevos
  FROM clientes
  WHERE barberia_id = p_barberia_id
    AND created_at::date BETWEEN p_fecha_desde AND p_fecha_hasta;

  RETURN jsonb_build_object(
    'clientes_activos', v_clientes_activos,
    'clientes_inactivos', v_clientes_inactivos,
    'visitas_periodo', v_visitas,
    'ingreso_total', v_ingreso,
    'ticket_promedio', ROUND(v_ticket_promedio, 2),
    'recompensas_canjeadas', v_recompensas,
    'nuevos_clientes', v_nuevos
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Clientes inactivos
CREATE OR REPLACE FUNCTION get_clientes_inactivos(
  p_barberia_id uuid,
  p_dias int DEFAULT 30
)
RETURNS TABLE (
  id uuid,
  nombre text,
  telefono text,
  ultima_visita date,
  dias_sin_visita int,
  puntos_actuales int
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id,
    c.nombre,
    c.telefono,
    c.ultima_visita,
    EXTRACT(DAY FROM CURRENT_DATE - c.ultima_visita)::int as dias_sin_visita,
    COALESCE(pc.puntos_actuales, 0) as puntos_actuales
  FROM clientes c
  LEFT JOIN puntos_cliente pc ON pc.cliente_id = c.id
  WHERE c.barberia_id = p_barberia_id
    AND c.ultima_visita IS NOT NULL
    AND c.ultima_visita < CURRENT_DATE - (p_dias || ' days')::interval
  ORDER BY c.ultima_visita ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ranking de barberos
CREATE OR REPLACE FUNCTION get_ranking_barberos(
  p_barberia_id uuid,
  p_fecha_desde date DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_fecha_hasta date DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  barbero_id uuid,
  nombre text,
  total_visitas bigint,
  ingresos numeric
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b.id as barbero_id,
    b.nombre,
    COUNT(v.id) as total_visitas,
    COALESCE(SUM(v.monto), 0) as ingresos
  FROM barberos b
  LEFT JOIN visitas v ON v.barbero_id = b.id
    AND v.fecha::date BETWEEN p_fecha_desde AND p_fecha_hasta
  WHERE b.barberia_id = p_barberia_id
    AND b.activo = true
  GROUP BY b.id, b.nombre
  ORDER BY total_visitas DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- RLS POLICIES
-- ============================================

ALTER TABLE barberias ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE barberos ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE visitas ENABLE ROW LEVEL SECURITY;
ALTER TABLE puntos_cliente ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimientos_puntos ENABLE ROW LEVEL SECURITY;
ALTER TABLE recompensas ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservas ENABLE ROW LEVEL SECURITY;

-- Barberias: dueno ve la suya (perfil vinculado)
CREATE POLICY "barberias_select" ON barberias
  FOR SELECT USING (
    id IN (SELECT barberia_id FROM profiles WHERE id = auth.uid())
  );

CREATE POLICY "barberias_update" ON barberias
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND rol = 'dueño' AND barberia_id = barberias.id)
  );

-- Profiles: cada usuario ve su perfil
CREATE POLICY "profiles_select" ON profiles
  FOR SELECT USING (id = auth.uid());

CREATE POLICY "profiles_insert" ON profiles
  FOR INSERT WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_update" ON profiles
  FOR UPDATE USING (id = auth.uid());

-- Barberos: visibles dentro de la barberia
CREATE POLICY "barberos_all" ON barberos
  FOR ALL USING (
    barberia_id IN (SELECT barberia_id FROM profiles WHERE id = auth.uid())
  );

-- Clientes: visibles dentro de la barberia
CREATE POLICY "clientes_all" ON clientes
  FOR ALL USING (
    barberia_id IN (SELECT barberia_id FROM profiles WHERE id = auth.uid())
  );

-- Visitas: visibles si el cliente pertenece a la barberia del usuario
CREATE POLICY "visitas_all" ON visitas
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM clientes c
      JOIN profiles p ON p.barberia_id = c.barberia_id
      WHERE c.id = visitas.cliente_id AND p.id = auth.uid()
    )
  );

-- Puntos cliente: visibles si el cliente pertenece a la barberia
CREATE POLICY "puntos_select" ON puntos_cliente
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM clientes c
      JOIN profiles p ON p.barberia_id = c.barberia_id
      WHERE c.id = puntos_cliente.cliente_id AND p.id = auth.uid()
    )
  );

-- Movimientos puntos: mismo criterio
CREATE POLICY "movimientos_select" ON movimientos_puntos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM clientes c
      JOIN profiles p ON p.barberia_id = c.barberia_id
      WHERE c.id = movimientos_puntos.cliente_id AND p.id = auth.uid()
    )
  );

-- Recompensas: visibles dentro de la barberia
CREATE POLICY "recompensas_all" ON recompensas
  FOR ALL USING (
    barberia_id IN (SELECT barberia_id FROM profiles WHERE id = auth.uid())
  );

-- Reservas: visibles si pertenecen a la barberia
CREATE POLICY "reservas_all" ON reservas
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM clientes c
      JOIN profiles p ON p.barberia_id = c.barberia_id
      WHERE c.id = reservas.cliente_id AND p.id = auth.uid()
    )
  );
