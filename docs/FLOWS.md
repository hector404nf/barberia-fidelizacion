# 🔁 Flujos de Usuario

> Cómo los usuarios interactúan con el sistema, paso a paso.

---

## Flujo 1: Primer Uso (Onboarding)

**Actor:** Dueño de barbería

```
1. Abre la app (URL en Vercel)
2. Ve pantalla de Login
3. Toca "Crear cuenta"
4. RegistroScreen:
   a. Ingresa nombre, email, contraseña
   b. Ingresa nombre del negocio, teléfono, dirección
   c. Toca "Crear cuenta"
5. Backend crea:
   - auth.users
   - barberias (con config_puntos default)
   - profiles (rol = 'dueño')
6. Redirige al Dashboard
7. Tutorial opcional: "Agrega tu primer cliente"
```

---

## Flujo 2: Cliente Nuevo en la Barbería

**Actor:** Barbero o Dueño

```
1. Cliente llega a la barbería
2. Barbero abre app → Clientes → Busca por teléfono
3. Si NO existe:
   a. Toca "+ Nuevo Cliente"
   b. Ingresa nombre, teléfono
   c. (Opcional) fecha nacimiento, barbero favorito
   d. Guarda
   e. Cliente creado con 0 puntos
4. Barbero registra visita:
   a. Desde perfil del cliente: "Nueva Visita"
   b. Selecciona servicio y monto
   c. Sistema calcula puntos a otorgar
   d. Confirma
   e. Visita guardada + puntos acreditados automáticamente
```

---

## Flujo 3: Fidelización (Acumulación de Puntos)

**Actor:** Cliente (indirecto) / Sistema

```
Cliente visita → Visita registrada → Trigger SQL:
  ├─ Inserta visita
  ├─ Calcula puntos (config.por_visita + monto * config.por_monto)
  ├─ Actualiza puntos_cliente (INSERT o UPDATE)
  ├─ Inserta movimiento_puntos ('ganado')
  └─ Actualiza cliente (ultima_visita, total_visitas, frecuencia)

Frontend (perfil del cliente):
  └─ Muestra saldo actualizado (Realtime o refresh)
```

---

## Flujo 4: Canje de Recompensa

**Actor:** Barbero/Dueño (físicamente con el cliente)

```
1. Cliente dice: "Quiero canjear mis puntos"
2. Barbero abre perfil del cliente
3. Ve sección "Recompensas Disponibles"
4. Sistema filtra recompensas donde puntos_requeridos <= saldo actual
5. Barbero selecciona recompensa (ej: "Corte Gratis")
6. Dialog de confirmación:
   - "Canjear 'Corte Gratis' por 100 puntos?"
   - Saldo actual: 150 → Saldo después: 50
7. Confirma → Llamada RPC 'canjear_recompensa'
8. SQL valida saldo, resta puntos, registra movimiento
9. Éxito: muestra mensaje + actualiza saldo en pantalla
10. Barbero atiende el servicio gratis
```

**Errores posibles:**
- Saldo insuficiente (mensaje amigable)
- Recompensa ya no está activa

---

## Flujo 5: Agenda / Reservas

**Actor:** Dueño/Barbero

```
1. Cliente pide turno (por teléfono o presencial)
2. Barbero abre Agenda → Nueva Reserva
3. Busca cliente (o crea nuevo)
4. Selecciona:
   - Barbero
   - Fecha
   - Hora (sistema valida que no esté ocupado)
   - Servicio
5. Guarda
6. Reserva aparece en calendario
7. *(Futuro)* Sistema envía recordatorio por WhatsApp 24h antes
```

**Conflictos de horario:**
```
Al guardar, SQL valida:
  NOT EXISTS (
    SELECT 1 FROM reservas
    WHERE barbero_id = NEW.barbero_id
      AND fecha = NEW.fecha
      AND hora BETWEEN NEW.hora - interval '30 min' AND NEW.hora + interval '30 min'
      AND estado = 'pendiente'
  )
```

---

## Flujo 6: Reactivación de Cliente Inactivo

**Actor:** Sistema (automatizado)

```
Cron (futuro Edge Function o pg_cron):
  Diariamente:
    1. Busca clientes donde ultima_visita < hoy - 30 días
    2. Marca estado = 'inactivo'
    3. *(Futuro)* Envía mensaje WhatsApp:
       "Te extrañamos en [Barbería] 😎. Agenda tu próximo corte aquí: [link]"
    4. Si el cliente vuelve → estado vuelve a 'activo' automáticamente
```

*Nota: Sin WhatsApp, este flujo solo marca inactivos en el dashboard para que el dueño pueda contactarlos manualmente.*

---

## Flujo 7: Dashboard de Análisis

**Actor:** Dueño

```
1. Abre Dashboard
2. Ve KPIs del mes actual (default)
3. Puede cambiar período:
   - Hoy
   - Esta semana
   - Este mes
   - Personalizado
4. Explora gráficos:
   - Toca "Visitas por día" → ve tendencia
   - Toca "Top barberos" → ve ranking
5. Detecta insights:
   - "12 clientes inactivos este mes"
   - Toca → va a lista de inactivos
   - Puede exportar (futuro) o contactar manualmente
```

---

## Flujo 8: Gestión de Barberos

**Actor:** Dueño

```
1. Va a Configuración → Barberos
2. Ve lista del equipo
3. Puede:
   a. Agregar nuevo barbero (nombre, especialidad, foto)
   b. Editar existente
   c. Desactivar (no eliminar, para preservar historial)
4. Barbero desactivado ya no aparece en dropdowns de nueva visita/reserva
5. Historial de visitas se conserva
```

---

## 📊 Estados del Cliente

```
[NUEVO] ──3 visitas──► [ACTIVO]
   │                      │
   │                      │ sin visita 30 días
   │                      ▼
   │                   [INACTIVO]
   │                      │
   │                      │ vuelve a visitar
   │                      ▼
   │                   [ACTIVO]
   │
   └── alta frecuencia + ticket alto ──► [VIP]
```

**Reglas de negocio:**
- `NUEVO`: total_visitas <= 2
- `ACTIVO`: ultima_visita >= hoy - 30 días
- `INACTIVO`: ultima_visita < hoy - 30 días
- `VIP`: total_visitas > 8/mes Y ticket promedio > $X (configurable)

---

## 🔔 Eventos del Sistema (para futuras notificaciones)

| Evento | Trigger | Acción Futura (WhatsApp) |
|--------|---------|-------------------------|
| `nueva_reserva` | INSERT en reservas | Recordatorio 24h antes |
| `visita_realizada` | INSERT en visitas | "Gracias por venir, acumulaste X puntos" |
| `recompensa_canjeada` | INSERT en movimientos_puntos tipo 'canjeado' | "Canjeaste X, te quedan Y puntos" |
| `cliente_inactivo` | Cron diario | "Te extrañamos, vuelve!" |
| `cumpleaños` | Cron diario | "Feliz cumple! Tienes un descuento especial" |
| `puntos_meta` | Trigger puntos >= recompensa | "Ya puedes canjear X!" |
