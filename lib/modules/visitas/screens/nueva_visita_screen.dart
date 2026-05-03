import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/cliente.dart';
import '../../../models/servicio.dart';
import '../../../models/visita.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/barberos_provider.dart';
import '../../../providers/clientes_provider.dart';
import '../../../providers/config_provider.dart';
import '../../../providers/servicios_provider.dart';
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
          const SnackBar(content: Text('Visita registrada correctamente'), backgroundColor: Colors.green),
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
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Nueva Visita', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_clienteSeleccionado == null) ...[
              _buildTextField(
                controller: _searchController,
                label: 'Buscar cliente (nombre o teléfono)',
                icon: Icons.search,
                onChanged: _buscarClientes,
              ),
              const SizedBox(height: 8),
              if (_buscando)
                const Center(child: CircularProgressIndicator())
              else if (_clientesBusqueda.isNotEmpty)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _clientesBusqueda.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = _clientesBusqueda[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber.shade100,
                          child: Text(c.nombre[0], style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(c.telefono, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        trailing: Text('${c.totalVisitas} visitas', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                color: Colors.amber.shade50,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber.shade600,
                    foregroundColor: Colors.white,
                    child: Text(_clienteSeleccionado!.nombre[0]),
                  ),
                  title: Text(_clienteSeleccionado!.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_clienteSeleccionado!.telefono, style: TextStyle(color: Colors.grey.shade700)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _clienteSeleccionado = null),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      barberosAsync.when(
                        data: (barberos) {
                          if (barberos.isEmpty) return const Text('No hay barberos activos');
                          return DropdownButtonFormField<String>(
                            value: _barberoSeleccionadoId,
                            decoration: InputDecoration(
                              labelText: 'Barbero',
                              prefixIcon: Icon(Icons.cut, color: Colors.grey.shade500),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
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

                      ref.watch(serviciosProvider).when(
                        data: (servicios) {
                          if (servicios.isEmpty) {
                            return Column(
                              children: [
                                _buildTextField(controller: _servicioController, label: 'Servicio *', icon: Icons.spa_outlined),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _montoController,
                                  label: 'Monto *',
                                  icon: Icons.attach_money_outlined,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            );
                          }
                          return DropdownButtonFormField<Servicio>(
                            decoration: InputDecoration(
                              labelText: 'Servicio *',
                              prefixIcon: Icon(Icons.spa_outlined, color: Colors.grey.shade500),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                            items: servicios.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text('${s.nombre} - \$${s.precio.toStringAsFixed(0)}'),
                              );
                            }).toList(),
                            onChanged: (s) {
                              if (s != null) {
                                setState(() {
                                  _servicioController.text = s.nombre;
                                  _montoController.text = s.precio.toString();
                                });
                              }
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => Column(
                          children: [
                            _buildTextField(controller: _servicioController, label: 'Servicio *', icon: Icons.spa_outlined),
                            const SizedBox(height: 16),
                            _buildTextField(controller: _montoController, label: 'Monto *', icon: Icons.attach_money_outlined, keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _montoController,
                        label: 'Monto *',
                        icon: Icons.attach_money_outlined,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      configAsync.when(
                        data: (config) {
                          final puntos = _calcularPuntos(config);
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.emoji_events, color: Colors.amber.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Puntos a otorgar', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                                      Text('$puntos puntos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _notasController,
                        label: 'Notas (opcional)',
                        icon: Icons.notes_outlined,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),

              ElevatedButton.icon(
                onPressed: _loading ? null : _guardar,
                icon: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: Text(_loading ? 'Guardando...' : 'Registrar Visita', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
