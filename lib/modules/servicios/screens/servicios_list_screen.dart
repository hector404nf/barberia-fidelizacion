import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/servicio.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/servicios_provider.dart';

class ServiciosListScreen extends ConsumerWidget {
  const ServiciosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviciosAsync = ref.watch(serviciosAdminProvider);
    final currency = NumberFormat.currency(locale: 'es_CL', symbol: '\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Servicios')),
      body: serviciosAsync.when(
        data: (servicios) {
          if (servicios.isEmpty) {
            return const Center(child: Text('No hay servicios configurados'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: servicios.length,
            itemBuilder: (context, index) {
              final s = servicios[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    s.nombre,
                    style: TextStyle(
                      decoration: s.activo ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (s.descripcion != null) Text(s.descripcion!),
                      Text('${s.duracionMinutos} min · ${currency.format(s.precio)}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => context.push('/servicios/${s.id}/editar'),
                      ),
                      IconButton(
                        icon: Icon(
                          s.activo ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () async {
                          await ref.read(servicioRepositoryProvider).update(
                            Servicio(
                              id: s.id,
                              barberiaId: s.barberiaId,
                              nombre: s.nombre,
                              descripcion: s.descripcion,
                              precio: s.precio,
                              duracionMinutos: s.duracionMinutos,
                              activo: !s.activo,
                              createdAt: s.createdAt,
                            ),
                          );
                          ref.invalidate(serviciosAdminProvider);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/servicios/nuevo'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
