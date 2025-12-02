import 'package:flutter/foundation.dart';
import '../models/usuario_model.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // Estado del usuario actual
  Usuario? _currentUser;

  // Estados de carga
  bool _isLoading = false;
  bool _isAuthenticating = false;

  // Mensajes de error
  String? _errorMessage;
  String? _successMessage;

  // Getters
  Usuario? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticating => _isAuthenticating;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isNegocio => _currentUser?.isNegocio ?? false;
  bool get isCliente => _currentUser?.isCliente ?? false;

  AuthViewModel() {
    _initializeAuth();
  }

  /// Inicializar y verificar si hay sesión activa
  Future<void> _initializeAuth() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.getCurrentUser();
      _currentUser = user;
    } catch (e) {
      _currentUser = null;
      debugPrint('Error al inicializar auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registrar nuevo usuario
  Future<bool> signUp({
    required String email,
    required String password,
    required String nombre,
    required String rol,
  }) async {
    try {
      _clearMessages();
      _isAuthenticating = true;
      notifyListeners();

      final user = await _authService.signUp(
        email: email,
        password: password,
        nombre: nombre,
        rol: rol,
      );

      if (user != null) {
        _currentUser = user;
        _successMessage = 'Registro exitoso. Bienvenido, ${user.nombre}!';
        _isAuthenticating = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'No se pudo completar el registro';
        _isAuthenticating = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _currentUser = null;
      _isAuthenticating = false;
      notifyListeners();
      return false;
    }
  }

  /// Iniciar sesión
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _clearMessages();
      _isAuthenticating = true;
      notifyListeners();

      final user = await _authService.signIn(
        email: email,
        password: password,
      );

      if (user != null) {
        _currentUser = user;
        _successMessage = 'Bienvenido de nuevo, ${user.nombre}!';
        _isAuthenticating = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Credenciales inválidas';
        _isAuthenticating = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _currentUser = null;
      _isAuthenticating = false;
      notifyListeners();
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();

      _currentUser = null;
      _successMessage = 'Sesión cerrada correctamente';
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recuperar contraseña
  Future<bool> resetPassword(String email) async {
    try {
      _clearMessages();
      _isLoading = true;
      notifyListeners();

      await _authService.resetPassword(email);

      _successMessage = 'Se ha enviado un email de recuperación a $email';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualizar perfil
  Future<bool> updateProfile({String? nombre}) async {
    if (_currentUser == null) return false;

    try {
      _clearMessages();
      _isLoading = true;
      notifyListeners();

      final updatedUser = await _authService.updateProfile(
        userId: _currentUser!.id,
        nombre: nombre,
      );

      if (updatedUser != null) {
        _currentUser = updatedUser;
        _successMessage = 'Perfil actualizado correctamente';
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verificar si email existe
  Future<bool> emailExists(String email) async {
    try {
      return await _authService.emailExists(email);
    } catch (e) {
      return false;
    }
  }

  /// Limpiar mensajes de error y éxito
  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  /// Limpiar mensaje de error manualmente (desde la UI)
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpiar mensaje de éxito manualmente (desde la UI)
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  /// Parsear mensaje de error para hacerlo más amigable
  String _parseErrorMessage(String error) {
    // Limpiar el mensaje de "Exception: "
    error = error.replaceAll('Exception: ', '');

    // Mensajes comunes de Supabase
    if (error.contains('Invalid login credentials')) {
      return 'Email o contraseña incorrectos';
    }
    if (error.contains('Email not confirmed')) {
      return 'Por favor confirma tu email antes de iniciar sesión';
    }
    if (error.contains('User already registered')) {
      return 'Este email ya está registrado';
    }
    if (error.contains('Password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (error.contains('Unable to validate email address')) {
      return 'Email inválido';
    }
    if (error.contains('Network request failed')) {
      return 'Sin conexión a internet. Verifica tu conexión';
    }

    // Si no es un error conocido, retornar el mensaje original
    return error;
  }

  @override
  void dispose() {
    // Cleanup si es necesario
    super.dispose();
  }
}