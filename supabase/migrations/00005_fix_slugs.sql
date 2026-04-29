-- ============================================
-- MIGRACION: Fix slugs faltantes
-- ============================================

-- 1. Regenerar slugs para barberias que no lo tengan
UPDATE barberias
SET slug = LOWER(REGEXP_REPLACE(
  REGEXP_REPLACE(nombre, '[^a-zA-Z0-9\\s]', '', 'g'),
  '\\s+', '-', 'g'
))
WHERE slug IS NULL OR slug = '';

-- 2. Asegurar unicidad nuevamente
DO $$
DECLARE
  r RECORD;
  counter int;
BEGIN
  FOR r IN SELECT id, slug FROM barberias WHERE slug IN (
    SELECT slug FROM barberias GROUP BY slug HAVING COUNT(*) > 1
  ) LOOP
    counter := 1;
    LOOP
      IF NOT EXISTS (SELECT 1 FROM barberias WHERE slug = r.slug || '-' || counter AND id != r.id) THEN
        UPDATE barberias SET slug = r.slug || '-' || counter WHERE id = r.id;
        EXIT;
      END IF;
      counter := counter + 1;
    END LOOP;
  END LOOP;
END $$;

-- 3. Actualizar funcion de registro para generar slug automaticamente
CREATE OR REPLACE FUNCTION crear_barberia_y_perfil(
  p_user_id uuid,
  p_nombre_barberia text,
  p_nombre_usuario text
)
RETURNS uuid AS $$
DECLARE
  v_barberia_id uuid;
  v_slug text;
  v_counter int := 1;
BEGIN
  -- Generar slug base
  v_slug := LOWER(REGEXP_REPLACE(
    REGEXP_REPLACE(p_nombre_barberia, '[^a-zA-Z0-9\\s]', '', 'g'),
    '\\s+', '-', 'g'
  ));

  -- Asegurar unicidad del slug
  WHILE EXISTS (SELECT 1 FROM barberias WHERE slug = v_slug) LOOP
    v_slug := v_slug || '-' || v_counter;
    v_counter := v_counter + 1;
  END LOOP;

  -- Crear barberia con slug (bypass RLS por SECURITY DEFINER)
  INSERT INTO barberias (nombre, slug)
  VALUES (p_nombre_barberia, v_slug)
  RETURNING id INTO v_barberia_id;

  -- Crear perfil como dueno
  INSERT INTO profiles (id, barberia_id, rol, nombre)
  VALUES (p_user_id, v_barberia_id, 'dueño', p_nombre_usuario);

  RETURN v_barberia_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
