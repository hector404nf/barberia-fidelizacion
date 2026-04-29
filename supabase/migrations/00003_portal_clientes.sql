-- ============================================
-- MIGRACION: Portal de Clientes
-- Agrega autenticación de clientes y RLS
-- ============================================

-- 1. Agregar auth_user_id a clientes para vincular con auth.users
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS auth_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_clientes_auth_user ON clientes(auth_user_id);

-- 2. Agregar código corto a barberías para que clientes la encuentren
ALTER TABLE barberias ADD COLUMN IF NOT EXISTS codigo text UNIQUE;

-- Generar códigos para barberías existentes (primeras 6 letras del nombre + random)
UPDATE barberias SET codigo = LOWER(REGEXP_REPLACE(LEFT(nombre, 6), '[^a-zA-Z]', '', 'g')) || FLOOR(RANDOM() * 1000)::text
WHERE codigo IS NULL;

-- 3. Hacer barberías visibles públicamente (solo select básico)
DROP POLICY IF EXISTS "barberias_select_public" ON barberias;
CREATE POLICY "barberias_select_public" ON barberias
  FOR SELECT USING (true);

-- 4. Clientes pueden verse a sí mismos (por auth_user_id)
DROP POLICY IF EXISTS "clientes_select_own" ON clientes;
CREATE POLICY "clientes_select_own" ON clientes
  FOR SELECT USING (auth_user_id = auth.uid());

DROP POLICY IF EXISTS "clientes_update_own" ON clientes;
CREATE POLICY "clientes_update_own" ON clientes
  FOR UPDATE USING (auth_user_id = auth.uid());

-- 5. Visitas: clientes ven sus propias visitas
DROP POLICY IF EXISTS "visitas_select_own" ON visitas;
CREATE POLICY "visitas_select_own" ON visitas
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM clientes c WHERE c.id = visitas.cliente_id AND c.auth_user_id = auth.uid())
  );

-- 6. Puntos: clientes ven sus propios puntos
DROP POLICY IF EXISTS "puntos_select_own" ON puntos_cliente;
CREATE POLICY "puntos_select_own" ON puntos_cliente
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM clientes c WHERE c.id = puntos_cliente.cliente_id AND c.auth_user_id = auth.uid())
  );

-- 7. Movimientos: clientes ven sus propios
DROP POLICY IF EXISTS "movimientos_select_own" ON movimientos_puntos;
CREATE POLICY "movimientos_select_own" ON movimientos_puntos
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM clientes c WHERE c.id = movimientos_puntos.cliente_id AND c.auth_user_id = auth.uid())
  );

-- 8. Recompensas: clientes ven las activas de su barbería
DROP POLICY IF EXISTS "recompensas_select_cliente" ON recompensas;
CREATE POLICY "recompensas_select_cliente" ON recompensas
  FOR SELECT USING (
    activa = true AND
    barberia_id IN (
      SELECT barberia_id FROM clientes WHERE auth_user_id = auth.uid()
    )
  );

-- 9. Reservas: clientes ven las propias
DROP POLICY IF EXISTS "reservas_select_own" ON reservas;
CREATE POLICY "reservas_select_own" ON reservas
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM clientes c WHERE c.id = reservas.cliente_id AND c.auth_user_id = auth.uid())
  );

DROP POLICY IF EXISTS "reservas_insert_own" ON reservas;
CREATE POLICY "reservas_insert_own" ON reservas
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM clientes c WHERE c.id = reservas.cliente_id AND c.auth_user_id = auth.uid())
  );

-- 10. Barberos: clientes ven los activos de su barbería
DROP POLICY IF EXISTS "barberos_select_cliente" ON barberos;
CREATE POLICY "barberos_select_cliente" ON barberos
  FOR SELECT USING (
    activo = true AND
    barberia_id IN (
      SELECT barberia_id FROM clientes WHERE auth_user_id = auth.uid()
    )
  );

-- ============================================
-- FUNCIONES RPC
-- ============================================

-- Registrar cliente nuevo (desde portal de cliente)
CREATE OR REPLACE FUNCTION registrar_cliente(
  p_auth_user_id uuid,
  p_barberia_id uuid,
  p_nombre text,
  p_telefono text,
  p_fecha_nacimiento date DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
  v_cliente_id uuid;
  v_existente uuid;
BEGIN
  -- Verificar si ya existe cliente con este teléfono en la barbería sin auth_user_id
  SELECT id INTO v_existente
  FROM clientes
  WHERE barberia_id = p_barberia_id
    AND telefono = p_telefono
    AND auth_user_id IS NULL;

  IF v_existente IS NOT NULL THEN
    -- Vincular cliente existente
    UPDATE clientes
    SET auth_user_id = p_auth_user_id,
        nombre = p_nombre
    WHERE id = v_existente;
    RETURN v_existente;
  END IF;

  -- Crear cliente nuevo
  INSERT INTO clientes (barberia_id, nombre, telefono, fecha_nacimiento, auth_user_id)
  VALUES (p_barberia_id, p_nombre, p_telefono, p_fecha_nacimiento, p_auth_user_id)
  RETURNING id INTO v_cliente_id;

  RETURN v_cliente_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Obtener datos del cliente logueado
CREATE OR REPLACE FUNCTION get_cliente_actual()
RETURNS TABLE (
  id uuid,
  nombre text,
  telefono text,
  barberia_id uuid,
  barberia_nombre text,
  estado text,
  total_visitas int,
  puntos_actuales int
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id,
    c.nombre,
    c.telefono,
    c.barberia_id,
    b.nombre as barberia_nombre,
    c.estado,
    c.total_visitas,
    COALESCE(pc.puntos_actuales, 0) as puntos_actuales
  FROM clientes c
  JOIN barberias b ON b.id = c.barberia_id
  LEFT JOIN puntos_cliente pc ON pc.cliente_id = c.id
  WHERE c.auth_user_id = auth.uid()
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Obtener disponibilidad de horarios para una fecha
CREATE OR REPLACE FUNCTION get_horarios_ocupados(
  p_barberia_id uuid,
  p_fecha date,
  p_barbero_id uuid DEFAULT NULL
)
RETURNS TABLE (hora time) AS $$
BEGIN
  RETURN QUERY
  SELECT r.hora
  FROM reservas r
  JOIN clientes c ON c.id = r.cliente_id
  WHERE c.barberia_id = p_barberia_id
    AND r.fecha = p_fecha
    AND r.estado IN ('pendiente', 'completada')
    AND (p_barbero_id IS NULL OR r.barbero_id = p_barbero_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
