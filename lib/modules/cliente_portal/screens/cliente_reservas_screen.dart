import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/reserva.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/reservas_provider.dart';

final misReservasProvider = FutureProvider.autoDispose<List<Reserva>>((ref) async {
  final clienteAsync = ref.watch(clienteAuthProvider);
  final cliente = clienteAsync.whenOrNull(data: (c) => c);
  if (cliente == null) return [];

  final response = await ref.read(reservaRepositoryProvider).getByCliente(cliente.id);
  return response;
});

class ClienteReservasScreen extends ConsumerWidget {
  const ClienteReservasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservasAsync = ref.watch(misReservasProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        title: const Text('Mis Reservas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(misReservasProvider),
        child: reservasAsync.when(
          data: (reservas) {
            if (reservas.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No tenés reservas', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/cliente/reservar'),
                      child: Text('Reservar ahora', style: TextStyle(color: Colors.amber.shade700, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reservas.length,
              itemBuilder: (context, index) {
                final r = reservas[index];
                return _ReservaClienteCard(reserva: r);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _ReservaClienteCard extends StatelessWidget {
  final Reserva reserva;

  const _ReservaClienteCard({required this.reserva});

  @override
  Widget build(BuildContext context) {
    final color = _colorPorEstado(reserva.estado);
    final fechaStr = DateFormat('dd/MM/yyyy').format(reserva.fecha);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  reserva.hora.substring(0, 5),
                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reserva.servicio, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(fechaStr, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _labelPorEstado(reserva.estado),
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorPorEstado(String estado) {
    switch (estado) {
      case 'solicitada':
        return Colors.orange.shade700;
      case 'confirmada':
        return Colors.blue.shade600;
      case 'completada':
        return Colors.green.shade600;
      case 'cancelada':
        return Colors.red.shade600;
      case 'no_show':
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _labelPorEstado(String estado) {
    switch (estado) {
      case 'solicitada':
        return 'Esperando confirmación';
      case 'confirmada':
        return 'Confirmada';
      case 'completada':
        return 'Completada';
      case 'cancelada':
        return 'Cancelada';
      case 'no_show':
        return 'No asistió';
      default:
        return estado;
    }
  }
}
