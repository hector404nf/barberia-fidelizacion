import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClienteRegistroScreen extends ConsumerStatefulWidget {
  const ClienteRegistroScreen({super.key});

  @override
  ConsumerState<ClienteRegistroScreen> createState() => _ClienteRegistroScreenState();
}

class _ClienteRegistroScreenState extends ConsumerState<ClienteRegistroScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _codigoController = TextEditingController();

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _barberiaSeleccionada;

  Future<void> _buscarBarberia() async {
    final codigo = _codigoController.text.trim().toLowerCase();
    if (codigo.isEmpty) {
      setState(() => _error = 'Ingresa el código de la barbería');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final response = await Supabase.instance.client
          .from('barberias')
          .select('id, nombre, codigo')
          .eq('codigo', codigo)
          .maybeSingle();

      if (response == null) {
        setState(() => _error = 'Barbería no encontrada. Verifica el código.');
      } else {
        setState(() => _barberiaSeleccionada = response);
      }
    } catch (e) {
      setState(() => _error = 'Error al buscar: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _registrar() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final nombre = _nombreController.text.trim();
    final telefono = _telefonoController.text.trim();

    if (email.isEmpty || password.length < 6) {
      setState(() => _error = 'Email válido y contraseña de al menos 6 caracteres');
      return;
    }
    if (nombre.isEmpty || telefono.isEmpty) {
      setState(() => _error = 'Nombre y teléfono son obligatorios');
      return;
    }
    if (_barberiaSeleccionada == null) {
      setState(() => _error = 'Busca y selecciona una barbería primero');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      // 1. Crear auth user
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final userId = authResponse.user!.id;
      final barberiaId = _barberiaSeleccionada!['id'] as String;

      // 2. Registrar/vincular cliente via RPC
      await Supabase.instance.client.rpc('registrar_cliente', params: {
        'p_auth_user_id': userId,
        'p_barberia_id': barberiaId,
        'p_nombre': nombre,
        'p_telefono': telefono,
      });

      // 3. Iniciar sesión automáticamente
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (mounted) context.go('/cliente');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Error inesperado: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta como Cliente')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Registro de Cliente',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pide tu código de barbería al encargado',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Código de barbería
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codigoController,
                        decoration: const InputDecoration(
                          labelText: 'Código de barbería',
                          hintText: 'Ej: barber123',
                        ),
                        textCapitalization: TextCapitalization.none,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loading ? null : _buscarBarberia,
                      child: const Text('Buscar'),
                    ),
                  ],
                ),
                if (_barberiaSeleccionada != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      label: Text(_barberiaSeleccionada!['nombre']),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ),
                const SizedBox(height: 16),

                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Tu nombre *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _telefonoController,
                  decoration: const InputDecoration(labelText: 'Teléfono *'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña *'),
                  obscureText: true,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _registrar,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Crear cuenta'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Ya tengo cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
