import 'package:flutter/foundation.dart';
import '../models/plato_model.dart';
import '../services/platos_service.dart';

class PlatosViewModel extends ChangeNotifier {
  final PlatosService _platosService = PlatosService();

  // Lista de platos
  List<Plato> _platos = [];
  Plato? _platoSeleccionado;

  // Estados de carga
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;

  // Mensajes
  String? _errorMessage;
  String? _successMessage;

  // Getters
  List<Plato> get platos => _platos;
  Plato? get platoSeleccionado => _platoSeleccionado;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasPlatos => _platos.isNotEmpty;
  int get totalPlatos => _platos.length;

  // Filtros
  List<Plato> get platosDisponibles =>
      _platos.where((p) => p.disponible).toList();

  List<Plato> get platosNoDisponibles =>
      _platos.where((p) => !p.disponible).toList();

  /// Cargar platos de un negocio
  Future<void> cargarPlatos(String negocioId) async {
    try {
      _clearMessages();
      _isLoading = true;
      notifyListeners();

      _platos = await _platosService.obtenerPlatosPorNegocio(negocioId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _platos = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar platos disponibles (para clientes)
  Future<void> cargarPlatosDisponibles() async {
    try {
      _clearMessages();
      _isLoading = true;
      notifyListeners();

      _platos = await _platosService.obtenerPlatosDisponibles();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _platos = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crear nuevo plato
  Future<bool> crearPlato({
    required Plato plato,
    String? imagePath,
  }) async {
    try {
      _clearMessages();
      _isCreating = true;
      notifyListeners();

      final nuevoPlato = await _platosService.crearPlato(
        plato: plato,
        imagePath: imagePath,
      );

      // Agregar a la lista
      _platos.insert(0, nuevoPlato);
      _successMessage = 'Plato "${nuevoPlato.nombre}" creado exitosamente';

      _isCreating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _isCreating = false;
      notifyListeners();
      return false;
    }
  }

  /// Crear plato desde bytes (web)
  Future<bool> crearPlatoFromBytes({
    required Plato plato,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    try {
      _clearMessages();
      _isCreating = true;
      notifyListeners();

      final nuevoPlato = await _platosService.crearPlatoFromBytes(
        plato: plato,
        imageBytes: imageBytes,
        imageExtension: imageExtension,
      );

      // Agregar a la lista
      _platos.insert(0, nuevoPlato);
      _successMessage = 'Plato "${nuevoPlato.nombre}" creado exitosamente';

      _isCreating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _isCreating = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualizar plato existente
  Future<bool> actualizarPlato({
    required String platoId,
    required Plato plato,
    String? imagePath,
    bool deleteOldImage = false,
  }) async {
    try {
      _clearMessages();
      _isUpdating = true;
      notifyListeners();

      final platoActualizado = await _platosService.actualizarPlato(
        platoId: platoId,
        plato: plato,
        imagePath: imagePath,
        deleteOldImage: deleteOldImage,
      );

      // Actualizar en la lista
      final index = _platos.indexWhere((p) => p.id == platoId);
      if (index != -1) {
        _platos[index] = platoActualizado;
      }

      _successMessage = 'Plato "${platoActualizado.nombre}" actualizado';
      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualizar plato desde bytes (web)
  Future<bool> actualizarPlatoFromBytes({
    required String platoId,
    required Plato plato,
    Uint8List? imageBytes,
    String? imageExtension,
    bool deleteOldImage = false,
  }) async {
    try {
      _clearMessages();
      _isUpdating = true;
      notifyListeners();

      final platoActualizado = await _platosService.actualizarPlatoFromBytes(
        platoId: platoId,
        plato: plato,
        imageBytes: imageBytes,
        imageExtension: imageExtension,
        deleteOldImage: deleteOldImage,
      );

      // Actualizar en la lista
      final index = _platos.indexWhere((p) => p.id == platoId);
      if (index != -1) {
        _platos[index] = platoActualizado;
      }

      _successMessage = 'Plato "${platoActualizado.nombre}" actualizado';
      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  /// Eliminar plato
  Future<bool> eliminarPlato(String platoId, {bool deleteImage = true}) async {
    try {
      _clearMessages();
      _isDeleting = true;
      notifyListeners();

      // Obtener nombre del plato antes de eliminarlo
      final plato = _platos.firstWhere((p) => p.id == platoId);
      final nombrePlato = plato.nombre;

      await _platosService.eliminarPlato(
        platoId: platoId,
        deleteImage: deleteImage,
      );

      // Remover de la lista
      _platos.removeWhere((p) => p.id == platoId);
      _successMessage = 'Plato "$nombrePlato" eliminado';

      _isDeleting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _isDeleting = false;
      notifyListeners();
      return false;
    }
  }

  /// Cambiar disponibilidad de un plato
  Future<bool> toggleDisponibilidad(String platoId) async {
    try {
      _clearMessages();

      // Obtener plato actual
      final platoActual = _platos.firstWhere((p) => p.id == platoId);
      final nuevaDisponibilidad = !platoActual.disponible;

      final platoActualizado = await _platosService.toggleDisponibilidad(
        platoId,
        nuevaDisponibilidad,
      );

      // Actualizar en la lista
      final index = _platos.indexWhere((p) => p.id == platoId);
      if (index != -1) {
        _platos[index] = platoActualizado;
      }

      final estado = nuevaDisponibilidad ? 'disponible' : 'no disponible';
      _successMessage = 'Plato marcado como $estado';

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Seleccionar plato para edición
  void seleccionarPlato(Plato? plato) {
    _platoSeleccionado = plato;
    notifyListeners();
  }

  /// Buscar platos por categoría
  Future<void> buscarPorCategoria(String categoria) async {
    try {
      _clearMessages();
      _isLoading = true;
      notifyListeners();

      _platos = await _platosService.buscarPorCategoria(categoria);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _platos = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtrar platos localmente por nombre
  List<Plato> filtrarPorNombre(String query) {
    if (query.isEmpty) return _platos;

    return _platos.where((plato) {
      return plato.nombre.toLowerCase().contains(query.toLowerCase()) ||
          plato.descripcion.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Obtener categorías únicas
  List<String> get categorias {
    final categoriasSet = _platos.map((p) => p.categoria).toSet();
    return categoriasSet.toList()..sort();
  }

  /// Limpiar mensajes
  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  /// Limpiar error manualmente
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpiar mensaje de éxito manualmente
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  /// Obtener lista de negocios que tienen platos disponibles
  Future<List<Map<String, String>>> obtenerNegociosConPlatos() async {
    try {
      final response = await _platosService.obtenerNegociosConPlatos();
      return response;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      notifyListeners();
      return [];
    }
  }

  /// Parsear mensaje de error
  String _parseErrorMessage(String error) {
    error = error.replaceAll('Exception: ', '');

    if (error.contains('Network request failed')) {
      return 'Sin conexión a internet';
    }
    if (error.contains('not found')) {
      return 'Plato no encontrado';
    }
    if (error.contains('permission denied')) {
      return 'No tienes permisos para realizar esta acción';
    }

    return error;
  }

  @override
  void dispose() {
    super.dispose();
  }
}