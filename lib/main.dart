import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:riderzz_app/core/services/foreground_location_service.dart';
import 'package:riderzz_app/core/services/native_overlay_controller.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/app/routes/app_routes.dart';

import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/providers/location_provider.dart';
import 'package:riderzz_app/core/services/location_service.dart';
import 'package:riderzz_app/core/storage/secure_storage_service.dart';
import 'package:riderzz_app/core/services/broadcast_socket_service.dart';
import 'package:riderzz_app/core/services/reward_notification_coordinator.dart';

import 'package:riderzz_app/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:riderzz_app/features/auth/data/repositories/auth_repository.dart';
import 'package:riderzz_app/features/auth/providers/auth_provider.dart';

import 'package:riderzz_app/features/user/addresses/data/datasource/address_remote_datasource.dart';
import 'package:riderzz_app/features/user/addresses/data/repositories/address_repository.dart';
import 'package:riderzz_app/features/user/addresses/providers/address_provider.dart';
import 'package:riderzz_app/features/user/saved_routes/data/datasource/saved_route_remote_datasource.dart';
import 'package:riderzz_app/features/user/saved_routes/data/repositories/saved_route_repository.dart';
import 'package:riderzz_app/features/user/saved_routes/providers/saved_route_provider.dart';
import 'package:riderzz_app/features/vehicle/data/datasource/vehicle_remote_datasource.dart';
import 'package:riderzz_app/features/vehicle/data/repositories/vehicle_repository.dart';
import 'package:riderzz_app/features/vehicle/providers/vehicle_provider.dart';
import 'package:riderzz_app/features/driver/home/data/datasource/driver_remote_datasource.dart';
import 'package:riderzz_app/features/driver/home/data/repositories/driver_repository.dart';
import 'package:riderzz_app/features/driver/home/providers/driver_home_provider.dart';
import 'package:riderzz_app/core/services/location_tracking_service.dart';
import 'package:riderzz_app/services/notification/local_notification_service.dart';
import 'package:riderzz_app/features/user/home/data/datasource/booking_datasource.dart';
import 'package:riderzz_app/features/user/home/data/repositories/booking_repository.dart';
import 'package:riderzz_app/features/user/home/providers/booking_provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:riderzz_app/features/support/data/datasource/support_remote_datasource.dart';
import 'package:riderzz_app/features/support/data/repositories/support_repository.dart';
import 'package:riderzz_app/features/support/providers/support_provider.dart';

