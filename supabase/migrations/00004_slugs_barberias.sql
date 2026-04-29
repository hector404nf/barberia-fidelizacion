-- ============================================
-- MIGRACION: URLs con slug por barberia
-- ============================================

-- Agregar slug a barberias
ALTER TABLE barberias ADD COLUMN IF NOT EXISTS slug text UNIQUE;

-- Generar slugs para barberias existentes
UPDATE barberias
SET slug = LOWER(REGEXP_REPLACE(
  REGEXP_REPLACE(nombre, '[^a-zA-Z0-9\\s]', '', 'g'),
  '\\s+', '-', 'g'
))
WHERE slug IS NULL;

-- Asegurar unicidad si hay nombres duplicados
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

-- Funcion para obtener barberia por slug
CREATE OR REPLACE FUNCTION get_barberia_por_slug(p_slug text)
RETURNS TABLE (
  id uuid,
  nombre text,
  slug text,
  codigo text
) AS $$
BEGIN
  RETURN QUERY
  SELECT b.id, b.nombre, b.slug, b.codigo
  FROM barberias b
  WHERE b.slug = p_slug
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
