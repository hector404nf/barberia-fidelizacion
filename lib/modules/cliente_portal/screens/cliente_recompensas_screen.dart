import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/recompensa.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/recompensas_provider.dart';

class ClienteRecompensasScreen extends ConsumerWidget {
  const ClienteRecompensasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recompensasAsync = ref.watch(recompensasProvider);
    final puntosAsync = ref.watch(clientePuntosProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        title: const Text('Recompensas'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: puntosAsync.when(
                data: (puntos) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$puntos pts',
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
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
                  Icon(Icons.trophy, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No hay recompensas disponibles',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recompensas.length,
            itemBuilder: (context, index) {
              final r = recompensas[index];
              return _RecompensaCanjeCard(recompensa: r);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _RecompensaCanjeCard extends ConsumerStatefulWidget {
  final Recompensa recompensa;
  const _RecompensaCanjeCard({required this.recompensa});

  @override
  ConsumerState<_RecompensaCanjeCard> createState() => _RecompensaCanjeCardState();
}

class _RecompensaCanjeCardState extends ConsumerState<_RecompensaCanjeCard> {
  bool _canjeando = false;

  Future<void> _canjear() async {
    final clienteAsync = ref.read(clienteAuthProvider);
    final cliente = clienteAsync.whenOrNull(data: (c) => c);
    if (cliente == null) return;

    setState(() => _canjeando = true);

    try {
      final result = await ref.read(recompensaRepositoryProvider).canjear(
        cliente.id,
        widget.recompensa.id,
      );

      final success = result['success'] as bool? ?? false;
      final mensaje = success
          ? 'Canje exitoso: ${result['recompensa']}'
          : result['error'] ?? 'Error al canjear';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }

      if (success) {
        ref.invalidate(clientePuntosProvider);
        ref.invalidate(recompensasProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _canjeando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recompensa;
    final puntosAsync = ref.watch(clientePuntosProvider);
    final puntos = puntosAsync.whenOrNull(data: (p) => p) ?? 0;
    final puedeCanjear = puntos >= r.puntosRequeridos && r.activa;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_iconoPorTipo(r.tipo), color: Colors.amber.shade700),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${r.puntosRequeridos} puntos',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (r.valor != null && r.valor!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  r.valor!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: puedeCanjear && !_canjeando ? _canjear : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _canjeando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(puedeCanjear ? 'Canjear ahora' : 'Puntos insuficientes'),
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
        return Icons.trophy;
    }
  }
}
