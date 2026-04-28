-- ============================================
-- MIGRACION: Funcion RPC para registro de dueño
-- Bypass RLS para crear barberia + perfil
-- ============================================

CREATE OR REPLACE FUNCTION crear_barberia_y_perfil(
  p_user_id uuid,
  p_nombre_barberia text,
  p_nombre_usuario text
)
RETURNS uuid AS $$
DECLARE
  v_barberia_id uuid;
BEGIN
  -- Crear barberia (bypass RLS por SECURITY DEFINER)
  INSERT INTO barberias (nombre)
  VALUES (p_nombre_barberia)
  RETURNING id INTO v_barberia_id;

  -- Crear perfil como dueño
  INSERT INTO profiles (id, barberia_id, rol, nombre)
  VALUES (p_user_id, v_barberia_id, 'dueño', p_nombre_usuario);

  RETURN v_barberia_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
