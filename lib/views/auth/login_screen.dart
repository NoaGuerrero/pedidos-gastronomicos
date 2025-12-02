import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../cliente/cliente_home_screen.dart';
import '../negocio/negocio_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Limpiar errores previos
    context.read<AuthViewModel>().clearError();

    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Realizar login
    final success = await context.read<AuthViewModel>().signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final authViewModel = context.read<AuthViewModel>();
      final user = authViewModel.currentUser;

      if (user == null) return;

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
    } else {
      // Mostrar error (se mostrará automáticamente con el listener)
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  void _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa tu email primero'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final success = await context.read<AuthViewModel>().resetPassword(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              context.read<AuthViewModel>().successMessage ??
                  'Email de recuperación enviado'
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Consumer<AuthViewModel>(
              builder: (context, authViewModel, child) {

                // EDICION POR ERROR
                // Null check operator used on a null value
                // login_screen.dart:125:65
                final message = authViewModel.errorMessage;

                if (message != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo/Icono
                      const Icon(
                        Icons.restaurant_menu,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),

                      // Título
                      Text(
                        'Bienvenido',
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Subtítulo
                      Text(
                        'Inicia sesión para continuar',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

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

                      // Campo Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
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
                        onFieldSubmitted: (_) => _handleLogin(),
                      ),
                      const SizedBox(height: 8),

                      // Recordarme y Olvidé contraseña
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: authViewModel.isAuthenticating
                                    ? null
                                    : (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              Text(
                                'Recordarme',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: authViewModel.isAuthenticating
                                ? null
                                : _handleForgotPassword,
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Botón de Login
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: authViewModel.isAuthenticating
                              ? null
                              : _handleLogin,
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
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('O'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Botón de Registro
                      OutlinedButton(
                        onPressed: authViewModel.isAuthenticating
                            ? null
                            : _navigateToRegister,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        child: const Text(
                          '¿No tienes cuenta? Regístrate',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.primary,
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