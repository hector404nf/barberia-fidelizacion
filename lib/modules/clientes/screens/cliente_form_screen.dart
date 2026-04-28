import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/cliente.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/clientes_provider.dart';
import '../../../repositories/cliente_repository.dart';

class ClienteFormScreen extends ConsumerStatefulWidget {
  final String? clienteId;
  const ClienteFormScreen({super.key, this.clienteId});

  @override
  ConsumerState<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends ConsumerState<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.clienteId != null) {
      _cargarCliente();
    }
  }

  Future<void> _cargarCliente() async {
    final cliente = await ref.read(clienteRepositoryProvider).getById(widget.clienteId!);
    if (cliente != null && mounted) {
      _nombreController.text = cliente.nombre;
      _telefonoController.text = cliente.telefono;
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final barberiaId = ref.read(barberiaIdProvider);
    if (barberiaId == null) return;

    try {
      final repo = ref.read(clienteRepositoryProvider);
      if (widget.clienteId != null) {
        final existing = await repo.getById(widget.clienteId!);
        if (existing != null) {
          await repo.update(existing.copyWith(
            nombre: _nombreController.text.trim(),
            telefono: _telefonoController.text.trim(),
          ));
        }
      } else {
        await repo.create(Cliente(
          id: '',
          barberiaId: barberiaId,
          nombre: _nombreController.text.trim(),
          telefono: _telefonoController.text.trim(),
          createdAt: DateTime.now(),
        ));
      }
      if (mounted) {
        ref.invalidate(clientesProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.clienteId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Cliente' : 'Nuevo Cliente')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre *'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono *'),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _guardar,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(isEditing ? 'Guardar cambios' : 'Crear cliente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }
}
