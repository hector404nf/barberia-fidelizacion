import 'package:equatable/equatable.dart';

class Recompensa extends Equatable {
  final String id;
  final String barberiaId;
  final String nombre;
  final int puntosRequeridos;
  final String tipo;
  final String? valor;
  final bool activa;
  final bool stockLimitado;
  final int? stockActual;
  final DateTime createdAt;

  const Recompensa({
    required this.id,
    required this.barberiaId,
    required this.nombre,
    required this.puntosRequeridos,
    this.tipo = 'servicio',
    this.valor,
    this.activa = true,
    this.stockLimitado = false,
    this.stockActual,
    required this.createdAt,
  });

  factory Recompensa.fromJson(Map<String, dynamic> json) {
    return Recompensa(
      id: json['id'] as String,
      barberiaId: json['barberia_id'] as String,
      nombre: json['nombre'] as String,
      puntosRequeridos: json['puntos_requeridos'] as int,
      tipo: json['tipo'] as String? ?? 'servicio',
      valor: json['valor'] as String?,
      activa: json['activa'] as bool? ?? true,
      stockLimitado: json['stock_limitado'] as bool? ?? false,
      stockActual: json['stock_actual'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'barberia_id': barberiaId,
        'nombre': nombre,
        'puntos_requeridos': puntosRequeridos,
        'tipo': tipo,
        'valor': valor,
        'stock_limitado': stockLimitado,
        'stock_actual': stockActual,
      };

  Recompensa copyWith({
    String? id,
    String? barberiaId,
    String? nombre,
    int? puntosRequeridos,
    String? tipo,
    String? valor,
    bool? activa,
    bool? stockLimitado,
    int? stockActual,
    DateTime? createdAt,
  }) {
    return Recompensa(
      id: id ?? this.id,
      barberiaId: barberiaId ?? this.barberiaId,
      nombre: nombre ?? this.nombre,
      puntosRequeridos: puntosRequeridos ?? this.puntosRequeridos,
      tipo: tipo ?? this.tipo,
      valor: valor ?? this.valor,
      activa: activa ?? this.activa,
      stockLimitado: stockLimitado ?? this.stockLimitado,
      stockActual: stockActual ?? this.stockActual,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, nombre, puntosRequeridos, activa];
}
