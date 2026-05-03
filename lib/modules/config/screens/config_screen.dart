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
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Configuración', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                final urlCliente = slug != null
                    ? 'https://barberia-fidelizacion.vercel.app/b/$slug'
                    : null;

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.link, color: Colors.amber.shade700),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Portal de Clientes',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Compartí esta URL con tus clientes para que se registren y reserven turnos.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        if (urlCliente != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
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
                                  icon: Icon(Icons.copy, size: 20, color: Colors.amber.shade700),
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
                          Text(
                            'Slug no disponible. Contactá soporte.',
                            style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.people, color: Colors.grey.shade700),
                  ),
                  title: const Text('Barberos', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  onTap: () => context.push('/barberos'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.history, color: Colors.grey.shade700),
                  ),
                  title: const Text('Historial de Visitas', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  onTap: () => context.push('/visitas'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.info, color: Colors.grey.shade700),
                  ),
                  title: const Text('Acerca de', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.logout, color: Colors.red.shade400),
              ),
              title: Text('Cerrar sesión', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600)),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/');
              },
            ),
          ),
        ],
      ),
    );
  }
}