import 'package:riderzz_app/features/notification/data/datasource/notification_remote_datasource.dart';
import 'package:riderzz_app/features/notification/data/repositories/notification_repository.dart';
import 'package:riderzz_app/features/user/wallet/data/datasource/customer_wallet_remote_datasource.dart';
import 'package:riderzz_app/features/user/wallet/data/repositories/customer_wallet_repository.dart';
import 'package:riderzz_app/features/user/wallet/providers/customer_wallet_provider.dart';
import 'package:riderzz_app/features/user/coupons/data/datasource/customer_coupon_remote_datasource.dart';
import 'package:riderzz_app/features/user/coupons/data/repositories/customer_coupon_repository.dart';
import 'package:riderzz_app/features/user/coupons/providers/customer_coupon_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riderzz_app/core/services/firebase_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Print raw data payload
  print('Handling a background message: ${message.messageId}');
  print('Background Message data: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler);

  // Initialize FCM notification service (Phase 1)
  await FirebaseNotificationService.instance.initialize();

  // Initialize communication port for background service Isolate
  FlutterForegroundTask.initCommunicationPort();

  // Initialize foreground service options
  ForegroundLocationService.init();

  await LocalNotificationService.initialize();

  // Load .env configuration
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NativeOverlayController.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RewardNotificationCoordinator.instance.checkAndShowPendingReward();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NativeOverlayController.dispose();
    super.dispose();
  }

  // ── Lifecycle observer ──────────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        NativeOverlayController.onAppMovedToBackground();
        break;
      case AppLifecycleState.resumed:
        NativeOverlayController.onAppReturnedToForeground();
        RewardNotificationCoordinator.instance.checkAndShowPendingReward();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Core Services & Network
        Provider<SecureStorageService>(create: (_) => SecureStorageService()),
        ProxyProvider<SecureStorageService, ApiClient>(
          update: (context, storage, previous) =>
              ApiClient(storageService: storage),
        ),
        ProxyProvider<SecureStorageService, BroadcastSocketService>(
          update: (_, storage, previous) =>
              previous ?? BroadcastSocketService(storage),
        ),

        // 2. Data Sources
        ProxyProvider<ApiClient, AuthRemoteDataSource>(
          update: (_, apiClient, previous) => AuthRemoteDataSource(apiClient),
        ),
        ProxyProvider<ApiClient, AddressRemoteDataSource>(
          update: (_, apiClient, previous) =>
              AddressRemoteDataSource(apiClient),
        ),
        ProxyProvider<ApiClient, SavedRouteRemoteDataSource>(
          update: (_, apiClient, previous) =>
              SavedRouteRemoteDataSource(apiClient),
        ),
        ProxyProvider<ApiClient, VehicleRemoteDataSource>(
          update: (_, apiClient, previous) =>
              VehicleRemoteDataSource(apiClient),
        ),
        ProxyProvider<ApiClient, DriverRemoteDataSource>(
          update: (_, apiClient, previous) => DriverRemoteDataSource(apiClient),
        ),
        ProxyProvider<ApiClient, BookingRemoteDataSource>(
          update: (_, apiClient, previous) =>
              BookingRemoteDataSource(apiClient),
        ),
        ProxyProvider<ApiClient, SupportRemoteDataSource>(
          update: (_, apiClient, previous) =>
              SupportRemoteDataSource(apiClient),
        ),
        ProxyProvider<ApiClient, NotificationRemoteDataSource>(
          update: (_, apiClient, previous) =>
              NotificationRemoteDataSource(apiClient),
        ),
        ProxyProvider<ApiClient, CustomerWalletRemoteDataSource>(
          update: (_, apiClient, previous) =>
              CustomerWalletRemoteDataSource(apiClient),
        ),
        ProxyProvider<ApiClient, CustomerCouponRemoteDataSource>(
          update: (_, apiClient, previous) =>
              CustomerCouponRemoteDataSource(apiClient),
        ),

        // 3. Repositories
        ProxyProvider<AuthRemoteDataSource, AuthRepository>(
          update: (_, authDataSource, previous) =>
              AuthRepository(authDataSource),
        ),
        ProxyProvider<AddressRemoteDataSource, AddressRepository>(
          update: (_, addressDataSource, previous) =>
              AddressRepository(addressDataSource),
        ),
        ProxyProvider<SavedRouteRemoteDataSource, SavedRouteRepository>(
          update: (_, dataSource, previous) => SavedRouteRepository(dataSource),
        ),
        ProxyProvider<VehicleRemoteDataSource, VehicleRepository>(
          update: (_, dataSource, previous) =>
              VehicleRepository(dataSource),
        ),
        ProxyProvider<DriverRemoteDataSource, DriverRepository>(
          update: (_, dataSource, previous) => DriverRepository(dataSource),
        ),
        ProxyProvider<BookingRemoteDataSource, BookingRepository>(
          update: (_, dataSource, previous) => BookingRepository(dataSource),
        ),
        ProxyProvider<SupportRemoteDataSource, SupportRepository>(
          update: (_, dataSource, previous) => SupportRepository(dataSource),
        ),
        ProxyProvider2<NotificationRemoteDataSource, SecureStorageService, NotificationRepository>(
          update: (_, dataSource, storage, previous) =>
              previous ?? NotificationRepository(dataSource, storage),
        ),
        ProxyProvider<CustomerWalletRemoteDataSource, CustomerWalletRepository>(
          update: (_, dataSource, previous) =>
              CustomerWalletRepository(dataSource),
        ),
        ProxyProvider<CustomerCouponRemoteDataSource, CustomerCouponRepository>(
          update: (_, dataSource, previous) =>
              CustomerCouponRepository(dataSource),
        ),

        // 4. State Management (Providers)
        ChangeNotifierProxyProvider3<
          AuthRepository,
          SecureStorageService,
          NotificationRepository,
          AuthProvider
        >(
          create: (context) => AuthProvider(
            authRepository: context.read<AuthRepository>(),
            storageService: context.read<SecureStorageService>(),
            notificationRepository: context.read<NotificationRepository>(),
          ),
          update: (_, authRepo, storageService, notifRepo, previous) {
            // Inject NotificationRepository into FirebaseNotificationService
            // so token-refresh events can auto-upload.
            FirebaseNotificationService.instance
                .setNotificationRepository(notifRepo);
            return previous ??
                AuthProvider(
                  authRepository: authRepo,
                  storageService: storageService,
                  notificationRepository: notifRepo,
                );
          },
        ),

        ChangeNotifierProxyProvider<AddressRepository, AddressProvider>(
          create: (context) =>
              AddressProvider(context.read<AddressRepository>()),
          update: (_, addressRepo, previous) =>
              previous ?? AddressProvider(addressRepo),
        ),
        ChangeNotifierProxyProvider<SavedRouteRepository, SavedRouteProvider>(
          create: (context) =>
              SavedRouteProvider(context.read<SavedRouteRepository>()),
          update: (_, repo, previous) => previous ?? SavedRouteProvider(repo),
        ),
        ChangeNotifierProxyProvider<
          VehicleRepository,
          VehicleProvider
        >(
          create: (context) =>
              VehicleProvider(context.read<VehicleRepository>()),
          update: (_, repository, previous) =>
              previous ?? VehicleProvider(repository),
        ),
        ChangeNotifierProxyProvider2<
          DriverRepository,
          BroadcastSocketService,
          DriverHomeProvider
        >(
          create: (context) => DriverHomeProvider(
            context.read<DriverRepository>(),
            context.read<BroadcastSocketService>(),
          ),
          update: (_, repository, socketService, previous) =>
              previous ?? DriverHomeProvider(repository, socketService),
        ),
        ProxyProvider<DriverRepository, LocationTrackingService>(
          create: (context) =>
              LocationTrackingService(context.read<DriverRepository>()),
          update: (_, repository, previous) =>
              previous ?? LocationTrackingService(repository),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProxyProvider<BookingRepository, BookingProvider>(
          create: (context) =>
              BookingProvider(context.read<BookingRepository>()),
          update: (_, repository, previous) =>
              previous ?? BookingProvider(repository),
        ),

        // LocationProvider for current device location
        ChangeNotifierProvider<LocationProvider>(
          create: (_) => LocationProvider(LocationService()),
        ),
        ChangeNotifierProxyProvider<SupportRepository, SupportProvider>(
          create: (context) =>
              SupportProvider(context.read<SupportRepository>()),
          update: (_, repository, previous) =>
              previous ?? SupportProvider(repository),
        ),
        ChangeNotifierProxyProvider<CustomerWalletRepository, CustomerWalletProvider>(
          create: (context) =>
              CustomerWalletProvider(context.read<CustomerWalletRepository>()),
          update: (_, repository, previous) =>
              previous ?? CustomerWalletProvider(repository),
        ),
        ChangeNotifierProxyProvider<CustomerCouponRepository, CustomerCouponProvider>(
          create: (context) =>
              CustomerCouponProvider(context.read<CustomerCouponRepository>()),
          update: (_, repository, previous) =>
              previous ?? CustomerCouponProvider(repository),
        ),
      ],
      child: MaterialApp(
        title: 'Riderzz',
        navigatorKey: AppRoutes.navigatorKey,
        navigatorObservers: [
          RewardNotificationCoordinator.instance.routeObserver,
        ],
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: GoogleFonts.interTextTheme(),
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
