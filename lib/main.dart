import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/app/routes/app_routes.dart';

import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/providers/location_provider.dart';
import 'package:riderzz_app/core/services/location_service.dart';
import 'package:riderzz_app/core/storage/secure_storage_service.dart';

import 'package:riderzz_app/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:riderzz_app/features/auth/data/repositories/auth_repository.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';

import 'package:riderzz_app/features/user/addresses/data/datasource/address_remote_datasource.dart';
import 'package:riderzz_app/features/user/addresses/data/repositories/address_repository.dart';
import 'package:riderzz_app/features/user/addresses/providers/address_provider.dart';

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
        // 1. Core Services & Network
        Provider<SecureStorageService>(create: (_) => SecureStorageService()),
        ProxyProvider<SecureStorageService, ApiClient>(
          update: (context, storage, previous) => ApiClient(storageService: storage),
        ),
        
        // 2. Data Sources
        ProxyProvider<ApiClient, AuthRemoteDataSource>(
          update: (_, apiClient, previous) => AuthRemoteDataSource(apiClient),
        ),
        ProxyProvider<ApiClient, AddressRemoteDataSource>(
          update: (_, apiClient, previous) => AddressRemoteDataSource(apiClient),
        ),

        // 3. Repositories
        ProxyProvider<AuthRemoteDataSource, AuthRepository>(
          update: (_, authDataSource, previous) => AuthRepository(authDataSource),
        ),
        ProxyProvider<AddressRemoteDataSource, AddressRepository>(
          update: (_, addressDataSource, previous) => AddressRepository(addressDataSource),
        ),
        
        // 4. State Management (Providers)
        ChangeNotifierProxyProvider2<AuthRepository, SecureStorageService, AuthProvider>(
          create: (context) => AuthProvider(
            authRepository: context.read<AuthRepository>(),
            storageService: context.read<SecureStorageService>(),
          ),
          update: (_, authRepo, storageService, previous) =>
              previous ?? AuthProvider(authRepository: authRepo, storageService: storageService),
        ),

        ChangeNotifierProxyProvider<AddressRepository, AddressProvider>(
          create: (context) => AddressProvider(context.read<AddressRepository>()),
          update: (_, addressRepo, previous) => previous ?? AddressProvider(addressRepo),
        ),

        // LocationProvider for current device location
        ChangeNotifierProvider<LocationProvider>(
          create: (_) => LocationProvider(LocationService()),
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
