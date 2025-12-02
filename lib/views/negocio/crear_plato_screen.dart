import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/plato_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/platos_viewmodel.dart';

class CrearPlatoScreen extends StatefulWidget {
  final bool isEdit;

  const CrearPlatoScreen({
    super.key,
    this.isEdit = false,
  });

  @override
  State<CrearPlatoScreen> createState() => _CrearPlatoScreenState();
}

class _CrearPlatoScreenState extends State<CrearPlatoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();

  String _categoriaSeleccionada = 'Plato Principal';
  bool _disponible = true;

  // Imagen
  XFile? _imagenSeleccionada;
  Uint8List? _imagenBytes; // Para web
  String? _imagenUrlActual;
  bool _imagenCambiada = false;

  final ImagePicker _picker = ImagePicker();

  // Categorías predefinidas
  final List<String> _categorias = [
    'Entrada',
    'Plato Principal',
    'Guarnición',
    'Postre',
    'Bebida',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _cargarDatosPlato();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  void _cargarDatosPlato() {
    final plato = context.read<PlatosViewModel>().platoSeleccionado;
    if (plato != null) {
      _nombreController.text = plato.nombre;
      _descripcionController.text = plato.descripcion;
      _precioController.text = plato.precio.toString();
      _categoriaSeleccionada = plato.categoria;
      _disponible = plato.disponible;
      _imagenUrlActual = plato.imagenUrl;
    }
  }

  Future<void> _seleccionarImagen() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        // Para web, leer como bytes
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _imagenSeleccionada = image;
            _imagenBytes = bytes;
            _imagenCambiada = true;
          });
        } else {
          // Para móvil
          setState(() {
            _imagenSeleccionada = image;
            _imagenCambiada = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _imagenSeleccionada = image;
            _imagenBytes = bytes;
            _imagenCambiada = true;
          });
        } else {
          setState(() {
            _imagenSeleccionada = image;
            _imagenCambiada = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al tomar foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen();
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _tomarFoto();
                },
              ),
            if (_imagenSeleccionada != null || _imagenUrlActual != null)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar imagen'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imagenSeleccionada = null;
                    _imagenBytes = null;
                    _imagenUrlActual = null;
                    _imagenCambiada = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarPlato() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authViewModel = context.read<AuthViewModel>();
    final platosViewModel = context.read<PlatosViewModel>();

    if (authViewModel.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No hay usuario autenticado'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Crear objeto Plato
    final plato = Plato(
      id: widget.isEdit
          ? platosViewModel.platoSeleccionado!.id
          : '',
      negocioId: authViewModel.currentUser!.id,
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      precio: double.parse(_precioController.text),
      imagenUrl: _imagenUrlActual,
      categoria: _categoriaSeleccionada,
      disponible: _disponible,
      createdAt: DateTime.now(),
    );

    bool success;

    if (widget.isEdit) {
      // Actualizar plato existente
      if (kIsWeb) {
        success = await platosViewModel.actualizarPlatoFromBytes(
          platoId: plato.id,
          plato: plato,
          imageBytes: _imagenCambiada ? _imagenBytes : null,
          imageExtension: _imagenSeleccionada != null
              ? _imagenSeleccionada!.path.split('.').last
              : null,
          deleteOldImage: _imagenCambiada && _imagenUrlActual != null,
        );
      } else {
        success = await platosViewModel.actualizarPlato(
          platoId: plato.id,
          plato: plato,
          imagePath: _imagenCambiada ? _imagenSeleccionada?.path : null,
          deleteOldImage: _imagenCambiada && _imagenUrlActual != null,
        );
      }
    } else {
      // Crear nuevo plato
      if (kIsWeb) {
        success = await platosViewModel.crearPlatoFromBytes(
          plato: plato,
          imageBytes: _imagenBytes,
          imageExtension: _imagenSeleccionada?.path.split('.').last,
        );
      } else {
        success = await platosViewModel.crearPlato(
          plato: plato,
          imagePath: _imagenSeleccionada?.path,
        );
      }
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              platosViewModel.errorMessage ?? 'Error al guardar plato'
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Editar Plato' : 'Nuevo Plato'),
        actions: [
          Consumer<PlatosViewModel>(
            builder: (context, viewModel, child) {
              return TextButton(
                onPressed: viewModel.isCreating || viewModel.isUpdating
                    ? null
                    : _guardarPlato,
                child: viewModel.isCreating || viewModel.isUpdating
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textLight,
                    ),
                  ),
                )
                    : const Text(
                  'Guardar',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<PlatosViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Selector de imagen
                  _buildImageSelector(),
                  const SizedBox(height: 24),

                  // Nombre
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del plato',
                      hintText: 'Ej: Hamburguesa Especial',
                      prefixIcon: Icon(Icons.fastfood),
                    ),
                    validator: Validators.nombre,
                    enabled: !viewModel.isCreating && !viewModel.isUpdating,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Describe tu plato...',
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: Validators.descripcion,
                    enabled: !viewModel.isCreating && !viewModel.isUpdating,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  // Precio y Categoría
                  Row(
                    children: [
                      // Precio
                      Expanded(
                        child: TextFormField(
                          controller: _precioController,
                          decoration: InputDecoration(
                            labelText: 'Precio',
                            hintText: '0.00',
                            prefixText: '${AppConstants.currencySymbol} ',
                            prefixIcon: const Icon(Icons.attach_money),
                          ),
                          validator: Validators.precio,
                          enabled: !viewModel.isCreating && !viewModel.isUpdating,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Categoría
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _categoriaSeleccionada,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: _categorias.map((categoria) {
                            return DropdownMenuItem(
                              value: categoria,
                              child: Text(categoria, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: viewModel.isCreating || viewModel.isUpdating
                              ? null
                              : (value) {
                            setState(() {
                              _categoriaSeleccionada = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Disponibilidad
                  Card(
                    child: SwitchListTile(
                      title: const Text('Disponible'),
                      subtitle: Text(
                        _disponible
                            ? 'El plato está disponible para pedidos'
                            : 'El plato no está disponible',
                      ),
                      value: _disponible,
                      onChanged: viewModel.isCreating || viewModel.isUpdating
                          ? null
                          : (value) {
                        setState(() {
                          _disponible = value;
                        });
                      },
                      activeColor: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón Guardar (móvil)
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: viewModel.isCreating || viewModel.isUpdating
                          ? null
                          : _guardarPlato,
                      child: viewModel.isCreating || viewModel.isUpdating
                          ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textLight,
                        ),
                      )
                          : Text(
                        widget.isEdit ? 'Actualizar Plato' : 'Crear Plato',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Selector de imagen con preview
  Widget _buildImageSelector() {
    return GestureDetector(
      onTap: _mostrarOpcionesImagen,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textSecondary,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: _buildImagePreview(),
      ),
    );
  }

  /// Preview de la imagen
  Widget _buildImagePreview() {
    // Si hay imagen nueva seleccionada
    if (_imagenSeleccionada != null) {
      if (kIsWeb && _imagenBytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            _imagenBytes!,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        );
      } else if (!kIsWeb) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(_imagenSeleccionada!.path),
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        );
      }
    }

    // Si hay imagen actual (modo edición)
    if (_imagenUrlActual != null && !_imagenCambiada) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: _imagenUrlActual!,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => _buildPlaceholder(),
        ),
      );
    }

    // Placeholder
    return _buildPlaceholder();
  }

  /// Placeholder cuando no hay imagen
  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_photo_alternate,
          size: 64,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 8),
        Text(
          'Toca para agregar una imagen',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}