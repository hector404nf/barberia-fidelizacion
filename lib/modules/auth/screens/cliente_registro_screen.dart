import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/app_alert.dart';

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

  Future<void> _registrar(Map<String, dynamic> barberia) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final nombre = _nombreController.text.trim();
    final telefono = _telefonoController.text.trim();

    if (email.isEmpty || password.length < 6) {
      showValidationError(context, 'Email válido y contraseña de al menos 6 caracteres');
      return;
    }
    if (nombre.isEmpty || telefono.isEmpty) {
      showValidationError(context, 'Nombre y teléfono son obligatorios');
      return;
    }

    setState(() { _loading = true; });

    try {
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final userId = authResponse.user!.id;
      final barberiaId = barberia['id'] as String;

      await Supabase.instance.client.rpc('registrar_cliente', params: {
        'p_auth_user_id': userId,
        'p_barberia_id': barberiaId,
        'p_nombre': nombre,
        'p_telefono': telefono,
      });

      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (mounted) context.go('/cliente');
    } on AuthException catch (e) {
      if (mounted) showValidationError(context, e.message);
    } catch (e) {
      if (mounted) showValidationError(context, 'Error inesperado: $e');
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
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: barberiaAsync.when(
        data: (barberia) {
          if (barberia == null) {
            return const Center(child: Text('Barbería no encontrada'));
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    barberia['nombre'] as String,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crear cuenta de cliente',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(_nombreController, 'Tu nombre *', Icons.person),
                  const SizedBox(height: 16),
                  _buildTextField(_telefonoController, 'Teléfono *', Icons.phone, TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField(_emailController, 'Email *', Icons.email, TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildTextField(_passwordController, 'Contraseña *', Icons.lock, null, true),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : () => _registrar(barberia),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Crear cuenta', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/b/${widget.slug}/login'),
                      child: Text(
                        '¿Ya tenés cuenta? Iniciar sesión',
                        style: TextStyle(color: Colors.amber.shade700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, [TextInputType? type, bool obscure = false]) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: type,
      obscureText: obscure,
    );
  }
}
