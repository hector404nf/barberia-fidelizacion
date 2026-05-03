import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/reserva.dart';
import '../../../providers/reservas_provider.dart';
import '../../../widgets/app_alert.dart';

class CalendarioScreen extends ConsumerStatefulWidget {
  const CalendarioScreen({super.key});

  @override
  ConsumerState<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends ConsumerState<CalendarioScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final selected = _selectedDay ?? _focusedDay;
    final reservasAsync = ref.watch(reservasPorFechaProvider(selected));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Agenda', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Solicitudes',
            onPressed: () => context.push('/solicitudes'),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Mes',
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Colors.amber.shade600,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: reservasAsync.when(
              data: (reservas) {
                // Separar: solicitudes vs confirmadas
                final solicitudes = reservas.where((r) => r.estado == 'solicitada').toList();
                final confirmadas = reservas.where((r) => r.estado != 'solicitada').toList();

                if (reservas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('No hay reservas para este día', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: solicitudes.length + confirmadas.length + (solicitudes.isNotEmpty ? 1 : 0) + (confirmadas.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Header solicitudes
                    if (solicitudes.isNotEmpty && index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Solicitudes pendientes',
                                style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    // Items solicitudes
                    if (solicitudes.isNotEmpty && index <= solicitudes.length) {
                      final r = solicitudes[index - 1];
                      return _SolicitudTile(
                        reserva: r,
                        onConfirmar: () async {
                          await ref.read(reservaRepositoryProvider).updateEstado(r.id, 'confirmada');
                          ref.invalidate(reservasPorFechaProvider(selected));
                        },
                        onRechazar: () async {
                          await ref.read(reservaRepositoryProvider).updateEstado(r.id, 'cancelada');
                          ref.invalidate(reservasPorFechaProvider(selected));
                        },
                      );
                    }
                    // Header confirmadas
                    final confirmadasOffset = solicitudes.isNotEmpty ? solicitudes.length + 1 : 0;
                    if (confirmadas.isNotEmpty && index == confirmadasOffset) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Reservas confirmadas',
                                style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    // Items confirmadas
                    final r = confirmadas[index - confirmadasOffset - 1];
                    return _ReservaTile(
                      reserva: r,
                      onEstadoChanged: (estado) async {
                        await ref.read(reservaRepositoryProvider).updateEstado(r.id, estado);
                        ref.invalidate(reservasPorFechaProvider(selected));
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber.shade600,
        onPressed: () => context.push('/agenda/nueva'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _SolicitudTile extends StatelessWidget {
  final Reserva reserva;
  final VoidCallback onConfirmar;
  final VoidCallback onRechazar;

  const _SolicitudTile({
    required this.reserva,
    required this.onConfirmar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = reserva.clienteNombre ?? 'Cliente';
    final telefono = reserva.clienteTelefono ?? '';

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
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
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

class _ReservaTile extends StatelessWidget {
  final Reserva reserva;
  final ValueChanged<String> onEstadoChanged;

  const _ReservaTile({
    required this.reserva,
    required this.onEstadoChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorPorEstado(reserva.estado);
    final puedeCompletar = reserva.estado == 'confirmada';
    final nombre = reserva.clienteNombre ?? 'Cliente';
    final telefono = reserva.clienteTelefono ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  reserva.hora.substring(0, 5),
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            title: Text(reserva.servicio, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                if (telefono.isNotEmpty)
                  Text(telefono, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                reserva.estado,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (puedeCompletar)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onEstadoChanged('completada'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Completar', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onEstadoChanged('cancelada'),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onEstadoChanged('no_show'),
                      icon: const Icon(Icons.person_off, size: 16),
                      label: const Text('No Show', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade700,
                        side: BorderSide(color: Colors.orange.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _colorPorEstado(String estado) {
    switch (estado) {
      case 'confirmada':
        return Colors.blue.shade600;
      case 'completada':
        return Colors.green.shade600;
      case 'cancelada':
        return Colors.red.shade600;
      case 'no_show':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade600;
    }
  }
}
