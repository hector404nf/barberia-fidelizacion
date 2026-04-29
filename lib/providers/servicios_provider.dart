import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/servicio.dart';
import '../repositories/servicio_repository.dart';
import 'auth_provider.dart';

final servicioRepositoryProvider = Provider<ServicioRepository>((ref) {
  return ServicioRepository(ref.watch(supabaseClientProvider));
});

final serviciosProvider = FutureProvider.autoDispose<List<Servicio>>((ref) async {
  final barberiaId = ref.watch(barberiaIdProvider);
  if (barberiaId == null) return [];
  return ref.read(servicioRepositoryProvider).getAll(barberiaId);
});

final serviciosAdminProvider = FutureProvider.autoDispose<List<Servicio>>((ref) async {
  final barberiaId = ref.watch(barberiaIdProvider);
  if (barberiaId == null) return [];
  return ref.read(servicioRepositoryProvider).getAllAdmin(barberiaId);
});
