import '../constants/app_constants.dart';

class Validators {
  // Validar email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido';
    }

    return null;
  }

  // Validar password
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'La contraseña debe tener al menos ${AppConstants.minPasswordLength} caracteres';
    }

    return null;
  }

  // Validar nombre
  static String? nombre(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }

    if (value.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }

    return null;
  }

  // Validar precio
  static String? precio(String? value) {
    if (value == null || value.isEmpty) {
      return 'El precio es requerido';
    }

    final precio = double.tryParse(value);
    if (precio == null) {
      return 'Ingresa un precio válido';
    }

    if (precio <= 0) {
      return 'El precio debe ser mayor a 0';
    }

    return null;
  }

  // Validar descripción
  static String? descripcion(String? value) {
    if (value == null || value.isEmpty) {
      return 'La descripción es requerida';
    }

    if (value.length < 10) {
      return 'La descripción debe tener al menos 10 caracteres';
    }

    return null;
  }

  // Validar cantidad
  static String? cantidad(String? value) {
    if (value == null || value.isEmpty) {
      return 'La cantidad es requerida';
    }

    final cantidad = int.tryParse(value);
    if (cantidad == null) {
      return 'Ingresa una cantidad válida';
    }

    if (cantidad <= 0) {
      return 'La cantidad debe ser mayor a 0';
    }

    return null;
  }
}