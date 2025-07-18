// routes/route_generator.dart
import 'package:flutter/material.dart';
import '../ui/pages/auth/welcome_page.dart';
import '../ui/pages/auth/login_page.dart';
import '../ui/pages/auth/register_page.dart';
import '../ui/pages/dashboard/dashboard_page.dart';
import '../ui/pages/device/add_device_page.dart';
import '../ui/pages/device/device_details_page.dart';
import '../ui/pages/data/data_monitoring_page.dart';
import '../ui/pages/grow/add_grow_page.dart';
import '../ui/pages/grow/grow_list_page.dart';
import '../ui/pages/grow_profile/add_profile/add_profile_page.dart';
import 'package:hydrozap_app/ui/pages/device/actuator_settings_page.dart' as actuator;
import 'package:hydrozap_app/ui/pages/grow_profile/profile_list_page.dart' as profile;
import '../ui/pages/plant_profile/plant_profile_page.dart';
import '../ui/pages/alerts/alerts_page.dart';
import '../ui/pages/alerts/trigger_alert_page.dart';
import '../ui/pages/performance/performance_matrix_page.dart';
import '../ui/pages/performance/performance_results_page.dart';
import '../ui/pages/predictor/predictor_page.dart';
import '../ui/pages/predictor/environment_recommendation_page.dart';
import '../ui/pages/settings/settings_page.dart';
import '../ui/pages/settings/account/account_settings_page.dart';
import '../ui/pages/onboarding/onboarding_flow.dart';
import '../ui/pages/change_logs/changes_log_page.dart';
import 'app_routes.dart';
import '../core/models/device_model.dart';
import '../ui/pages/performance/global_leaderboard_page.dart';
import '../ui/pages/performance/leaderboard_entry_detail_page.dart';
import '../core/models/performance_matrix_model.dart'; // Contains LeaderboardEntry class
import '../ui/pages/dosing_logs/dosing_logs_page.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomePage());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case AppRoutes.dashboard:
        final userId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => DashboardPage(userId: userId));
      case AppRoutes.addDevice:
        final userId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => AddDevicePage(userId: userId));
      case AppRoutes.deviceDetails:
        final device = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => DeviceDetailsPage(
          device: DeviceModel.fromJson(device['device_id'] as String, device)
        ));
      case AppRoutes.dataMonitoring:
        return MaterialPageRoute(builder: (_) => const DataMonitoringPage());
      case AppRoutes.addGrow:
        final userId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => AddGrowPage(userId: userId));
      case AppRoutes.growList:
        final userId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => GrowListPage(userId: userId));
      case AppRoutes.addProfile:
        final args = settings.arguments;
        // Handle both String and Map arguments for backward compatibility
        if (args is String) {
          // Original case: just userId as String
          return MaterialPageRoute(builder: (_) => AddProfilePage(userId: args));
        } else if (args is Map<String, dynamic>) {
          // New case: Map with userId and optional recommendation_data
          final userId = args['userId'] as String;
          final recommendationData = args['recommendation_data'] as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => AddProfilePage(
              userId: userId,
              recommendationData: recommendationData,
            ),
          );
        } else {
          // Fallback
          return _errorRoute();
        }
      case AppRoutes.profileList:
        final userId = settings.arguments as String;  
        return MaterialPageRoute(builder: (_) => profile.ProfileListPage(userId: userId));
      case AppRoutes.plantProfiles:
        final userId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => PlantProfilePage(userId: userId));
      case AppRoutes.actuatorSettings:
        final deviceId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => actuator.ActuatorSettingsPage(deviceId: deviceId));
      case AppRoutes.alerts:
        final userId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => AlertsPage(userId: userId));
      case AppRoutes.triggerAlert:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) =>
                TriggerAlertPage(userId: args['user_id'], deviceId: args['device_id']));
      case AppRoutes.performanceMatrix:
        final userId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => PerformanceMatrixPage(userId: userId));
      case AppRoutes.performanceResults:
        final userId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => PerformanceResultsPage(userId: userId));
      case AppRoutes.predictor:
        final userId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => PredictorPage(userId: userId));
      case AppRoutes.environmentRecommendation:
        final userId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => EnvironmentRecommendationPage(userId: userId));
      case AppRoutes.settings:
        final userId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => SettingsPage(userId: userId));
      case AppRoutes.accountSettings:
        return MaterialPageRoute(builder: (_) => const AccountSettingsPage());
      case AppRoutes.onboardingFlow:
        return MaterialPageRoute(builder: (_) => const OnboardingFlow());
      case AppRoutes.changesLog:
        return MaterialPageRoute(builder: (_) => const ChangesLogPage());
      case AppRoutes.globalLeaderboard:
        return MaterialPageRoute(
          builder: (_) => GlobalLeaderboardPage(userId: settings.arguments as String),
        );
      case AppRoutes.leaderboardEntryDetail:
        return MaterialPageRoute(
          builder: (_) => LeaderboardEntryDetailPage(entry: settings.arguments as LeaderboardEntry),
        );
      case AppRoutes.dosingLogs:
        final deviceId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => DosingLogsPage(deviceId: deviceId));
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Page not found!")),
      ),
    );
  }
}
