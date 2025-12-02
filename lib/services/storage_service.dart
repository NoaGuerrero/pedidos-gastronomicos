import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import 'supabase_service.dart';

class StorageService {
  final SupabaseClient _supabase = SupabaseService.client;
  final String _bucket = SupabaseConstants.bucketPlatos;

  /// Subir imagen al Storage
  ///
  /// [filePath] - Ruta local del archivo
  /// [fileName] - Nombre único para el archivo (incluir extensión)
  ///
  /// Retorna la URL pública de la imagen o null si falla
  Future<String?> uploadImage({
    required String filePath,
    required String fileName,
  }) async {
    try {
      // Verificar que el archivo existe
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('El archivo no existe: $filePath');
      }

      // Leer bytes del archivo
      final bytes = await file.readAsBytes();

      // Subir a Storage
      await _supabase.storage.from(_bucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true, // Sobrescribir si existe
        ),
      );

      // Obtener URL pública
      final url = _supabase.storage.from(_bucket).getPublicUrl(fileName);

      return url;
    } on StorageException catch (e) {
      debugPrint('Error de Storage: ${e.message}');
      throw Exception('Error al subir imagen: ${e.message}');
    } catch (e) {
      debugPrint('Error al subir imagen: $e');
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Subir imagen desde bytes (útil para web)
  ///
  /// [bytes] - Bytes de la imagen
  /// [fileName] - Nombre único para el archivo
  ///
  /// Retorna la URL pública de la imagen o null si falla
  Future<String?> uploadImageFromBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      // Subir a Storage
      await _supabase.storage.from(_bucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      // Obtener URL pública
      final url = _supabase.storage.from(_bucket).getPublicUrl(fileName);

      return url;
    } on StorageException catch (e) {
      debugPrint('Error de Storage: ${e.message}');
      throw Exception('Error al subir imagen: ${e.message}');
    } catch (e) {
      debugPrint('Error al subir imagen: $e');
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Eliminar imagen del Storage
  ///
  /// [fileName] - Nombre del archivo a eliminar
  Future<void> deleteImage(String fileName) async {
    try {
      await _supabase.storage.from(_bucket).remove([fileName]);
    } on StorageException catch (e) {
      debugPrint('Error al eliminar imagen: ${e.message}');
      throw Exception('Error al eliminar imagen: ${e.message}');
    } catch (e) {
      debugPrint('Error al eliminar imagen: $e');
      throw Exception('Error al eliminar imagen: $e');
    }
  }

  /// Eliminar imagen usando su URL pública
  ///
  /// [imageUrl] - URL pública de la imagen
  Future<void> deleteImageByUrl(String imageUrl) async {
    try {
      // Extraer el nombre del archivo de la URL
      final fileName = _extractFileNameFromUrl(imageUrl);
      if (fileName == null) {
        throw Exception('No se pudo extraer el nombre del archivo de la URL');
      }

      await deleteImage(fileName);
    } catch (e) {
      debugPrint('Error al eliminar imagen por URL: $e');
      throw Exception('Error al eliminar imagen: $e');
    }
  }

  /// Obtener URL pública de una imagen
  ///
  /// [fileName] - Nombre del archivo
  String getPublicUrl(String fileName) {
    return _supabase.storage.from(_bucket).getPublicUrl(fileName);
  }

  /// Listar todas las imágenes en el bucket
  Future<List<FileObject>> listImages() async {
    try {
      final files = await _supabase.storage.from(_bucket).list();
      return files;
    } on StorageException catch (e) {
      debugPrint('Error al listar imágenes: ${e.message}');
      throw Exception('Error al listar imágenes: ${e.message}');
    } catch (e) {
      debugPrint('Error al listar imágenes: $e');
      throw Exception('Error al listar imágenes: $e');
    }
  }

  /// Generar nombre único para archivo
  ///
  /// [userId] - ID del usuario (para organizar por usuario)
  /// [extension] - Extensión del archivo (jpg, png, etc.)
  String generateFileName(String userId, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$userId\_$timestamp.$extension';
  }

  /// Extraer nombre de archivo de una URL pública
  String? _extractFileNameFromUrl(String url) {
    try {
      // Ejemplo URL: https://xxx.supabase.co/storage/v1/object/public/platos-imagenes/archivo.jpg
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      // El nombre del archivo está al final de los segments
      if (segments.isNotEmpty) {
        return segments.last;
      }

      return null;
    } catch (e) {
      debugPrint('Error al extraer nombre de archivo: $e');
      return null;
    }
  }

  /// Validar tamaño de archivo
  ///
  /// [filePath] - Ruta del archivo
  /// [maxSizeMB] - Tamaño máximo en MB
  Future<bool> validateFileSize(String filePath, int maxSizeMB) async {
    try {
      final file = File(filePath);
      final bytes = await file.length();
      final sizeMB = bytes / (1024 * 1024);
      return sizeMB <= maxSizeMB;
    } catch (e) {
      debugPrint('Error al validar tamaño: $e');
      return false;
    }
  }

  /// Validar extensión de archivo
  ///
  /// [fileName] - Nombre del archivo
  /// [allowedExtensions] - Extensiones permitidas (sin punto)
  bool validateFileExtension(
      String fileName,
      List<String> allowedExtensions,
      ) {
    final extension = fileName.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  /// Obtener extensión de archivo
  String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }
}