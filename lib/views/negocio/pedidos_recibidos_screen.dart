import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/pedidos_viewmodel.dart';
import '../../widgets/pedido_card.dart';

class PedidosRecibidosScreen extends StatefulWidget {
  const PedidosRecibidosScreen({super.key});

  @override
  State<PedidosRecibidosScreen> createState() => _PedidosRecibidosScreenState();
}

class _PedidosRecibidosScreenState extends State<PedidosRecibidosScreen> {
  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    final authViewModel = context.read<AuthViewModel>();
    final pedidosViewModel = context.read<PedidosViewModel>();

    if (authViewModel.currentUser != null) {
      await pedidosViewModel.cargarPedidosNegocio(authViewModel.currentUser!.id);
      pedidosViewModel.iniciarRealtimeNegocio(authViewModel.currentUser!.id);
    }
  }

  @override
  void dispose() {
    context.read<PedidosViewModel>().detenerRealtime();
    super.dispose();
  }

  Future<void> _cargarPedidos() async {
    final authViewModel = context.read<AuthViewModel>();
    final pedidosViewModel = context.read<PedidosViewModel>();

    if (authViewModel.currentUser != null) {
      await pedidosViewModel.cargarPedidosNegocio(authViewModel.currentUser!.id);
    }
  }

  Future<void> _cambiarEstado(String pedidoId, String nuevoEstado) async {
    final pedidosViewModel = context.read<PedidosViewModel>();
    await pedidosViewModel.actualizarEstado(
      pedidoId: pedidoId,
      nuevoEstado: nuevoEstado,
    );
  }

  Future<void> _cancelarPedido(String pedidoId) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: const Text('¿Estás seguro de cancelar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      await context.read<PedidosViewModel>().cancelarPedido(pedidoId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos Recibidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPedidos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<PedidosViewModel>(
        builder: (context, viewModel, child) {
          // Mostrar mensajes
          if (viewModel.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(viewModel.errorMessage!),
                  backgroundColor: AppColors.error,
                ),
              );
              viewModel.clearError();
            });
          }

          if (viewModel.successMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(viewModel.successMessage!),
                  backgroundColor: AppColors.success,
                ),
              );
              viewModel.clearSuccess();
            });
          }

          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!viewModel.hasPedidosActivos) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _cargarPedidos,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.pedidosActivos.length,
              itemBuilder: (context, index) {
                final pedido = viewModel.pedidosActivos[index];

                String? siguienteEstado;
                if (pedido.isPendiente) {
                  siguienteEstado = AppConstants.estadoEnPreparacion;
                } else if (pedido.isEnPreparacion) {
                  siguienteEstado = AppConstants.estadoListo;
                } else if (pedido.isListo) {
                  siguienteEstado = AppConstants.estadoEntregado;
                }

                return PedidoCard(
                  pedido: pedido,
                  mostrarCliente: true,
                  mostrarAcciones: true,
                  onCambiarEstado: siguienteEstado != null
                      ? () => _cambiarEstado(pedido.id, siguienteEstado!)
                      : null,
                  onCancelar: pedido.isPendiente
                      ? () => _cancelarPedido(pedido.id)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 100,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          Text(
            'No hay pedidos activos',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Los pedidos aparecerán aquí en tiempo real',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _cargarPedidos,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}