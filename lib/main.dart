import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'services/supabase_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/platos_viewmodel.dart';
import 'viewmodels/pedidos_viewmodel.dart';
import 'views/shared/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await SupabaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => PlatosViewModel()),
        ChangeNotifierProvider(create: (_) => PedidosViewModel()),
      ],
      child: MaterialApp(
        title: 'Pedidos Gastronómicos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}