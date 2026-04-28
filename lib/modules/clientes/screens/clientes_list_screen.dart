import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/clientes_provider.dart';
import '../../../widgets/estado_chip.dart';

class ClientesListScreen extends ConsumerWidget {
  const ClientesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientesAsync = ref.watch(clientesFiltradosProvider);
    final searchController = TextEditingController(text: ref.watch(clienteSearchProvider));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o teléfono...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          ref.read(clienteSearchProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) => ref.read(clienteSearchProvider.notifier).state = value,
            ),
          ),
        ),
      ),
      body: clientesAsync.when(
        data: (clientes) {
          if (clientes.isEmpty) {
            return const Center(child: Text('No hay clientes'));
          }
          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final c = clientes[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(c.nombre.substring(0, 1).toUpperCase()),
                ),
                title: Text(c.nombre),
                subtitle: Text(c.telefono),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EstadoChip(estado: c.estado),
                    const SizedBox(width: 8),
                    if (c.totalVisitas > 0)
                      Text('${c.totalVisitas} visitas', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                onTap: () => context.push('/clientes/${c.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/clientes/nuevo'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
