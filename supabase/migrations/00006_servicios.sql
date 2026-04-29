-- ============================================
-- MIGRACION: Servicios con precios
-- ============================================

CREATE TABLE servicios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  barberia_id uuid NOT NULL REFERENCES barberias(id) ON DELETE CASCADE,
  nombre text NOT NULL,
  descripcion text,
  precio decimal(10,2) NOT NULL,
  duracion_minutos int NOT NULL DEFAULT 30,
  activo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_servicios_barberia ON servicios(barberia_id);

-- RLS
ALTER TABLE servicios ENABLE ROW LEVEL SECURITY;

CREATE POLICY "servicios_select" ON servicios
  FOR SELECT USING (
    barberia_id IN (SELECT barberia_id FROM profiles WHERE id = auth.uid())
    OR barberia_id IN (SELECT barberia_id FROM clientes WHERE auth_user_id = auth.uid())
  );

CREATE POLICY "servicios_insert" ON servicios
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND rol = 'dueño' AND barberia_id = servicios.barberia_id)
  );

CREATE POLICY "servicios_update" ON servicios
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND rol = 'dueño' AND barberia_id = servicios.barberia_id)
  );
