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
      appBar: AppBar(
        title: Text(widget.barberoId != null ? 'Editar Barbero' : 'Nuevo Barbero'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre *'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _especialidadController,
              decoration: const InputDecoration(
                labelText: 'Especialidad',
                hintText: 'Ej: Cortes modernos, barbas...',
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ElevatedButton(
              onPressed: _loading ? null : _guardar,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.barberoId != null ? 'Guardar cambios' : 'Crear barbero'),
            ),
          ],
        ),
      ),
    );
  }
}
