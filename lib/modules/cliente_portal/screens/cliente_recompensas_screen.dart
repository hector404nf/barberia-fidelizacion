import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
      appBar: AppBar(
        title: const Text('Recompensas'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: puntosAsync.when(
                data: (puntos) => Chip(
                  label: Text('$puntos pts'),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                ),
                loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
      body: recompensasAsync.when(
        data: (recompensas) {
          if (recompensas.isEmpty) {
            return const Center(child: Text('No hay recompensas disponibles'));
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
          ? '¡Canje exitoso! ${result['recompensa']}'
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconoPorTipo(r.tipo),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.nombre, style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        '${r.puntosRequeridos} puntos',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (r.valor != null && r.valor!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(r.valor!, style: Theme.of(context).textTheme.bodySmall),
              ),
            if (r.stockLimitado)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Stock disponible: ${r.stockActual ?? 0}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: puedeCanjear && !_canjeando ? _canjear : null,
                child: _canjeando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(puedeCanjear ? 'Canjear' : 'Puntos insuficientes'),
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
