# 🧩 Módulos del Sistema

> Descripción detallada de cada módulo, sus pantallas y funcionalidades.

---

## 1. Autenticación (`modules/auth/`)

**Responsabilidad:** Login, registro, recuperación de sesión.

### Pantallas:
1. **LoginScreen**
   - Email + contraseña (o magic link)
   - Logo de la app
   - "¿Olvidaste tu contraseña?"

2. **RegistroScreen**
   - Datos del dueño: nombre, email
   - Datos de la barbería: nombre, teléfono, dirección
   - Un solo paso: crea auth user + barbería + profile

3. **Splash / AuthGuard**
   - Verifica sesión activa
   - Redirige a login o dashboard

### Servicios:
- `AuthService` - wrapper de Supabase Auth
- `ProfileService` - obtiene rol y barbería del usuario

---

## 2. Dashboard (`modules/dashboard/`)

**Responsabilidad:** Vista general del negocio. Solo accesible para dueños.

### Pantalla: DashboardScreen

**KPIs mostrados (cards):**
- Clientes activos (visitas últimos 30 días)
- Clientes inactivos (sin visita >30 días)
- Total de visitas (hoy / esta semana / este mes)
- Ingresos totales (período seleccionado)
- Ticket promedio
- Recompensas canjeadas

**Gráficos:**
- Visitas por día (últimos 7 días)
- Ingresos por semana (últimas 4 semanas)
- Top barberos (visitas e ingresos)

**Acciones rápidas (FAB o botones):**
- [+] Nuevo cliente
- [+] Nueva visita
- [+] Nueva reserva

### Servicios:
- `DashboardService` - llama a RPC `get_estadisticas`

---

## 3. Clientes (`modules/clientes/`)

**Responsabilidad:** CRUD completo de clientes + historial.

### Pantallas:

1. **ClientesListScreen**
   - Search bar con búsqueda por nombre o teléfono (debounce 300ms)
   - Lista con: nombre, teléfono, última visita, puntos actuales
   - Badge de estado: Activo / Inactivo / VIP
   - Filter chips: Todos / Activos / Inactivos / VIP / Nuevos

2. **ClienteDetailScreen**
   - Header: foto (opcional), nombre, teléfono, puntos actuales (destacado)
   - Info: fecha nacimiento, barbero favorito, frecuencia de visitas
   - Tabs:
     - **Historial:** Lista de visitas (fecha, servicio, monto, puntos)
     - **Puntos:** Saldo + historial de movimientos
     - **Reservas:** Próximos turnos
   - FAB: "Nueva Visita" / "Nueva Reserva"

3. **ClienteFormScreen** (crear/editar)
   - Nombre* (text)
   - Teléfono* (text con formato)
   - Fecha nacimiento (date picker)
   - Barbero favorito (dropdown)
   - Foto (opcional, upload)
   - *Al crear: mostrar mensaje de éxito con puntos iniciales (0)*

### Estados/Segmentación automática:
- **NUEVO:** 0-2 visitas
- **ACTIVO:** visitó en los últimos 30 días
- **VIP:** más de X visitas/mes (configurable) o ticket alto
- **INACTIVO:** más de 30 días sin visitar

### Servicios:
- `ClienteRepository` - CRUD + búsqueda
- `ClienteService` - lógica de negocio (segmentación)

---

## 4. Visitas (`modules/visitas/`)

**Responsabilidad:** Registrar servicios realizados.

### Pantallas:

1. **NuevaVisitaScreen**
   - **Paso 1:** Buscar cliente (por teléfono o nombre) o seleccionar de lista
   - **Paso 2:** Datos de la visita:
     - Barbero (dropdown, default: favorito del cliente)
     - Servicio* (text con sugerencias de servicios previos)
     - Monto* (number)
     - Notas (text multiline)
   - **Preview:** Puntos que se otorgarán (calculado en tiempo real)
   - **Confirmar:** Guarda visita + actualiza puntos automáticamente

2. **VisitasListScreen** (opcional, accesible desde dashboard)
   - Lista de visitas del día/semana
   - Filtro por barbero

### Lógica de puntos:
```
puntos = config.por_visita + floor(monto * config.por_monto)
```
Ej: config = {por_visita: 10, por_monto: 1}, monto = $35
→ puntos = 10 + 35 = 45 puntos

### Servicios:
- `VisitaRepository` - insert visitas
- Trigger SQL maneja puntos automáticamente

