import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NuevaVisitaScreen extends ConsumerStatefulWidget {
  const NuevaVisitaScreen({super.key});

  @override
  ConsumerState<NuevaVisitaScreen> createState() => _NuevaVisitaScreenState();
}

class _NuevaVisitaScreenState extends ConsumerState<NuevaVisitaScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Visita')),
      body: const Center(child: Text('Formulario de nueva visita')),
    );
  }
}
