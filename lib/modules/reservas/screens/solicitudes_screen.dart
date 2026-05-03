import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/reserva.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/reservas_provider.dart';
import '../../../widgets/app_alert.dart';

final solicitudesPendientesProvider = FutureProvider<List<Reserva>>((ref) async {
  final barberiaId = ref.watch(barberiaIdProvider);
  if (barberiaId == null) {
    // Esperar a que el perfil cargue
    await Future.delayed(const Duration(seconds: 2));
    final retryId = ref.read(barberiaIdProvider);
    if (retryId == null) return [];
    return ref.read(reservaRepositoryProvider).getSolicitudesPendientes(retryId);
  }

  try {
    return await ref.read(reservaRepositoryProvider).getSolicitudesPendientes(barberiaId);
  } catch (e) {
    throw Exception('Error al cargar solicitudes: $e');
  }
});

class SolicitudesScreen extends ConsumerWidget {
  const SolicitudesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barberiaId = ref.watch(barberiaIdProvider);
    final solicitudesAsync = ref.watch(solicitudesPendientesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Solicitudes de Reservas', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(solicitudesPendientesProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(solicitudesPendientesProvider),
        child: solicitudesAsync.when(
          data: (solicitudes) {
            if (solicitudes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      barberiaId == null
                          ? 'Cargando tu barbería...'
                          : 'No hay solicitudes pendientes',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                    if (barberiaId == null) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: solicitudes.length,
              itemBuilder: (context, index) {
                final r = solicitudes[index];
                return _SolicitudCard(
                  reserva: r,
                  onConfirmar: () async {
                    await ref.read(reservaRepositoryProvider).updateEstado(r.id, 'confirmada');
                    ref.invalidate(solicitudesPendientesProvider);
                    if (context.mounted) {
                      showSuccessAlert(context, 'Reserva confirmada');
                    }
                  },
                  onRechazar: () async {
                    await ref.read(reservaRepositoryProvider).updateEstado(r.id, 'cancelada');
                    ref.invalidate(solicitudesPendientesProvider);
                    if (context.mounted) {
                      showSuccessAlert(context, 'Reserva rechazada');
                    }
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, stack) {
            debugPrint('Error en solicitudes: $e');
            debugPrint('Stack: $stack');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Error al cargar', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('$e', style: TextStyle(color: Colors.red.shade400, fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(solicitudesPendientesProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  final Reserva reserva;
  final VoidCallback onConfirmar;
  final VoidCallback onRechazar;

  const _SolicitudCard({
    required this.reserva,
    required this.onConfirmar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = reserva.clienteNombre ?? 'Cliente';
    final telefono = reserva.clienteTelefono ?? '';
    final fechaStr = DateFormat('dd/MM/yyyy').format(reserva.fecha);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      reserva.hora.substring(0, 5),
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reserva.servicio, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(nombre, style: TextStyle(color: Colors.grey.shade800, fontSize: 14)),
                      if (telefono.isNotEmpty)
                        Text(telefono, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      Text(fechaStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Solicitud',
                    style: TextStyle(color: Colors.orange.shade900, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onConfirmar,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Confirmar', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRechazar,
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Rechazar', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
