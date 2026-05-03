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
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Servicios', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: serviciosAsync.when(
        data: (servicios) {
          if (servicios.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.spa_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No hay servicios configurados', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: servicios.length,
            itemBuilder: (context, index) {
              final s = servicios[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.spa, size: 20, color: Colors.amber.shade700),
                  ),
                  title: Text(
                    s.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: s.activo ? null : TextDecoration.lineThrough,
                      color: s.activo ? Colors.black87 : Colors.grey.shade500,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (s.descripcion != null) Text(s.descripcion!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      Text('${s.duracionMinutos} min · ${currency.format(s.precio)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
        backgroundColor: Colors.amber.shade600,
        onPressed: () => context.push('/servicios/nuevo'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
