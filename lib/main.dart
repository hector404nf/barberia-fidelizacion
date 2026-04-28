import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

// Credenciales de Supabase (públicas, seguras en frontend)
const _supabaseUrl = 'https://gzrncvukxfaejcozffut.supabase.co';
const _supabaseAnonKey = 'sb_publishable_Pxw2qtWdfEhZVRpxYm861Q_gD6bLAeH';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  runApp(const ProviderScope(child: BarberiaApp()));
}
