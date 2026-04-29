import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/visita.dart';
import '../repositories/visita_repository.dart';
import 'auth_provider.dart';

final visitaRepositoryProvider = Provider<VisitaRepository>((ref) {
  return VisitaRepository(ref.watch(supabaseClientProvider));
});

final visitasPorBarberiaProvider = FutureProvider.autoDispose<List<Visita>>((ref) async {
  final barberiaId = ref.watch(barberiaIdProvider);
  if (barberiaId == null) return [];
  return ref.read(visitaRepositoryProvider).getByBarberia(barberiaId);
});

final visitasPorClienteProvider = FutureProvider.autoDispose.family<List<Visita>, String>((ref, clienteId) async {
  return ref.read(visitaRepositoryProvider).getByCliente(clienteId);
});
