import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_colors.dart';
import '../models/plato_model.dart';

class PlatoCard extends StatelessWidget {
  final Plato plato;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleDisponibilidad;
  final bool showActions;
  final bool isCompact;
  final bool showNegocioName;

  const PlatoCard({
    super.key,
    required this.plato,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleDisponibilidad,
    this.showActions = true,
    this.isCompact = false,
    this.showNegocioName = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen con altura reducida
            _buildImage(context),

            // Contenido expandido para ocupar espacio disponible
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre + badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plato.nombre,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildDisponibilidadBadge(),
                      ],
                    ),

                    // Mostrar nombre del negocio si está habilitado
                    if (showNegocioName) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.store,
                            size: 10,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'ID: ${plato.negocioId.substring(0, 8)}...', // Mostrar ID corto
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (!isCompact) ...[
                      const SizedBox(height: 3),
                      // Descripción eliminada para ahorrar espacio en grid

                      // Categoría
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          plato.categoria,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Precio
                      Text(
                        plato.precioFormateado,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ] else ...[
                      // Compacto: solo precio
                      const Spacer(),
                      Text(
                        plato.precioFormateado,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],

                    // Acciones compactas
                    if (showActions) ...[
                      const SizedBox(height: 4),
                      _buildActions(context),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir imagen del plato con altura reducida
  Widget _buildImage(BuildContext context) {
    return SizedBox(
      height: isCompact ? 80 : 120, // Reducido a 120 para dar más espacio al contenido
      width: double.infinity,
      child: plato.tieneImagen
          ? CachedNetworkImage(
        imageUrl: plato.imagenUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.background,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      )
          : _buildPlaceholder(),
    );
  }

  /// Placeholder cuando no hay imagen
  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Icon(
          Icons.restaurant,
          size: 48,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  /// Badge de disponibilidad más compacto
  Widget _buildDisponibilidadBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: plato.disponible ? AppColors.success : AppColors.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        plato.disponible ? 'Disp' : 'N/D',
        style: const TextStyle(
          color: AppColors.textLight,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Acciones más compactas con altura fija
  Widget _buildActions(BuildContext context) {
    return SizedBox(
      height: 28, // Reducido de 32 a 28
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Toggle disponibilidad
          if (onToggleDisponibilidad != null)
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  plato.disponible ? Icons.visibility : Icons.visibility_off,
                  size: 16,
                ),
                onPressed: onToggleDisponibilidad,
                tooltip: plato.disponible
                    ? 'Marcar como no disponible'
                    : 'Marcar como disponible',
                color: AppColors.info,
              ),
            ),

          // Editar
          if (onEdit != null)
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.edit, size: 16),
                onPressed: onEdit,
                tooltip: 'Editar plato',
                color: AppColors.secondary,
              ),
            ),

          // Eliminar
          if (onDelete != null)
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.delete, size: 16),
                onPressed: onDelete,
                tooltip: 'Eliminar plato',
                color: AppColors.error,
              ),
            ),
        ],
      ),
    );
  }
}