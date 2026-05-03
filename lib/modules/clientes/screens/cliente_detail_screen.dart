import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/clientes_provider.dart';
import '../../../widgets/estado_chip.dart';

class ClienteDetailScreen extends ConsumerWidget {
  final String clienteId;
  const ClienteDetailScreen({super.key, required this.clienteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clienteAsync = ref.watch(clienteDetailProvider(clienteId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Detalle Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.amber.shade100,
                              child: Text(
                                cliente.nombre.substring(0, 1).toUpperCase(),
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cliente.nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text(cliente.telefono, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                                  const SizedBox(height: 4),
                                  EstadoChip(estado: cliente.estado),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/agenda/nueva?clienteId=$clienteId'),
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Nueva Reserva'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.amber.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
