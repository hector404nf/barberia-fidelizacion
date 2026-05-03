import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/servicio.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/servicios_provider.dart';

class ServicioFormScreen extends ConsumerStatefulWidget {
  final String? servicioId;
  const ServicioFormScreen({super.key, this.servicioId});

  @override
  ConsumerState<ServicioFormScreen> createState() => _ServicioFormScreenState();
}

class _ServicioFormScreenState extends ConsumerState<ServicioFormScreen> {
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _duracionController = TextEditingController(text: '30');

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.servicioId != null) {
      _cargarServicio();
    }
  }

  Future<void> _cargarServicio() async {
    final barberiaId = ref.read(barberiaIdProvider);
    if (barberiaId == null) return;

    final lista = await ref.read(servicioRepositoryProvider).getAllAdmin(barberiaId);
    final s = lista.firstWhere((x) => x.id == widget.servicioId);
    if (!mounted) return;

    setState(() {
      _nombreController.text = s.nombre;
      _descripcionController.text = s.descripcion ?? '';
      _precioController.text = s.precio.toString();
      _duracionController.text = s.duracionMinutos.toString();
    });
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    final precio = double.tryParse(_precioController.text);
    final duracion = int.tryParse(_duracionController.text);

    if (nombre.isEmpty) {
      setState(() => _error = 'Ingresa un nombre');
      return;
    }
    if (precio == null || precio <= 0) {
      setState(() => _error = 'Precio inválido');
      return;
    }

    final barberiaId = ref.read(barberiaIdProvider);
    if (barberiaId == null) {
      setState(() => _error = 'No se pudo obtener la barbería');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final repo = ref.read(servicioRepositoryProvider);
      if (widget.servicioId != null) {
        await repo.update(Servicio(
          id: widget.servicioId!,
          barberiaId: barberiaId,
          nombre: nombre,
          descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
          precio: precio,
          duracionMinutos: duracion ?? 30,
          createdAt: DateTime.now(),
        ));
      } else {
        await repo.create(Servicio(
          id: '',
          barberiaId: barberiaId,
          nombre: nombre,
          descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
          precio: precio,
          duracionMinutos: duracion ?? 30,
          createdAt: DateTime.now(),
        ));
      }

      ref.invalidate(serviciosAdminProvider);
      if (mounted) context.go('/servicios');
    } catch (e) {
      setState(() => _error = 'Error al guardar: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _duracionController.dispose();
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
        title: Text(widget.servicioId != null ? 'Editar Servicio' : 'Nuevo Servicio', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    _buildTextField(controller: _nombreController, label: 'Nombre *', icon: Icons.spa_outlined),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _descripcionController, label: 'Descripción', icon: Icons.description_outlined, maxLines: 2),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _precioController, label: 'Precio *', icon: Icons.attach_money_outlined, keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _duracionController, label: 'Duración (minutos) *', icon: Icons.timer_outlined, keyboardType: TextInputType.number),
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
                  : Text(widget.servicioId != null ? 'Guardar cambios' : 'Crear servicio', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
