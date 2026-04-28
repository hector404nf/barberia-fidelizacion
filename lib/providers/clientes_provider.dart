import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cliente.dart';
import '../repositories/cliente_repository.dart';
import 'auth_provider.dart';

final clienteRepositoryProvider = Provider<ClienteRepository>((ref) {
  return ClienteRepository(ref.watch(supabaseClientProvider));
});

final clientesProvider = FutureProvider.autoDispose<List<Cliente>>((ref) async {
  final barberiaId = ref.watch(barberiaIdProvider);
  if (barberiaId == null) return [];
  return ref.read(clienteRepositoryProvider).getAll(barberiaId);
});

final clienteSearchProvider = StateProvider<String>((ref) => '');

final clientesFiltradosProvider = Provider.autoDispose<AsyncValue<List<Cliente>>>((ref) {
  final clientesAsync = ref.watch(clientesProvider);
  final query = ref.watch(clienteSearchProvider);

  if (query.isEmpty) return clientesAsync;

  return clientesAsync.when(
    data: (lista) => AsyncValue.data(
      lista.where((c) =>
        c.nombre.toLowerCase().contains(query.toLowerCase()) ||
        c.telefono.contains(query)
      ).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

final clienteDetailProvider = FutureProvider.autoDispose.family<Cliente?, String>((ref, id) async {
  return ref.read(clienteRepositoryProvider).getById(id);
});
