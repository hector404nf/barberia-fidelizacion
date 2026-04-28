# 💈 Barbería Fidelización - Documento de Proyecto

> **Versión:** 1.0.0  
> **Última actualización:** 2026-04-28  
> **Estado:** MVP en desarrollo

---

## 📌 Propósito

Sistema web de fidelización para barberías que permite:
- Gestionar clientes y su historial de visitas
- Automatizar un sistema de puntos y recompensas
- Gestionar reservas/turnos
- Visualizar métricas clave (KPIs) en un dashboard
- *(Futuro)* Enviar notificaciones automáticas por WhatsApp

**Propuesta de valor:** "Sistema que llena tu agenda automáticamente"

---

## 🏗️ Stack Tecnológico

| Capa | Tecnología | Uso |
|------|-----------|-----|
| **Frontend** | Flutter Web | UI multiplataforma (web primero, mobile después) |
| **Hosting Web** | Vercel | CDN + Deploy automático desde Git |
| **Backend** | Supabase | BaaS completo (DB, Auth, Storage, Realtime, Edge Functions) |
| **Base de Datos** | PostgreSQL (vía Supabase) | Datos relaciones con RLS |
| **Auth** | Supabase Auth | Magic links + Roles (dueño/barbero) |
| **Storage** | Supabase Storage | Fotos de perfil, logos |
| **Realtime** | Supabase Realtime | Actualizaciones en vivo de reservas |
| **WhatsApp** | *(Futuro)* Microservicio Node.js | whatsapp-web.js o Baileys en VPS/Fly.io |

---

## 📁 Estructura del Repositorio

```
barberia-fidelizacion/
├── AGENTS.md                 # Este archivo
├── README.md                 # Documentación pública
├── docs/                     # Documentación técnica detallada
│   ├── ARCHITECTURE.md       # Arquitectura y decisiones técnicas
│   ├── DATA_MODEL.md         # Esquema de base de datos
│   ├── API.md                # Endpoints y funciones
│   ├── MODULES.md            # Módulos y funcionalidades
│   ├── FLOWS.md              # Flujos de usuario
│   └── DEV_GUIDE.md          # Guía de desarrollo y convenciones
├── supabase/                 # Configuración de Supabase
│   ├── migrations/           # SQL migrations
│   ├── seed.sql              # Datos de prueba
│   └── functions/            # Edge Functions
├── lib/                      # Código Flutter
│   ├── main.dart
│   ├── app.dart
│   ├── core/                 # Utilidades, temas, constantes
│   ├── models/               # Modelos de datos
│   ├── services/             # Supabase service layer
│   ├── repositories/         # Acceso a datos
│   ├── blocs/                # State management (Bloc/Riverpod)
│   ├── modules/              # Módulos de la app
│   │   ├── auth/
│   │   ├── clientes/
│   │   ├── visitas/
│   │   ├── puntos/
│   │   ├── reservas/
│   │   └── dashboard/
│   └── widgets/              # Componentes compartidos
├── test/                     # Tests
└── vercel.json               # Config de deploy
```

---

## 🎯 Alcance del MVP (Fase 1)

### Incluye:
1. ✅ Autenticación (dueño/barbero)
2. ✅ Gestión de clientes (CRUD + búsqueda por teléfono)
3. ✅ Registro de visitas
4. ✅ Sistema de puntos automático
5. ✅ Catálogo de recompensas + canje
6. ✅ Agenda de reservas básica
7. ✅ Dashboard con KPIs simples

### NO incluye (Fase 2+):
- ❌ Integración WhatsApp
- ❌ Segmentación avanzada de clientes
- ❌ Ranking de barberos
- ❌ Suscripciones mensuales
- ❌ Precios dinámicos

---

## 🔐 Roles de Usuario

| Rol | Permisos |
|-----|----------|
| **Dueño** | Todo. Gestiona barberos, ve todos los KPIs, configura puntos |
| **Barbero** | Ver clientes, registrar visitas, crear reservas. No puede eliminar clientes ni ver finanzas totales |

---

## 🚀 Despliegue

- **Frontend:** `git push` → Vercel auto-deploy
- **Backend:** Supabase Cloud (proyecto gratuito)
- **DB Migrations:** Supabase CLI

---

## 📚 Documentación Relacionada

- [Arquitectura](docs/ARCHITECTURE.md)
- [Modelo de Datos](docs/DATA_MODEL.md)
- [API y Funciones](docs/API.md)
- [Módulos](docs/MODULES.md)
- [Flujos de Usuario](docs/FLOWS.md)
- [Guía de Desarrollo](docs/DEV_GUIDE.md)

---

## 📝 Notas de Decisión

### ¿Por qué Flutter Web?
- Una sola codebase para web y futura app mobile
- Buen rendimiento para dashboards y tablas
- Integración nativa con Supabase via `supabase_flutter`

### ¿Por qué Supabase?
- PostgreSQL real con RLS (seguridad a nivel de fila)
- Auth incluido con magic links
- Realtime para reservas
- Edge Functions serverless
- Free tier generoso

### ¿Por qué no WhatsApp ahora?
- Requiere infraestructura adicional (VPS/microservicio)
- Complejidad de configuración de número de negocio o manejo de bans
- El core de fidelización funciona sin él
- Se integra vía API REST más adelante sin tocar el frontend
