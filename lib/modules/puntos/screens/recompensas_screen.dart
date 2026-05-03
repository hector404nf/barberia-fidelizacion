import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Recompensas', style: TextStyle(fontWeight: FontWeight.bold)),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No hay recompensas configuradas', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: recompensa.activa ? Colors.amber.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _iconoPorTipo(recompensa.tipo),
                    color: recompensa.activa ? Colors.amber.shade700 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recompensa.nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: recompensa.activa ? null : TextDecoration.lineThrough,
                          color: recompensa.activa ? Colors.black87 : Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        '${recompensa.puntosRequeridos} puntos',
                        style: TextStyle(color: Colors.amber.shade700, fontWeight: FontWeight.w600, fontSize: 14),
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
                      recompensa.activa ? Icons.visibility_off : Icons.visibility,
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            if (recompensa.stockLimitado)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Stock: ${recompensa.stockActual ?? 0}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            if (!recompensa.activa)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'INACTIVA',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
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
        return Icons.percent;
      case 'producto':
        return Icons.card_giftcard;
      default:
        return Icons.emoji_events;
    }
  }
}
