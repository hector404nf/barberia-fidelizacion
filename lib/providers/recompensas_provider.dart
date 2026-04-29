import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recompensa.dart';
import '../repositories/recompensa_repository.dart';
import 'auth_provider.dart';

final recompensaRepositoryProvider = Provider<RecompensaRepository>((ref) {
  return RecompensaRepository(ref.watch(supabaseClientProvider));
});

final recompensasProvider = FutureProvider.autoDispose<List<Recompensa>>((ref) async {
  final barberiaId = ref.watch(barberiaIdProvider);
  if (barberiaId == null) return [];
  return ref.read(recompensaRepositoryProvider).getAll(barberiaId);
});

final recompensasAdminProvider = FutureProvider.autoDispose<List<Recompensa>>((ref) async {
  final barberiaId = ref.watch(barberiaIdProvider);
  if (barberiaId == null) return [];
  return ref.read(recompensaRepositoryProvider).getAllIncludingInactive(barberiaId);
});
