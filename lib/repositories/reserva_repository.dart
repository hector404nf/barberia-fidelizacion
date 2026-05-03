import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/reserva.dart';

class ReservaRepository {
  final SupabaseClient _client;
  ReservaRepository(this._client);

  Future<List<Reserva>> getByFecha(String barberiaId, DateTime fecha) async {
    final fechaStr = fecha.toIso8601String().split('T').first;
    final response = await _client
        .from('reservas')
        .select('*, clientes!inner(nombre, telefono, barberia_id)')
        .eq('clientes.barberia_id', barberiaId)
        .eq('fecha', fechaStr)
        .order('hora');
    return (response as List).map((e) => Reserva.fromJson(e)).toList();
  }

  Future<List<Reserva>> getByCliente(String clienteId) async {
    final response = await _client
        .from('reservas')
        .select('*')
        .eq('cliente_id', clienteId)
        .order('fecha', ascending: false)
        .order('hora');
    return (response as List).map((e) => Reserva.fromJson(e)).toList();
  }

  Future<List<Reserva>> getByBarbero(String barberoId, DateTime fecha) async {
    final fechaStr = fecha.toIso8601String().split('T').first;
    final response = await _client
        .from('reservas')
        .select('*, clientes(nombre)')
        .eq('barbero_id', barberoId)
        .eq('fecha', fechaStr)
        .order('hora');
    return (response as List).map((e) => Reserva.fromJson(e)).toList();
  }

  Future<Reserva> create(Reserva reserva, {String? estado}) async {
    final response = await _client
        .from('reservas')
        .insert(reserva.toInsertJson(estadoOverride: estado))
        .select()
        .single();
    return Reserva.fromJson(response);
  }

  Future<List<Reserva>> getSolicitudesPendientes(String barberiaId) async {
    // Obtener solicitudes con estado 'solicitada' o 'pendiente' (reservas viejas)
    final response = await _client
        .from('reservas')
        .select('*, clientes!inner(nombre, telefono, barberia_id)')
        .eq('clientes.barberia_id', barberiaId)
        .inFilter('estado', ['solicitada', 'pendiente'])
        .order('fecha')
        .order('hora');
    return (response as List).map((e) => Reserva.fromJson(e)).toList();
  }

  Future<Reserva> updateEstado(String id, String estado) async {
    final response = await _client
        .from('reservas')
        .update({'estado': estado})
        .eq('id', id)
        .select()
        .single();
    return Reserva.fromJson(response);
  }

  Stream<List<Reserva>> streamByFecha(String barberiaId, DateTime fecha) {
    final fechaStr = fecha.toIso8601String().split('T').first;
    return _client
        .from('reservas')
        .stream(primaryKey: ['id'])
        .eq('fecha', fechaStr)
        .map((data) => data.map((e) => Reserva.fromJson(e)).toList());
  }
}
