import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

// Credenciales de Supabase
// Para desarrollo local, compila con:
// flutter run --dart-define=SUPABASE_URL=https://tu-proyecto.supabase.co --dart-define=SUPABASE_ANON_KEY=tu-anon-key
// Para Vercel, configura estas variables en el dashboard del proyecto.
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  assert(
    _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty,
    'Faltan las variables SUPABASE_URL y SUPABASE_ANON_KEY. '
    'Compila con --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
  );

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  runApp(const ProviderScope(child: BarberiaApp()));
}
