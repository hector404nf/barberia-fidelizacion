import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

class ScaffoldWithNav extends ConsumerWidget {
  final Widget child;
  const ScaffoldWithNav({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final esDueno = ref.watch(esDuenoProvider);

    int currentIndex = 0;
    if (location.startsWith('/dashboard')) currentIndex = 0;
    else if (location.startsWith('/clientes')) currentIndex = 1;
    else if (location.startsWith('/agenda')) currentIndex = 2;
    else if (_isExtraRoute(location)) currentIndex = 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == 3) {
            _showMoreMenu(context, ref, esDueno);
            return;
          }
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/clientes');
              break;
            case 2:
              context.go('/agenda');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Más',
          ),
        ],
      ),
    );
  }

  bool _isExtraRoute(String location) {
    return location.startsWith('/servicios') ||
        location.startsWith('/recompensas') ||
        location.startsWith('/barberos') ||
        location.startsWith('/config') ||
        location.startsWith('/visitas');
  }

  void _showMoreMenu(BuildContext context, WidgetRef ref, bool esDueno) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Más opciones',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _MenuItem(
                icon: Icons.spa_outlined,
                label: 'Servicios',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/servicios');
                },
              ),
              _MenuItem(
                icon: Icons.emoji_events_outlined,
                label: 'Recompensas',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/recompensas');
                },
              ),
              _MenuItem(
                icon: Icons.people_outline,
                label: 'Barberos',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/barberos');
                },
              ),
              _MenuItem(
                icon: Icons.history,
                label: 'Historial de Visitas',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/visitas');
                },
              ),
              _MenuItem(
                icon: Icons.settings_outlined,
                label: 'Configuración',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/config');
                },
              ),
              const Divider(height: 32),
              _MenuItem(
                icon: Icons.logout,
                label: 'Cerrar sesión',
                iconColor: Colors.red.shade400,
                textColor: Colors.red.shade400,
                onTap: () async {
                  Navigator.pop(context);
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) context.go('/');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.amber.shade700).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? Colors.amber.shade700),
      ),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, color: textColor ?? Colors.black87),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
