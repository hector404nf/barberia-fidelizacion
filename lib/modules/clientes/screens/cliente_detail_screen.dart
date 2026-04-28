import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/clientes_provider.dart';
import '../../../repositories/visita_repository.dart';
import '../../../widgets/estado_chip.dart';

class ClienteDetailScreen extends ConsumerWidget {
  final String clienteId;
  const ClienteDetailScreen({super.key, required this.clienteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clienteAsync = ref.watch(clienteDetailProvider(clienteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle Cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/clientes/$clienteId/editar'),
          ),
        ],
      ),
      body: clienteAsync.when(
        data: (cliente) {
          if (cliente == null) return const Center(child: Text('Cliente no encontrado'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              child: Text(cliente.nombre.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(fontSize: 28)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cliente.nombre, style: Theme.of(context).textTheme.titleLarge),
                                  Text(cliente.telefono, style: Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(height: 4),
                                  EstadoChip(estado: cliente.estado),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _InfoRow(label: 'Total visitas', value: '${cliente.totalVisitas}'),
                        if (cliente.frecuenciaVisitas != null)
                          _InfoRow(label: 'Frecuencia', value: 'Cada ${cliente.frecuenciaVisitas} días'),
                        if (cliente.ultimaVisita != null)
                          _InfoRow(label: 'Última visita', value: _formatDate(cliente.ultimaVisita!)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/visitas/nueva?clienteId=$clienteId'),
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva Visita'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/agenda/nueva?clienteId=$clienteId'),
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Nueva Reserva'),
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

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
