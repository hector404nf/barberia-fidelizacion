import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/auth_provider.dart';

class ClienteRegistroScreen extends ConsumerStatefulWidget {
  final String slug;
  const ClienteRegistroScreen({super.key, required this.slug});

  @override
  ConsumerState<ClienteRegistroScreen> createState() => _ClienteRegistroScreenState();
}

class _ClienteRegistroScreenState extends ConsumerState<ClienteRegistroScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _registrar(Map<String, dynamic> barberia) async {
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

    setState(() { _loading = true; _error = null; });

    try {
      // 1. Crear auth user
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final userId = authResponse.user!.id;
      final barberiaId = barberia['id'] as String;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barberiaAsync = ref.watch(barberiaPorSlugProvider(widget.slug));

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: barberiaAsync.when(
        data: (barberia) {
          if (barberia == null) {
            return const Center(child: Text('Barbería no encontrada'));
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      barberia['nombre'] as String,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Registro de Cliente',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
                    ),
                    const SizedBox(height: 24),
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
                      onPressed: _loading ? null : () => _registrar(barberia),
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Crear cuenta'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/b/${widget.slug}'),
                      child: const Text('Ya tengo cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
