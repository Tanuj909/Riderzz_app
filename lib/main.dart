import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/app/routes/app_routes.dart';
import 'package:riderzz_app/core/api/dio_client.dart';
import 'package:riderzz_app/core/storage/secure_storage_service.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';
import 'package:riderzz_app/features/auth/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env configuration
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services and core clients
        Provider<DioClient>(create: (_) => DioClient()),
        Provider<SecureStorageService>(create: (_) => SecureStorageService()),
        
        // Proxy provider for AuthService depending on DioClient
        ProxyProvider<DioClient, AuthService>(
          update: (_, dioClient, previous) => AuthService(dioClient),
        ),
        
        // ChangeNotifierProvider for AuthProvider
        ChangeNotifierProxyProvider2<AuthService, SecureStorageService, AuthProvider>(
          create: (context) => AuthProvider(
            authService: context.read<AuthService>(),
            storageService: context.read<SecureStorageService>(),
          ),
          update: (_, authService, storageService, previous) =>
              previous ?? AuthProvider(authService: authService, storageService: storageService),
        ),
      ],
      child: MaterialApp(
        title: 'Riderzz',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.cyanAccent,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.initial,
        routes: AppRoutes.routes,
      ),
    );
  }
}
