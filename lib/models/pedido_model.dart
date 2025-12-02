import '../core/constants/app_constants.dart';

class Pedido {
  final String id;
  final String clienteId;
  final String negocioId;
  final String platoId;
  final int cantidad;
  final String estado;
  final double total;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Datos adicionales (joins)
  final String? clienteNombre;
  final String? negocioNombre;
  final String? platoNombre;
  final String? platoImagenUrl;
  final double? platoPrecio;

  Pedido({
    required this.id,
    required this.clienteId,
    required this.negocioId,
    required this.platoId,
    required this.cantidad,
    required this.estado,
    required this.total,
    required this.createdAt,
    required this.updatedAt,
    this.clienteNombre,
    this.negocioNombre,
    this.platoNombre,
    this.platoImagenUrl,
    this.platoPrecio,
  });

  // Constructor vacío
  Pedido.empty()
      : id = '',
        clienteId = '',
        negocioId = '',
        platoId = '',
        cantidad = 0,
        estado = AppConstants.estadoPendiente,
        total = 0.0,
        createdAt = DateTime.now(),
        updatedAt = DateTime.now(),
        clienteNombre = null,
        negocioNombre = null,
        platoNombre = null,
        platoImagenUrl = null,
        platoPrecio = null;

  // Crear Pedido desde JSON
  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: json['id'] as String,
      clienteId: json['cliente_id'] as String,
      negocioId: json['negocio_id'] as String,
      platoId: json['plato_id'] as String,
      cantidad: json['cantidad'] as int,
      estado: json['estado'] as String,
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      clienteNombre: json['cliente_nombre'] as String?,
      negocioNombre: json['negocio_nombre'] as String?,
      platoNombre: json['plato_nombre'] as String?,
      platoImagenUrl: json['plato_imagen_url'] as String?,
      platoPrecio: json['plato_precio'] != null
          ? (json['plato_precio'] as num).toDouble()
          : null,
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'negocio_id': negocioId,
      'plato_id': platoId,
      'cantidad': cantidad,
      'estado': estado,
      'total': total,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Para insertar (sin id, created_at, updated_at)
  Map<String, dynamic> toInsert() {
    return {
      'cliente_id': clienteId,
      'negocio_id': negocioId,
      'plato_id': platoId,
      'cantidad': cantidad,
      'estado': estado,
      'total': total,
    };
  }

  // Para actualizar (solo estado)
  Map<String, dynamic> toUpdate() {
    return {
      'estado': estado,
    };
  }

  // Getters útiles
  String get totalFormateado => '${AppConstants.currencySymbol} ${total.toStringAsFixed(2)}';

  bool get isPendiente => estado == AppConstants.estadoPendiente;
  bool get isEnPreparacion => estado == AppConstants.estadoEnPreparacion;
  bool get isListo => estado == AppConstants.estadoListo;
  bool get isEntregado => estado == AppConstants.estadoEntregado;
  bool get isCancelado => estado == AppConstants.estadoCancelado;

  bool get isActivo => !isEntregado && !isCancelado;

  // CopyWith
  Pedido copyWith({
    String? id,
    String? clienteId,
    String? negocioId,
    String? platoId,
    int? cantidad,
    String? estado,
    double? total,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? clienteNombre,
    String? negocioNombre,
    String? platoNombre,
    String? platoImagenUrl,
    double? platoPrecio,
  }) {
    return Pedido(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      negocioId: negocioId ?? this.negocioId,
      platoId: platoId ?? this.platoId,
      cantidad: cantidad ?? this.cantidad,
      estado: estado ?? this.estado,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      negocioNombre: negocioNombre ?? this.negocioNombre,
      platoNombre: platoNombre ?? this.platoNombre,
      platoImagenUrl: platoImagenUrl ?? this.platoImagenUrl,
      platoPrecio: platoPrecio ?? this.platoPrecio,
    );
  }

  @override
  String toString() {
    return 'Pedido(id: $id, plato: $platoNombre, cantidad: $cantidad, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pedido && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}