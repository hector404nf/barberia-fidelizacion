import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/barbero.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/barberos_provider.dart';

class BarberosListScreen extends ConsumerWidget {
  const BarberosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esDueno = ref.watch(esDuenoProvider);
    final barberosAsync = ref.watch(barberosAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Barberos')),
      body: barberosAsync.when(
        data: (barberos) {
          if (barberos.isEmpty) {
            return const Center(child: Text('No hay barberos registrados'));
          }
          return ListView.builder(
            itemCount: barberos.length,
            itemBuilder: (context, index) {
              final b = barberos[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(b.nombre.substring(0, 1)),
                ),
                title: Text(
                  b.nombre,
                  style: TextStyle(
                    decoration: b.activo ? null : TextDecoration.lineThrough,
                  ),
                ),
                subtitle: b.especialidad != null ? Text(b.especialidad!) : null,
                trailing: esDueno
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => context.push('/barberos/${b.id}/editar'),
                          ),
                          if (b.activo)
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Desactivar barbero'),
                                    content: Text('¿Desactivar a ${b.nombre}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Desactivar'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(barberoRepositoryProvider).delete(b.id);
                                  ref.invalidate(barberosAdminProvider);
                                }
                              },
                            ),
                        ],
                      )
                    : null,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: esDueno
          ? FloatingActionButton(
              onPressed: () => context.push('/barberos/nuevo'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
