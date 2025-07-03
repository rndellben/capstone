import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/remote/firebase_service.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../components/custom_card.dart';
import 'account/account_settings_page.dart';
import 'notification/notification_settings_page.dart';
import 'measurements/units_measurements_page.dart';
import 'device_settings_page.dart';
import 'terms_of_service_page.dart';
import 'privacy_policy_page.dart';
import 'send_feedback/send_feedback_page.dart';
import 'help_center/help_center_page.dart';

class SettingsPage extends StatefulWidget {
  final String userId;

  const SettingsPage({super.key, required this.userId});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textOnDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.forest,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnDark),
      ),
      drawer: AppDrawer(userId: widget.userId),
      body: Container(
        color: Colors.grey[100], // Light background similar to example
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isDesktop = constraints.maxWidth > 700;

                  // Setting options with distinct colors
                  final userSettings = [
                    _buildSettingsCard(
                      title: 'Account Settings',
                      description: 'Manage your profile',
                      icon: Icons.account_circle,
                      iconColor: const Color(0xFF7B1FA2), // Purple
                      backgroundColor: Colors.white,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccountSettingsPage(),
                          ),
                        );
                      },
                    ),
                  ];

                  final appSettings = [
                    _buildSettingsCard(
                      title: 'Notifications',
                      description: 'Configure alerts',
                      icon: Icons.notifications,
                      iconColor: const Color(0xFF303F9F), // Indigo
                      backgroundColor: Colors.white,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationSettingsPage(),
                          ),
                        );
                      },
                    ),
                    
                  ];

                  final supportSettings = [
                    _buildSettingsCard(
                      title: 'Help Center',
                      description: 'Get help with the app',
                      icon: Icons.help,
                      iconColor: const Color(0xFF0288D1), // Light Blue
                      backgroundColor: Colors.white,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpCenterPage(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsCard(
                      title: 'Send Feedback',
                      description: 'Report bugs or suggest features',
                      icon: Icons.feedback,
                      iconColor: const Color(0xFF00897B), // Teal
                      backgroundColor: Colors.white,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SendFeedbackPage(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsCard(
                      title: 'About',
                      description: 'App information and policies',
                      icon: Icons.info,
                      iconColor: const Color(0xFF512DA8), // Deep Purple
                      backgroundColor: Colors.white,
                      onTap: () {
                        _showAboutBottomSheet();
                      },
                    ),
                  ];

                  // For desktop view, we'll merge all sections together in a single grid
                  if (isDesktop) {
                    List<Widget> allCards = [];
                    allCards.addAll(userSettings);
                    allCards.addAll(appSettings);
                    allCards.addAll(supportSettings);
                    
                    return GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.0, // Perfect square
                      children: allCards,
                    );
                  } else {
                    // For mobile, keep the existing layout with sections
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildSectionHeader('User Settings', AppColors.forest),
                        Column(children: userSettings),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Application Settings', AppColors.moss),
                        Column(children: appSettings),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Support & Feedback', AppColors.soil),
                        Column(children: supportSettings),
                        const SizedBox(height: 36),
                        _buildLogoutButton(),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoonMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        backgroundColor: AppColors.moss,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showAboutBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Hydrozap',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.moss,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Smart hydroponics monitoring and control',
              style: TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildAboutOptionButton(
              title: 'Terms of Service',
              icon: Icons.gavel,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsOfServicePage(),
                  ),
                );
              },
            ),
            _buildAboutOptionButton(
              title: 'Privacy Policy',
              icon: Icons.privacy_tip,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyPage(),
                  ),
                );
              },
            ),
            _buildAboutOptionButton(
              title: 'Licenses',
              icon: Icons.description,
              onTap: () {
                Navigator.pop(context);
                showLicensePage(
                  context: context,
                  applicationName: 'Hydrozap',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(
                    Icons.eco,
                    size: 50,
                    color: AppColors.moss,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutOptionButton({
    required String title, 
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.moss,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    final bool isDesktop = MediaQuery.of(context).size.width > 700;
    
    if (isDesktop) {
      // Desktop dashboard-style tile layout like the example image
      return InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large centered icon
              Expanded(
                flex: 3,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              ),
              // Title at the bottom
              Expanded(
                flex: 1,
                child: Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Mobile list-style layout
      return Card(
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: AppColors.sand,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.stone.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildLogoutButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sunset,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _firebaseService.signOut();
      if (!mounted) return;
      
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}