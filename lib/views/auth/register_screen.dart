import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../cliente/cliente_home_screen.dart';
import '../negocio/negocio_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRol = AppConstants.rolCliente;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma tu contraseña';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    // Limpiar errores previos
    context.read<AuthViewModel>().clearError();

    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar términos y condiciones
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Realizar registro
    final success = await context.read<AuthViewModel>().signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      nombre: _nombreController.text.trim(),
      rol: _selectedRol,
    );

    if (!mounted) return;

    if (success) {
      final authViewModel = context.read<AuthViewModel>();
      final user = authViewModel.currentUser;

      if (user == null) return;

      // Mostrar mensaje de éxito
      if (authViewModel.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authViewModel.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
      }

      // Navegar según el rol
      Widget homeScreen;
      if (user.isNegocio) {
        homeScreen = const NegocioHomeScreen();
      } else {
        homeScreen = const ClienteHomeScreen();
      }

      // Reemplazar toda la pila de navegación
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => homeScreen),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Consumer<AuthViewModel>(
              builder: (context, authViewModel, child) {
                // Mostrar mensajes de error
                if (authViewModel.errorMessage != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(authViewModel.errorMessage!),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                    authViewModel.clearError();
                  });
                }

                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo/Icono
                      const Icon(
                        Icons.person_add_outlined,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),

                      // Título
                      Text(
                        'Registro',
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Subtítulo
                      Text(
                        'Crea tu cuenta para comenzar',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Campo Nombre
                      TextFormField(
                        controller: _nombreController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo',
                          hintText: 'Juan Pérez',
                          prefixIcon: Icon(Icons.person_outlined),
                        ),
                        validator: Validators.nombre,
                        enabled: !authViewModel.isAuthenticating,
                      ),
                      const SizedBox(height: 16),

                      // Campo Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'correo@ejemplo.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: Validators.email,
                        enabled: !authViewModel.isAuthenticating,
                      ),
                      const SizedBox(height: 16),

                      // Selector de Rol
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.textSecondary,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Tipo de cuenta',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            RadioListTile<String>(
                              title: const Text('Cliente'),
                              subtitle: const Text(
                                'Puedo realizar pedidos',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: AppConstants.rolCliente,
                              groupValue: _selectedRol,
                              activeColor: AppColors.primary,
                              onChanged: authViewModel.isAuthenticating
                                  ? null
                                  : (value) {
                                setState(() {
                                  _selectedRol = value!;
                                });
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text('Negocio'),
                              subtitle: const Text(
                                'Puedo gestionar menú y pedidos',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: AppConstants.rolNegocio,
                              groupValue: _selectedRol,
                              activeColor: AppColors.primary,
                              onChanged: authViewModel.isAuthenticating
                                  ? null
                                  : (value) {
                                setState(() {
                                  _selectedRol = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Campo Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: Validators.password,
                        enabled: !authViewModel.isAuthenticating,
                      ),
                      const SizedBox(height: 16),

                      // Campo Confirmar Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Confirmar Contraseña',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: _validateConfirmPassword,
                        enabled: !authViewModel.isAuthenticating,
                        onFieldSubmitted: (_) => _handleRegister(),
                      ),
                      const SizedBox(height: 16),

                      // Términos y Condiciones
                      Row(
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            onChanged: authViewModel.isAuthenticating
                                ? null
                                : (value) {
                              setState(() {
                                _acceptTerms = value ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: authViewModel.isAuthenticating
                                  ? null
                                  : () {
                                setState(() {
                                  _acceptTerms = !_acceptTerms;
                                });
                              },
                              child: Text(
                                'Acepto los términos y condiciones',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Botón de Registro
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: authViewModel.isAuthenticating
                              ? null
                              : _handleRegister,
                          child: authViewModel.isAuthenticating
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textLight,
                              ),
                            ),
                          )
                              : const Text(
                            'Crear Cuenta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Link a Login
                      Center(
                        child: TextButton(
                          onPressed: authViewModel.isAuthenticating
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text(
                            '¿Ya tienes cuenta? Inicia sesión',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}