import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/pedido_model.dart';

class PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback? onTap;
  final VoidCallback? onCambiarEstado;
  final VoidCallback? onCancelar;
  final bool mostrarCliente;
  final bool mostrarNegocio;
  final bool mostrarAcciones;

  const PedidoCard({
    super.key,
    required this.pedido,
    this.onTap,
    this.onCambiarEstado,
    this.onCancelar,
    this.mostrarCliente = false,
    this.mostrarNegocio = false,
    this.mostrarAcciones = false,
  });

  Color _getEstadoColor() {
    switch (pedido.estado) {
      case AppConstants.estadoPendiente:
        return AppColors.estadoPendiente;
      case AppConstants.estadoEnPreparacion:
        return AppColors.estadoEnPreparacion;
      case AppConstants.estadoListo:
        return AppColors.estadoListo;
      case AppConstants.estadoEntregado:
        return AppColors.estadoEntregado;
      case AppConstants.estadoCancelado:
        return AppColors.estadoCancelado;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getEstadoTexto() {
    switch (pedido.estado) {
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
        return pedido.estado;
    }
  }

  IconData _getEstadoIcon() {
    switch (pedido.estado) {
      case AppConstants.estadoPendiente:
        return Icons.schedule;
      case AppConstants.estadoEnPreparacion:
        return Icons.restaurant;
      case AppConstants.estadoListo:
        return Icons.check_circle;
      case AppConstants.estadoEntregado:
        return Icons.done_all;
      case AppConstants.estadoCancelado:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor = _getEstadoColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con plato e imagen
              Row(
                children: [
                  // Imagen del plato
                  if (pedido.platoImagenUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: pedido.platoImagenUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: AppColors.background,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: AppColors.background,
                          child: const Icon(Icons.restaurant, size: 30),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.restaurant, size: 30),
                    ),
                  const SizedBox(width: 12),

                  // Info del pedido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pedido.platoNombre ?? 'Plato',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cantidad: ${pedido.cantidad}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  // Badge de estado
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: estadoColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getEstadoIcon(),
                          size: 16,
                          color: estadoColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getEstadoTexto(),
                          style: TextStyle(
                            color: estadoColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Información adicional
              if (mostrarCliente && pedido.clienteNombre != null)
                _buildInfoRow(
                  Icons.person,
                  'Cliente',
                  pedido.clienteNombre!,
                ),

              if (mostrarNegocio && pedido.negocioNombre != null)
                _buildInfoRow(
                  Icons.store,
                  'Negocio',
                  pedido.negocioNombre!,
                ),

              _buildInfoRow(
                Icons.attach_money,
                'Total',
                pedido.totalFormateado,
              ),

              _buildInfoRow(
                Icons.access_time,
                'Fecha',
                DateFormat('dd/MM/yyyy HH:mm').format(pedido.createdAt),
              ),

              // Acciones
              if (mostrarAcciones && pedido.isActivo) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                _buildAcciones(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcciones(BuildContext context) {
    if (pedido.isPendiente) {
      return Row(
        children: [
          if (onCancelar != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCancelar,
                icon: const Icon(Icons.cancel, size: 18),
                label: const Text('Cancelar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          if (onCancelar != null && onCambiarEstado != null)
            const SizedBox(width: 12),
          if (onCambiarEstado != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCambiarEstado,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Aceptar'),
              ),
            ),
        ],
      );
    } else if (onCambiarEstado != null) {
      String textoBoton;
      IconData iconBoton;

      if (pedido.isEnPreparacion) {
        textoBoton = 'Marcar Listo';
        iconBoton = Icons.check_circle;
      } else if (pedido.isListo) {
        textoBoton = 'Entregar';
        iconBoton = Icons.done_all;
      } else {
        return const SizedBox.shrink();
      }

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onCambiarEstado,
          icon: Icon(iconBoton, size: 18),
          label: Text(textoBoton),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}