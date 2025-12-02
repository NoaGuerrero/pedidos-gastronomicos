import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/pedidos_viewmodel.dart';
import '../../widgets/pedido_card.dart';

class SeguimientoPedidoScreen extends StatefulWidget {
  final int initialTabIndex;
  const SeguimientoPedidoScreen({
    super.key,
    this.initialTabIndex = 0, // Por defecto tab 0 (Activos)
  });
  @override
  State<SeguimientoPedidoScreen> createState() => _SeguimientoPedidoScreenState();
}

class _SeguimientoPedidoScreenState extends State<SeguimientoPedidoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex, // Usa el parámetro aquí
    );
    _cargarPedidos();
  }

  Future<void> _inicializar() async {
    final authViewModel = context.read<AuthViewModel>();
    final pedidosViewModel = context.read<PedidosViewModel>();

    if (authViewModel.currentUser != null) {
      await pedidosViewModel.cargarPedidosCliente(authViewModel.currentUser!.id);
      pedidosViewModel.iniciarRealtimeCliente(authViewModel.currentUser!.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose(); // ← AGREGAR esto
    context.read<PedidosViewModel>().detenerRealtime();
    super.dispose();
  }
  Future<void> _cargarPedidos() async {
    final authViewModel = context.read<AuthViewModel>();
    final pedidosViewModel = context.read<PedidosViewModel>();

    if (authViewModel.currentUser != null) {
      await pedidosViewModel.cargarPedidosCliente(authViewModel.currentUser!.id);
    }
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
        title: const Text('Seguimiento de Pedidos'),
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

          return Column(
            children: [
              Container(
                color: AppColors.cardBackground,
                child: TabBar(
                  controller: _tabController, // ← AGREGAR esto
                  tabs: const [
                    Tab(text: 'Activos', icon: Icon(Icons.pending_actions)),
                    Tab(text: 'Historial', icon: Icon(Icons.history)),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController, // ← AGREGAR esto
                  children: [
                    _buildPedidosActivos(viewModel),
                    _buildHistorial(viewModel),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPedidosActivos(PedidosViewModel viewModel) {
    if (!viewModel.hasPedidosActivos) {
      return _buildEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'No hay pedidos activos',
        subtitle: 'Tus pedidos aparecerán aquí en tiempo real',
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarPedidos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.pedidosActivos.length,
        itemBuilder: (context, index) {
          final pedido = viewModel.pedidosActivos[index];

          return PedidoCard(
            pedido: pedido,
            mostrarNegocio: true,
            mostrarAcciones: pedido.isPendiente,
            onCancelar: pedido.isPendiente
                ? () => _cancelarPedido(pedido.id)
                : null,
            onTap: () => _mostrarDetallePedido(pedido),
          );
        },
      ),
    );
  }

  Widget _buildHistorial(PedidosViewModel viewModel) {
    final pedidosHistorial = viewModel.pedidos
        .where((p) => !p.isActivo)
        .toList();

    if (pedidosHistorial.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No hay historial',
        subtitle: 'Los pedidos completados aparecerán aquí',
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarPedidos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pedidosHistorial.length,
        itemBuilder: (context, index) {
          final pedido = pedidosHistorial[index];

          return PedidoCard(
            pedido: pedido,
            mostrarNegocio: true,
            mostrarAcciones: false,
            onTap: () => _mostrarDetallePedido(pedido),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
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

  void _mostrarDetallePedido(pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Detalle del Pedido',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                _buildDetalleRow('Plato', pedido.platoNombre ?? 'N/A'),
                _buildDetalleRow('Negocio', pedido.negocioNombre ?? 'N/A'),
                _buildDetalleRow('Cantidad', '${pedido.cantidad}'),
                _buildDetalleRow('Total', pedido.totalFormateado),
                _buildDetalleRow('Estado', _getEstadoTexto(pedido.estado)),
                const SizedBox(height: 24),
                if (pedido.isPendiente)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _cancelarPedido(pedido.id);
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar Pedido'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case AppConstants.estadoPendiente:
        return 'Pendiente';
      case AppConstants.estadoEnPreparacion:
        return 'En Preparación';
      case AppConstants.estadoListo:
        return 'Listo';
      case AppConstants.estadoEntregado:
        return 'Entregado';
      case AppConstants.estadoCancelado:
        return 'Cancelado';
      default:
        return estado;
    }
  }
}