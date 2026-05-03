import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/recompensa.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/recompensas_provider.dart';

class RecompensaFormScreen extends ConsumerStatefulWidget {
  final String? recompensaId;
  const RecompensaFormScreen({super.key, this.recompensaId});

  @override
  ConsumerState<RecompensaFormScreen> createState() => _RecompensaFormScreenState();
}

class _RecompensaFormScreenState extends ConsumerState<RecompensaFormScreen> {
  final _nombreController = TextEditingController();
  final _puntosController = TextEditingController();
  final _valorController = TextEditingController();
  final _stockController = TextEditingController();

  String _tipo = 'servicio';
  bool _stockLimitado = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.recompensaId != null) {
      _cargarRecompensa();
    }
  }

  Future<void> _cargarRecompensa() async {
    final barberiaId = ref.read(barberiaIdProvider);
    if (barberiaId == null) return;

    final lista = await ref.read(recompensaRepositoryProvider).getAllIncludingInactive(barberiaId);
    final r = lista.firstWhere((x) => x.id == widget.recompensaId);
    if (!mounted) return;

    setState(() {
      _nombreController.text = r.nombre;
      _puntosController.text = r.puntosRequeridos.toString();
      _valorController.text = r.valor ?? '';
      _tipo = r.tipo;
      _stockLimitado = r.stockLimitado;
      if (r.stockActual != null) _stockController.text = r.stockActual.toString();
    });
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    final puntos = int.tryParse(_puntosController.text);

    if (nombre.isEmpty) {
      setState(() => _error = 'Ingresa un nombre');
      return;
    }
    if (puntos == null || puntos <= 0) {
      setState(() => _error = 'Puntos requeridos inválidos');
      return;
    }

    final barberiaId = ref.read(barberiaIdProvider);
    if (barberiaId == null) {
      setState(() => _error = 'No se pudo obtener la barbería');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final repo = ref.read(recompensaRepositoryProvider);

      if (widget.recompensaId != null) {
        await repo.update(Recompensa(
          id: widget.recompensaId!,
          barberiaId: barberiaId,
          nombre: nombre,
          puntosRequeridos: puntos,
          tipo: _tipo,
          valor: _valorController.text.trim().isEmpty ? null : _valorController.text.trim(),
          stockLimitado: _stockLimitado,
          stockActual: _stockLimitado ? int.tryParse(_stockController.text) : null,
          createdAt: DateTime.now(),
        ));
      } else {
        await repo.create(Recompensa(
          id: '',
          barberiaId: barberiaId,
          nombre: nombre,
          puntosRequeridos: puntos,
          tipo: _tipo,
          valor: _valorController.text.trim().isEmpty ? null : _valorController.text.trim(),
          stockLimitado: _stockLimitado,
          stockActual: _stockLimitado ? int.tryParse(_stockController.text) : null,
          createdAt: DateTime.now(),
        ));
      }

      ref.invalidate(recompensasAdminProvider);
      if (mounted) context.go('/recompensas');
    } catch (e) {
      setState(() => _error = 'Error al guardar: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _puntosController.dispose();
    _valorController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(widget.recompensaId != null ? 'Editar Recompensa' : 'Nueva Recompensa', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(controller: _nombreController, label: 'Nombre *', icon: Icons.emoji_events_outlined),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _puntosController, label: 'Puntos requeridos *', icon: Icons.star_outline, keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _tipo,
                      decoration: InputDecoration(
                        labelText: 'Tipo',
                        prefixIcon: Icon(Icons.category_outlined, color: Colors.grey.shade500),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'servicio', child: Text('Servicio')),
                        DropdownMenuItem(value: 'descuento', child: Text('Descuento')),
                        DropdownMenuItem(value: 'producto', child: Text('Producto')),
                      ],
                      onChanged: (v) => setState(() => _tipo = v!),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _valorController,
                      label: 'Valor / Descripción',
                      icon: Icons.description_outlined,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Stock limitado'),
                      value: _stockLimitado,
                      onChanged: (v) => setState(() => _stockLimitado = v),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    if (_stockLimitado)
                      _buildTextField(controller: _stockController, label: 'Stock actual', icon: Icons.inventory_2_outlined, keyboardType: TextInputType.number),
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
            ElevatedButton(
              onPressed: _loading ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(widget.recompensaId != null ? 'Guardar cambios' : 'Crear recompensa', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
