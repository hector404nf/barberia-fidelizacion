import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final statsAsync = ref.watch(estadisticasProvider);
    final rankingAsync = ref.watch(rankingBarberosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(supabaseClientProvider).auth.signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(estadisticasProvider);
          ref.invalidate(rankingBarberosProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saludo
              profileAsync.when(
                data: (profile) {
                  if (profile == null) return const SizedBox.shrink();
                  return Text(
                    'Hola, ${profile.nombre}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 4),
              Text(
                'Resumen de los últimos 30 días',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 24),

              // KPIs
              statsAsync.when(
                data: (stats) {
                  if (stats.isEmpty) {
                    return const Center(child: Text('Sin datos disponibles'));
                  }
                  return Column(
                    children: [
                      _KpiGrid(stats: stats),
                      const SizedBox(height: 24),
                      _IngresosCard(stats: stats),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text('Error al cargar estadísticas: $e'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Ranking Barberos
              rankingAsync.when(
                data: (ranking) {
                  if (ranking.isEmpty) return const SizedBox.shrink();
                  return _RankingBarberos(ranking: ranking);
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),

              // Acciones rápidas
              Text('Acciones rápidas', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.person_add,
                      label: 'Nuevo Cliente',
                      onTap: () => context.push('/clientes/nuevo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add_circle,
                      label: 'Nueva Visita',
                      onTap: () => context.push('/visitas/nueva'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.calendar_today,
                      label: 'Nueva Reserva',
                      onTap: () => context.push('/agenda/nueva'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _KpiGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_CL', symbol: '\$');

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _KpiCard(
          title: 'Clientes Activos',
          value: '${stats['clientes_activos'] ?? 0}',
          icon: Icons.people,
          color: Colors.green,
        ),
        _KpiCard(
          title: 'Inactivos',
          value: '${stats['clientes_inactivos'] ?? 0}',
          icon: Icons.person_off,
          color: Colors.orange,
        ),
        _KpiCard(
          title: 'Visitas',
          value: '${stats['visitas_periodo'] ?? 0}',
          icon: Icons.cut,
          color: Colors.blue,
        ),
        _KpiCard(
          title: 'Ingresos',
          value: currency.format((stats['ingreso_total'] ?? 0) as num),
          icon: Icons.attach_money,
          color: Colors.teal,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 20, color: color),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngresosCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _IngresosCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_CL', symbol: '\$');
    final ticketPromedio = (stats['ticket_promedio'] ?? 0) as num;
    final recompensas = stats['recompensas_canjeadas'] ?? 0;
    final nuevos = stats['nuevos_clientes'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métricas adicionales',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _MetricRow(
              label: 'Ticket promedio',
              value: currency.format(ticketPromedio),
            ),
            const Divider(height: 24),
            _MetricRow(
              label: 'Recompensas canjeadas',
              value: '$recompensas',
            ),
            const Divider(height: 24),
            _MetricRow(
              label: 'Nuevos clientes',
              value: '$nuevos',
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _RankingBarberos extends StatelessWidget {
  final List<Map<String, dynamic>> ranking;
  const _RankingBarberos({required this.ranking});

  @override
  Widget build(BuildContext context) {
    final activos = ranking.where((b) => ((b['total_visitas'] as num?) ?? 0) > 0).toList();
    if (activos.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Barberos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...activos.take(3).map((b) {
              final nombre = b['nombre'] as String? ?? 'Barbero';
              final visitas = (b['total_visitas'] as num?)?.toInt() ?? 0;
              final ingresos = (b['ingresos'] as num?) ?? 0;
              final currency = NumberFormat.currency(locale: 'es_CL', symbol: '\$');

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        nombre.substring(0, 1),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nombre, style: Theme.of(context).textTheme.bodyLarge),
                          Text(
                            '$visitas visitas',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currency.format(ingresos),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
