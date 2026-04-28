# Barbería Fidelización - Deploy a Vercel

## Opción 1: Deploy automático desde GitHub (RECOMENDADA)

### Paso 1: Crear repo en GitHub
```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/barberia-fidelizacion.git
git push -u origin main
```

### Paso 2: Conectar Vercel
1. Ve a [vercel.com](https://vercel.com) → Add New Project
2. Importa tu repo de GitHub
3. En **Build & Output Settings**:
   - Framework Preset: `Other`
   - Build Command: `flutter build web --release`
   - Output Directory: `build/web`
4. Agrega las **Environment Variables**:
   - `SUPABASE_URL` = *(tu URL de Supabase)*
   - `SUPABASE_ANON_KEY` = *(tu Anon Key de Supabase)*
5. Deploy

## Opción 2: Deploy manual con CLI

```bash
# Instalar Vercel CLI
npm i -g vercel

# Login
vercel login

# Deploy
vercel --prod
```

## Opción 3: CI/CD con GitHub Actions (ya configurado en .github/workflows/)

Cada push a `main` deploya automáticamente.

Necesitas agregar estos **Secrets** en GitHub:
- `VERCEL_TOKEN` - Desde [vercel.com/account/tokens](https://vercel.com/account/tokens)
- `VERCEL_ORG_ID` - Desde `vercel team list` o tu dashboard
- `VERCEL_PROJECT_ID` - Desde Project Settings en Vercel
