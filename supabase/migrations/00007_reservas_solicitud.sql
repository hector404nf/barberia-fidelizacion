-- Fix: Elimina cualquier constraint de estado y recrea con todos los estados permitidos
-- Ejecutar en orden para evitar conflictos

-- 1. Eliminar TODAS las constraints de estado posibles
DO $$ BEGIN
  ALTER TABLE reservas DROP CONSTRAINT IF EXISTS reservas_estado_check;
EXCEPTION WHEN undefined_table THEN RAISE NOTICE 'Constraint no existe';
END $$;

DO $$ BEGIN
  ALTER TABLE reservas DROP CONSTRAINT IF EXISTS reservas_estado_check_v2;
EXCEPTION WHEN undefined_table THEN RAISE NOTICE 'Constraint v2 no existe';
END $$;

-- 2. Actualizar reservas con estado inválido
UPDATE reservas SET estado = 'confirmada' WHERE estado = 'pendiente';

-- 3. Crear la constraint con todos los estados
ALTER TABLE reservas ADD CONSTRAINT reservas_estado_check
  CHECK (estado IN ('solicitada', 'confirmada', 'completada', 'cancelada', 'no_show'));

-- 4. Setear default
ALTER TABLE reservas ALTER COLUMN estado SET DEFAULT 'solicitada';
