import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/barbero.dart';
import '../repositories/barbero_repository.dart';
import 'auth_provider.dart';

final barberoRepositoryProvider = Provider<BarberoRepository>((ref) {
  return BarberoRepository(ref.watch(supabaseClientProvider));
});

final barberosProvider = FutureProvider.autoDispose<List<Barbero>>((ref) async {
  final barberiaId = ref.watch(barberiaIdProvider);
  if (barberiaId == null) return [];
  return ref.read(barberoRepositoryProvider).getAll(barberiaId);
});
