import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/visitas_provider.dart';
import '../../../providers/reservas_provider.dart';

class ClientePortalScreen extends ConsumerWidget {
  const ClientePortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clienteAsync = ref.watch(clienteAuthProvider);
    final puntosAsync = ref.watch(clientePuntosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Cuenta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: clienteAsync.when(
        data: (cliente) {
          if (cliente == null) {
            return const Center(child: Text('No se encontró tu perfil de cliente'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarjeta de bienvenida + puntos
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            cliente.nombre.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 28, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hola, ${cliente.nombre}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        puntosAsync.when(
                          data: (puntos) => _PuntosBadge(puntos: puntos),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Text('Error al cargar puntos'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Estado del cliente
                _InfoCard(
                  title: 'Tu estado',
                  items: [
                    _InfoItem(label: 'Estado', value: cliente.estado.toUpperCase()),
                    _InfoItem(label: 'Total visitas', value: '${cliente.totalVisitas}'),
                    if (cliente.ultimaVisita != null)
                      _InfoItem(
                        label: 'Última visita',
                        value: DateFormat('dd/MM/yyyy').format(cliente.ultimaVisita!),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Acciones rápidas
                Text('Acciones rápidas', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.calendar_today,
                        label: 'Reservar',
                        onTap: () => context.go('/cliente/reservar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.emoji_events,
                        label: 'Canjear',
                        onTap: () => context.go('/cliente/recompensas'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _PuntosBadge extends StatelessWidget {
  final int puntos;
  const _PuntosBadge({required this.puntos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$puntos',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
          Text(
            'puntos disponibles',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;
  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.label, style: TextStyle(color: Colors.grey.shade600)),
                      Text(item.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}
