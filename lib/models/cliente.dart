import 'package:equatable/equatable.dart';

class Cliente extends Equatable {
  final String id;
  final String barberiaId;
  final String nombre;
  final String telefono;
  final DateTime? fechaNacimiento;
  final String? barberoFavoritoId;
  final String estado;
  final int? frecuenciaVisitas;
  final DateTime? ultimaVisita;
  final int totalVisitas;
  final DateTime createdAt;

  const Cliente({
    required this.id,
    required this.barberiaId,
    required this.nombre,
    required this.telefono,
    this.fechaNacimiento,
    this.barberoFavoritoId,
    this.estado = 'nuevo',
    this.frecuenciaVisitas,
    this.ultimaVisita,
    this.totalVisitas = 0,
    required this.createdAt,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as String,
      barberiaId: json['barberia_id'] as String,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String,
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.parse(json['fecha_nacimiento'] as String)
          : null,
      barberoFavoritoId: json['barbero_favorito_id'] as String?,
      estado: json['estado'] as String? ?? 'nuevo',
      frecuenciaVisitas: json['frecuencia_visitas'] as int?,
      ultimaVisita: json['ultima_visita'] != null
          ? DateTime.parse(json['ultima_visita'] as String)
          : null,
      totalVisitas: json['total_visitas'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'barberia_id': barberiaId,
        'nombre': nombre,
        'telefono': telefono,
        'fecha_nacimiento': fechaNacimiento?.toIso8601String().split('T').first,
        'barbero_favorito_id': barberoFavoritoId,
        'estado': estado,
        'frecuencia_visitas': frecuenciaVisitas,
        'ultima_visita': ultimaVisita?.toIso8601String(),
        'total_visitas': totalVisitas,
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toInsertJson() => {
        'barberia_id': barberiaId,
        'nombre': nombre,
        'telefono': telefono,
        'fecha_nacimiento': fechaNacimiento?.toIso8601String().split('T').first,
        'barbero_favorito_id': barberoFavoritoId,
      };

  Cliente copyWith({
    String? id,
    String? barberiaId,
    String? nombre,
    String? telefono,
    DateTime? fechaNacimiento,
    String? barberoFavoritoId,
    String? estado,
    int? frecuenciaVisitas,
    DateTime? ultimaVisita,
    int? totalVisitas,
    DateTime? createdAt,
  }) {
    return Cliente(
      id: id ?? this.id,
      barberiaId: barberiaId ?? this.barberiaId,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      barberoFavoritoId: barberoFavoritoId ?? this.barberoFavoritoId,
      estado: estado ?? this.estado,
      frecuenciaVisitas: frecuenciaVisitas ?? this.frecuenciaVisitas,
      ultimaVisita: ultimaVisita ?? this.ultimaVisita,
      totalVisitas: totalVisitas ?? this.totalVisitas,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, nombre, telefono, estado, totalVisitas];
}
