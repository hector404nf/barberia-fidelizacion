import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/cliente.dart';
import '../../../models/reserva.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/barberos_provider.dart';
import '../../../providers/clientes_provider.dart';
import '../../../providers/reservas_provider.dart';
import '../../../repositories/cliente_repository.dart';

class NuevaReservaScreen extends ConsumerStatefulWidget {
  const NuevaReservaScreen({super.key});

  @override
  ConsumerState<NuevaReservaScreen> createState() => _NuevaReservaScreenState();
}

class _NuevaReservaScreenState extends ConsumerState<NuevaReservaScreen> {
  final _searchController = TextEditingController();
  final _servicioController = TextEditingController();
  final _notasController = TextEditingController();

  Cliente? _clienteSeleccionado;
  String? _barberoSeleccionadoId;
  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = const TimeOfDay(hour: 10, minute: 0);

  bool _loading = false;
  String? _error;
  List<Cliente> _clientesBusqueda = [];
  bool _buscando = false;

  Future<void> _buscarClientes(String query) async {
    if (query.length < 2) {
      setState(() => _clientesBusqueda = []);
      return;
    }
    setState(() => _buscando = true);
    final barberiaId = ref.read(barberiaIdProvider);
    if (barberiaId == null) return;

    final resultados = await ref.read(clienteRepositoryProvider).search(barberiaId, query);
    setState(() {
      _clientesBusqueda = resultados;
      _buscando = false;
    });
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _seleccionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora,
    );
    if (picked != null) setState(() => _hora = picked);
  }

  Future<void> _guardar() async {
    if (_clienteSeleccionado == null) {
      setState(() => _error = 'Selecciona un cliente');
      return;
    }
    if (_servicioController.text.trim().isEmpty) {
      setState(() => _error = 'Ingresa el servicio');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final reserva = Reserva(
        id: '',
        clienteId: _clienteSeleccionado!.id,
        barberoId: _barberoSeleccionadoId,
        fecha: _fecha,
        hora: '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}:00',
        servicio: _servicioController.text.trim(),
        notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(reservaRepositoryProvider).create(reserva);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva creada correctamente')),
        );
        context.go('/agenda');
      }
    } catch (e) {
      setState(() => _error = 'Error al guardar: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _servicioController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barberosAsync = ref.watch(barberosProvider);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Reserva')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cliente
            if (_clienteSeleccionado == null) ...[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar cliente',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _clientesBusqueda = []);
                          },
                        )
                      : null,
                ),
                onChanged: _buscarClientes,
              ),
              const SizedBox(height: 8),
              if (_buscando)
                const Center(child: CircularProgressIndicator())
              else if (_clientesBusqueda.isNotEmpty)
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _clientesBusqueda.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = _clientesBusqueda[index];
                      return ListTile(
                        title: Text(c.nombre),
                        subtitle: Text(c.telefono),
                        onTap: () => setState(() {
                          _clienteSeleccionado = c;
                          _clientesBusqueda = [];
                        }),
                      );
                    },
                  ),
                )
              else if (_searchController.text.length >= 2)
                const Text('No se encontraron clientes', textAlign: TextAlign.center),
            ] else ...[
              Card(
                child: ListTile(
                  title: Text(_clienteSeleccionado!.nombre),
                  subtitle: Text(_clienteSeleccionado!.telefono),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _clienteSeleccionado = null),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Barbero
              barberosAsync.when(
                data: (barberos) {
                  if (barberos.isEmpty) return const Text('No hay barberos activos');
                  return DropdownButtonFormField<String>(
                    value: _barberoSeleccionadoId,
                    decoration: const InputDecoration(labelText: 'Barbero (opcional)'),
                    items: barberos.map((b) {
                      return DropdownMenuItem(value: b.id, child: Text(b.nombre));
                    }).toList(),
                    onChanged: (v) => setState(() => _barberoSeleccionadoId = v),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error al cargar barberos'),
              ),
              const SizedBox(height: 16),

              // Fecha y hora
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _seleccionarFecha,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(dateFormat.format(_fecha)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _seleccionarHora,
                      icon: const Icon(Icons.access_time),
                      label: Text(_hora.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Servicio
              TextField(
                controller: _servicioController,
                decoration: const InputDecoration(labelText: 'Servicio *'),
              ),
              const SizedBox(height: 16),

              // Notas
              TextField(
                controller: _notasController,
                decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              if (_error != null)
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ElevatedButton(
                onPressed: _loading ? null : _guardar,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Crear Reserva'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
