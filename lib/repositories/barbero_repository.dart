import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/barbero.dart';

class BarberoRepository {
  final SupabaseClient _client;
  BarberoRepository(this._client);

  Future<List<Barbero>> getAll(String barberiaId) async {
    final response = await _client
        .from('barberos')
        .select()
        .eq('barberia_id', barberiaId)
        .eq('activo', true)
        .order('nombre');
    return (response as List).map((e) => Barbero.fromJson(e)).toList();
  }

  Future<List<Barbero>> getAllIncludingInactive(String barberiaId) async {
    final response = await _client
        .from('barberos')
        .select()
        .eq('barberia_id', barberiaId)
        .order('nombre');
    return (response as List).map((e) => Barbero.fromJson(e)).toList();
  }
}
