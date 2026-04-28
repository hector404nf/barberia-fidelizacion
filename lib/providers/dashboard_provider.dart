import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/dashboard_repository.dart';
import 'auth_provider.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(supabaseClientProvider));
});

final estadisticasProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final barberiaId = ref.watch(barberiaIdProvider);
  if (barberiaId == null) return {};
  return ref.read(dashboardRepositoryProvider).getEstadisticas(barberiaId);
});

final rankingBarberosProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final barberiaId = ref.watch(barberiaIdProvider);
  if (barberiaId == null) return [];
  return ref.read(dashboardRepositoryProvider).getRankingBarberos(barberiaId);
});
