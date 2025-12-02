import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../models/plato_model.dart';
import 'supabase_service.dart';
import 'storage_service.dart';

class PlatosService {
  final SupabaseClient _supabase = SupabaseService.client;
  final StorageService _storageService = StorageService();

  /// Crear nuevo plato
  ///
  /// [plato] - Plato a crear
  /// [imagePath] - Ruta local de la imagen (opcional)
  ///
  /// Retorna el Plato creado con su ID y URL de imagen
  Future<Plato> crearPlato({
    required Plato plato,
    String? imagePath,
  }) async {
    try {
      String? imageUrl;

      // Si hay imagen, subirla primero
      if (imagePath != null && imagePath.isNotEmpty) {
        final extension = _storageService.getFileExtension(imagePath);
        final fileName = _storageService.generateFileName(
          plato.negocioId,
          extension,
        );

        imageUrl = await _storageService.uploadImage(
          filePath: imagePath,
          fileName: fileName,
        );
      }

      // Crear plato con URL de imagen
      final platoConImagen = plato.copyWith(imagenUrl: imageUrl);

      // Insertar en base de datos
      final response = await _supabase
          .from(SupabaseConstants.tablePlatos)
          .insert(platoConImagen.toInsert())
          .select()
          .single();

      return Plato.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('Error de base de datos: ${e.message}');
      throw Exception('Error al crear plato: ${e.message}');
    } catch (e) {
      debugPrint('Error al crear plato: $e');
      throw Exception('Error al crear plato: $e');
    }
  }

  /// Crear plato desde bytes (útil para web)
  Future<Plato> crearPlatoFromBytes({
    required Plato plato,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    try {
      String? imageUrl;

      // Si hay imagen, subirla primero
      if (imageBytes != null && imageExtension != null) {
        final fileName = _storageService.generateFileName(
          plato.negocioId,
          imageExtension,
        );

        imageUrl = await _storageService.uploadImageFromBytes(
          bytes: imageBytes,
          fileName: fileName,
        );
      }

      // Crear plato con URL de imagen
      final platoConImagen = plato.copyWith(imagenUrl: imageUrl);

      // Insertar en base de datos
      final response = await _supabase
          .from(SupabaseConstants.tablePlatos)
          .insert(platoConImagen.toInsert())
          .select()
          .single();

      return Plato.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('Error de base de datos: ${e.message}');
      throw Exception('Error al crear plato: ${e.message}');
    } catch (e) {
      debugPrint('Error al crear plato: $e');
      throw Exception('Error al crear plato: $e');
    }
  }

  /// Obtener todos los platos de un negocio
  Future<List<Plato>> obtenerPlatosPorNegocio(String negocioId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tablePlatos)
          .select()
          .eq('negocio_id', negocioId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Plato.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      debugPrint('Error al obtener platos: ${e.message}');
      throw Exception('Error al obtener platos: ${e.message}');
    } catch (e) {
      debugPrint('Error al obtener platos: $e');
      throw Exception('Error al obtener platos: $e');
    }
  }

