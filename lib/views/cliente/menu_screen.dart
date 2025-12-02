import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/platos_viewmodel.dart';
import '../../widgets/plato_card.dart';
import 'detalle_plato_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _categoriaSeleccionada = 'Todas';
  String _negocioSeleccionado = 'Todos';

  // Lista de negocios (se cargará dinámicamente)
  List<Map<String, String>> _negocios = [];
  bool _loadingNegocios = true;

  @override
  void initState() {
    super.initState();
    _cargarPlatos();
    _cargarNegocios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarPlatos() async {
    await context.read<PlatosViewModel>().cargarPlatosDisponibles();
  }

  Future<void> _cargarNegocios() async {
    setState(() => _loadingNegocios = true);

    try {
      final viewModel = context.read<PlatosViewModel>();
      final negocios = await viewModel.obtenerNegociosConPlatos();

      setState(() {
        _negocios = negocios;
        _loadingNegocios = false;
      });
    } catch (e) {
      setState(() => _loadingNegocios = false);
    }
  }

  void _navigateToDetalle(BuildContext context, String platoId) {
    final plato = context.read<PlatosViewModel>().platos
        .firstWhere((p) => p.id == platoId);

    context.read<PlatosViewModel>().seleccionarPlato(plato);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DetallePlatoScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú Disponible'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _cargarPlatos();
              _cargarNegocios();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<PlatosViewModel>(
        builder: (context, viewModel, child) {
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

          return Column(
            children: [
              _buildHeader(viewModel),
              Expanded(
                child: _buildPlatosList(viewModel),
              ),
            ],
          );
        },
      ),
    );
  }

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

          // Filtro de restaurantes/negocios
          if (!_loadingNegocios && _negocios.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Restaurante',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildNegocioChip('Todos', ''),
                  ..._negocios.map((negocio) =>
                      _buildNegocioChip(negocio['nombre']!, negocio['id']!)
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Filtro de categorías
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Categoría',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 45,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoriaChip('Todas'),
                ...viewModel.categorias.map((cat) => _buildCategoriaChip(cat)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNegocioChip(String nombre, String id) {
    final isSelected = _negocioSeleccionado == id ||
        (id.isEmpty && _negocioSeleccionado == 'Todos');

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(nombre),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _negocioSeleccionado = id.isEmpty ? 'Todos' : id;
          });
        },
        backgroundColor: AppColors.background,
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildCategoriaChip(String categoria) {
    final isSelected = _categoriaSeleccionada == categoria;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(categoria),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _categoriaSeleccionada = categoria;
          });
        },
        backgroundColor: AppColors.background,
        selectedColor: AppColors.accent.withOpacity(0.3),
        checkmarkColor: AppColors.accent,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPlatosList(PlatosViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!viewModel.hasPlatos) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restaurant_menu,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay platos disponibles',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Los restaurantes aún no han publicado su menú',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Filtrar platos
    var platos = viewModel.platosDisponibles;

    // Filtrar por negocio/restaurante
    if (_negocioSeleccionado != 'Todos') {
      platos = platos.where((plato) => plato.negocioId == _negocioSeleccionado).toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      platos = platos.where((plato) {
        return plato.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            plato.descripcion.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filtrar por categoría
    if (_categoriaSeleccionada != 'Todas') {
      platos = platos.where((plato) => plato.categoria == _categoriaSeleccionada).toList();
    }

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
            const SizedBox(height: 8),
            Text(
              'Intenta con otros filtros',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _cargarPlatos();
        await _cargarNegocios();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determinar número de columnas según ancho
          int crossAxisCount = 2;
          double childAspectRatio = 0.75; // Ajustado igual que GestionMenuScreen

          if (constraints.maxWidth < 360) {
            // Pantallas muy pequeñas: 1 columna
            crossAxisCount = 1;
            childAspectRatio = 1.3;
          } else if (constraints.maxWidth < 600) {
            // Pantallas medianas: 2 columnas
            crossAxisCount = 2;
            childAspectRatio = 0.75; // Más altura para evitar overflow
          } else {
            // Pantallas grandes (tablets): 3 columnas
            crossAxisCount = 3;
            childAspectRatio = 0.80;
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
                showActions: false,
                showNegocioName: true, // Mostrar nombre del restaurante
                onTap: () => _navigateToDetalle(context, plato.id),
              );
            },
          );
        },
      ),
    );
  }
}