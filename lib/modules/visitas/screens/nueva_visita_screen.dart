import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../models/cliente.dart';
import '../../../models/visita.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/barberos_provider.dart';
import '../../../providers/clientes_provider.dart';
import '../../../providers/config_provider.dart';
import '../../../providers/visitas_provider.dart';
import '../../../repositories/cliente_repository.dart';

class NuevaVisitaScreen extends ConsumerStatefulWidget {
  final String? clienteId;
  const NuevaVisitaScreen({super.key, this.clienteId});

  @override
  ConsumerState<NuevaVisitaScreen> createState() => _NuevaVisitaScreenState();
}

class _NuevaVisitaScreenState extends ConsumerState<NuevaVisitaScreen> {
  final _searchController = TextEditingController();
  final _servicioController = TextEditingController();
  final _montoController = TextEditingController();
  final _notasController = TextEditingController();

  Cliente? _clienteSeleccionado;
  String? _barberoSeleccionadoId;
  bool _loading = false;
  String? _error;
  List<Cliente> _clientesBusqueda = [];
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    if (widget.clienteId != null) {
      _cargarCliente(widget.clienteId!);
    }
  }

  Future<void> _cargarCliente(String id) async {
    final cliente = await ref.read(clienteRepositoryProvider).getById(id);
    if (cliente != null && mounted) {
      setState(() => _clienteSeleccionado = cliente);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _servicioController.dispose();
    _montoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

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

  int _calcularPuntos(Map<String, dynamic> config) {
    final monto = double.tryParse(_montoController.text) ?? 0;
    final porVisita = (config['por_visita'] as num?)?.toInt() ?? 10;
    final porMonto = (config['por_monto'] as num?)?.toDouble() ?? 1.0;
    return porVisita + (monto * porMonto).floor();
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
    final monto = double.tryParse(_montoController.text);
    if (monto == null || monto <= 0) {
      setState(() => _error = 'Ingresa un monto válido');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final visita = Visita(
        id: '',
        clienteId: _clienteSeleccionado!.id,
        barberoId: _barberoSeleccionadoId,
        fecha: DateTime.now(),
        servicio: _servicioController.text.trim(),
        monto: monto,
        createdAt: DateTime.now(),
      );

      await ref.read(visitaRepositoryProvider).create(visita);
      ref.invalidate(clientesProvider);
      ref.invalidate(clienteDetailProvider(_clienteSeleccionado!.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visita registrada correctamente')),
        );
        context.go('/clientes/${_clienteSeleccionado!.id}');
      }
    } catch (e) {
      setState(() => _error = 'Error al guardar: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(configPuntosProvider);
    final barberosAsync = ref.watch(barberosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Visita')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Buscar cliente ---
            if (_clienteSeleccionado == null) ...[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar cliente (nombre o teléfono)',
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
                        leading: CircleAvatar(child: Text(c.nombre[0])),
                        title: Text(c.nombre),
                        subtitle: Text(c.telefono),
                        trailing: Text('${c.totalVisitas} visitas'),
                        onTap: () => setState(() {
                          _clienteSeleccionado = c;
                          _clientesBusqueda = [];
                        }),
                      );
                    },
                  ),
                )
              else if (_searchController.text.length >= 2)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('No se encontraron clientes', textAlign: TextAlign.center),
                ),
            ] else ...[
              // Cliente seleccionado
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    child: Text(_clienteSeleccionado!.nombre[0]),
                  ),
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
                    decoration: const InputDecoration(labelText: 'Barbero'),
                    items: barberos.map((b) {
                      return DropdownMenuItem(
                        value: b.id,
                        child: Text(b.nombre + (b.especialidad != null ? ' - ${b.especialidad}' : '')),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _barberoSeleccionadoId = v),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error al cargar barberos'),
              ),
              const SizedBox(height: 16),

              // Servicio
              TextField(
                controller: _servicioController,
                decoration: const InputDecoration(
                  labelText: 'Servicio *',
                  hintText: 'Ej: Corte + Barba',
                ),
              ),
              const SizedBox(height: 16),

              // Monto
              TextField(
                controller: _montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto *',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Preview de puntos
              configAsync.when(
                data: (config) {
                  final puntos = _calcularPuntos(config);
                  return Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(PhosphorIconsFill.trophy,
                              color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Puntos a otorgar',
                                    style: Theme.of(context).textTheme.bodyMedium),
                                Text('$puntos puntos',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: Theme.of(context).colorScheme.secondary,
                                          fontWeight: FontWeight.bold,
                                        )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // Notas
              TextField(
                controller: _notasController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  hintText: 'Detalles adicionales...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),

              ElevatedButton.icon(
                onPressed: _loading ? null : _guardar,
                icon: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: Text(_loading ? 'Guardando...' : 'Registrar Visita'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
