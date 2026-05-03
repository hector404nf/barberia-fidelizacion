import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    else if (location.startsWith('/servicios')) currentIndex = 2;
    else if (location.startsWith('/agenda')) currentIndex = 3;
    else if (location.startsWith('/recompensas')) currentIndex = 4;
    else if (location.startsWith('/config')) currentIndex = 5;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/clientes');
              break;
            case 2:
              context.go('/servicios');
              break;
            case 3:
              context.go('/agenda');
              break;
            case 4:
              context.go('/recompensas');
              break;
            case 5:
              context.go('/config');
              break;
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.cut_outlined),
            selectedIcon: Icon(Icons.cut),
            label: 'Servicios',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Recompensas',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: esDueno ? 'Config' : 'Perfil',
          ),
        ],
      ),
    );
  }
}
