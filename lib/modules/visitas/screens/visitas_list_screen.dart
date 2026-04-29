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
      appBar: AppBar(title: const Text('Historial de Visitas')),
      body: visitasAsync.when(
        data: (visitas) {
          if (visitas.isEmpty) {
            return const Center(child: Text('No hay visitas registradas'));
          }
          return ListView.builder(
            itemCount: visitas.length,
            itemBuilder: (context, index) {
              final v = visitas[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.cut, size: 18),
                ),
                title: Text(v.servicio),
                subtitle: Text(dateFormat.format(v.fecha.toLocal())),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(currency.format(v.monto),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                    Text('${v.puntosOtorgados} pts',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            )),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/visitas/nueva'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
