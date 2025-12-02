import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/plato_model.dart';
import '../../models/pedido_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/pedidos_viewmodel.dart';

class RealizarPedidoScreen extends StatefulWidget {
  final Plato plato;

  const RealizarPedidoScreen({
    super.key,
    required this.plato,
  });

  @override
  State<RealizarPedidoScreen> createState() => _RealizarPedidoScreenState();
}

class _RealizarPedidoScreenState extends State<RealizarPedidoScreen> {
  int _cantidad = 1;
  bool _isLoading = false;

  double get _total => widget.plato.precio * _cantidad;

  void _incrementar() {
    setState(() {
      _cantidad++;
    });
  }

  void _decrementar() {
    if (_cantidad > 1) {
      setState(() {
        _cantidad--;
      });
    }
  }

  Future<void> _realizarPedido() async {
    final authViewModel = context.read<AuthViewModel>();
    final pedidosViewModel = context.read<PedidosViewModel>();

    if (authViewModel.currentUser == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para realizar un pedido'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final pedido = Pedido(
      id: '',
      clienteId: authViewModel.currentUser!.id,
      negocioId: widget.plato.negocioId,
      platoId: widget.plato.id,
      cantidad: _cantidad,
      estado: AppConstants.estadoPendiente,
      total: _total,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await pedidosViewModel.crearPedido(pedido: pedido);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 32),
              SizedBox(width: 12),
              Text('¡Pedido Realizado!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tu pedido de ${widget.plato.nombre} ha sido enviado.'),
              const SizedBox(height: 8),
              Text('Cantidad: $_cantidad'),
              Text('Total: ${AppConstants.currencySymbol} ${_total.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Text(
                'El negocio recibirá tu pedido en tiempo real.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realizar Pedido'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen del plato
                  if (widget.plato.tieneImagen)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: widget.plato.imagenUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Nombre del plato
                  Text(
                    widget.plato.nombre,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),

                  // Precio unitario
                  Text(
                    'Precio: ${widget.plato.precioFormateado}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Selector de cantidad
                  Text(
                    'Cantidad',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.textSecondary),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botón decrementar
                        IconButton(
                          onPressed: _cantidad > 1 ? _decrementar : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 40,
                          color: AppColors.primary,
                        ),

                        // Cantidad
                        Text(
                          '$_cantidad',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Botón incrementar
                        IconButton(
                          onPressed: _incrementar,
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 40,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Resumen
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${AppConstants.currencySymbol} ${_total.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total:',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${AppConstants.currencySymbol} ${_total.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botón confirmar pedido
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _realizarPedido,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textLight,
                    ),
                  )
                      : const Text(
                    'Confirmar Pedido',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}