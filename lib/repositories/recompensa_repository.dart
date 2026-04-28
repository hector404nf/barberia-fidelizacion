import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/recompensa.dart';

class RecompensaRepository {
  final SupabaseClient _client;
  RecompensaRepository(this._client);

  Future<List<Recompensa>> getAll(String barberiaId) async {
    final response = await _client
        .from('recompensas')
        .select()
        .eq('barberia_id', barberiaId)
        .eq('activa', true)
        .order('puntos_requeridos');
    return (response as List).map((e) => Recompensa.fromJson(e)).toList();
  }

  Future<Recompensa> create(Recompensa recompensa) async {
    final response = await _client
        .from('recompensas')
        .insert(recompensa.toInsertJson())
        .select()
        .single();
    return Recompensa.fromJson(response);
  }

  Future<Recompensa> update(Recompensa recompensa) async {
    final response = await _client
        .from('recompensas')
        .update({
          'nombre': recompensa.nombre,
          'puntos_requeridos': recompensa.puntosRequeridos,
          'tipo': recompensa.tipo,
          'valor': recompensa.valor,
          'activa': recompensa.activa,
          'stock_limitado': recompensa.stockLimitado,
          'stock_actual': recompensa.stockActual,
        })
        .eq('id', recompensa.id)
        .select()
        .single();
    return Recompensa.fromJson(response);
  }
}
