import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

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
  return profileAsync.whenOrNull(data: (p) => p?.barberiaId);
});
