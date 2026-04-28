import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/visita_repository.dart';
import 'auth_provider.dart';

final visitaRepositoryProvider = Provider<VisitaRepository>((ref) {
  return VisitaRepository(ref.watch(supabaseClientProvider));
});
