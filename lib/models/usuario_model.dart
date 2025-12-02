import 'package:uuid/uuid.dart';

class Usuario {
  final String id;
  final String email;
  final String nombre;
  final String rol; // 'negocio' o 'cliente'
  final DateTime createdAt;

  Usuario({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
    required this.createdAt,
  });

  // Constructor vacío para casos donde no hay usuario
  Usuario.empty()
      : id = '',
        email = '',
        nombre = '',
        rol = '',
        createdAt = DateTime.now();

  // Crear Usuario desde JSON (Supabase)
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      email: json['email'] as String,
      nombre: json['nombre'] as String,
      rol: json['rol'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convertir Usuario a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'rol': rol,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Crear Usuario para inserción en BD (sin id ni created_at)
  Map<String, dynamic> toInsert() {
    return {
      'email': email,
      'nombre': nombre,
      'rol': rol,
    };
  }

  // Verificar si es negocio
  bool get isNegocio => rol == 'negocio';

  // Verificar si es cliente
  bool get isCliente => rol == 'cliente';

  // CopyWith para crear copias modificadas
  Usuario copyWith({
    String? id,
    String? email,
    String? nombre,
    String? rol,
    DateTime? createdAt,
  }) {
    return Usuario(
      id: id ?? this.id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Usuario(id: $id, email: $email, nombre: $nombre, rol: $rol)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Usuario &&
        other.id == id &&
        other.email == email &&
        other.nombre == nombre &&
        other.rol == rol;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    email.hashCode ^
    nombre.hashCode ^
    rol.hashCode ^
    createdAt.hashCode;
  }
}