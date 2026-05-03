import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/barbero.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/barberos_provider.dart';

class BarberoFormScreen extends ConsumerStatefulWidget {
  final String? barberoId;
  const BarberoFormScreen({super.key, this.barberoId});

  @override
  ConsumerState<BarberoFormScreen> createState() => _BarberoFormScreenState();
}

class _BarberoFormScreenState extends ConsumerState<BarberoFormScreen> {
  final _nombreController = TextEditingController();
  final _especialidadController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.barberoId != null) {
      _cargarBarbero();
    }
  }

  Future<void> _cargarBarbero() async {
    final barberiaId = ref.read(barberiaIdProvider);
    if (barberiaId == null) return;

    final lista = await ref.read(barberoRepositoryProvider).getAllIncludingInactive(barberiaId);
    final b = lista.firstWhere((x) => x.id == widget.barberoId);
    if (!mounted) return;

    setState(() {
      _nombreController.text = b.nombre;
      _especialidadController.text = b.especialidad ?? '';
    });
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Ingresa un nombre');
      return;
    }

    final barberiaId = ref.read(barberiaIdProvider);
    if (barberiaId == null) {
      setState(() => _error = 'No se pudo obtener la barbería');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final repo = ref.read(barberoRepositoryProvider);
      if (widget.barberoId != null) {
        await repo.update(Barbero(
          id: widget.barberoId!,
          barberiaId: barberiaId,
          nombre: nombre,
          especialidad: _especialidadController.text.trim().isEmpty
              ? null
              : _especialidadController.text.trim(),
          createdAt: DateTime.now(),
        ));
      } else {
        await repo.create(Barbero(
          id: '',
          barberiaId: barberiaId,
          nombre: nombre,
          especialidad: _especialidadController.text.trim().isEmpty
              ? null
              : _especialidadController.text.trim(),
          createdAt: DateTime.now(),
        ));
      }

      ref.invalidate(barberosAdminProvider);
      if (mounted) context.go('/barberos');
    } catch (e) {
      setState(() => _error = 'Error al guardar: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _especialidadController.dispose();
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
        title: Text(widget.barberoId != null ? 'Editar Barbero' : 'Nuevo Barbero', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    _buildTextField(controller: _nombreController, label: 'Nombre *', icon: Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _especialidadController,
                      label: 'Especialidad',
                      icon: Icons.star_outline,
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
                  : Text(widget.barberoId != null ? 'Guardar cambios' : 'Crear barbero', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
  }) {
    return TextField(
      controller: controller,
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
