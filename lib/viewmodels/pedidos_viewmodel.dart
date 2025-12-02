import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pedido_model.dart';
import '../services/pedidos_service.dart';

class PedidosViewModel extends ChangeNotifier {
  final PedidosService _pedidosService = PedidosService();

  // Listas de pedidos
  List<Pedido> _pedidos = [];
  List<Pedido> _pedidosActivos = [];
  Pedido? _pedidoSeleccionado;

  // Estados de carga
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;

  // Mensajes
  String? _errorMessage;
  String? _successMessage;

  // Canal Realtime
  RealtimeChannel? _realtimeChannel;

  // Getters
  List<Pedido> get pedidos => _pedidos;
  List<Pedido> get pedidosActivos => _pedidosActivos;
  Pedido? get pedidoSeleccionado => _pedidoSeleccionado;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasPedidos => _pedidos.isNotEmpty;
  bool get hasPedidosActivos => _pedidosActivos.isNotEmpty;
  int get totalPedidos => _pedidos.length;

  // Filtros
  List<Pedido> get pedidosPendientes =>
      _pedidosActivos.where((p) => p.isPendiente).toList();

  List<Pedido> get pedidosEnPreparacion =>
      _pedidosActivos.where((p) => p.isEnPreparacion).toList();

  List<Pedido> get pedidosListos =>
      _pedidosActivos.where((p) => p.isListo).toList();

