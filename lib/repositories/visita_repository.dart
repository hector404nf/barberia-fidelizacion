import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/visita.dart';

class VisitaRepository {
  final SupabaseClient _client;
  VisitaRepository(this._client);

  Future<List<Visita>> getByCliente(String clienteId) async {
    final response = await _client
        .from('visitas')
        .select()
        .eq('cliente_id', clienteId)
        .order('fecha', ascending: false);
    return (response as List).map((e) => Visita.fromJson(e)).toList();
  }

  Future<List<Visita>> getByBarberia(String barberiaId, {int limit = 100}) async {
    final response = await _client
        .from('visitas')
        .select(''', clientes!inner(nombre)')
        .eq('clientes.barberia_id', barberiaId)
        .order('fecha', ascending: false)
        .limit(limit);
    return (response as List).map((e) => Visita.fromJson(e)).toList();
  }

  Future<Visita> create(Visita visita) async {
    final response = await _client
        .from('visitas')
        .insert(visita.toInsertJson())
        .select()
        .single();
    return Visita.fromJson(response);
  }
}
