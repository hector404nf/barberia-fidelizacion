import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/reserva.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/barberos_provider.dart';
import '../../../providers/reservas_provider.dart';
import '../../../widgets/app_alert.dart';

final reservasHistoricoProvider = FutureProvider.autoDispose.family<List<Reserva>, List<DateTime>>((ref, fechas) async {
  final barberiaId = ref.watch(barberiaIdProvider);
  if (barberiaId == null) return [];

  final fechaInicio = fechas[0];
  final fechaFin = fechas[1];

  final fechaInicioStr = fechaInicio.toIso8601String().split('T').first;
  final fechaFinStr = fechaFin.toIso8601String().split('T').first;

  // Primero obtener todos los clientes de la barberia
  final clientesResponse = await Supabase.instance.client
      .from('clientes')
      .select('id')
      .eq('barberia_id', barberiaId);

  final clienteIds = (clientesResponse as List).map((c) => c['id'] as String).toList();
  if (clienteIds.isEmpty) return [];

  // Ahora obtener las reservas de esos clientes
  var query = Supabase.instance.client
      .from('reservas')
      .select('*, clientes(nombre, telefono)')
      .inFilter('cliente_id', clienteIds)
      .gte('fecha', fechaInicioStr)
      .lte('fecha', fechaFinStr)
      .order('fecha', ascending: false)
      .order('hora', ascending: false);

  final response = await query;
  return (response as List).map((e) => Reserva.fromJson(e)).toList();
});

class HistoricoReservasScreen extends ConsumerStatefulWidget {
  const HistoricoReservasScreen({super.key});

  @override
  ConsumerState<HistoricoReservasScreen> createState() => _HistoricoReservasScreenState();
}

class _HistoricoReservasScreenState extends ConsumerState<HistoricoReservasScreen> {
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();
  String _filtroEstado = 'todos';
  String? _filtroBarbero;

  @override
  Widget build(BuildContext context) {
    final reservasAsync = ref.watch(reservasHistoricoProvider([_fechaInicio, _fechaFin]));
    final barberiaId = ref.watch(barberiaIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Histórico de Reservas', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _mostrarFiltros(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros de fecha
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Desde', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_fechaInicio),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today, size: 20),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _fechaInicio,
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: _fechaFin,
                              );
                              if (picked != null) setState(() => _fechaInicio = picked);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hasta', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_fechaFin),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today, size: 20),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _fechaFin,
                                firstDate: _fechaInicio,
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setState(() => _fechaFin = picked);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Resumen
          reservasAsync.when(
            data: (reservas) {
              final completadas = reservas.where((r) => r.estado == 'completada').length;
              final canceladas = reservas.where((r) => r.estado == 'cancelada' || r.estado == 'no_show').length;
              final total = reservas.length;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _ResumenChip(label: 'Total', value: total, color: Colors.blue),
                    const SizedBox(width: 8),
                    _ResumenChip(label: 'Completadas', value: completadas, color: Colors.green),
                    const SizedBox(width: 8),
                    _ResumenChip(label: 'Canceladas', value: canceladas, color: Colors.red),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Lista de reservas
          Expanded(
            child: reservasAsync.when(
              data: (reservas) {
                // Filtrar por estado
                var filtradas = reservas;
                if (_filtroEstado != 'todos') {
                  filtradas = reservas.where((r) => r.estado == _filtroEstado).toList();
                }

                // Filtrar por barbero
                if (_filtroBarbero != null && _filtroBarbero!.isNotEmpty) {
                  filtradas = filtradas.where((r) => r.barberoId == _filtroBarbero).toList();
                }

                if (filtradas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No hay reservas en este período',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtradas.length,
                  itemBuilder: (context, index) {
                    final r = filtradas[index];
                    return _ReservaCard(
                      reserva: r,
                      onCancelar: () async {
                        await ref.read(reservaRepositoryProvider).updateEstado(r.id, 'cancelada');
                        ref.invalidate(reservasHistoricoProvider([_fechaInicio, _fechaFin]));
                        if (mounted) {
                          showSuccessAlert(context, 'Reserva cancelada');
                        }
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
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5F3EF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Filtrar por estado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _FiltroChip(label: 'Todos', value: 'todos', selected: _filtroEstado, onTap: (v) => setState(() => _filtroEstado = v)),
            _FiltroChip(label: 'Completada', value: 'completada', selected: _filtroEstado, onTap: (v) => setState(() => _filtroEstado = v)),
            _FiltroChip(label: 'Confirmada', value: 'confirmada', selected: _filtroEstado, onTap: (v) => setState(() => _filtroEstado = v)),
            _FiltroChip(label: 'Cancelada', value: 'cancelada', selected: _filtroEstado, onTap: (v) => setState(() => _filtroEstado = v)),
            _FiltroChip(label: 'No Show', value: 'no_show', selected: _filtroEstado, onTap: (v) => setState(() => _filtroEstado = v)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Aplicar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ResumenChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('$value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final void Function(String) onTap;

  const _FiltroChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.amber.shade600 : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }
}

class _ReservaCard extends StatelessWidget {
  final Reserva reserva;
  final VoidCallback onCancelar;

  const _ReservaCard({required this.reserva, required this.onCancelar});

  @override
  Widget build(BuildContext context) {
    final color = _colorPorEstado(reserva.estado);
    final nombre = reserva.clienteNombre ?? 'Cliente';
    final telefono = reserva.clienteTelefono ?? '';
    final esCancelada = reserva.estado == 'cancelada' || reserva.estado == 'no_show';
    final fechaStr = DateFormat('dd/MM/yyyy').format(reserva.fecha);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      reserva.hora.substring(0, 5),
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(fechaStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Text('•', style: TextStyle(color: Colors.grey.shade400)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(reserva.servicio, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(nombre, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                      if (telefono.isNotEmpty)
                        Text(telefono, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
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
              ],
            ),
            if (!esCancelada)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onCancelar,
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Cancelar', style: TextStyle(fontSize: 13)),
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
              ),
          ],
        ),
      ),
    );
  }

  Color _colorPorEstado(String estado) {
    switch (estado) {
      case 'confirmada': return Colors.blue.shade600;
      case 'completada': return Colors.green.shade600;
      case 'cancelada': return Colors.red.shade600;
      case 'no_show': return Colors.orange.shade700;
      case 'solicitada': return Colors.orange.shade600;
      default: return Colors.grey.shade600;
    }
  }
}
