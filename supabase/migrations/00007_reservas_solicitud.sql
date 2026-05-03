-- Agrega estados 'solicitada' y 'confirmada' al flujo de reservas
-- Las reservas creadas por clientes empiezan como 'solicitada'
-- El admin debe confirmarlas para pasarlas a 'confirmada'

-- Primero actualizar reservas existentes pendientes a 'confirmada'
UPDATE reservas SET estado = 'confirmada' WHERE estado = 'pendiente';

-- Actualizar la constraint CHECK de estados en reservas (usar nombre nuevo para evitar conflictos)
ALTER TABLE reservas DROP CONSTRAINT IF EXISTS reservas_estado_check;
ALTER TABLE reservas ADD CONSTRAINT reservas_estado_check_v2
  CHECK (estado IN ('solicitada', 'confirmada', 'completada', 'cancelada', 'no_show'));

-- Default para nuevas reservas
ALTER TABLE reservas ALTER COLUMN estado SET DEFAULT 'solicitada';

-- Función para que las reservas administrativas vayan directo a confirmada
CREATE OR REPLACE FUNCTION crear_reserva_admin(
  p_cliente_id uuid,
  p_barbero_id uuid DEFAULT NULL,
  p_fecha date,
  p_hora time,
  p_servicio text,
  p_notas text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_reserva_id uuid;
BEGIN
  INSERT INTO reservas (cliente_id, barbero_id, fecha, hora, servicio, estado, notas)
  VALUES (p_cliente_id, p_barbero_id, p_fecha, p_hora, p_servicio, 'confirmada', p_notas)
  RETURNING id INTO v_reserva_id;
  
  RETURN v_reserva_id;
END;
$$;

-- Comentarios
COMMENT ON TABLE reservas IS 'Reservas con flujo: solicitada → confirmada → completada/cancelada/no_show';