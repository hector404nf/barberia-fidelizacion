import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/auth_provider.dart';

class ConfigScreen extends ConsumerWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barberiaId = ref.watch(barberiaIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        children: [
          // URL del portal de clientes
          if (barberiaId != null)
            FutureBuilder(
              future: Supabase.instance.client
                  .from('barberias')
                  .select('nombre, slug')
                  .eq('id', barberiaId)
                  .single(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final barberia = snapshot.data as Map<String, dynamic>;
                final slug = barberia['slug'] as String?;
                final nombre = barberia['nombre'] as String;
                final urlCliente = slug != null
                    ? 'https://barberia-fidelizacion.vercel.app/b/$slug'
                    : null;

                return Card(
                  margin: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Portal de Clientes',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Compartí esta URL con tus clientes para que se registren y reserven turnos.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (urlCliente != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    urlCliente,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: urlCliente));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('URL copiada al portapapeles')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          )
                        else
                          const Text(
                            'Slug no disponible. Contactá soporte.',
                            style: TextStyle(color: Colors.orange),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Barberos'),
            onTap: () => context.push('/barberos'),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historial de Visitas'),
            onTap: () => context.push('/visitas'),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Acerca de'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
    );
  }
}
