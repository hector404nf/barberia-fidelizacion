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
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Barberos', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: barberosAsync.when(
        data: (barberos) {
          if (barberos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cut_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No hay barberos registrados', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: barberos.length,
            itemBuilder: (context, index) {
              final b = barberos[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.amber.shade100,
                    child: Text(
                      b.nombre.substring(0, 1),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                    ),
                  ),
                  title: Text(
                    b.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: b.activo ? null : TextDecoration.lineThrough,
                      color: b.activo ? Colors.black87 : Colors.grey.shade500,
                    ),
                  ),
                  subtitle: b.especialidad != null
                      ? Text(b.especialidad!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))
                      : null,
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
                                icon: Icon(Icons.delete, size: 20, color: Colors.red.shade400),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: const Text('Desactivar barbero'),
                                      content: Text('¿Desactivar a ${b.nombre}?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: Text('Desactivar', style: TextStyle(color: Colors.red.shade600)),
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
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: esDueno
          ? FloatingActionButton(
              backgroundColor: Colors.amber.shade600,
              onPressed: () => context.push('/barberos/nuevo'),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
