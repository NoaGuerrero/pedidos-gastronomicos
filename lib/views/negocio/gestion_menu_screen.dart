import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/platos_viewmodel.dart';
import '../../widgets/plato_card.dart';
import 'crear_plato_screen.dart';

class GestionMenuScreen extends StatefulWidget {
  const GestionMenuScreen({super.key});

  @override
  State<GestionMenuScreen> createState() => _GestionMenuScreenState();
}

class _GestionMenuScreenState extends State<GestionMenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarPlatos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarPlatos() async {
    final authViewModel = context.read<AuthViewModel>();
    final platosViewModel = context.read<PlatosViewModel>();

    if (authViewModel.currentUser != null) {
      await platosViewModel.cargarPlatos(authViewModel.currentUser!.id);
    }
  }

  Future<void> _navigateToCrearPlato({bool isEdit = false}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearPlatoScreen(isEdit: isEdit),
      ),
    );

    // Si se creó/editó un plato, recargar lista
    if (result == true) {
      _cargarPlatos();
    }
  }

  Future<void> _confirmarEliminar(String platoId, String nombrePlato) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar "$nombrePlato"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<PlatosViewModel>().eliminarPlato(platoId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                context.read<PlatosViewModel>().successMessage ??
                    'Plato eliminado'
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Menú'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPlatos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<PlatosViewModel>(
        builder: (context, platosViewModel, child) {
          // Mostrar mensajes de error
          if (platosViewModel.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(platosViewModel.errorMessage!),
                  backgroundColor: AppColors.error,
                ),
              );
              platosViewModel.clearError();
            });
          }

          // Mostrar mensajes de éxito
          if (platosViewModel.successMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(platosViewModel.successMessage!),
                  backgroundColor: AppColors.success,
                ),
              );
              platosViewModel.clearSuccess();
            });
          }

          return Column(
            children: [
              // Barra de búsqueda y estadísticas
              _buildHeader(platosViewModel),

              // Lista de platos
              Expanded(
                child: _buildPlatosList(platosViewModel),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<PlatosViewModel>().seleccionarPlato(null);
          _navigateToCrearPlato(isEdit: false);
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar Plato'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  /// Header con búsqueda y estadísticas
  Widget _buildHeader(PlatosViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.cardBackground,
      child: Column(
        children: [
          // Búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar platos...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
              )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // Estadísticas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Total',
                viewModel.totalPlatos.toString(),
                AppColors.info,
              ),
              _buildStatCard(
                'Disponibles',
                viewModel.platosDisponibles.length.toString(),
                AppColors.success,
              ),
              _buildStatCard(
                'No disponibles',
                viewModel.platosNoDisponibles.length.toString(),
                AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Card de estadística
  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Lista de platos con grid responsive
  Widget _buildPlatosList(PlatosViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!viewModel.hasPlatos) {
      return _buildEmptyState();
    }

    // Filtrar platos por búsqueda
    final platos = _searchQuery.isEmpty
        ? viewModel.platos
        : viewModel.filtrarPorNombre(_searchQuery);

    if (platos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron platos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarPlatos,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determinar número de columnas según ancho
          int crossAxisCount = 2;
          double childAspectRatio = 0.85; // Aumentado significativamente

          if (constraints.maxWidth < 360) {
            // Pantallas muy pequeñas: 1 columna
            crossAxisCount = 1;
            childAspectRatio = 1.4;
          } else if (constraints.maxWidth < 600) {
            // Pantallas medianas: 2 columnas
            crossAxisCount = 2;
            childAspectRatio = 0.75; // Mucho más alto para evitar overflow
          } else {
            // Pantallas grandes (tablets): 3 columnas
            crossAxisCount = 3;
            childAspectRatio = 0.90;
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: platos.length,
            itemBuilder: (context, index) {
              final plato = platos[index];

              return PlatoCard(
                plato: plato,
                onEdit: () {
                  viewModel.seleccionarPlato(plato);
                  _navigateToCrearPlato(isEdit: true);
                },
                onDelete: () => _confirmarEliminar(plato.id, plato.nombre),
                onToggleDisponibilidad: () async {
                  final success = await viewModel.toggleDisponibilidad(plato.id);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(viewModel.successMessage ?? 'Actualizado'),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Estado vacío
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.restaurant_menu,
            size: 100,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          Text(
            'No tienes platos aún',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primer plato para comenzar',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.read<PlatosViewModel>().seleccionarPlato(null);
              _navigateToCrearPlato(isEdit: false);
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar Primer Plato'),
          ),
        ],
      ),
    );
  }
}