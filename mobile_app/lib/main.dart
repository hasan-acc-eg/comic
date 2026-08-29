// mobile_app/lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FlutterSecureStorage>(
          create: (_) => const FlutterSecureStorage(),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthService(context.read<FlutterSecureStorage>()),
        ),
        ProxyProvider<AuthService, ApiService>(
          update: (_, authService, __) => ApiService(authService),
        ),
      ],
      child: MaterialApp(
        title: 'كوميكس دايلي',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/home': (context) => const HomeScreen(),
          '/search': (context) => const SearchScreen(),
        },
      ),
    );
  }
}