---

## 5. Puntos y Recompensas (`modules/puntos/`)

**Responsabilidad:** Catálogo de recompensas y canjes.

### Pantallas:

1. **RecompensasScreen** (catálogo)
   - Grid/list de recompensas disponibles
   - Card: nombre, puntos requeridos, tipo, stock si aplica
   - Toggle para activar/desactivar (dueño)
   - FAB: "Nueva Recompensa"

2. **RecompensaFormScreen**
   - Nombre*
   - Puntos requeridos*
   - Tipo* (servicio / descuento / producto)
   - Valor (ej: "Corte" o "20%")
   - Stock limitado (toggle) + cantidad

3. **CanjeDialog** (modal desde perfil de cliente)
   - Lista de recompensas que el cliente PUEDE canjear (filtradas por puntos)
   - Al seleccionar: confirmación + validación de saldo
   - Éxito: muestra mensaje + actualiza saldo en tiempo real

### Servicios:
- `RecompensaRepository`
- `PuntosService` - wrapper de `.rpc('canjear_recompensa')`

---

## 6. Reservas / Agenda (`modules/reservas/`)

**Responsabilidad:** Calendario de turnos.

### Pantallas:

1. **CalendarioScreen**
   - Vista tipo calendario semanal (o lista por día)
   - Selector de fecha (arriba)
   - Lista de reservas del día agrupadas por barbero
   - Estado visual: pendiente (azul), completada (verde), cancelada (rojo)

2. **NuevaReservaScreen**
   - Cliente (buscar/selector)
   - Barbero (dropdown)
   - Fecha (date picker)
   - Hora (time picker, intervalos de 30min)
   - Servicio (text)
   - Notas
   - Validación: no permitir solapamiento de horarios para mismo barbero

3. **ReservaDetailSheet** (bottom sheet al tocar)
   - Ver datos completos
   - Acciones: Completar / Cancelar / Reagendar / Eliminar

### Servicios:
- `ReservaRepository` - CRUD + validación de horarios
- Realtime subscription para actualizaciones en vivo

---

## 7. Barberos (`modules/barberos/`)

**Responsabilidad:** Gestión del equipo (opcional para MVP, pero preparado).

### Pantallas:

1. **BarberosListScreen**
   - Lista con foto, nombre, especialidad, estado (activo/inactivo)
   - Badge con número de clientes atendidos (este mes)

2. **BarberoFormScreen**
   - Nombre*, especialidad, foto
   - Toggle activo/inactivo

### Servicios:
- `BarberoRepository`

---

## 8. Configuración (`modules/config/`)

**Responsabilidad:** Ajustes del sistema.

### Pantalla: ConfigScreen

**Secciones:**
- **Puntos:** Editar config_puntos (por visita, por monto)
- **Recompensas:** Acceso al catálogo
- **Barberos:** Gestión de equipo
- **Perfil:** Datos del negocio (nombre, dirección, logo)
- **Cuenta:** Cambiar email, cerrar sesión

---

## 🗺️ Mapa de Navegación

```
LoginScreen (no auth)
    │
    ▼
DashboardScreen (dueño) / AgendaScreen (barbero)
    │
    ├── FAB → [NuevaVisitaScreen]
    │
    ├── BottomNav: Clientes
    │       └── ClientesListScreen → ClienteDetailScreen → [NuevaVisita / NuevaReserva]
    │
    ├── BottomNav: Agenda
    │       └── CalendarioScreen → NuevaReservaScreen
    │
    ├── BottomNav: Recompensas
    │       └── RecompensasScreen → RecompensaFormScreen
    │
    └── BottomNav: Config
            └── ConfigScreen → [sub-pantallas]
```

---

## 📱 Componentes Compartidos Reutilizables

- `AppSearchBar` - Búsqueda con debounce
- `EmptyState` - Ilustración + mensaje cuando no hay datos
- `LoadingOverlay` - Spinner centrado
- `PuntosBadge` - Badge circular con cantidad de puntos (colores según cantidad)
- `EstadoChip` - Chips de estado del cliente (Nuevo/Activo/VIP/Inactivo)
- `ClienteListTile` - Tile estándar para listas de clientes
- `DatePickerField` - Campo de fecha con picker integrado
- `TimePickerField` - Campo de hora con picker integrado
- `ConfirmDialog` - Diálogo de confirmación reutilizable
- `SuccessAnimation` - Check animado para operaciones exitosas
