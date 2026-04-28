import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NuevaReservaScreen extends ConsumerWidget {
  const NuevaReservaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Reserva')),
      body: const Center(child: Text('Formulario de nueva reserva')),
    );
  }
}
