import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../models/recompensa.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/recompensas_provider.dart';

class RecompensasScreen extends ConsumerWidget {
  const RecompensasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esDueno = ref.watch(esDuenoProvider);
    final recompensasAsync = ref.watch(
      esDueno ? recompensasAdminProvider : recompensasProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recompensas'),
        actions: [
          if (esDueno)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Nueva recompensa',
              onPressed: () => context.push('/recompensas/nueva'),
            ),
        ],
      ),
      body: recompensasAsync.when(
        data: (recompensas) {
          if (recompensas.isEmpty) {
            return const Center(child: Text('No hay recompensas configuradas'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recompensas.length,
            itemBuilder: (context, index) {
              final r = recompensas[index];
              return _RecompensaCard(
                recompensa: r,
                esDueno: esDueno,
                onEdit: esDueno
                    ? () => context.push('/recompensas/${r.id}/editar')
                    : null,
                onToggle: esDueno
                    ? () async {
                        final repo = ref.read(recompensaRepositoryProvider);
                        await repo.update(r.copyWith(activa: !r.activa));
                        ref.invalidate(recompensasAdminProvider);
                      }
                    : null,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _RecompensaCard extends StatelessWidget {
  final Recompensa recompensa;
  final bool esDueno;
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;

  const _RecompensaCard({
    required this.recompensa,
    required this.esDueno,
    this.onEdit,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = recompensa.activa
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconoPorTipo(recompensa.tipo),
                  color: recompensa.activa
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recompensa.nombre,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: recompensa.activa
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                      ),
                      Text(
                        '${recompensa.puntosRequeridos} puntos',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                if (esDueno) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: Icon(
                      recompensa.activa
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: onToggle,
                  ),
                ],
              ],
            ),
            if (recompensa.valor != null && recompensa.valor!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Valor: ${recompensa.valor}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (recompensa.stockLimitado)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Stock: ${recompensa.stockActual ?? 0}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (!recompensa.activa)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'INACTIVA',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconoPorTipo(String tipo) {
    switch (tipo) {
      case 'descuento':
        return PhosphorIconsRegular.percent;
      case 'producto':
        return PhosphorIconsRegular.package;
      default:
        return PhosphorIconsRegular.scissors;
    }
  }
}
