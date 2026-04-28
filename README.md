# 💈 Barbería Fidelización

Sistema web de fidelización para barberías. Gestiona clientes, visitas, puntos, recompensas y reservas.

## 🚀 Stack

- **Frontend:** Flutter Web
- **Backend:** Supabase (PostgreSQL + Auth + Realtime)
- **Hosting:** Vercel

## 🌐 URLs

- **App:** https://barberia-fidelizacion.vercel.app
- **Supabase:** https://gzrncvukxfaejcozffut.supabase.co

## 🛠️ Desarrollo local

### Requisitos
- Flutter SDK >= 3.22.0
- Cuenta en Supabase (ya configurada)

### Pasos

1. Clonar el repo
```bash
git clone https://github.com/TU_USUARIO/barberia-fidelizacion.git
cd barberia-fidelizacion
```

2. Instalar dependencias
```bash
flutter pub get
```

3. Correr en modo web
```bash
flutter run -d chrome --web-port 8080
```

## 📦 Deploy manual

Si no usas GitHub Actions:

```bash
# Windows
deploy.bat

# Linux/Mac
./deploy.sh
```

O manualmente:
```bash
flutter build web --release
vercel --prod --scope hector404nfs-projects
```

## ⚙️ Configuración de CI/CD (GitHub Actions)

1. Ve a tu repo en GitHub → Settings → Secrets and variables → Actions
2. Agrega un nuevo **Repository secret**:
   - Name: `VERCEL_TOKEN`
   - Value: *(tu token de Vercel)*
3. Cada push a `main` deployará automáticamente

## 📚 Documentación

- [Arquitectura](docs/ARCHITECTURE.md)
- [Modelo de Datos](docs/DATA_MODEL.md)
- [API](docs/API.md)
- [Módulos](docs/MODULES.md)
- [Flujos](docs/FLOWS.md)
- [Guía de Desarrollo](docs/DEV_GUIDE.md)

## 🔐 Seguridad

- Las credenciales de Supabase están embebidas solo para desarrollo
- Para producción, usa variables de entorno
- Nunca commitees tokens ni claves privadas

## 📝 Licencia

MIT
