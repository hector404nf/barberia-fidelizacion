-- ============================================
-- SEED DATA: Datos de prueba
-- ============================================

-- Nota: Ejecutar DESPUES de crear el schema y un usuario auth de Supabase
-- Reemplazar :user_id con el UUID real del usuario creado en Supabase Auth

-- 1. Crear barberia
INSERT INTO barberias (id, nombre, telefono, direccion, config_puntos)
VALUES (
  gen_random_uuid(),
  'La Barbería Premium',
  '+56912345678',
  'Av. Principal 123, Santiago',
  '{"por_visita": 10, "por_monto": 1}'::jsonb
)
RETURNING id;

-- Guardar el id de barberia generado para usarlo despues
-- (En psql o supabase studio, ejecutar paso a paso)

-- Ejemplo con barberia_id ficticio (reemplazar):
-- DO $$
-- DECLARE
--   v_barberia_id uuid := 'TU_BARBERIA_UUID';
--   v_user_id uuid := 'TU_USER_UUID';
-- BEGIN
--   ... resto del seed ...
-- END $$;

-- 2. Crear profile del dueño (vincular con auth.users existente)
-- INSERT INTO profiles (id, barberia_id, rol, nombre)
-- VALUES ('TU_USER_UUID', 'TU_BARBERIA_UUID', 'dueño', 'Carlos Dueño');

-- 3. Barberos
INSERT INTO barberos (barberia_id, nombre, especialidad) VALUES
  ('TU_BARBERIA_UUID', 'Carlos', 'Degradados y fades'),
  ('TU_BARBERIA_UUID', 'Miguel', 'Barba y afeitado'),
  ('TU_BARBERIA_UUID', 'Javier', 'Cortes clasicos');

-- 4. Clientes
INSERT INTO clientes (barberia_id, nombre, telefono, fecha_nacimiento, estado, total_visitas) VALUES
  ('TU_BARBERIA_UUID', 'Juan Perez', '+56911111111', '1990-05-15', 'activo', 5),
  ('TU_BARBERIA_UUID', 'Pedro Gomez', '+56922222222', '1985-08-22', 'vip', 12),
  ('TU_BARBERIA_UUID', 'Luis Torres', '+56933333333', '1995-03-10', 'activo', 3),
  ('TU_BARBERIA_UUID', 'Diego Ruiz', '+56944444444', null, 'nuevo', 1),
  ('TU_BARBERIA_UUID', 'Andres Silva', '+56955555555', '1988-12-01', 'inactivo', 8),
  ('TU_BARBERIA_UUID', 'Matias Lopez', '+56966666666', '1992-07-18', 'activo', 6),
  ('TU_BARBERIA_UUID', 'Felipe Castro', '+56977777777', null, 'nuevo', 2),
  ('TU_BARBERIA_UUID', 'Nicolas Vera', '+56988888888', '1980-11-30', 'vip', 15);

-- 5. Puntos iniciales
INSERT INTO puntos_cliente (cliente_id, puntos_actuales, total_ganados, total_canjeados)
SELECT id, total_visitas * 50, total_visitas * 50, 0
FROM clientes
WHERE barberia_id = 'TU_BARBERIA_UUID';

