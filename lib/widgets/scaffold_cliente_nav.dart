import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
      body: child,
      bottomNavigationBar: NavigationBar(
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
            icon: Icon(PhosphorIconsRegular.house),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.scissors),
            label: 'Mis Visitas',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.calendarPlus),
            label: 'Reservar',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.trophy),
            label: 'Recompensas',
          ),
        ],
      ),
    );
  }
}
