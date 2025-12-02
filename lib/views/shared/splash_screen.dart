import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/theme/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/viewmodels/auth_viewmodel.dart';
import '/views/auth/login_screen.dart';
import '/views/cliente/cliente_home_screen.dart';
import '/views/negocio/negocio_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Esperar 2 segundos para mostrar el splash
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Obtener el AuthViewModel
    final authViewModel = context.read<AuthViewModel>();

    // Esperar a que termine de cargar
    while (authViewModel.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    // Verificar si el usuario está autenticado
    Widget nextScreen;

    if (authViewModel.isAuthenticated && authViewModel.currentUser != null) {
      // Usuario autenticado - navegar según rol
      final user = authViewModel.currentUser!;
      if (user.isNegocio) {
        nextScreen = const NegocioHomeScreen();
      } else {
        nextScreen = const ClienteHomeScreen();
      }
    } else {
      // No autenticado - ir a login
      nextScreen = const LoginScreen();
    }

    // Navegar
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o ícono
            const Icon(
              Icons.restaurant_menu,
              size: 100,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 24),
            // Nombre de la app
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}