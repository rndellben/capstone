import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hydrozap_app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/dashboard_provider.dart';
import 'responsive_widget.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/auth_provider.dart';
import '../pages/auth/login_page.dart';
import '../../../main.dart'; // Import the main.dart to access the navigator key

class AppDrawer extends StatefulWidget {
  final String? userId;

  const AppDrawer({super.key, this.userId});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCounts();
    });
  }

  Future<void> _fetchCounts() async {
    if (widget.userId == null) return;

    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    // Only fetch if not already loading
    if (!dashboardProvider.isLoading) {
      await dashboardProvider.fetchCounts(widget.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
           gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forest, AppColors.accent],
        ),
          borderRadius: ResponsiveWidget.isDesktop(context)
              ? const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                )
              : null,
        ),
        child: Column(
          children: const [
            _DrawerHeader(),
            SizedBox(height: 8),
            Expanded(child: _MenuItems()),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
      decoration: BoxDecoration(
        // Use a gradient background from forest to leaf
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forest, AppColors.leaf],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            // Gradient leaf icon
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.leaf, AppColors.forest],
                ).createShader(bounds);
              },
              child: const Icon(Icons.eco, size: 40, color: Colors.white),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HydroZap',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Smart Hydroponics Control',
                  style: TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItems extends StatelessWidget {
  const _MenuItems();

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final userId = (context.findAncestorWidgetOfExactType<AppDrawer>())?.userId;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    Widget divider(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        );

    Widget navItem(String title, IconData icon, String route,
        {bool highlighted = false, String? badge, Color badgeColor = AppColors.secondary}) {
      // Check if this is the current route
      final isCurrentRoute = currentRoute == route;
      final isHighlighted = highlighted || isCurrentRoute;
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Icon(icon, color: isHighlighted ? AppColors.secondary : AppColors.normal, size: 22),
          title: Text(
            title,
            style: TextStyle(
              color: isHighlighted ? AppColors.secondary : AppColors.normal,
              fontSize: 15,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          trailing: badge != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
                  child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onTap: () => Navigator.of(context).pushNamed(route, arguments: userId),
          tileColor: isHighlighted ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        ),
      );
    }

    // Custom navItem for Data Monitoring that navigates directly without device requirements
    final dataMonitoringItem = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(Icons.analytics, color: AppColors.normal, size: 22),
        title: Text(
          'Data Monitoring',
          style: TextStyle(
            color: AppColors.normal,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          Navigator.of(context).pushNamed(AppRoutes.dataMonitoring);
        },
        tileColor: Colors.transparent,
      ),
    );

    // Dosing Logs nav item (requires a deviceId)
    final dosingLogsItem = Builder(
      builder: (context) {
        final devices = deviceProvider.devices;
        final hasDevice = devices.isNotEmpty;
        final deviceId = hasDevice ? devices.first.id : null;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Icon(Icons.science, color: hasDevice ? AppColors.normal : Colors.grey, size: 22),
          title: Text(
            'Dosing Logs',
            style: TextStyle(
              color: hasDevice ? AppColors.normal : Colors.grey,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          enabled: hasDevice,
          onTap: hasDevice
              ? () => Navigator.of(context).pushNamed(AppRoutes.dosingLogs, arguments: deviceId)
              : null,
          tileColor: Colors.transparent,
        );
      },
    );

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      children: [
        divider('Main'),
        navItem('Dashboard', Icons.dashboard_rounded, AppRoutes.dashboard),
        
        navItem('Active Grows', Icons.eco_outlined, AppRoutes.growList),

        divider('Performance'),
        navItem('Results & Top Performers', Icons.analytics_outlined, AppRoutes.performanceResults),
        navItem('Global Leaderboard', Icons.emoji_events_outlined, AppRoutes.globalLeaderboard),
        navItem('Crop Suitability', Icons.auto_graph, AppRoutes.predictor),

        divider('Profiles'),
        navItem('Grow Profiles', Icons.grain_rounded, AppRoutes.profileList),
        navItem('Plant Profiles', Icons.eco_rounded, AppRoutes.plantProfiles),

        divider('System'),
        navItem('Alerts', Icons.notifications_active, AppRoutes.alerts,
            badge: dashboardProvider.alertCount.toString(), badgeColor: Colors.redAccent),
        dataMonitoringItem,  // Use the custom item instead of navItem
        dosingLogsItem,
        navItem('Changes Log', Icons.history, AppRoutes.changesLog),
        navItem('Settings', Icons.settings, AppRoutes.settings),

        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          // First just close the dialog
                          Navigator.pop(context);
                          
                          try {
                            // Get auth provider and properly trigger logout
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            print('AppDrawer: Starting logout process');
                            await authProvider.logout();
                            print('AppDrawer: Logout successful');
                            
                            // Schedule navigation for the next frame to avoid widget disposal issues
                            print('AppDrawer: Scheduling navigation');
                            // Use a safer approach by scheduling navigation for the next frame
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              print('AppDrawer: Post-frame callback executing');
                              final context = navigatorKey.currentContext;
                              if (context != null) {
                                print('AppDrawer: Navigating with global navigator key');
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
                                );
                              } else {
                                print('AppDrawer: No valid context found for navigation, using direct routing');
                                // Manual navigation as last resort
                                final route = MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                );
                                Navigator.pushAndRemoveUntil(
                                  navigatorKey.currentState!.context,
                                  route,
                                  (route) => false,
                                );
                              }
                            });
                          } catch (e) {
                            print('AppDrawer: Logout error - $e');
                            // Error handling will need to be adjusted due to context issues
                          }
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.normal,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
