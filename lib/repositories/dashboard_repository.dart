import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardRepository {
  final SupabaseClient _client;
  DashboardRepository(this._client);

  Future<Map<String, dynamic>> getEstadisticas(String barberiaId, {DateTime? desde, DateTime? hasta}) async {
    final response = await _client.rpc('get_estadisticas', params: {
      'p_barberia_id': barberiaId,
      'p_fecha_desde': (desde ?? DateTime.now().subtract(const Duration(days: 30))).toIso8601String().split('T').first,
      'p_fecha_hasta': (hasta ?? DateTime.now()).toIso8601String().split('T').first,
    });
    return response as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getRankingBarberos(String barberiaId) async {
    final response = await _client.rpc('get_ranking_barberos', params: {
      'p_barberia_id': barberiaId,
    });
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getClientesInactivos(String barberiaId, {int dias = 30}) async {
    final response = await _client.rpc('get_clientes_inactivos', params: {
      'p_barberia_id': barberiaId,
      'p_dias': dias,
    });
    return (response as List).cast<Map<String, dynamic>>();
  }
}
