import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/visitas_provider.dart';

class VisitasListScreen extends ConsumerWidget {
  const VisitasListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitasAsync = ref.watch(visitasPorBarberiaProvider);
    final currency = NumberFormat.currency(locale: 'es_CL', symbol: '\$');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Historial de Visitas', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: visitasAsync.when(
        data: (visitas) {
          if (visitas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cut_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No hay visitas registradas', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visitas.length,
            itemBuilder: (context, index) {
              final v = visitas[index];
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
                    child: Icon(Icons.cut, size: 20, color: Colors.amber.shade700),
                  ),
                  title: Text(v.servicio, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(dateFormat.format(v.fecha.toLocal()), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(currency.format(v.monto), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('${v.puntosOtorgados} pts', style: TextStyle(color: Colors.amber.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
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
        onPressed: () => context.push('/visitas/nueva'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
