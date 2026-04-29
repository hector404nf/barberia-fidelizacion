import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'modules/auth/screens/login_screen.dart';
import 'modules/auth/screens/registro_screen.dart';
import 'modules/auth/screens/cliente_login_screen.dart';
import 'modules/auth/screens/cliente_registro_screen.dart';
import 'modules/dashboard/screens/dashboard_screen.dart';
import 'modules/clientes/screens/clientes_list_screen.dart';
import 'modules/clientes/screens/cliente_form_screen.dart';
import 'modules/clientes/screens/cliente_detail_screen.dart';
import 'modules/visitas/screens/nueva_visita_screen.dart';
import 'modules/visitas/screens/visitas_list_screen.dart';
import 'modules/reservas/screens/calendario_screen.dart';
import 'modules/reservas/screens/nueva_reserva_screen.dart';
import 'modules/puntos/screens/recompensas_screen.dart';
import 'modules/puntos/screens/recompensa_form_screen.dart';
import 'modules/config/screens/config_screen.dart';
import 'modules/puntos/screens/recompensa_form_screen.dart';
import 'modules/visitas/screens/visitas_list_screen.dart';
import 'modules/barberos/screens/barberos_list_screen.dart';
import 'modules/barberos/screens/barbero_form_screen.dart';
import 'modules/servicios/screens/servicios_list_screen.dart';
import 'modules/servicios/screens/servicio_form_screen.dart';
import 'modules/cliente_portal/screens/cliente_portal_screen.dart';
import 'modules/cliente_portal/screens/cliente_visitas_screen.dart';
import 'modules/cliente_portal/screens/cliente_reservar_screen.dart';
import 'modules/cliente_portal/screens/cliente_recompensas_screen.dart';
import 'widgets/scaffold_with_nav.dart';
import 'widgets/scaffold_cliente_nav.dart';

final _router = GoRouter(
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    // Lee directamente la URL del navegador (funciona en web)
    final currentPath = Uri.base.path;

    // Rutas públicas: cliente (/b/:slug) y auth general
    if (currentPath.startsWith('/b/') ||
        currentPath == '/' ||
        currentPath == '/registro') {
      return null;
    }

    if (session == null) return '/';

    if (session != null && (currentPath == '/' || currentPath == '/registro')) {
      return '/dashboard';
    }

    return null;
  },
  routes: [
    // === AUTH GENERAL ===
    GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/registro', builder: (context, state) => const RegistroScreen()),

    // === CLIENTE PÚBLICO CON SLUG ===
    GoRoute(
      path: '/b/:slug',
      builder: (context, state) => ClienteLoginScreen(
        slug: state.pathParameters['slug']!,
      ),
    ),
    GoRoute(
      path: '/b/:slug/registro',
      builder: (context, state) => ClienteRegistroScreen(
        slug: state.pathParameters['slug']!,
      ),
    ),

    // === STAFF SHELL ===
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNav(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
        GoRoute(path: '/clientes', builder: (context, state) => const ClientesListScreen()),
        GoRoute(path: '/clientes/nuevo', builder: (context, state) => const ClienteFormScreen()),
        GoRoute(path: '/clientes/:id', builder: (context, state) => ClienteDetailScreen(clienteId: state.pathParameters['id']!)),
        GoRoute(path: '/clientes/:id/editar', builder: (context, state) => ClienteFormScreen(clienteId: state.pathParameters['id'])),
        GoRoute(
          path: '/visitas/nueva',
          builder: (context, state) => NuevaVisitaScreen(
            clienteId: state.uri.queryParameters['clienteId'],
          ),
        ),
        GoRoute(path: '/agenda', builder: (context, state) => const CalendarioScreen()),
        GoRoute(path: '/agenda/nueva', builder: (context, state) => const NuevaReservaScreen()),
        GoRoute(path: '/recompensas', builder: (context, state) => const RecompensasScreen()),
        GoRoute(path: '/recompensas/nueva', builder: (context, state) => const RecompensaFormScreen()),
        GoRoute(path: '/recompensas/:id/editar', builder: (context, state) => RecompensaFormScreen(recompensaId: state.pathParameters['id'])),
        GoRoute(path: '/visitas', builder: (context, state) => const VisitasListScreen()),
        GoRoute(path: '/barberos', builder: (context, state) => const BarberosListScreen()),
        GoRoute(path: '/barberos/nuevo', builder: (context, state) => const BarberoFormScreen()),
        GoRoute(path: '/barberos/:id/editar', builder: (context, state) => BarberoFormScreen(barberoId: state.pathParameters['id'])),
        GoRoute(path: '/servicios', builder: (context, state) => const ServiciosListScreen()),
        GoRoute(path: '/servicios/nuevo', builder: (context, state) => const ServicioFormScreen()),
        GoRoute(path: '/servicios/:id/editar', builder: (context, state) => ServicioFormScreen(servicioId: state.pathParameters['id'])),
        GoRoute(path: '/config', builder: (context, state) => const ConfigScreen()),
      ],
    ),

    // === CLIENTE SHELL ===
    ShellRoute(
      builder: (context, state, child) => ScaffoldClienteNav(child: child),
      routes: [
        GoRoute(path: '/cliente', builder: (context, state) => const ClientePortalScreen()),
        GoRoute(path: '/cliente/visitas', builder: (context, state) => const ClienteVisitasScreen()),
        GoRoute(path: '/cliente/reservar', builder: (context, state) => const ClienteReservarScreen()),
        GoRoute(path: '/cliente/recompensas', builder: (context, state) => const ClienteRecompensasScreen()),
      ],
    ),
  ],
);

class BarberiaApp extends ConsumerWidget {
  const BarberiaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateProvider, (previous, next) {
      _router.refresh();
    });

    return MaterialApp.router(
      title: 'Barberia Fidelizacion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
