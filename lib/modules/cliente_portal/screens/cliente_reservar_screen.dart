import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../widgets/app_alert.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/reserva.dart';
import '../../../models/servicio.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/barberos_provider.dart';
import '../../../providers/reservas_provider.dart';
import '../../../providers/servicios_provider.dart';

class ClienteReservarScreen extends ConsumerStatefulWidget {
  const ClienteReservarScreen({super.key});

  @override
  ConsumerState<ClienteReservarScreen> createState() => _ClienteReservarScreenState();
}

class _ClienteReservarScreenState extends ConsumerState<ClienteReservarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _barberoSeleccionadoId;
  String? _servicio;
  String? _horaSeleccionada;
  bool _loading = false;

  final _horariosDisponibles = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30', '17:00', '17:30', '18:00', '18:30',
  ];

  Future<List<String>> _getHorariosOcupados(DateTime fecha, String? barberoId) async {
    final barberiaId = ref.read(barberiaIdProvider);
    if (barberiaId == null) return [];

    try {
      final response = await Supabase.instance.client.rpc('get_horarios_ocupados', params: {
        'p_barberia_id': barberiaId,
        'p_fecha': fecha.toIso8601String().split('T').first,
        if (barberoId != null) 'p_barbero_id': barberoId,
      });
      return (response as List).map((e) => (e['hora'] as String).substring(0, 5)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _confirmarReserva() async {
    if (_horaSeleccionada == null) {
      showValidationError(context, 'Selecciona un horario');
      return;
    }

    final clienteAsync = ref.read(clienteAuthProvider);
    final cliente = clienteAsync.whenOrNull(data: (c) => c);
    if (cliente == null) {
      showValidationError(context, 'No se encontró tu perfil');
      return;
    }

    if (_servicio == null || _servicio!.trim().isEmpty) {
      showValidationError(context, 'Selecciona un servicio');
      return;
    }

    final fecha = _selectedDay ?? _focusedDay;

    setState(() { _loading = true; });

    try {
      await ref.read(reservaRepositoryProvider).create(
        Reserva(
          id: '',
          clienteId: cliente.id,
          barberoId: _barberoSeleccionadoId,
          fecha: fecha,
          hora: '$_horaSeleccionada:00',
          servicio: _servicio!,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (mounted) {
        showSuccessAlert(context, 'Reserva confirmada', onConfirm: () {
          setState(() {
            _horaSeleccionada = null;
            _servicio = null;
          });
        });
      }
    } catch (e) {
      if (mounted) showValidationError(context, 'Error al reservar: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedDay ?? _focusedDay;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        title: const Text('Agendar Turno'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 60)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Barbero
            ref.watch(barberosProvider).when(
              data: (barberos) {
                return DropdownButtonFormField<String>(
                  value: _barberoSeleccionadoId,
                  decoration: InputDecoration(
                    labelText: 'Barbero (opcional)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Cualquiera disponible')),
                    ...barberos.map((b) => DropdownMenuItem(value: b.id, child: Text(b.nombre))),
                  ],
                  onChanged: (v) => setState(() => _barberoSeleccionadoId = v),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error al cargar barberos'),
            ),
            const SizedBox(height: 20),

            // Servicio
            ref.watch(serviciosProvider).when(
              data: (servicios) {
                if (servicios.isEmpty) {
                  return TextField(
                    decoration: InputDecoration(
                      labelText: 'Servicio *',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => setState(() => _servicio = v),
                  );
                }
                return DropdownButtonFormField<Servicio>(
                  decoration: InputDecoration(
                    labelText: 'Servicio *',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  items: servicios.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text('${s.nombre} - \$${s.precio.toStringAsFixed(0)}'),
                    );
                  }).toList(),
                  onChanged: (s) {
                    if (s != null) setState(() => _servicio = s.nombre);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => TextField(
                decoration: InputDecoration(labelText: 'Servicio *'),
                onChanged: (v) => setState(() => _servicio = v),
              ),
            ),
            const SizedBox(height: 24),

            // Horarios
            Text(
              'Horarios disponibles - ${DateFormat('dd/MM/yyyy').format(selected)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<String>>(
              future: _getHorariosOcupados(selected, _barberoSeleccionadoId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ocupados = snapshot.data ?? [];
                final disponibles = _horariosDisponibles.where((h) => !ocupados.contains(h)).toList();

                if (disponibles.isEmpty) {
                  return const Center(child: Text('No hay horarios disponibles'));
                }

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: disponibles.map((hora) {
                    final seleccionado = _horaSeleccionada == hora;
                    return ChoiceChip(
                      label: Text(hora),
                      selected: seleccionado,
                      selectedColor: Colors.amber.shade200,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: seleccionado ? Colors.amber.shade900 : Colors.grey.shade700,
                        fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide.none,
                      ),
                      onSelected: _loading ? null : (selected) {
                        setState(() => _horaSeleccionada = selected ? hora : null);
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _loading || _horaSeleccionada == null ? null : _confirmarReserva,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirmar Turno', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
