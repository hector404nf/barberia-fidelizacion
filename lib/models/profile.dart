import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  final String id;
  final String? barberiaId;
  final String rol;
  final String nombre;
  final DateTime createdAt;

  const Profile({
    required this.id,
    this.barberiaId,
    this.rol = 'barbero',
    required this.nombre,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      barberiaId: json['barberia_id'] as String?,
      rol: json['rol'] as String? ?? 'barbero',
      nombre: json['nombre'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get esDueno => rol == 'dueño';

  @override
  List<Object?> get props => [id, barberiaId, rol, nombre];
}
