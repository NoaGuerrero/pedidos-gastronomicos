import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../models/usuario_model.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseService.client;

  // Obtener usuario actual de auth
  User? get currentAuthUser => _supabase.auth.currentUser;

  // Stream de cambios de autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Verificar si hay sesión activa
  bool get isAuthenticated => currentAuthUser != null;

  /// Registrar nuevo usuario
  ///
  /// [email] - Email del usuario
  /// [password] - Contraseña
  /// [nombre] - Nombre completo
  /// [rol] - 'negocio' o 'cliente'
  ///
  /// Retorna el Usuario creado o null si falla
  Future<Usuario?> signUp({
    required String email,
    required String password,
    required String nombre,
    required String rol,
  }) async {
    try {
      // 1. Crear usuario en Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('No se pudo crear el usuario en Auth');
      }

      final authUserId = response.user!.id;

      // 2. Crear registro en tabla usuarios
      // Nota: Si tienes un trigger que auto-crea el usuario, este paso podría ser opcional
      // await _supabase.from(SupabaseConstants.tableUsuarios).insert({
      //   'id': authUserId,
      //   'email': email,
      //   'nombre': nombre,
      //   'rol': rol,
      // });

      // 3. Obtener el usuario creado
      final userData = await _supabase
          .from(SupabaseConstants.tableUsuarios)
          .select()
          .eq('id', authUserId)
          .single();

      return Usuario.fromJson(userData);
    } on AuthException catch (e) {
      throw Exception('Error de autenticación: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Error de base de datos: ${e.message}');
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    }
  }

  /// Iniciar sesión
  ///
  /// [email] - Email del usuario
  /// [password] - Contraseña
  ///
  /// Retorna el Usuario o null si falla
  Future<Usuario?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Autenticar con Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Credenciales inválidas');
      }

      final userId = response.user!.id;

      // 2. Obtener datos del usuario de la tabla usuarios
      final userData = await _supabase
          .from(SupabaseConstants.tableUsuarios)
          .select()
          .eq('id', userId)
          .single();

      return Usuario.fromJson(userData);
    } on AuthException catch (e) {
      throw Exception('Error de autenticación: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener datos del usuario: ${e.message}');
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Error al cerrar sesión: ${e.message}');
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// Obtener usuario actual completo (con datos de la tabla usuarios)
  Future<Usuario?> getCurrentUser() async {
    try {
      final authUser = currentAuthUser;
      if (authUser == null) return null;

      final userData = await _supabase
          .from(SupabaseConstants.tableUsuarios)
          .select()
          .eq('id', authUser.id)
          .single();

      return Usuario.fromJson(userData);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener usuario actual: ${e.message}');
    } catch (e) {
      throw Exception('Error al obtener usuario actual: $e');
    }
  }

  /// Verificar si el email ya está registrado
  Future<bool> emailExists(String email) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tableUsuarios)
          .select('id')
          .eq('email', email);

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Recuperar contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception('Error al enviar email de recuperación: ${e.message}');
    } catch (e) {
      throw Exception('Error al recuperar contraseña: $e');
    }
  }

  /// Actualizar perfil de usuario
  Future<Usuario?> updateProfile({
    required String userId,
    String? nombre,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (nombre != null) updates['nombre'] = nombre;

      if (updates.isEmpty) return null;

      await _supabase
          .from(SupabaseConstants.tableUsuarios)
          .update(updates)
          .eq('id', userId);

      // Obtener usuario actualizado
      return await getCurrentUser();
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar perfil: ${e.message}');
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }
}