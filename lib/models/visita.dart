import 'package:equatable/equatable.dart';

class Visita extends Equatable {
  final String id;
  final String clienteId;
  final String? barberoId;
  final DateTime fecha;
  final String servicio;
  final double monto;
  final int puntosOtorgados;
  final String? notas;
  final DateTime createdAt;

  const Visita({
    required this.id,
    required this.clienteId,
    this.barberoId,
    required this.fecha,
    required this.servicio,
    required this.monto,
    this.puntosOtorgados = 0,
    this.notas,
    required this.createdAt,
  });

  factory Visita.fromJson(Map<String, dynamic> json) {
    return Visita(
      id: json['id'] as String,
      clienteId: json['cliente_id'] as String,
      barberoId: json['barbero_id'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
      servicio: json['servicio'] as String,
      monto: (json['monto'] as num).toDouble(),
      puntosOtorgados: json['puntos_otorgados'] as int? ?? 0,
      notas: json['notas'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'cliente_id': clienteId,
        'barbero_id': barberoId,
        'servicio': servicio,
        'monto': monto,
        'notas': notas,
      };

  @override
  List<Object?> get props => [id, clienteId, fecha, servicio, monto];
}
