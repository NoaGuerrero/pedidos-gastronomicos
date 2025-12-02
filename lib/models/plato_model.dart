class Plato {
  final String id;
  final String negocioId;
  final String nombre;
  final String descripcion;
  final double precio;
  final String? imagenUrl;
  final String categoria;
  final bool disponible;
  final DateTime createdAt;

  Plato({
    required this.id,
    required this.negocioId,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    this.imagenUrl,
    required this.categoria,
    required this.disponible,
    required this.createdAt,
  });

  // Constructor vacío
  Plato.empty()
      : id = '',
        negocioId = '',
        nombre = '',
        descripcion = '',
        precio = 0.0,
        imagenUrl = null,
        categoria = '',
        disponible = true,
        createdAt = DateTime.now();

  // Crear Plato desde JSON (Supabase)
  factory Plato.fromJson(Map<String, dynamic> json) {
    return Plato(
      id: json['id'] as String,
      negocioId: json['negocio_id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      precio: (json['precio'] as num).toDouble(),
      imagenUrl: json['imagen_url'] as String?,
      categoria: json['categoria'] as String? ?? 'General',
      disponible: json['disponible'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convertir Plato a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'negocio_id': negocioId,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'imagen_url': imagenUrl,
      'categoria': categoria,
      'disponible': disponible,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Para insertar nuevo plato (sin id ni created_at)
  Map<String, dynamic> toInsert() {
    return {
      'negocio_id': negocioId,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'imagen_url': imagenUrl,
      'categoria': categoria,
      'disponible': disponible,
    };
  }

  // Para actualizar plato existente (sin id, negocio_id ni created_at)
  Map<String, dynamic> toUpdate() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'imagen_url': imagenUrl,
      'categoria': categoria,
      'disponible': disponible,
    };
  }

  // Precio formateado con moneda
  String get precioFormateado => 'Bs ${precio.toStringAsFixed(2)}';

  // Verificar si tiene imagen
  bool get tieneImagen => imagenUrl != null && imagenUrl!.isNotEmpty;

  // CopyWith para crear copias modificadas
  Plato copyWith({
    String? id,
    String? negocioId,
    String? nombre,
    String? descripcion,
    double? precio,
    String? imagenUrl,
    String? categoria,
    bool? disponible,
    DateTime? createdAt,
  }) {
    return Plato(
      id: id ?? this.id,
      negocioId: negocioId ?? this.negocioId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      categoria: categoria ?? this.categoria,
      disponible: disponible ?? this.disponible,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Plato(id: $id, nombre: $nombre, precio: $precio, disponible: $disponible)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Plato &&
        other.id == id &&
        other.nombre == nombre &&
        other.precio == precio;
  }

  @override
  int get hashCode {
    return id.hashCode ^ nombre.hashCode ^ precio.hashCode;
  }
}