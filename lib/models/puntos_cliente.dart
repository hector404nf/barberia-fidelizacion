import 'package:equatable/equatable.dart';

class PuntosCliente extends Equatable {
  final String clienteId;
  final int puntosActuales;
  final int totalGanados;
  final int totalCanjeados;
  final DateTime updatedAt;

  const PuntosCliente({
    required this.clienteId,
    this.puntosActuales = 0,
    this.totalGanados = 0,
    this.totalCanjeados = 0,
    required this.updatedAt,
  });

  factory PuntosCliente.fromJson(Map<String, dynamic> json) {
    return PuntosCliente(
      clienteId: json['cliente_id'] as String,
      puntosActuales: json['puntos_actuales'] as int? ?? 0,
      totalGanados: json['total_ganados'] as int? ?? 0,
      totalCanjeados: json['total_canjeados'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [clienteId, puntosActuales];
}
