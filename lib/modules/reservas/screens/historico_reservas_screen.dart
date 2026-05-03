import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/reserva.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/barberos_provider.dart';
import '../../../providers/reservas_provider.dart';
import '../../../providers/clientes_provider.dart';
import '../../../widgets/app_alert.dart';

class ReservasHistoricoNotifier extends StateNotifier<AsyncValue<List<Reserva>>> {
  ReservasHistoricoNotifier() : super(const AsyncValue.loading());

  Future<void> load({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String barberiaId,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final fechaInicioStr = fechaInicio.toIso8601String().split('T').first;
      final fechaFinStr = fechaFin.toIso8601String().split('T').first;

      final clientesResponse = await Supabase.instance.client
          .from('clientes')
          .select('id')
          .eq('barberia_id', barberiaId);

      final clienteIds = (clientesResponse as List).map((c) => c['id'] as String).toList();
      if (clienteIds.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      final response = await Supabase.instance.client
          .from('reservas')
          .select('*, clientes(nombre, telefono)')
          .inFilter('cliente_id', clienteIds)
          .gte('fecha', fechaInicioStr)
          .lte('fecha', fechaFinStr)
          .order('fecha', ascending: false)
          .order('hora', ascending: false);

      final reservas = (response as List).map((e) => Reserva.fromJson(e)).toList();
      state = AsyncValue.data(reservas);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final reservasHistoricoProvider = StateNotifierProvider<ReservasHistoricoNotifier, AsyncValue<List<Reserva>>>((ref) {
  return ReservasHistoricoNotifier();
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
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadData();
    }
  }

  void _loadData() {
    final profile = ref.read(profileProvider).whenOrNull(data: (p) => p);
    final barberiaId = profile?.barberiaId;
    if (barberiaId != null) {
      ref.read(reservasHistoricoProvider.notifier).load(
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        barberiaId: barberiaId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).whenOrNull(data: (p) => p);
    final barberiaId = profile?.barberiaId;
    final reservasAsync = ref.watch(reservasHistoricoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Histórico de Reservas', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.amber),
            onPressed: () => _mostrarFiltros(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.amber),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tarjeta de rango de fechas
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade600, Colors.amber.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildDateSelector(
                    label: 'Desde',
                    date: _fechaInicio,
                    onSelect: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fechaInicio,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: _fechaFin,
                        builder: (context, child) => Theme(
                          child: child!,
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: Colors.amber.shade600,
                            ),
                          ),
                        ),
                      );
                      if (picked != null) {
                        setState(() => _fechaInicio = picked);
                        _loadData();
                      }
                    },
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildDateSelector(
                    label: 'Hasta',
                    date: _fechaFin,
                    onSelect: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fechaFin,
                        firstDate: _fechaInicio,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) => Theme(
                          child: child!,
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: Colors.amber.shade600,
                            ),
                          ),
                        ),
                      );
                      if (picked != null) {
                        setState(() => _fechaFin = picked);
                        _loadData();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Resumen estadístico
          reservasAsync.when(
            data: (reservas) {
              final completadas = reservas.where((r) => r.estado == 'completada').length;
              final canceladas = reservas.where((r) => r.estado == 'cancelada' || r.estado == 'no_show').length;
              final confirmadas = reservas.where((r) => r.estado == 'confirmada').length;
              final solicitadas = reservas.where((r) => r.estado == 'solicitada').length;
              final total = reservas.length;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStatCard('Total', total, Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatCard('Completadas', completadas, Colors.green),
                    const SizedBox(width: 8),
                    _buildStatCard('Confirmadas', confirmadas, Colors.orange),
                    const SizedBox(width: 8),
                    _buildStatCard('Canceladas', canceladas, Colors.red),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // Lista de reservas
          Expanded(
            child: reservasAsync.when(
              data: (reservas) {
                var filtradas = reservas;
                if (_filtroEstado != 'todos') {
                  filtradas = reservas.where((r) => r.estado == _filtroEstado).toList();
                }

                if (filtradas.isEmpty) {
                  return _buildEmptyState();
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
                        _loadData();
                        if (mounted) {
                          showSuccessAlert(context, 'Reserva cancelada');
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
              error: (e, _) => _buildErrorState(e),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector({required String label, required DateTime date, required VoidCallback onSelect}) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(date),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay reservas en este período',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intentá cambiar el rango de fechas',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            'Error al cargar',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Filtrar por estado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            _FiltroChip(label: 'Todos', value: 'todos', selected: _filtroEstado, onTap: (v) => setState(() => _filtroEstado = v)),
            _FiltroChip(label: 'Completada', value: 'completada', selected: _filtroEstado, onTap: (v) => setState(() => _filtroEstado = v)),
            _FiltroChip(label: 'Confirmada', value: 'confirmada', selected: _filtroEstado, onTap: (v) => setState(() => _filtroEstado = v)),
            _FiltroChip(label: 'Solicitada', value: 'solicitada', selected: _filtroEstado, onTap: (v) => setState(() => _filtroEstado = v)),
            _FiltroChip(label: 'Cancelada', value: 'cancelada', selected: _filtroEstado, onTap: (v) => setState(() => _filtroEstado = v)),
            _FiltroChip(label: 'No Show', value: 'no_show', selected: _filtroEstado, onTap: (v) => setState(() => _filtroEstado = v)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Aplicar filtros', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
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
    final esHoy = DateTime.now().difference(reserva.fecha).inDays.abs() <= 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              reserva.hora.substring(0, 5),
                              style: TextStyle(
                                color: color,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (esHoy)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'HOY',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  reserva.servicio,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nombre,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (telefono.isNotEmpty)
                            Text(
                              telefono,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        reserva.estado,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!esCancelada)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onCancelar,
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text('Cancelar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade600,
                              side: BorderSide(color: Colors.red.shade200),
                              backgroundColor: Colors.red.shade50,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
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

class _FiltroChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final void Function(String) onTap;

  const _FiltroChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade600 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.amber.shade600 : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
