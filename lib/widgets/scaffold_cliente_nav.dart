import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ScaffoldClienteNav extends ConsumerWidget {
  final Widget child;
  const ScaffoldClienteNav({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location == '/cliente') currentIndex = 0;
    else if (location == '/cliente/visitas') currentIndex = 1;
    else if (location == '/cliente/reservar') currentIndex = 2;
    else if (location == '/cliente/recompensas') currentIndex = 3;

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
              context.go('/cliente');
              break;
            case 1:
              context.go('/cliente/visitas');
              break;
            case 2:
              context.go('/cliente/reservar');
              break;
            case 3:
              context.go('/cliente/recompensas');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.cut_outlined),
            selectedIcon: Icon(Icons.cut),
            label: 'Mis Visitas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Reservar',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Recompensas',
          ),
        ],
      ),
    );
  }
}
