import 'package:equatable/equatable.dart';

class Servicio extends Equatable {
  final String id;
  final String barberiaId;
  final String nombre;
  final String? descripcion;
  final double precio;
  final int duracionMinutos;
  final bool activo;
  final DateTime createdAt;

  const Servicio({
    required this.id,
    required this.barberiaId,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.duracionMinutos = 30,
    this.activo = true,
    required this.createdAt,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      id: json['id'] as String,
      barberiaId: json['barberia_id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      precio: (json['precio'] as num).toDouble(),
      duracionMinutos: json['duracion_minutos'] as int? ?? 30,
      activo: json['activo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'barberia_id': barberiaId,
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'duracion_minutos': duracionMinutos,
      };

  @override
  List<Object?> get props => [id, nombre, precio, activo];
}
