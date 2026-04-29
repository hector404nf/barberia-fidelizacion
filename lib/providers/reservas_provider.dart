import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reserva.dart';
import '../repositories/reserva_repository.dart';
import 'auth_provider.dart';

final reservaRepositoryProvider = Provider<ReservaRepository>((ref) {
  return ReservaRepository(ref.watch(supabaseClientProvider));
});

final reservasPorFechaProvider = FutureProvider.autoDispose.family<List<Reserva>, DateTime>((ref, fecha) async {
  final barberiaId = ref.watch(barberiaIdProvider);
  if (barberiaId == null) return [];
  return ref.read(reservaRepositoryProvider).getByFecha(barberiaId, fecha);
});
