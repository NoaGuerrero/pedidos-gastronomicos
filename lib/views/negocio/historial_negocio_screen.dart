import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/pedidos_viewmodel.dart';
import '../../widgets/pedido_card.dart';
import 'package:intl/intl.dart';

class HistorialNegocioScreen extends StatefulWidget {
  const HistorialNegocioScreen({super.key});

  @override
  State<HistorialNegocioScreen> createState() => _HistorialNegocioScreenState();
}

class _HistorialNegocioScreenState extends State<HistorialNegocioScreen> {
  String _filtroEstado = 'todos';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _isLoading = true);
    final viewModel = context.read<PedidosViewModel>();
    await viewModel.cargarPedidosNegocioAutenticado();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historial de Pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<PedidosViewModel>(
        builder: (context, viewModel, child) {
          final pedidosFiltrados = _aplicarFiltros(viewModel.pedidos);

          if (pedidosFiltrados.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildEstadisticas(pedidosFiltrados),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _cargarHistorial,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pedidosFiltrados.length,
                    itemBuilder: (context, index) {
                      final pedido = pedidosFiltrados[index];
                      return PedidoCard(
                        pedido: pedido,
                        mostrarCliente: true,
                        mostrarAcciones: false,
                        onTap: () => _mostrarDetallePedido(pedido),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<dynamic> _aplicarFiltros(List<dynamic> pedidos) {
    // Filtrar solo pedidos no activos (historial)
    var filtrados = pedidos.where((p) => !p.isActivo).toList();

    // Filtrar por estado
    if (_filtroEstado != 'todos') {
      filtrados = filtrados.where((p) => p.estado == _filtroEstado).toList();
    }

    // Filtrar por fecha
    if (_fechaInicio != null) {
      filtrados = filtrados.where((p) {
        final fechaPedido = p.updatedAt; // Ya es DateTime, no parsear
        return fechaPedido.isAfter(_fechaInicio!) ||
            fechaPedido.isAtSameMomentAs(_fechaInicio!);
      }).toList();
    }

    if (_fechaFin != null) {
      filtrados = filtrados.where((p) {
        final fechaPedido = p.updatedAt; // Ya es DateTime, no parsear
        final fechaFinDia = DateTime(
          _fechaFin!.year,
          _fechaFin!.month,
          _fechaFin!.day,
          23,
          59,
          59,
        );
        return fechaPedido.isBefore(fechaFinDia) ||
            fechaPedido.isAtSameMomentAs(fechaFinDia);
      }).toList();
    }

    // Ordenar por fecha (más recientes primero)
    filtrados.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Sin DateTime.parse()

    return filtrados;
  }
  Widget _buildEstadisticas(List<dynamic> pedidos) {
    final entregados = pedidos.where((p) => p.estado == 'entregado').length;
    final cancelados = pedidos.where((p) => p.estado == 'cancelado').length;
    final totalIngresos = pedidos
        .where((p) => p.estado == 'entregado')
        .fold<double>(0, (sum, p) => sum + p.total);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Estadísticas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEstadisticaItem(
                icon: Icons.check_circle,
                label: 'Entregados',
                valor: entregados.toString(),
                color: AppColors.success,
              ),
              _buildEstadisticaItem(
                icon: Icons.cancel,
                label: 'Cancelados',
                valor: cancelados.toString(),
                color: AppColors.error,
              ),
              _buildEstadisticaItem(
                icon: Icons.attach_money,
                label: 'Ingresos',
                valor: 'Bs ${totalIngresos.toStringAsFixed(2)}',
                color: AppColors.primary,
              ),
            ],
          ),
          if (_fechaInicio != null || _fechaFin != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              _getRangoFechaTexto(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstadisticaItem({
    required IconData icon,
    required String label,
    required String valor,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 100,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay historial',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _filtroEstado != 'todos' || _fechaInicio != null || _fechaFin != null
                ? 'No hay pedidos con los filtros seleccionados'
                : 'Los pedidos completados aparecerán aquí',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_filtroEstado != 'todos' ||
              _fechaInicio != null ||
              _fechaFin != null)
            OutlinedButton.icon(
              onPressed: _limpiarFiltros,
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar filtros'),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _cargarHistorial,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filtros',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Estado del Pedido',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: _filtroEstado == 'todos',
                      onSelected: (selected) {
                        setModalState(() => _filtroEstado = 'todos');
                        setState(() => _filtroEstado = 'todos');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Entregados'),
                      selected: _filtroEstado == 'entregado',
                      onSelected: (selected) {
                        setModalState(() => _filtroEstado = 'entregado');
                        setState(() => _filtroEstado = 'entregado');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Cancelados'),
                      selected: _filtroEstado == 'cancelado',
                      onSelected: (selected) {
                        setModalState(() => _filtroEstado = 'cancelado');
                        setState(() => _filtroEstado = 'cancelado');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Rango de Fechas',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: _fechaInicio ?? DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                          );
                          if (fecha != null) {
                            setModalState(() => _fechaInicio = fecha);
                            setState(() => _fechaInicio = fecha);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _fechaInicio == null
                              ? 'Desde'
                              : DateFormat('dd/MM/yy').format(_fechaInicio!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: _fechaFin ?? DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                          );
                          if (fecha != null) {
                            setModalState(() => _fechaFin = fecha);
                            setState(() => _fechaFin = fecha);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _fechaFin == null
                              ? 'Hasta'
                              : DateFormat('dd/MM/yy').format(_fechaFin!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _limpiarFiltros();
                          setModalState(() {});
                          Navigator.pop(context);
                        },
                        child: const Text('Limpiar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroEstado = 'todos';
      _fechaInicio = null;
      _fechaFin = null;
    });
  }

  String _getRangoFechaTexto() {
    if (_fechaInicio != null && _fechaFin != null) {
      return 'Rango: ${DateFormat('dd/MM/yy').format(_fechaInicio!)} - ${DateFormat('dd/MM/yy').format(_fechaFin!)}';
    } else if (_fechaInicio != null) {
      return 'Desde: ${DateFormat('dd/MM/yy').format(_fechaInicio!)}';
    } else if (_fechaFin != null) {
      return 'Hasta: ${DateFormat('dd/MM/yy').format(_fechaFin!)}';
    }
    return '';
  }

  void _mostrarDetallePedido(dynamic pedido) {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detalle del Pedido',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(pedido.estado),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getEstadoTexto(pedido.estado),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetalleItem(
                  icon: Icons.person,
                  label: 'Cliente',
                  valor: pedido.clienteNombre ?? 'Cliente',
                ),
                const SizedBox(height: 12),
                _buildDetalleItem(
                  icon: Icons.restaurant,
                  label: 'Plato',
                  valor: pedido.platoNombre,
                ),
                const SizedBox(height: 12),
                _buildDetalleItem(
                  icon: Icons.numbers,
                  label: 'Cantidad',
                  valor: '${pedido.cantidad} unidades',
                ),
                const SizedBox(height: 12),
                _buildDetalleItem(
                  icon: Icons.attach_money,
                  label: 'Total',
                  valor: 'Bs ${pedido.total.toStringAsFixed(2)}',
                  valorColor: AppColors.primary,
                ),
                const SizedBox(height: 12),
                _buildDetalleItem(
                  icon: Icons.access_time,
                  label: 'Fecha del pedido',
                  valor: DateFormat('dd/MM/yyyy HH:mm').format(pedido.createdAt), // Sin DateTime.parse()
                ),
                const SizedBox(height: 12),
                _buildDetalleItem(
                  icon: Icons.update,
                  label: 'Última actualización',
                  valor: DateFormat('dd/MM/yyyy HH:mm').format(pedido.updatedAt), // Sin DateTime.parse()
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetalleItem({
    required IconData icon,
    required String label,
    required String valor,
    Color? valorColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: valorColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'entregado':
        return AppColors.success;
      case 'cancelado':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'entregado':
        return 'ENTREGADO';
      case 'cancelado':
        return 'CANCELADO';
      default:
        return estado.toUpperCase();
    }
  }
}