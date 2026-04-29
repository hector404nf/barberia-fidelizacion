import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cliente.dart';
import '../models/profile.dart';

enum TipoUsuario { dueno, barbero, cliente, ninguno }

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentSessionProvider = Provider<Session?>((ref) {
  return Supabase.instance.client.auth.currentSession;
});

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

// --- STAFF (dueño/barbero) ---

final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final response = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  if (response == null) return null;
  return Profile.fromJson(response);
});

final esDuenoProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(profileProvider);
  return profileAsync.whenOrNull(data: (p) => p?.esDueno ?? false) ?? false;
});

final barberiaIdProvider = Provider<String?>((ref) {
  final profileAsync = ref.watch(profileProvider);
  final clienteAsync = ref.watch(clienteAuthProvider);

  // Prioridad: staff
  final barberiaIdStaff = profileAsync.whenOrNull(data: (p) => p?.barberiaId);
  if (barberiaIdStaff != null) return barberiaIdStaff;

  // Fallback: cliente
  return clienteAsync.whenOrNull(data: (c) => c?.barberiaId);
});

// --- CLIENTE ---

final clienteAuthProvider = FutureProvider<Cliente?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final response = await Supabase.instance.client
      .from('clientes')
      .select(''', puntos_cliente(puntos_actuales)')
      .eq('auth_user_id', user.id)
      .maybeSingle();

  if (response == null) return null;
  return Cliente.fromJson(response);
});

final clientePuntosProvider = FutureProvider<int>((ref) async {
  final clienteAsync = ref.watch(clienteAuthProvider);
  final cliente = clienteAsync.whenOrNull(data: (c) => c);
  if (cliente == null) return 0;

  final response = await Supabase.instance.client
      .from('puntos_cliente')
      .select('puntos_actuales')
      .eq('cliente_id', cliente.id)
      .maybeSingle();

  return (response?['puntos_actuales'] as int?) ?? 0;
});

// --- DETECCIÓN DE TIPO DE USUARIO ---

final tipoUsuarioProvider = Provider<TipoUsuario>((ref) {
  final profileAsync = ref.watch(profileProvider);
  final clienteAsync = ref.watch(clienteAuthProvider);

  final profile = profileAsync.whenOrNull(data: (p) => p);
  if (profile != null) {
    return profile.esDueno ? TipoUsuario.dueno : TipoUsuario.barbero;
  }

  final cliente = clienteAsync.whenOrNull(data: (c) => c);
  if (cliente != null) return TipoUsuario.cliente;

  return TipoUsuario.ninguno;
});

final esClienteProvider = Provider<bool>((ref) {
  return ref.watch(tipoUsuarioProvider) == TipoUsuario.cliente;
});

final esStaffProvider = Provider<bool>((ref) {
  final tipo = ref.watch(tipoUsuarioProvider);
  return tipo == TipoUsuario.dueno || tipo == TipoUsuario.barbero;
});