  /// Obtener todos los platos disponibles (para clientes)
  Future<List<Plato>> obtenerPlatosDisponibles() async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tablePlatos)
          .select()
          .eq('disponible', true)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Plato.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      debugPrint('Error al obtener platos disponibles: ${e.message}');
      throw Exception('Error al obtener platos: ${e.message}');
    } catch (e) {
      debugPrint('Error al obtener platos: $e');
      throw Exception('Error al obtener platos: $e');
    }
  }

  /// Obtener plato por ID
  Future<Plato?> obtenerPlatoPorId(String platoId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tablePlatos)
          .select()
          .eq('id', platoId)
          .maybeSingle();

      if (response == null) return null;

      return Plato.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('Error al obtener plato: ${e.message}');
      throw Exception('Error al obtener plato: ${e.message}');
    } catch (e) {
      debugPrint('Error al obtener plato: $e');
      throw Exception('Error al obtener plato: $e');
    }
  }

  /// Actualizar plato existente
  ///
  /// [platoId] - ID del plato a actualizar
  /// [plato] - Datos actualizados del plato
  /// [imagePath] - Nueva imagen (opcional, null para mantener la actual)
  /// [deleteOldImage] - Si es true, elimina la imagen anterior
  Future<Plato> actualizarPlato({
    required String platoId,
    required Plato plato,
    String? imagePath,
    bool deleteOldImage = false,
  }) async {
    try {
      String? imageUrl = plato.imagenUrl;

      // Si hay nueva imagen, subirla
      if (imagePath != null && imagePath.isNotEmpty) {
        // Eliminar imagen anterior si existe
        if (deleteOldImage && plato.tieneImagen) {
          try {
            await _storageService.deleteImageByUrl(plato.imagenUrl!);
          } catch (e) {
            debugPrint('Error al eliminar imagen anterior: $e');
          }
        }

        // Subir nueva imagen
        final extension = _storageService.getFileExtension(imagePath);
        final fileName = _storageService.generateFileName(
          plato.negocioId,
          extension,
        );

        imageUrl = await _storageService.uploadImage(
          filePath: imagePath,
          fileName: fileName,
        );
      }

      // Actualizar plato con nueva URL de imagen
      final platoActualizado = plato.copyWith(imagenUrl: imageUrl);

      // Actualizar en base de datos
      final response = await _supabase
          .from(SupabaseConstants.tablePlatos)
          .update(platoActualizado.toUpdate())
          .eq('id', platoId)
          .select()
          .single();

      return Plato.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('Error de base de datos: ${e.message}');
      throw Exception('Error al actualizar plato: ${e.message}');
    } catch (e) {
      debugPrint('Error al actualizar plato: $e');
      throw Exception('Error al actualizar plato: $e');
    }
  }

  /// Actualizar plato desde bytes (web)
  Future<Plato> actualizarPlatoFromBytes({
    required String platoId,
    required Plato plato,
    Uint8List? imageBytes,
    String? imageExtension,
    bool deleteOldImage = false,
  }) async {
    try {
      String? imageUrl = plato.imagenUrl;

      // Si hay nueva imagen, subirla
      if (imageBytes != null && imageExtension != null) {
        // Eliminar imagen anterior si existe
        if (deleteOldImage && plato.tieneImagen) {
          try {
            await _storageService.deleteImageByUrl(plato.imagenUrl!);
          } catch (e) {
            debugPrint('Error al eliminar imagen anterior: $e');
          }
        }

        // Subir nueva imagen
        final fileName = _storageService.generateFileName(
          plato.negocioId,
          imageExtension,
        );

        imageUrl = await _storageService.uploadImageFromBytes(
          bytes: imageBytes,
          fileName: fileName,
        );
      }

      // Actualizar plato con nueva URL de imagen
      final platoActualizado = plato.copyWith(imagenUrl: imageUrl);

      // Actualizar en base de datos
      final response = await _supabase
          .from(SupabaseConstants.tablePlatos)
          .update(platoActualizado.toUpdate())
          .eq('id', platoId)
          .select()
          .single();

      return Plato.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('Error de base de datos: ${e.message}');
      throw Exception('Error al actualizar plato: ${e.message}');
    } catch (e) {
      debugPrint('Error al actualizar plato: $e');
      throw Exception('Error al actualizar plato: $e');
    }
  }

  /// Eliminar plato
  ///
  /// [platoId] - ID del plato a eliminar
  /// [deleteImage] - Si es true, también elimina la imagen del Storage
  Future<void> eliminarPlato({
    required String platoId,
    bool deleteImage = true,
  }) async {
    try {
      // Obtener plato para acceder a la URL de imagen
      final plato = await obtenerPlatoPorId(platoId);

      // Eliminar imagen si existe
      if (deleteImage && plato != null && plato.tieneImagen) {
        try {
          await _storageService.deleteImageByUrl(plato.imagenUrl!);
        } catch (e) {
          debugPrint('Error al eliminar imagen: $e');
        }
      }

      // Eliminar plato de la base de datos
      await _supabase
          .from(SupabaseConstants.tablePlatos)
          .delete()
          .eq('id', platoId);
    } on PostgrestException catch (e) {
      debugPrint('Error al eliminar plato: ${e.message}');
      throw Exception('Error al eliminar plato: ${e.message}');
    } catch (e) {
      debugPrint('Error al eliminar plato: $e');
      throw Exception('Error al eliminar plato: $e');
    }
  }

  /// Cambiar disponibilidad de un plato
  Future<Plato> toggleDisponibilidad(String platoId, bool disponible) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tablePlatos)
          .update({'disponible': disponible})
          .eq('id', platoId)
          .select()
          .single();

      return Plato.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('Error al cambiar disponibilidad: ${e.message}');
      throw Exception('Error al cambiar disponibilidad: ${e.message}');
    } catch (e) {
      debugPrint('Error al cambiar disponibilidad: $e');
      throw Exception('Error al cambiar disponibilidad: $e');
    }
  }

  /// Buscar platos por categoría
  Future<List<Plato>> buscarPorCategoria(String categoria) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tablePlatos)
          .select()
          .eq('categoria', categoria)
          .eq('disponible', true)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Plato.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      debugPrint('Error al buscar por categoría: ${e.message}');
      throw Exception('Error al buscar platos: ${e.message}');
    } catch (e) {
      debugPrint('Error al buscar platos: $e');
      throw Exception('Error al buscar platos: $e');
    }
  }

  /// Obtener lista de negocios que tienen platos disponibles
  Future<List<Map<String, String>>> obtenerNegociosConPlatos() async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tablePlatos)
          .select('negocio_id, usuarios!inner(id, nombre)')
          .eq('disponible', true);

      // Extraer negocios únicos
      final negociosMap = <String, String>{};

      for (var plato in response) {
        final negocioData = plato['usuarios'];
        if (negocioData != null) {
          final id = negocioData['id'] as String;
          final nombre = negocioData['nombre'] as String;
          negociosMap[id] = nombre;
        }
      }

      // Convertir a lista de mapas
      return negociosMap.entries
          .map((entry) => {'id': entry.key, 'nombre': entry.value})
          .toList();
    } catch (e) {
      throw Exception('Error al obtener negocios: $e');
    }
  }
}

