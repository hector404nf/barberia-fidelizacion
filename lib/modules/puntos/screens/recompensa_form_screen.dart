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
      appBar: AppBar(
        title: Text(widget.recompensaId != null ? 'Editar Recompensa' : 'Nueva Recompensa'),
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
              controller: _puntosController,
              decoration: const InputDecoration(labelText: 'Puntos requeridos *'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const [
                DropdownMenuItem(value: 'servicio', child: Text('Servicio')),
                DropdownMenuItem(value: 'descuento', child: Text('Descuento')),
                DropdownMenuItem(value: 'producto', child: Text('Producto')),
              ],
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valorController,
              decoration: const InputDecoration(
                labelText: 'Valor / Descripción',
                hintText: 'Ej: 20% de descuento o Corte gratis',
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Stock limitado'),
              value: _stockLimitado,
              onChanged: (v) => setState(() => _stockLimitado = v),
            ),
            if (_stockLimitado)
              TextField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock actual'),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ElevatedButton(
              onPressed: _loading ? null : _guardar,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.recompensaId != null ? 'Guardar cambios' : 'Crear recompensa'),
            ),
          ],
        ),
      ),
    );
  }
}
