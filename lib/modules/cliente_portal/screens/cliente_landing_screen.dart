import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';

class ClienteLandingScreen extends ConsumerWidget {
  final String slug;
  const ClienteLandingScreen({super.key, required this.slug});

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
          return _LandingContent(
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

class _LandingContent extends StatelessWidget {
  final String slug;
  final String barberiaNombre;

  const _LandingContent({required this.slug, required this.barberiaNombre});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo / Nombre
            Text(
              barberiaNombre,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),

            // Título principal
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
                children: [
                  const TextSpan(text: 'Step Into '),
                  TextSpan(
                    text: 'The World Of Elegance',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Book premium barbers easily and enjoy a refined grooming experience',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/b/$slug/registro'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/b/$slug/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Log In'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Imagen de barbero
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 380,
                width: double.infinity,
                color: Colors.grey.shade300,
                child: Image.network(
                  'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=600&h=800&fit=crop',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 80, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
