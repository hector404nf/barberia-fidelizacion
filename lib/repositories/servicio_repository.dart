import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/servicio.dart';

class ServicioRepository {
  final SupabaseClient _client;
  ServicioRepository(this._client);

  Future<List<Servicio>> getAll(String barberiaId) async {
    final response = await _client
        .from('servicios')
        .select()
        .eq('barberia_id', barberiaId)
        .eq('activo', true)
        .order('nombre');
    return (response as List).map((e) => Servicio.fromJson(e)).toList();
  }

  Future<List<Servicio>> getAllAdmin(String barberiaId) async {
    final response = await _client
        .from('servicios')
        .select()
        .eq('barberia_id', barberiaId)
        .order('nombre');
    return (response as List).map((e) => Servicio.fromJson(e)).toList();
  }

  Future<Servicio> create(Servicio servicio) async {
    final response = await _client
        .from('servicios')
        .insert(servicio.toInsertJson())
        .select()
        .single();
    return Servicio.fromJson(response);
  }

  Future<Servicio> update(Servicio servicio) async {
    final response = await _client
        .from('servicios')
        .update({
          'nombre': servicio.nombre,
          'descripcion': servicio.descripcion,
          'precio': servicio.precio,
          'duracion_minutos': servicio.duracionMinutos,
          'activo': servicio.activo,
        })
        .eq('id', servicio.id)
        .select()
        .single();
    return Servicio.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _client.from('servicios').update({'activo': false}).eq('id', id);
  }
}
