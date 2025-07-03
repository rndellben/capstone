// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/device_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/actuator_provider.dart';
import 'providers/grow_profile_provider.dart'; 
import 'providers/grow_provider.dart'; 
import 'providers/harvest_log_provider.dart';
import 'providers/performance_matrix_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/plant_profile_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/user_profile_provider.dart';
import 'routes/route_generator.dart';
import 'core/api/api_service.dart';
import 'core/constants/app_colors.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/push_notification_service.dart';
import 'data/local/hive_service.dart';
import 'data/remote/firebase_service.dart';
import 'data/repositories/device_repository.dart';
import 'data/repositories/grow_profile_repository.dart';
import 'data/repositories/alert_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/plant_profile_repository.dart';
import 'ui/pages/auth/splash_screen.dart';

// Global navigator key for safe navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Service instances
final connectivityService = ConnectivityService();
final hiveService = HiveService();
final firebaseService = FirebaseService();
final apiService = ApiService();

// Repository instances
final deviceRepository = DeviceRepository();
final growProfileRepository = GrowProfileRepository();
final alertRepository = AlertRepository();
final plantProfileRepository = PlantProfileRepository();
final dashboardRepository = DashboardRepository(
  hiveService: hiveService, 
  firebaseService: firebaseService, 
  connectivityService: connectivityService
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize connectivity service first
  connectivityService.initialize();
  
  // Initialize Hive for local storage
  await hiveService.initialize();
  
  // Initialize repositories
  await deviceRepository.initialize();
  await growProfileRepository.initialize();
  await alertRepository.initialize();
  await plantProfileRepository.initialize();
  await dashboardRepository.initialize();
  
  // Create sync service
  final syncService = SyncService(
    deviceRepository: deviceRepository,
    growProfileRepository: growProfileRepository,
    alertRepository: alertRepository,
    connectivityService: connectivityService,
    hiveService: hiveService,
  );
  
  // Create notification provider before push notification service
  final notificationProvider = NotificationProvider();
  
  // Create and initialize push notification service
  // PushNotificationService will handle Firebase initialization
  final pushNotificationService = PushNotificationService(notificationProvider);
  await pushNotificationService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<NotificationProvider>.value(value: notificationProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => ActuatorProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => GrowProfileProvider()),
        ChangeNotifierProvider(create: (_) => GrowProvider()),
        ChangeNotifierProvider(create: (_) => HarvestLogProvider(apiService)),
        ChangeNotifierProvider(create: (_) => PerformanceMatrixProvider()),
        ChangeNotifierProvider(create: (_) => PlantProfileProvider(
          apiService, 
          repository: plantProfileRepository, 
          connectivityService: connectivityService
        )),
        ChangeNotifierProvider(create: (_) => DashboardProvider(dashboardRepository: dashboardRepository)),
        // Provide repositories
        Provider<DeviceRepository>.value(value: deviceRepository),
        Provider<GrowProfileRepository>.value(value: growProfileRepository),
        Provider<AlertRepository>.value(value: alertRepository),
        Provider<PlantProfileRepository>.value(value: plantProfileRepository),
        Provider<DashboardRepository>.value(value: dashboardRepository),
        // Provide services
        Provider<ConnectivityService>.value(value: connectivityService),
        Provider<SyncService>.value(value: syncService),
        Provider<HiveService>.value(value: hiveService),
        Provider<PushNotificationService>.value(value: pushNotificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'HydroZap',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        // Set Montserrat as the default font family
        fontFamily: 'Montserrat',
        
        // Primary and accent colors
        primarySwatch: Colors.blue,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),

        // Text theme configuration with responsive scaling
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: MediaQuery.of(context).size.width > 1200 ? 48 : 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: MediaQuery.of(context).size.width > 1200 ? 40 : 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          displaySmall: TextStyle(
            fontSize: MediaQuery.of(context).size.width > 1200 ? 32 : 24,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            fontSize: MediaQuery.of(context).size.width > 1200 ? 28 : 20,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            fontSize: MediaQuery.of(context).size.width > 1200 ? 24 : 18,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            fontSize: MediaQuery.of(context).size.width > 1200 ? 20 : 16,
            fontWeight: FontWeight.normal,
          ),
          bodyMedium: TextStyle(
            fontSize: MediaQuery.of(context).size.width > 1200 ? 18 : 14,
            fontWeight: FontWeight.normal,
          ),
          labelLarge: TextStyle(
            fontSize: MediaQuery.of(context).size.width > 1200 ? 20 : 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ).apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),

        // Input decoration theme with responsive padding
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.normal,
          contentPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width > 1200 ? 32 : 16,
            vertical: MediaQuery.of(context).size.width > 1200 ? 20 : 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary.withAlpha((0.3 * 255).round())),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.error),
          ),
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: MediaQuery.of(context).size.width > 1200 ? 18 : 14,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withAlpha((0.7 * 255).round()),
            fontSize: MediaQuery.of(context).size.width > 1200 ? 18 : 14,
          ),
        ),

        // Button theme with responsive padding
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 1200 ? 48 : 24,
              vertical: MediaQuery.of(context).size.width > 1200 ? 32 : 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: MediaQuery.of(context).size.width > 1200 ? 22 : 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            minimumSize: Size(
              MediaQuery.of(context).size.width > 1200 ? 200 : 120,
              MediaQuery.of(context).size.width > 1200 ? 64 : 48,
            ),
          ),
        ),

        // Outlined button theme with responsive padding
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 1200 ? 48 : 24,
              vertical: MediaQuery.of(context).size.width > 1200 ? 32 : 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: MediaQuery.of(context).size.width > 1200 ? 22 : 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            minimumSize: Size(
              MediaQuery.of(context).size.width > 1200 ? 200 : 120,
              MediaQuery.of(context).size.width > 1200 ? 64 : 48,
            ),
            side: BorderSide(
              color: AppColors.primary,
              width: MediaQuery.of(context).size.width > 1200 ? 2 : 1,
            ),
          ),
        ),

        // Card theme with responsive elevation and border radius
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              MediaQuery.of(context).size.width > 1200 ? 24 : 16,
            ),
          ),
          elevation: MediaQuery.of(context).size.width > 1200 ? 6 : 2,
          margin: EdgeInsets.all(
            MediaQuery.of(context).size.width > 1200 ? 16 : 8,
          ),
        ),

        // Add responsive spacing
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      
      // Use the splash screen as home
      home: const SplashScreen(),
      
      // Set initialRoute to null since we're using home
      initialRoute: null,
      
      // Keep the route generator for navigation after splash screen
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
