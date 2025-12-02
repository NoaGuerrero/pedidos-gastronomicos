import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/pedidos_viewmodel.dart';
import '../auth/login_screen.dart';
import '../negocio/gestion_menu_screen.dart';
import '../negocio/pedidos_recibidos_screen.dart';
import '../negocio/historial_negocio_screen.dart';

class NegocioHomeScreen extends StatefulWidget {
  const NegocioHomeScreen({super.key});

  @override
  State<NegocioHomeScreen> createState() => _NegocioHomeScreenState();
}

class _NegocioHomeScreenState extends State<NegocioHomeScreen> {
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

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await context.read<AuthViewModel>().signOut();

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  void _navigateToGestionMenu(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GestionMenuScreen()),
    );
  }

  void _navigateToPedidos(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PedidosRecibidosScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Negocio'),
        actions: [
          Consumer<PedidosViewModel>(
            builder: (context, pedidosViewModel, child) {
              final pedidosActivos = pedidosViewModel.pedidosActivos.length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag),
                    onPressed: () => _navigateToPedidos(context),
                    tooltip: 'Pedidos',
                  ),
                  if (pedidosActivos > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          pedidosActivos > 9 ? '9+' : '$pedidosActivos',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Consumer2<AuthViewModel, PedidosViewModel>(
        builder: (context, authViewModel, pedidosViewModel, child) {
          final user = authViewModel.currentUser;

          // Mostrar notificación de nuevo pedido
          if (pedidosViewModel.successMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.notifications_active, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(pedidosViewModel.successMessage!),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'Ver',
                    textColor: Colors.white,
                    onPressed: () => _navigateToPedidos(context),
                  ),
                ),
              );
              pedidosViewModel.clearSuccess();
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary,
                          child: Icon(
                            Icons.store,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '¡Hola, ${user?.nombre ?? "Negocio"}!',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Resumen de pedidos
                if (pedidosViewModel.hasPedidosActivos)
                  Card(
                    color: AppColors.warning.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.pending_actions,
                            size: 40,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${pedidosViewModel.pedidosActivos.length} pedidos activos',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${pedidosViewModel.pedidosPendientes.length} pendientes',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _navigateToPedidos(context),
                            child: const Text('Ver todos'),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Funcionalidades
                Text(
                  'Funcionalidades',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _buildFeatureCard(
                  context,
                  icon: Icons.restaurant_menu,
                  title: 'Gestión de Menú',
                  subtitle: 'Administra tus platos',
                  color: AppColors.primary,
                  onTap: () => _navigateToGestionMenu(context),
                ),
                const SizedBox(height: 12),

                _buildFeatureCard(
                  context,
                  icon: Icons.shopping_bag,
                  title: 'Pedidos Recibidos',
                  subtitle: 'Gestiona los pedidos',
                  color: AppColors.secondary,
                  onTap: () => _navigateToPedidos(context),
                  badge: pedidosViewModel.pedidosActivos.length,
                ),
                const SizedBox(height: 12),

                _buildFeatureCard(
                  context,
                  icon: Icons.history,
                  title: 'Historial',
                  subtitle: 'Ver pedidos pasados',
                  color: AppColors.info,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistorialNegocioScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        VoidCallback? onTap,
        int? badge,
      }) {
    final isAvailable = onTap != null;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? color.withOpacity(0.1)
                          : AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: isAvailable ? color : AppColors.textSecondary,
                    ),
                  ),
                  if (badge != null && badge > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          badge > 9 ? '9+' : '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isAvailable
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isAvailable
                            ? AppColors.textSecondary
                            : AppColors.textSecondary.withOpacity(0.7),
                        fontStyle: isAvailable
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAvailable)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}