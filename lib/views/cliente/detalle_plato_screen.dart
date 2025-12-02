import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../viewmodels/platos_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/plato_model.dart';
import 'realizar_pedido_screen.dart';

class DetallePlatoScreen extends StatelessWidget {
  const DetallePlatoScreen({super.key});

  void _navigateToRealizarPedido(BuildContext context, Plato plato) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RealizarPedidoScreen(plato: plato),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PlatosViewModel>(
        builder: (context, viewModel, child) {
          final plato = viewModel.platoSeleccionado;

          if (plato == null) {
            return const Center(
              child: Text('Plato no encontrado'),
            );
          }

          return CustomScrollView(
            slivers: [
              // AppBar con imagen
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: plato.tieneImagen
                      ? CachedNetworkImage(
                    imageUrl: plato.imagenUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.background,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        _buildPlaceholder(),
                  )
                      : _buildPlaceholder(),
                ),
              ),

              // Contenido
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre y categorÃ­a
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              plato.nombre,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          _buildDisponibilidadBadge(plato.disponible),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // CategorÃ­a
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          plato.categoria,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Precio
                      Text(
                        plato.precioFormateado,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // DescripciÃ³n
                      Text(
                        'Descripción',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        plato.descripcion,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),

                      // BotÃ³n de pedido
                      if (plato.disponible)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToRealizarPedido(context, plato),
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text(
                              'Realizar Pedido',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Este plato no estÃ¡ disponible',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Icon(
          Icons.restaurant,
          size: 100,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildDisponibilidadBadge(bool disponible) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: disponible ? AppColors.success : AppColors.error,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        disponible ? 'Disponible' : 'No disponible',
        style: const TextStyle(
          color: AppColors.textLight,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}