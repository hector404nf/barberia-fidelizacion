import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

final configPuntosProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final barberiaId = ref.watch(barberiaIdProvider);
  if (barberiaId == null) return {'por_visita': 10, 'por_monto': 1};

  final response = await ref.read(supabaseClientProvider)
      .from('barberias')
      .select('config_puntos')
      .eq('id', barberiaId)
      .single();

  return (response['config_puntos'] as Map<String, dynamic>?) ??
      {'por_visita': 10, 'por_monto': 1};
});
