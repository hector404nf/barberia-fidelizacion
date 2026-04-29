import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/reserva.dart';
import '../../../providers/reservas_provider.dart';

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
      appBar: AppBar(title: const Text('Agenda')),
      body: Column(
        children: [
          TableCalendar(
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
          ),
          const Divider(),
          Expanded(
            child: reservasAsync.when(
              data: (reservas) {
                if (reservas.isEmpty) {
                  return const Center(child: Text('No hay reservas para este día'));
                }
                return ListView.builder(
                  itemCount: reservas.length,
                  itemBuilder: (context, index) {
                    final r = reservas[index];
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
        onPressed: () => context.push('/agenda/nueva'),
        child: const Icon(Icons.add),
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
    final puedeAccionar = reserva.estado == 'pendiente';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Text(reserva.hora.substring(0, 5), style: TextStyle(color: color, fontSize: 12)),
            ),
            title: Text(reserva.servicio),
            subtitle: Text('Cliente: ${reserva.clienteId.substring(0, 8)}...'),
            trailing: Chip(
              label: Text(reserva.estado, style: const TextStyle(fontSize: 10)),
              backgroundColor: color.withOpacity(0.2),
              side: BorderSide.none,
            ),
          ),
          if (puedeAccionar)
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
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
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
                        foregroundColor: Colors.red,
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
                        foregroundColor: Colors.orange,
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
      case 'completada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'no_show':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