-- 6. Visitas historicas (para los ultimos 45 dias)
INSERT INTO visitas (cliente_id, barbero_id, fecha, servicio, monto) VALUES
  -- Juan Perez (5 visitas)
  ((SELECT id FROM clientes WHERE telefono = '+56911111111'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '2 days', 'Corte + Barba', 15000),
  ((SELECT id FROM clientes WHERE telefono = '+56911111111'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '10 days', 'Corte', 10000),
  ((SELECT id FROM clientes WHERE telefono = '+56911111111'), (SELECT id FROM barberos WHERE nombre = 'Miguel'), now() - interval '18 days', 'Corte + Barba', 15000),
  ((SELECT id FROM clientes WHERE telefono = '+56911111111'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '25 days', 'Corte', 10000),
  ((SELECT id FROM clientes WHERE telefono = '+56911111111'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '35 days', 'Corte + Ceja', 12000),
  
  -- Pedro Gomez (12 visitas, VIP)
  ((SELECT id FROM clientes WHERE telefono = '+56922222222'), (SELECT id FROM barberos WHERE nombre = 'Javier'), now() - interval '3 days', 'Corte Premium', 18000),
  ((SELECT id FROM clientes WHERE telefono = '+56922222222'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '8 days', 'Corte + Barba', 15000),
  ((SELECT id FROM clientes WHERE telefono = '+56922222222'), (SELECT id FROM barberos WHERE nombre = 'Miguel'), now() - interval '12 days', 'Afeitado completo', 12000),
  ((SELECT id FROM clientes WHERE telefono = '+56922222222'), (SELECT id FROM barberos WHERE nombre = 'Javier'), now() - interval '16 days', 'Corte Premium', 18000),
  ((SELECT id FROM clientes WHERE telefono = '+56922222222'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '20 days', 'Corte + Barba', 15000),
  ((SELECT id FROM clientes WHERE telefono = '+56922222222'), (SELECT id FROM barberos WHERE nombre = 'Miguel'), now() - interval '24 days', 'Corte', 10000),
  ((SELECT id FROM clientes WHERE telefono = '+56922222222'), (SELECT id FROM barberos WHERE nombre = 'Javier'), now() - interval '28 days', 'Corte + Barba', 15000),
  ((SELECT id FROM clientes WHERE telefono = '+56922222222'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '32 days', 'Corte Premium', 18000),
  ((SELECT id FROM clientes WHERE telefono = '+56922222222'), (SELECT id FROM barberos WHERE nombre = 'Miguel'), now() - interval '36 days', 'Corte + Ceja', 12000),
  ((SELECT id FROM clientes WHERE telefono = '+56922222222'), (SELECT id FROM barberos WHERE nombre = 'Javier'), now() - interval '40 days', 'Corte', 10000),
  ((SELECT id FROM clientes WHERE telefono = '+56922222222'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '44 days', 'Corte + Barba', 15000),
  
  -- Luis Torres (3 visitas)
  ((SELECT id FROM clientes WHERE telefono = '+56933333333'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '5 days', 'Corte', 10000),
  ((SELECT id FROM clientes WHERE telefono = '+56933333333'), (SELECT id FROM barberos WHERE nombre = 'Miguel'), now() - interval '15 days', 'Corte + Barba', 15000),
  ((SELECT id FROM clientes WHERE telefono = '+56933333333'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '28 days', 'Corte', 10000),
  
  -- Diego Ruiz (1 visita, nuevo)
  ((SELECT id FROM clientes WHERE telefono = '+56944444444'), (SELECT id FROM barberos WHERE nombre = 'Javier'), now() - interval '1 days', 'Corte', 10000),
  
  -- Andres Silva (8 visitas, inactivo - ultima hace 40 dias)
  ((SELECT id FROM clientes WHERE telefono = '+56955555555'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '40 days', 'Corte + Barba', 15000),
  ((SELECT id FROM clientes WHERE telefono = '+56955555555'), (SELECT id FROM barberos WHERE nombre = 'Miguel'), now() - interval '48 days', 'Corte', 10000),
  ((SELECT id FROM clientes WHERE telefono = '+56955555555'), (SELECT id FROM barberos WHERE nombre = 'Javier'), now() - interval '55 days', 'Corte + Barba', 15000),
  ((SELECT id FROM clientes WHERE telefono = '+56955555555'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '62 days', 'Corte', 10000),
  ((SELECT id FROM clientes WHERE telefono = '+56955555555'), (SELECT id FROM barberos WHERE nombre = 'Miguel'), now() - interval '70 days', 'Corte + Ceja', 12000),
  ((SELECT id FROM clientes WHERE telefono = '+56955555555'), (SELECT id FROM barberos WHERE nombre = 'Javier'), now() - interval '78 days', 'Corte', 10000),
  ((SELECT id FROM clientes WHERE telefono = '+56955555555'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '85 days', 'Corte + Barba', 15000),
  ((SELECT id FROM clientes WHERE telefono = '+56955555555'), (SELECT id FROM barberos WHERE nombre = 'Miguel'), now() - interval '95 days', 'Corte', 10000),
  
  -- Matias Lopez (6 visitas)
  ((SELECT id FROM clientes WHERE telefono = '+56966666666'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '4 days', 'Corte + Barba', 15000),
  ((SELECT id FROM clientes WHERE telefono = '+56966666666'), (SELECT id FROM barberos WHERE nombre = 'Javier'), now() - interval '11 days', 'Corte', 10000),
  ((SELECT id FROM clientes WHERE telefono = '+56966666666'), (SELECT id FROM barberos WHERE nombre = 'Miguel'), now() - interval '19 days', 'Corte + Barba', 15000),
  ((SELECT id FROM clientes WHERE telefono = '+56966666666'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '26 days', 'Corte Premium', 18000),
  ((SELECT id FROM clientes WHERE telefono = '+56966666666'), (SELECT id FROM barberos WHERE nombre = 'Javier'), now() - interval '33 days', 'Corte', 10000),
  ((SELECT id FROM clientes WHERE telefono = '+56966666666'), (SELECT id FROM barberos WHERE nombre = 'Miguel'), now() - interval '41 days', 'Corte + Barba', 15000),
  
  -- Felipe Castro (2 visitas, nuevo)
  ((SELECT id FROM clientes WHERE telefono = '+56977777777'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '3 days', 'Corte', 10000),
  ((SELECT id FROM clientes WHERE telefono = '+56977777777'), (SELECT id FROM barberos WHERE nombre = 'Miguel'), now() - interval '12 days', 'Corte + Barba', 15000),
  
  -- Nicolas Vera (15 visitas, VIP)
  ((SELECT id FROM clientes WHERE telefono = '+56988888888'), (SELECT id FROM barberos WHERE nombre = 'Javier'), now() - interval '2 days', 'Corte Premium', 18000),
  ((SELECT id FROM clientes WHERE telefono = '+56988888888'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '6 days', 'Corte + Barba', 15000),
  ((SELECT id FROM clientes WHERE telefono = '+56988888888'), (SELECT id FROM barberos WHERE nombre = 'Miguel'), now() - interval '9 days', 'Corte', 10000),
  ((SELECT id FROM clientes WHERE telefono = '+56988888888'), (SELECT id FROM barberos WHERE nombre = 'Javier'), now() - interval '13 days', 'Corte + Barba', 15000),
  ((SELECT id FROM clientes WHERE telefono = '+56988888888'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), now() - interval '16 days', 'Corte Premium', 18000);

-- 7. Recompensas
INSERT INTO recompensas (barberia_id, nombre, puntos_requeridos, tipo, valor, stock_limitado, stock_actual) VALUES
  ('TU_BARBERIA_UUID', 'Corte Gratis', 100, 'servicio', 'Corte', false, null),
  ('TU_BARBERIA_UUID', 'Barba Gratis', 80, 'servicio', 'Barba', false, null),
  ('TU_BARBERIA_UUID', '20% Descuento', 150, 'descuento', '20%', false, null),
  ('TU_BARBERIA_UUID', 'Corte + Barba Gratis', 200, 'servicio', 'Corte + Barba', false, null),
  ('TU_BARBERIA_UUID', 'Gorra Exclusiva', 300, 'producto', 'Gorra Barberia', true, 10);

-- 8. Reservas (proximos 7 dias)
INSERT INTO reservas (cliente_id, barbero_id, fecha, hora, servicio, estado) VALUES
  ((SELECT id FROM clientes WHERE telefono = '+56911111111'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), CURRENT_DATE + 1, '10:00', 'Corte + Barba', 'pendiente'),
  ((SELECT id FROM clientes WHERE telefono = '+56922222222'), (SELECT id FROM barberos WHERE nombre = 'Javier'), CURRENT_DATE + 1, '11:30', 'Corte Premium', 'pendiente'),
  ((SELECT id FROM clientes WHERE telefono = '+56933333333'), (SELECT id FROM barberos WHERE nombre = 'Miguel'), CURRENT_DATE + 2, '14:00', 'Corte', 'pendiente'),
  ((SELECT id FROM clientes WHERE telefono = '+56966666666'), (SELECT id FROM barberos WHERE nombre = 'Carlos'), CURRENT_DATE + 2, '16:00', 'Corte + Barba', 'pendiente'),
  ((SELECT id FROM clientes WHERE telefono = '+56988888888'), (SELECT id FROM barberos WHERE nombre = 'Javier'), CURRENT_DATE + 3, '10:00', 'Corte Premium', 'pendiente');
