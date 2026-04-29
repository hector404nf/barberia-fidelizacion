import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
      body: child,
      bottomNavigationBar: NavigationBar(
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
            icon: Icon(PhosphorIconsRegular.chartBar),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(PhosphorIconsRegular.users),
            label: 'Clientes',
          ),
          const NavigationDestination(
            icon: Icon(PhosphorIconsRegular.scissors),
            label: 'Servicios',
          ),
          const NavigationDestination(
            icon: Icon(PhosphorIconsRegular.calendarBlank),
            label: 'Agenda',
          ),
          const NavigationDestination(
            icon: Icon(PhosphorIconsRegular.trophy),
            label: 'Recompensas',
          ),
          NavigationDestination(
            icon: const Icon(PhosphorIconsRegular.gear),
            label: esDueno ? 'Config' : 'Perfil',
          ),
        ],
      ),
    );
  }
}