  /// Cargar pedidos de un cliente
  Future<void> cargarPedidosCliente(String clienteId) async {
    try {
      _clearMessages();
      _isLoading = true;
      notifyListeners();

      _pedidos = await _pedidosService.obtenerPedidosPorCliente(clienteId);
      _pedidosActivos = await _pedidosService.obtenerPedidosActivosCliente(clienteId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _pedidos = [];
      _pedidosActivos = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar pedidos de un negocio
  Future<void> cargarPedidosNegocio(String negocioId) async {
    try {
      _clearMessages();
      _isLoading = true;
      notifyListeners();

      _pedidos = await _pedidosService.obtenerPedidosPorNegocio(negocioId);
      _pedidosActivos = await _pedidosService.obtenerPedidosActivosNegocio(negocioId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _pedidos = [];
      _pedidosActivos = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar pedidos del negocio autenticado (obtiene el ID automáticamente)
  Future<void> cargarPedidosNegocioAutenticado() async {
    try {
      _clearMessages();
      _isLoading = true;
      notifyListeners();

      // Obtener el usuario autenticado actual
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Cargar pedidos usando el ID del usuario como negocioId
      _pedidos = await _pedidosService.obtenerPedidosPorNegocio(user.id);
      _pedidosActivos = await _pedidosService.obtenerPedidosActivosNegocio(user.id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _pedidos = [];
      _pedidosActivos = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crear nuevo pedido
  Future<bool> crearPedido({
    required Pedido pedido,
  }) async {
    try {
      _clearMessages();
      _isCreating = true;
      notifyListeners();

      final nuevoPedido = await _pedidosService.crearPedido(pedido: pedido);

      // Agregar a las listas
      _pedidos.insert(0, nuevoPedido);
      if (nuevoPedido.isActivo) {
        _pedidosActivos.insert(0, nuevoPedido);
      }

      _successMessage = 'Pedido realizado exitosamente';
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

  /// Actualizar estado de pedido
  Future<bool> actualizarEstado({
    required String pedidoId,
    required String nuevoEstado,
  }) async {
    try {
      _clearMessages();
      _isUpdating = true;
      notifyListeners();

      final pedidoActualizado = await _pedidosService.actualizarEstado(
        pedidoId: pedidoId,
        nuevoEstado: nuevoEstado,
      );

      // Actualizar en la lista de todos los pedidos
      final indexTodos = _pedidos.indexWhere((p) => p.id == pedidoId);
      if (indexTodos != -1) {
        _pedidos[indexTodos] = pedidoActualizado;
      }

      // Actualizar en la lista de activos
      final indexActivos = _pedidosActivos.indexWhere((p) => p.id == pedidoId);
      if (pedidoActualizado.isActivo) {
        if (indexActivos != -1) {
          _pedidosActivos[indexActivos] = pedidoActualizado;
        } else {
          _pedidosActivos.insert(0, pedidoActualizado);
        }
      } else {
        // Si ya no está activo, remover de activos
        if (indexActivos != -1) {
          _pedidosActivos.removeAt(indexActivos);
        }
      }

      _successMessage = 'Estado actualizado correctamente';
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

  /// Cancelar pedido
  Future<bool> cancelarPedido(String pedidoId) async {
    try {
      _clearMessages();
      _isUpdating = true;
      notifyListeners();

      final pedidoActualizado = await _pedidosService.cancelarPedido(pedidoId);

      // Actualizar en las listas
      final indexTodos = _pedidos.indexWhere((p) => p.id == pedidoId);
      if (indexTodos != -1) {
        _pedidos[indexTodos] = pedidoActualizado;
      }

      // Remover de activos
      _pedidosActivos.removeWhere((p) => p.id == pedidoId);

      _successMessage = 'Pedido cancelado';
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

  /// Seleccionar pedido para ver detalles
  void seleccionarPedido(Pedido? pedido) {
    _pedidoSeleccionado = pedido;
    notifyListeners();
  }

  /// Iniciar escucha Realtime para cliente
  void iniciarRealtimeCliente(String clienteId) {
    // Desuscribirse del canal anterior si existe
    if (_realtimeChannel != null) {
      _pedidosService.desuscribirse(_realtimeChannel!);
    }

    _realtimeChannel = _pedidosService.suscribirsePedidosCliente(
      clienteId: clienteId,
      onInsert: (pedido) {
        // Nuevo pedido recibido
        _pedidos.insert(0, pedido);
        if (pedido.isActivo) {
          _pedidosActivos.insert(0, pedido);
        }
        notifyListeners();
      },
      onUpdate: (pedido) {
        // Pedido actualizado
        final indexTodos = _pedidos.indexWhere((p) => p.id == pedido.id);
        if (indexTodos != -1) {
          _pedidos[indexTodos] = pedido;
        }

        final indexActivos = _pedidosActivos.indexWhere((p) => p.id == pedido.id);
        if (pedido.isActivo) {
          if (indexActivos != -1) {
            _pedidosActivos[indexActivos] = pedido;
          }
        } else {
          if (indexActivos != -1) {
            _pedidosActivos.removeAt(indexActivos);
          }
        }

        notifyListeners();
      },
    );
  }

  /// Iniciar escucha Realtime para negocio
  void iniciarRealtimeNegocio(String negocioId) {
    // Desuscribirse del canal anterior si existe
    if (_realtimeChannel != null) {
      _pedidosService.desuscribirse(_realtimeChannel!);
    }

    _realtimeChannel = _pedidosService.suscribirsePedidosNegocio(
      negocioId: negocioId,
      onInsert: (pedido) {
        // Nuevo pedido recibido
        _pedidos.insert(0, pedido);
        if (pedido.isActivo) {
          _pedidosActivos.insert(0, pedido);
        }
        _successMessage = '¡Nuevo pedido recibido!';
        notifyListeners();
      },
      onUpdate: (pedido) {
        // Pedido actualizado
        final indexTodos = _pedidos.indexWhere((p) => p.id == pedido.id);
        if (indexTodos != -1) {
          _pedidos[indexTodos] = pedido;
        }

        final indexActivos = _pedidosActivos.indexWhere((p) => p.id == pedido.id);
        if (pedido.isActivo) {
          if (indexActivos != -1) {
            _pedidosActivos[indexActivos] = pedido;
          }
        } else {
          if (indexActivos != -1) {
            _pedidosActivos.removeAt(indexActivos);
          }
        }

        notifyListeners();
      },
    );
  }

  /// Detener escucha Realtime
  void detenerRealtime() {
    if (_realtimeChannel != null) {
      _pedidosService.desuscribirse(_realtimeChannel!);
      _realtimeChannel = null;
    }
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

  /// Parsear mensaje de error
  String _parseErrorMessage(String error) {
    error = error.replaceAll('Exception: ', '');

    if (error.contains('Network request failed')) {
      return 'Sin conexión a internet';
    }
    if (error.contains('not found')) {
      return 'Pedido no encontrado';
    }
    if (error.contains('permission denied')) {
      return 'No tienes permisos para realizar esta acción';
    }

    return error;
  }

  @override
  void dispose() {
    detenerRealtime();
    super.dispose();
  }
}