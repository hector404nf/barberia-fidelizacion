import 'package:flutter/material.dart';

class EstadoChip extends StatelessWidget {
  final String estado;
  const EstadoChip({super.key, required this.estado});

  Color _color(BuildContext context) {
    return switch (estado.toLowerCase()) {
      'nuevo' => Colors.blue,
      'activo' => Colors.green,
      'vip' => Colors.amber.shade700,
      'inactivo' => Colors.grey,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        estado.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: _color(context),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
