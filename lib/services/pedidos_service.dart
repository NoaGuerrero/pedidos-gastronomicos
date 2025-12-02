import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../models/pedido_model.dart';
import 'supabase_service.dart';

class PedidosService {
  final SupabaseClient _supabase = SupabaseService.client;

  /// Crear nuevo pedido
  Future<Pedido> crearPedido({
    required Pedido pedido,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tablePedidos)
          .insert(pedido.toInsert())
          .select()
          .single();

      return Pedido.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('Error de base de datos: ${e.message}');
      throw Exception('Error al crear pedido: ${e.message}');
    } catch (e) {
      debugPrint('Error al crear pedido: $e');
      throw Exception('Error al crear pedido: $e');
    }
  }

  /// Obtener pedidos de un cliente
  Future<List<Pedido>> obtenerPedidosPorCliente(String clienteId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tablePedidos)
          .select('''
            *,
            cliente:cliente_id(nombre),
            negocio:negocio_id(nombre),
            plato:plato_id(nombre, precio, imagen_url)
          ''')
          .eq('cliente_id', clienteId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        // Aplanar los datos de las relaciones
        return Pedido.fromJson({
          ...json,
          'cliente_nombre': json['cliente']?['nombre'],
          'negocio_nombre': json['negocio']?['nombre'],
          'plato_nombre': json['plato']?['nombre'],
          'plato_precio': json['plato']?['precio'],
          'plato_imagen_url': json['plato']?['imagen_url'],
        });
      }).toList();
    } on PostgrestException catch (e) {
      debugPrint('Error al obtener pedidos: ${e.message}');
      throw Exception('Error al obtener pedidos: ${e.message}');
    } catch (e) {
      debugPrint('Error al obtener pedidos: $e');
      throw Exception('Error al obtener pedidos: $e');
    }
  }

  /// Obtener pedidos de un negocio
  Future<List<Pedido>> obtenerPedidosPorNegocio(String negocioId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tablePedidos)
          .select('''
            *,
            cliente:cliente_id(nombre),
            negocio:negocio_id(nombre),
            plato:plato_id(nombre, precio, imagen_url)
          ''')
          .eq('negocio_id', negocioId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        return Pedido.fromJson({
          ...json,
          'cliente_nombre': json['cliente']?['nombre'],
          'negocio_nombre': json['negocio']?['nombre'],
          'plato_nombre': json['plato']?['nombre'],
          'plato_precio': json['plato']?['precio'],
          'plato_imagen_url': json['plato']?['imagen_url'],
        });
      }).toList();
    } on PostgrestException catch (e) {
      debugPrint('Error al obtener pedidos: ${e.message}');
      throw Exception('Error al obtener pedidos: ${e.message}');
    } catch (e) {
      debugPrint('Error al obtener pedidos: $e');
      throw Exception('Error al obtener pedidos: $e');
    }
  }

  /// Obtener pedidos activos de un cliente
  Future<List<Pedido>> obtenerPedidosActivosCliente(String clienteId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tablePedidos)
          .select('''
            *,
            cliente:cliente_id(nombre),
            negocio:negocio_id(nombre),
            plato:plato_id(nombre, precio, imagen_url)
          ''')
          .eq('cliente_id', clienteId)
          .neq('estado', 'entregado')
          .neq('estado', 'cancelado')
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        return Pedido.fromJson({
          ...json,
          'cliente_nombre': json['cliente']?['nombre'],
          'negocio_nombre': json['negocio']?['nombre'],
          'plato_nombre': json['plato']?['nombre'],
          'plato_precio': json['plato']?['precio'],
          'plato_imagen_url': json['plato']?['imagen_url'],
        });
      }).toList();
    } on PostgrestException catch (e) {
      debugPrint('Error al obtener pedidos activos: ${e.message}');
      throw Exception('Error al obtener pedidos: ${e.message}');
    } catch (e) {
      debugPrint('Error al obtener pedidos: $e');
      throw Exception('Error al obtener pedidos: $e');
    }
  }

  /// Obtener pedidos activos de un negocio
  Future<List<Pedido>> obtenerPedidosActivosNegocio(String negocioId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tablePedidos)
          .select('''
            *,
            cliente:cliente_id(nombre),
            negocio:negocio_id(nombre),
            plato:plato_id(nombre, precio, imagen_url)
          ''')
          .eq('negocio_id', negocioId)
          .neq('estado', 'entregado')
          .neq('estado', 'cancelado')
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        return Pedido.fromJson({
          ...json,
          'cliente_nombre': json['cliente']?['nombre'],
          'negocio_nombre': json['negocio']?['nombre'],
          'plato_nombre': json['plato']?['nombre'],
          'plato_precio': json['plato']?['precio'],
          'plato_imagen_url': json['plato']?['imagen_url'],
        });
      }).toList();
    } on PostgrestException catch (e) {
      debugPrint('Error al obtener pedidos activos: ${e.message}');
      throw Exception('Error al obtener pedidos: ${e.message}');
    } catch (e) {
      debugPrint('Error al obtener pedidos: $e');
      throw Exception('Error al obtener pedidos: $e');
    }
  }

  /// Obtener pedido por ID
  Future<Pedido?> obtenerPedidoPorId(String pedidoId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tablePedidos)
          .select('''
            *,
            cliente:cliente_id(nombre),
            negocio:negocio_id(nombre),
            plato:plato_id(nombre, precio, imagen_url)
          ''')
          .eq('id', pedidoId)
          .maybeSingle();

      if (response == null) return null;

      return Pedido.fromJson({
        ...response,
        'cliente_nombre': response['cliente']?['nombre'],
        'negocio_nombre': response['negocio']?['nombre'],
        'plato_nombre': response['plato']?['nombre'],
        'plato_precio': response['plato']?['precio'],
        'plato_imagen_url': response['plato']?['imagen_url'],
      });
    } on PostgrestException catch (e) {
      debugPrint('Error al obtener pedido: ${e.message}');
      throw Exception('Error al obtener pedido: ${e.message}');
    } catch (e) {
      debugPrint('Error al obtener pedido: $e');
      throw Exception('Error al obtener pedido: $e');
    }
  }

  /// Actualizar estado de pedido
  Future<Pedido> actualizarEstado({
    required String pedidoId,
    required String nuevoEstado,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tablePedidos)
          .update({'estado': nuevoEstado})
          .eq('id', pedidoId)
          .select('''
            *,
            cliente:cliente_id(nombre),
            negocio:negocio_id(nombre),
            plato:plato_id(nombre, precio, imagen_url)
          ''')
          .single();

      return Pedido.fromJson({
        ...response,
        'cliente_nombre': response['cliente']?['nombre'],
        'negocio_nombre': response['negocio']?['nombre'],
        'plato_nombre': response['plato']?['nombre'],
        'plato_precio': response['plato']?['precio'],
        'plato_imagen_url': response['plato']?['imagen_url'],
      });
    } on PostgrestException catch (e) {
      debugPrint('Error al actualizar estado: ${e.message}');
      throw Exception('Error al actualizar estado: ${e.message}');
    } catch (e) {
      debugPrint('Error al actualizar estado: $e');
      throw Exception('Error al actualizar estado: $e');
    }
  }

  /// Cancelar pedido
  Future<Pedido> cancelarPedido(String pedidoId) async {
    return actualizarEstado(
      pedidoId: pedidoId,
      nuevoEstado: 'cancelado',
    );
  }

  /// Suscribirse a cambios en pedidos de un negocio (Realtime)
  RealtimeChannel suscribirsePedidosNegocio({
    required String negocioId,
    required Function(Pedido) onInsert,
    required Function(Pedido) onUpdate,
  }) {
    final channel = _supabase
        .channel('pedidos_negocio_$negocioId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: SupabaseConstants.tablePedidos,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'negocio_id',
        value: negocioId,
      ),
      callback: (payload) async {
        try {
          final pedido = await obtenerPedidoPorId(payload.newRecord['id'] as String);
          if (pedido != null) {
            onInsert(pedido);
          }
        } catch (e) {
          debugPrint('Error en callback insert: $e');
        }
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: SupabaseConstants.tablePedidos,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'negocio_id',
        value: negocioId,
      ),
      callback: (payload) async {
        try {
          final pedido = await obtenerPedidoPorId(payload.newRecord['id'] as String);
          if (pedido != null) {
            onUpdate(pedido);
          }
        } catch (e) {
          debugPrint('Error en callback update: $e');
        }
      },
    )
        .subscribe();

    return channel;
  }

  /// Suscribirse a cambios en pedidos de un cliente (Realtime)
  RealtimeChannel suscribirsePedidosCliente({
    required String clienteId,
    required Function(Pedido) onInsert,
    required Function(Pedido) onUpdate,
  }) {
    final channel = _supabase
        .channel('pedidos_cliente_$clienteId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: SupabaseConstants.tablePedidos,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'cliente_id',
        value: clienteId,
      ),
      callback: (payload) async {
        try {
          final pedido = await obtenerPedidoPorId(payload.newRecord['id'] as String);
          if (pedido != null) {
            onInsert(pedido);
          }
        } catch (e) {
          debugPrint('Error en callback insert: $e');
        }
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: SupabaseConstants.tablePedidos,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'cliente_id',
        value: clienteId,
      ),
      callback: (payload) async {
        try {
          final pedido = await obtenerPedidoPorId(payload.newRecord['id'] as String);
          if (pedido != null) {
            onUpdate(pedido);
          }
        } catch (e) {
          debugPrint('Error en callback update: $e');
        }
      },
    )
        .subscribe();

    return channel;
  }

  /// Desuscribirse de un canal
  Future<void> desuscribirse(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}