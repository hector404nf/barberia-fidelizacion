# 📘 Guía de Desarrollo

> Convenciones, reglas y buenas prácticas para el equipo (o para ti mismo en 3 meses).

---

## 🚀 Setup Inicial

### 1. Crear proyecto Flutter
```bash
flutter create --platforms web barberia_fidelizacion
cd barberia_fidelizacion
```

### 2. Dependencias (`pubspec.yaml`)
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State management
  flutter_riverpod: ^2.5.0
  
  # Supabase
  supabase_flutter: ^2.5.0
  
  # UI Utilities
  intl: ^0.19.0
  google_fonts: ^6.2.0
  flutter_slidable: ^3.1.0
  shimmer: ^3.0.0
  
  # Forms y validación
  flutter_form_builder: ^9.2.0
  form_builder_validators: ^10.0.0
  
  # Fechas y calendario
  table_calendar: ^3.1.0
  
  # Gráficos
  fl_chart: ^0.68.0
  
  # Icons
  phosphor_flutter: ^2.1.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

### 3. Configurar Supabase
Crear archivo `.env` (NO commitear):
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
```

Inicializar en `main.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  
  runApp(const ProviderScope(child: MyApp()));
}
```

---

## 📁 Convenciones de Código

### Nombres
| Tipo | Convención | Ejemplo |
|------|-----------|---------|
| Archivos | snake_case | `cliente_repository.dart` |
| Clases | PascalCase | `ClienteRepository` |
| Variables/Funciones | camelCase | `obtenerClientes()` |
| Constantes | lowerCamelCase | `defaultPuntosPorVisita` |
| Providers | lowerCamelCase + Provider | `clientesProvider` |
| Widgets | PascalCase + Widget | `ClienteListTile` |

### Estructura de archivos por módulo
```
lib/modules/clientes/
├── clientes_module.dart          # Exportaciones
├── screens/
│   ├── clientes_list_screen.dart
│   ├── cliente_detail_screen.dart
│   └── cliente_form_screen.dart
├── widgets/
│   ├── cliente_list_tile.dart
│   └── cliente_search_bar.dart
├── models/
│   └── cliente_models.dart       # Si son específicas del módulo
├── providers/
│   └── clientes_provider.dart
└── repositories/
    └── cliente_repository.dart
```

### Modelos: Freezed (opcional pero recomendado)
```dart
@freezed
class Cliente with _$Cliente {
  const factory Cliente({
    required String id,
    required String nombre,
    required String telefono,
    String? fechaNacimiento,
    String? barberoFavoritoId,
    @Default('activo') String estado,
    @Default(0) int totalVisitas,
    @Default(0) int puntosActuales,
    DateTime? createdAt,
  }) = _Cliente;

  factory Cliente.fromJson(Map<String, dynamic> json) =>
      _$ClienteFromJson(json);
}
```

*Si no usas Freezed, usar `copyWith` manual y `equatable`.*

---

## 🎨 UI/UX Guidelines

### Tema de la app
```dart
// core/theme/app_theme.dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2C3E50), // Azul barbería
        secondary: const Color(0xFFD4AF37), // Dorado premium
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
```

### Colores por estado de cliente
```dart
Color getColorForEstado(String estado) {
  return switch (estado) {
    'nuevo' => Colors.blue,
    'activo' => Colors.green,
    'vip' => Colors.amber,
    'inactivo' => Colors.grey,
    _ => Colors.grey,
  };
}
```

### Layout responsive
- Usar `LayoutBuilder` para adaptar a móvil/tablet/desktop
- En desktop: sidebar + contenido
- En móvil: bottom nav

---

## 🧪 Testing

### Estructura
```
test/
├── unit/
│   ├── models/
│   └── repositories/
├── widget/
│   └── screens/
└── integration/
    └── auth_flow_test.dart
```

### Ejemplo de test de repository
```dart
group('ClienteRepository', () {
  late SupabaseClient mockClient;
  late ClienteRepository repo;

  setUp(() {
    mockClient = MockSupabaseClient();
    repo = ClienteRepository(mockClient);
  });

  test('crearCliente retorna Cliente con id', () async {
    // arrange
    final nuevo = Cliente(nombre: 'Juan', telefono: '123456');
    
    // act
    final result = await repo.create(nuevo);
    
    // assert
    expect(result.id, isNotEmpty);
    expect(result.nombre, 'Juan');
  });
});
```

---

## 🔄 Git Workflow

### Branches
- `main` - Producción (deploy automático en Vercel)
- `develop` - Integración
- `feature/modulo-nombre` - Features
- `fix/descripcion` - Fixes

### Commits
Formato: `tipo(modulo): descripción`

```
feat(clientes): agregar búsqueda por teléfono
fix(puntos): corregir cálculo de puntos por monto
docs(api): actualizar endpoints de reservas
refactor(dashboard): simplificar provider de estadísticas
```

---

## 🚀 Deploy a Vercel

### 1. Build web
```bash
flutter build web --release
```

### 2. Configurar `vercel.json`
```json
{
  "version": 2,
  "name": "barberia-fidelizacion",
  "builds": [
    {
      "src": "build/web/**/*",
      "use": "@vercel/static"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ]
}
```

### 3. GitHub Actions (opcional)
```yaml
# .github/workflows/deploy.yml
name: Deploy to Vercel
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter build web --release
      - uses: vercel/action-deploy@v1
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
```

---

## ⚠️ Checklist antes de commitear

- [ ] Código compila sin errores
- [ ] No hay `print()` de debug (usar `debugPrint` si es necesario)
- [ ] Variables de entorno no están hardcodeadas
- [ ] RLS está habilitado en nuevas tablas
- [ ] Migraciones de Supabase están en `supabase/migrations/`
- [ ] El texto está en español (la app es para Latinoamérica)
- [ ] Funciona en modo web (probar con `flutter run -d chrome`)

---

## 🆘 Troubleshooting Común

### Supabase RLS bloquea queries
- Verificar que el usuario esté autenticado
- Verificar políticas RLS en la tabla
- Usar `service_role` key solo en Edge Functions, NUNCA en frontend

### Fechas timezone
- Supabase guarda en UTC
- Frontend debe convertir a local: `fecha.toLocal()`
- En queries, usar `timestamptz`

### Flutter Web y CORS
- Configurar CORS en Supabase: `Authentication → URL Configuration`
- Agregar dominio de Vercel a allowed origins

### Pérdida de sesión al refrescar (web)
- `Supabase.initialize` con `localStorage` como default ya persiste
- Verificar que `onAuthStateChange` maneje el estado inicial
