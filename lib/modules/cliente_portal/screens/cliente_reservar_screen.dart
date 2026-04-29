import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/reserva.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/barberos_provider.dart';
import '../../../providers/reservas_provider.dart';

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
  String? _notas;
  bool _loading = false;
  String? _error;

  final _horariosDisponibles = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30', '17:00', '17:30', '18:00', '18:30',
  ];

  Future<List<String>> _getHorariosOcupados(DateTime fecha, String? barberoId) async {
    final barberiaId = ref.read(barberiaIdProvider);
    if (barberiaId == null) return [];

    final response = await Supabase.instance.client.rpc('get_horarios_ocupados', params: {
      'p_barberia_id': barberiaId,
      'p_fecha': fecha.toIso8601String().split('T').first,
      if (barberoId != null) 'p_barbero_id': barberoId,
    });

    return (response as List).map((e) => (e['hora'] as String).substring(0, 5)).toList();
  }

  Future<void> _reservar(String hora) async {
    final clienteAsync = ref.read(clienteAuthProvider);
    final cliente = clienteAsync.whenOrNull(data: (c) => c);
    if (cliente == null) {
      setState(() => _error = 'No se encontró tu perfil');
      return;
    }

    if (_servicio == null || _servicio!.trim().isEmpty) {
      setState(() => _error = 'Selecciona o escribe un servicio');
      return;
    }

    final fecha = _selectedDay ?? _focusedDay;

    setState(() { _loading = true; _error = null; });

    try {
      await ref.read(reservaRepositoryProvider).create(
        Reserva(
          id: '',
          clienteId: cliente.id,
          barberoId: _barberoSeleccionadoId,
          fecha: fecha,
          hora: '$hora:00',
          servicio: _servicio!,
          notas: _notas,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva creada correctamente')),
        );
        setState(() => _servicio = null);
      }
    } catch (e) {
      setState(() => _error = 'Error al reservar: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final barberosAsync = ref.watch(barberosProvider);
    final selected = _selectedDay ?? _focusedDay;

    return Scaffold(
      appBar: AppBar(title: const Text('Reservar Turno')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Calendario
            TableCalendar(
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
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            ),
            const SizedBox(height: 16),

            // Selección de barbero
            barberosAsync.when(
              data: (barberos) {
                return DropdownButtonFormField<String>(
                  value: _barberoSeleccionadoId,
                  decoration: const InputDecoration(labelText: 'Barbero (opcional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Cualquiera disponible')),
                    ...barberos.map((b) => DropdownMenuItem(value: b.id, child: Text(b.nombre))),
                  ],
                  onChanged: (v) => setState(() => _barberoSeleccionadoId = v),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error al cargar barberos'),
            ),
            const SizedBox(height: 16),

            // Servicio
            TextField(
              decoration: const InputDecoration(
                labelText: 'Servicio *',
                hintText: 'Ej: Corte, Barba, etc.',
              ),
              onChanged: (v) => setState(() => _servicio = v),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
              maxLines: 2,
              onChanged: (v) => setState(() => _notas = v),
            ),
            const SizedBox(height: 16),

            if (_error != null)
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),

            // Horarios disponibles
            Text(
              'Horarios disponibles - ${DateFormat('dd/MM/yyyy').format(selected)}',
              style: Theme.of(context).textTheme.titleMedium,
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
                  return const Center(child: Text('No hay horarios disponibles para este día'));
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: disponibles.map((hora) {
                    return ActionChip(
                      label: Text(hora),
                      onPressed: _loading ? null : () => _reservar(hora),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
