import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/app_alert.dart';

class ClienteLoginScreen extends ConsumerWidget {
  final String slug;
  const ClienteLoginScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barberiaAsync = ref.watch(barberiaPorSlugProvider(slug));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: barberiaAsync.when(
        data: (barberia) {
          if (barberia == null) {
            return const Center(child: Text('Barbería no encontrada'));
          }
          return _ClienteLoginForm(
            slug: slug,
            barberiaNombre: barberia['nombre'] as String,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ClienteLoginForm extends ConsumerStatefulWidget {
  final String slug;
  final String barberiaNombre;
  const _ClienteLoginForm({required this.slug, required this.barberiaNombre});

  @override
  ConsumerState<_ClienteLoginForm> createState() => _ClienteLoginFormState();
}

class _ClienteLoginFormState extends ConsumerState<_ClienteLoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() { _loading = true; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) context.go('/cliente');
    } on AuthException catch (e) {
      if (mounted) showValidationError(context, e.message);
    } catch (e) {
      if (mounted) showValidationError(context, 'Error inesperado');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            // Logo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.cut, size: 48, color: Colors.amber.shade700),
                  const SizedBox(height: 8),
                  Text(
                    widget.barberiaNombre,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Portal de Clientes',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Iniciar Sesión',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresá tus datos para acceder a tu cuenta',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Ingresar', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.push('/b/${widget.slug}/registro'),
                child: Text(
                  '¿No tenés cuenta? Crear cuenta',
                  style: TextStyle(color: Colors.amber.shade700),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
