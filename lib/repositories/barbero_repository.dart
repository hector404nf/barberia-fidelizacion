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

  Future<Barbero> create(Barbero barbero) async {
    final response = await _client
        .from('barberos')
        .insert(barbero.toInsertJson())
        .select()
        .single();
    return Barbero.fromJson(response);
  }

  Future<Barbero> update(Barbero barbero) async {
    final response = await _client
        .from('barberos')
        .update({
          'nombre': barbero.nombre,
          'especialidad': barbero.especialidad,
          'foto_url': barbero.fotoUrl,
          'activo': barbero.activo,
        })
        .eq('id', barbero.id)
        .select()
        .single();
    return Barbero.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _client.from('barberos').update({'activo': false}).eq('id', id);
  }
}
