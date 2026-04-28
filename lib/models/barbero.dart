import 'package:equatable/equatable.dart';

class Barbero extends Equatable {
  final String id;
  final String barberiaId;
  final String nombre;
  final String? especialidad;
  final String? fotoUrl;
  final bool activo;
  final DateTime createdAt;

  const Barbero({
    required this.id,
    required this.barberiaId,
    required this.nombre,
    this.especialidad,
    this.fotoUrl,
    this.activo = true,
    required this.createdAt,
  });

  factory Barbero.fromJson(Map<String, dynamic> json) {
    return Barbero(
      id: json['id'] as String,
      barberiaId: json['barberia_id'] as String,
      nombre: json['nombre'] as String,
      especialidad: json['especialidad'] as String?,
      fotoUrl: json['foto_url'] as String?,
      activo: json['activo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'barberia_id': barberiaId,
        'nombre': nombre,
        'especialidad': especialidad,
        'foto_url': fotoUrl,
      };

  @override
  List<Object?> get props => [id, nombre, especialidad, activo];
}
