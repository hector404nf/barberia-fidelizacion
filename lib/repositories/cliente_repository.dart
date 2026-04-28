import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/cliente.dart';

class ClienteRepository {
  final SupabaseClient _client;
  ClienteRepository(this._client);

  Future<List<Cliente>> getAll(String barberiaId) async {
    final response = await _client
        .from('clientes')
        .select()
        .eq('barberia_id', barberiaId)
        .order('nombre');
    return (response as List).map((e) => Cliente.fromJson(e)).toList();
  }

  Future<Cliente?> getById(String id) async {
    final response = await _client
        .from('clientes')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Cliente.fromJson(response);
  }

  Future<Cliente?> getByTelefono(String barberiaId, String telefono) async {
    final response = await _client
        .from('clientes')
        .select()
        .eq('barberia_id', barberiaId)
        .eq('telefono', telefono)
        .maybeSingle();
    if (response == null) return null;
    return Cliente.fromJson(response);
  }

  Future<Cliente> create(Cliente cliente) async {
    final response = await _client
        .from('clientes')
        .insert(cliente.toInsertJson())
        .select()
        .single();
    return Cliente.fromJson(response);
  }

  Future<Cliente> update(Cliente cliente) async {
    final response = await _client
        .from('clientes')
        .update({
          'nombre': cliente.nombre,
          'telefono': cliente.telefono,
          'fecha_nacimiento': cliente.fechaNacimiento?.toIso8601String().split('T').first,
          'barbero_favorito_id': cliente.barberoFavoritoId,
        })
        .eq('id', cliente.id)
        .select()
        .single();
    return Cliente.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _client.from('clientes').update({'estado': 'inactivo'}).eq('id', id);
  }

  Future<List<Cliente>> search(String barberiaId, String query) async {
    final response = await _client
        .from('clientes')
        .select()
        .eq('barberia_id', barberiaId)
        .or('nombre.ilike.%$query%,telefono.ilike.%$query%')
        .order('nombre');
    return (response as List).map((e) => Cliente.fromJson(e)).toList();
  }
}
