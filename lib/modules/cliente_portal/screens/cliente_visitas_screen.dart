import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/visitas_provider.dart';

class ClienteVisitasScreen extends ConsumerWidget {
  const ClienteVisitasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clienteAsync = ref.watch(clienteAuthProvider);
    final currency = NumberFormat.currency(locale: 'es_CL', symbol: '\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Visitas')),
      body: clienteAsync.when(
        data: (cliente) {
          if (cliente == null) {
            return const Center(child: Text('No se encontró tu perfil'));
          }

          final visitasAsync = ref.watch(visitasPorClienteProvider(cliente.id));

          return visitasAsync.when(
            data: (visitas) {
              if (visitas.isEmpty) {
                return const Center(child: Text('Aún no tienes visitas registradas'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: visitas.length,
                itemBuilder: (context, index) {
                  final v = visitas[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.cut, size: 18),
                      ),
                      title: Text(v.servicio),
                      subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(v.fecha.toLocal())),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(currency.format(v.monto),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('+${v.puntosOtorgados} pts',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.secondary,
                              )),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
