import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecompensasScreen extends ConsumerWidget {
  const RecompensasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recompensas')),
      body: const Center(child: Text('Catálogo de recompensas')),
    );
  }
}
