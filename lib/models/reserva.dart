import 'package:equatable/equatable.dart';

class Reserva extends Equatable {
  final String id;
  final String clienteId;
  final String? barberoId;
  final DateTime fecha;
  final String hora;
  final String servicio;
  final String estado;
  final String? notas;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? clienteNombre;
  final String? clienteTelefono;

  const Reserva({
    required this.id,
    required this.clienteId,
    this.barberoId,
    required this.fecha,
    required this.hora,
    required this.servicio,
    this.estado = 'solicitada',
    this.notas,
    required this.createdAt,
    required this.updatedAt,
    this.clienteNombre,
    this.clienteTelefono,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    final clientes = json['clientes'] as Map<String, dynamic>?;
    return Reserva(
      id: json['id'] as String,
      clienteId: json['cliente_id'] as String,
      barberoId: json['barbero_id'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
      hora: json['hora'] as String,
      servicio: json['servicio'] as String,
      estado: json['estado'] as String? ?? 'solicitada',
      notas: json['notas'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      clienteNombre: clientes?['nombre'] as String?,
      clienteTelefono: clientes?['telefono'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson({String? estadoOverride}) => {
        'cliente_id': clienteId,
        'barbero_id': barberoId,
        'fecha': fecha.toIso8601String().split('T').first,
        'hora': hora,
        'servicio': servicio,
        'estado': estadoOverride ?? estado,
        'notas': notas,
      };

  Reserva copyWith({
    String? id,
    String? clienteId,
    String? barberoId,
    DateTime? fecha,
    String? hora,
    String? servicio,
    String? estado,
    String? notas,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? clienteNombre,
    String? clienteTelefono,
  }) {
    return Reserva(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      barberoId: barberoId ?? this.barberoId,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      servicio: servicio ?? this.servicio,
      estado: estado ?? this.estado,
      notas: notas ?? this.notas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteTelefono: clienteTelefono ?? this.clienteTelefono,
    );
  }

  @override
  List<Object?> get props => [id, clienteId, fecha, hora, estado];
}
