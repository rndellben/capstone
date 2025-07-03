import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/grow_profile_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/grow_profile_provider.dart';
import '../../../data/local/shared_prefs.dart';
import '../../widgets/responsive_widget.dart';
import 'edit_profile_page.dart';

class ProfileDetailPage extends StatefulWidget {
  final String profileId;

  const ProfileDetailPage({super.key, required this.profileId});

  @override
  _ProfileDetailPageState createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  late GrowProfile profile;
  bool isLoading = true;
  String? error;
  String userId = '';
  bool isAdvancedMode = false; // Track simple/advanced mode for optimal conditions

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Implement the logic to load the profile
    try {
      // Get the user ID from SharedPrefs
      final fetchedUserId = await SharedPrefs.getUserId();
      
      if (fetchedUserId == null || fetchedUserId.isEmpty) {
        setState(() {
          error = "User not authenticated";
          isLoading = false;
        });
        return;
      }
      
      // Save the user ID for use in the widget
      userId = fetchedUserId;
      
      // Create a temporary profile to prevent LateInitializationError
      profile = GrowProfile(
        id: widget.profileId,
        name: "Loading...",
        userId: userId,
        growDurationDays: 0,
        isActive: false,
        plantProfileId: "",
        optimalConditions: StageConditions(
          transplanting: OptimalConditions(
            temperature: Range(min: 0, max: 0),
            humidity: Range(min: 0, max: 0),
            phRange: Range(min: 0, max: 0),
            ecRange: Range(min: 0, max: 0),
            tdsRange: Range(min: 0, max: 0),
          ),
          vegetative: OptimalConditions(
            temperature: Range(min: 0, max: 0),
            humidity: Range(min: 0, max: 0),
            phRange: Range(min: 0, max: 0),
            ecRange: Range(min: 0, max: 0),
            tdsRange: Range(min: 0, max: 0),
          ),
          maturation: OptimalConditions(
            temperature: Range(min: 0, max: 0),
            humidity: Range(min: 0, max: 0),
            phRange: Range(min: 0, max: 0),
            ecRange: Range(min: 0, max: 0),
            tdsRange: Range(min: 0, max: 0),
          ),
        ),
        createdAt: DateTime.now(),
      );
      
      // Use the provider to get all profiles and find the matching one
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final profileProvider = Provider.of<GrowProfileProvider>(context, listen: false);
        
        // First check if profiles are already loaded
        if (!profileProvider.isLoading && profileProvider.growProfiles.isNotEmpty) {
          final foundProfiles = profileProvider.growProfiles
              .where((p) => p.id == widget.profileId)
              .toList();
              
          if (foundProfiles.isNotEmpty) {
            setState(() {
              profile = foundProfiles.first;
              isLoading = false;
            });
          } else {
            setState(() {
              error = "Profile not found";
              isLoading = false;
            });
          }
        }
        
        // Profiles not yet loaded, request to load them
        profileProvider.fetchGrowProfiles(userId).then((_) {
          final foundProfiles = profileProvider.growProfiles
              .where((p) => p.id == widget.profileId)
              .toList();
              
          if (foundProfiles.isNotEmpty) {
            setState(() {
              profile = foundProfiles.first;
              isLoading = false;
            });
          } else {
            setState(() {
              error = "Profile not found";
              isLoading = false;
            });
          }
        }).catchError((e) {
          setState(() {
            error = e.toString();
            isLoading = false;
          });
        });
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _editProfile();
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (error != null) {
            return Center(
              child: Text('Error: $error'),
            );
          }

          // Use different layouts based on screen width
          final screenWidth = MediaQuery.of(context).size.width;
          
          if (screenWidth < 600) {
            return _buildMobileLayout(context);
          } else if (screenWidth < 1200) {
            return _buildTabletLayout(context);
          } else {
            return _buildDesktopLayout(context);
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildOptimalConditionsCard(context),
          const SizedBox(height: 16),
          _buildEditProfileButton(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryCardTablet(),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildInfoCardTablet(),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 7,
                    child: _buildOptimalConditionsCard(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildEditProfileButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 40.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryCardDesktop(),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildInfoCardDesktop(),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 8,
                    child: _buildOptimalConditionsCard(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildEditProfileButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 3,
      shadowColor: AppColors.primary.withAlpha((0.2 * 255).round()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
                    colors: [AppColors.leaf, AppColors.forest],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withAlpha((0.9 * 255).round()),
                  radius: 24,
                  child: const Icon(
                    Icons.eco,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Growth Duration: ${profile.growDurationDays} days',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withAlpha((0.9 * 255).round()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white30, height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  Icons.thermostat, 
                  profile.optimalConditions != null 
                      ? '${profile.optimalConditions!.vegetative.temperature.min}°C - ${profile.optimalConditions!.vegetative.temperature.max}°C'
                      : 'Not set',
                  'Temp'
                ),
                _buildSummaryItem(
                  Icons.water_drop, 
                  profile.optimalConditions != null 
                      ? '${profile.optimalConditions!.vegetative.humidity.min}% - ${profile.optimalConditions!.vegetative.humidity.max}%'
                      : 'Not set',
                  'Humidity'
                ),
                _buildSummaryItem(
                  Icons.science, 
                  profile.optimalConditions != null 
                      ? '${profile.optimalConditions!.vegetative.phRange.min} - ${profile.optimalConditions!.vegetative.phRange.max}'
                      : 'Not set',
                  'pH'
                ),
                _buildSummaryItem(
                  Icons.electric_bolt, 
                  profile.optimalConditions != null 
                      ? '${profile.optimalConditions!.vegetative.ecRange.min} - ${profile.optimalConditions!.vegetative.ecRange.max}'
                      : 'Not set',
                  'EC'
                ),
                _buildSummaryItem(
                  Icons.opacity, 
                  profile.optimalConditions != null 
                      ? '${profile.optimalConditions!.vegetative.tdsRange.min} - ${profile.optimalConditions!.vegetative.tdsRange.max}'
                      : 'Not set',
                  'TDS'
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCardTablet() {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shadowColor: AppColors.primary.withAlpha((0.2 * 255).round()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
                    colors: [AppColors.leaf, AppColors.forest],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withAlpha((0.9 * 255).round()),
                  radius: 32,
                  child: const Icon(
                    Icons.eco,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Growth Duration: ${profile.growDurationDays} days',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withAlpha((0.9 * 255).round()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white30, height: 1),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryItemTablet(
                  Icons.thermostat, 
                  profile.optimalConditions != null 
                      ? '${profile.optimalConditions!.vegetative.temperature.min}°C - ${profile.optimalConditions!.vegetative.temperature.max}°C'
                      : 'Not set',
                  'Temperature'
                ),
                _buildSummaryItemTablet(
                  Icons.water_drop, 
                  profile.optimalConditions != null 
                      ? '${profile.optimalConditions!.vegetative.humidity.min}% - ${profile.optimalConditions!.vegetative.humidity.max}%'
                      : 'Not set',
                  'Humidity'
                ),
                _buildSummaryItemTablet(
                  Icons.science, 
                  profile.optimalConditions != null 
                      ? '${profile.optimalConditions!.vegetative.phRange.min} - ${profile.optimalConditions!.vegetative.phRange.max}'
                      : 'Not set',
                  'pH Value'
                ),
                _buildSummaryItemTablet(
                  Icons.electric_bolt, 
                  profile.optimalConditions != null 
                      ? '${profile.optimalConditions!.vegetative.ecRange.min} - ${profile.optimalConditions!.vegetative.ecRange.max}'
                      : 'Not set',
                  'EC Value'
                ),
                _buildSummaryItemTablet(
                  Icons.opacity, 
                  profile.optimalConditions != null 
                      ? '${profile.optimalConditions!.vegetative.tdsRange.min} - ${profile.optimalConditions!.vegetative.tdsRange.max}'
                      : 'Not set',
                  'TDS (ppm)'
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCardDesktop() {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shadowColor: AppColors.primary.withAlpha((0.3 * 255).round()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
                    colors: [AppColors.leaf, AppColors.forest],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white.withAlpha((0.9 * 255).round()),
                      radius: 40,
                      child: const Icon(
                        Icons.eco,
                        color: AppColors.primary,
                        size: 48,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Growth Duration: ${profile.growDurationDays} days',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withAlpha((0.9 * 255).round()),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last Updated: ${profile.lastUpdated.year}-${profile.lastUpdated.month.toString().padLeft(2, '0')}-${profile.lastUpdated.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withAlpha((0.8 * 255).round()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(
                color: Colors.white30,
                width: 60,
                thickness: 1,
                indent: 10,
                endIndent: 10,
              ),
              Expanded(
                flex: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryItemDesktop(
                      Icons.thermostat, 
                      profile.optimalConditions != null 
                          ? '${profile.optimalConditions!.vegetative.temperature.min}°C - ${profile.optimalConditions!.vegetative.temperature.max}°C'
                          : 'Not set',
                      'Temperature'
                    ),
                    _buildSummaryItemDesktop(
                      Icons.water_drop, 
                      profile.optimalConditions != null 
                          ? '${profile.optimalConditions!.vegetative.humidity.min}% - ${profile.optimalConditions!.vegetative.humidity.max}%'
                          : 'Not set',
                      'Humidity'
                    ),
                    _buildSummaryItemDesktop(
                      Icons.science, 
                      profile.optimalConditions != null 
                          ? '${profile.optimalConditions!.vegetative.phRange.min} - ${profile.optimalConditions!.vegetative.phRange.max}'
                          : 'Not set',
                      'pH Value'
                    ),
                    _buildSummaryItemDesktop(
                      Icons.electric_bolt, 
                      profile.optimalConditions != null 
                          ? '${profile.optimalConditions!.vegetative.ecRange.min} - ${profile.optimalConditions!.vegetative.ecRange.max}'
                          : 'Not set',
                      'EC Value'
                    ),
                    _buildSummaryItemDesktop(
                      Icons.opacity, 
                      profile.optimalConditions != null 
                          ? '${profile.optimalConditions!.vegetative.tdsRange.min} - ${profile.optimalConditions!.vegetative.tdsRange.max}'
                          : 'Not set',
                      'TDS (ppm)'
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withAlpha((0.9 * 255).round()), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withAlpha((0.8 * 255).round()),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItemTablet(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.15 * 255).round()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon, 
            color: Colors.white, 
            size: 26,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withAlpha((0.8 * 255).round()),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItemDesktop(IconData icon, String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.15 * 255).round()),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon, 
            color: Colors.white, 
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withAlpha((0.8 * 255).round()),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.eco, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1),
            ),
            _buildInfoRow('Name', profile.name, Icons.subtitles),
            const SizedBox(height: 12),
            _buildInfoRow('Total Growing Time', '${profile.growDurationDays} days', Icons.timer),
            const SizedBox(height: 12),
            _buildInfoRow('Created On', '${profile.createdAt.year}-${profile.createdAt.month.toString().padLeft(2, '0')}-${profile.createdAt.day.toString().padLeft(2, '0')}', Icons.calendar_today),
            const SizedBox(height: 12),
            _buildInfoRow('Last Updated', '${profile.lastUpdated.year}-${profile.lastUpdated.month.toString().padLeft(2, '0')}-${profile.lastUpdated.day.toString().padLeft(2, '0')}', Icons.update),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCardTablet() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1),
            ),
            _buildInfoRowTablet('Name', profile.name, Icons.subtitles),
            const SizedBox(height: 16),
            _buildInfoRowTablet(
              'Total Growing Time', 
              '${profile.growDurationDays} days', 
              Icons.timer
            ),
            const SizedBox(height: 16),
            _buildInfoRowTablet(
              'Created On', 
              '${profile.createdAt.year}-${profile.createdAt.month.toString().padLeft(2, '0')}-${profile.createdAt.day.toString().padLeft(2, '0')}', 
              Icons.calendar_today
            ),
            const SizedBox(height: 16),
            _buildInfoRowTablet(
              'Last Updated', 
              '${profile.lastUpdated.year}-${profile.lastUpdated.month.toString().padLeft(2, '0')}-${profile.lastUpdated.day.toString().padLeft(2, '0')}', 
              Icons.update
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCardDesktop() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Divider(height: 1),
            ),
            _buildInfoRowDesktop('Name', profile.name, Icons.subtitles),
            const SizedBox(height: 20),
            _buildInfoRowDesktop(
              'Total Growing Time', 
              '${profile.growDurationDays} days', 
              Icons.timer
            ),
            const SizedBox(height: 20),
            _buildInfoRowDesktop(
              'Created On', 
              '${profile.createdAt.year}-${profile.createdAt.month.toString().padLeft(2, '0')}-${profile.createdAt.day.toString().padLeft(2, '0')}', 
              Icons.calendar_today
            ),
            const SizedBox(height: 20),
            _buildInfoRowDesktop(
              'Last Updated', 
              '${profile.lastUpdated.year}-${profile.lastUpdated.month.toString().padLeft(2, '0')}-${profile.lastUpdated.day.toString().padLeft(2, '0')}', 
              Icons.update
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimalConditionsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.thermostat, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Optimal Growing Conditions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isAdvancedMode = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: !isAdvancedMode ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Simple',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: !isAdvancedMode ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isAdvancedMode = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isAdvancedMode ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Advanced',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isAdvancedMode ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (profile.optimalConditions != null) ...[
              if (!isAdvancedMode) ...[
                // Simple mode - show only basic conditions
                _buildSimpleConditionsView(profile.optimalConditions!),
              ] else ...[
                // Advanced mode - show detailed stage breakdown
                _buildStageExpansionTileTablet(
                  'Transplanting Stage',
                  profile.optimalConditions!.transplanting,
                  Icons.eco,
                ),
                const SizedBox(height: 8),
                _buildStageExpansionTileTablet(
                  'Vegetative Stage',
                  profile.optimalConditions!.vegetative,
                  Icons.forest,
                ),
                const SizedBox(height: 8),
                _buildStageExpansionTileTablet(
                  'Maturation Stage',
                  profile.optimalConditions!.maturation,
                  Icons.spa,
                ),
              ],
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No optimal conditions specified',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptimalConditionsCardTablet() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.thermostat,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Optimal Growing Conditions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                // Mode toggle button for tablet
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isAdvancedMode = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: !isAdvancedMode ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            'Simple',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: !isAdvancedMode ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isAdvancedMode = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isAdvancedMode ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            'Advanced',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isAdvancedMode ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1),
            ),
            if (profile.optimalConditions != null) ...[
              if (!isAdvancedMode) ...[
                // Simple mode for tablet
                _buildSimpleConditionsView(profile.optimalConditions!),
              ] else ...[
                // Advanced mode for tablet
                _buildStageExpansionTileTablet(
                  'Transplanting Stage',
                  profile.optimalConditions!.transplanting,
                  Icons.eco,
                ),
                const SizedBox(height: 12),
                _buildStageExpansionTileTablet(
                  'Vegetative Stage',
                  profile.optimalConditions!.vegetative,
                  Icons.forest,
                ),
                const SizedBox(height: 12),
                _buildStageExpansionTileTablet(
                  'Maturation Stage',
                  profile.optimalConditions!.maturation,
                  Icons.spa,
                ),
              ],
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: AppColors.textSecondary.withAlpha((0.7 * 255).round()),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No optimal conditions specified',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptimalConditionsCardDesktop(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.thermostat,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Optimal Growing Conditions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                // Mode toggle button for desktop
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isAdvancedMode = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: !isAdvancedMode ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Text(
                            'Simple',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: !isAdvancedMode ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isAdvancedMode = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isAdvancedMode ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Text(
                            'Advanced',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isAdvancedMode ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Divider(height: 1),
            ),
            if (profile.optimalConditions != null) ...[
              if (!isAdvancedMode) ...[
                // Simple mode for desktop
                _buildSimpleConditionsViewDesktop(profile.optimalConditions!),
              ] else ...[
                // Advanced mode for desktop
                _buildStageExpansionTileDesktop(
                  'Transplanting Stage',
                  profile.optimalConditions!.transplanting,
                  Icons.eco,
                ),
                const SizedBox(height: 16),
                _buildStageExpansionTileDesktop(
                  'Vegetative Stage',
                  profile.optimalConditions!.vegetative,
                  Icons.forest,
                ),
                const SizedBox(height: 16),
                _buildStageExpansionTileDesktop(
                  'Maturation Stage',
                  profile.optimalConditions!.maturation,
                  Icons.spa,
                ),
              ],
            ] else ...[
              Builder(
                builder: (context) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 64,
                          color: AppColors.textSecondary.withAlpha((0.7 * 255).round()),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No optimal conditions specified',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Conditions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: () => _navigateToEditProfile(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleConditionsView(StageConditions conditions) {
    // Use vegetative stage as the primary reference for simple view
    final primaryConditions = conditions.vegetative;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha((0.05 * 255).round()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withAlpha((0.2 * 255).round()),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Primary Growing Conditions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildSimpleConditionItemTablet(
                    'Temperature',
                    '${primaryConditions.temperature.min}°C - ${primaryConditions.temperature.max}°C',
                    Icons.thermostat,
                  ),
                  _buildSimpleConditionItemTablet(
                    'Humidity',
                    '${primaryConditions.humidity.min}% - ${primaryConditions.humidity.max}%',
                    Icons.water_drop,
                  ),
                  _buildSimpleConditionItemTablet(
                    'pH Range',
                    '${primaryConditions.phRange.min} - ${primaryConditions.phRange.max}',
                    Icons.science,
                  ),
                  _buildSimpleConditionItemTablet(
                    'EC Range',
                    '${primaryConditions.ecRange.min} - ${primaryConditions.ecRange.max}',
                    Icons.electric_bolt,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withAlpha((0.05 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Switch to Advanced mode to view detailed conditions for each growth stage',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleConditionsViewTablet(StageConditions conditions) {
    // Use vegetative stage as the primary reference for simple view
    final primaryConditions = conditions.vegetative;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha((0.05 * 255).round()),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withAlpha((0.2 * 255).round()),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Primary Growing Conditions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildSimpleConditionItemTablet(
                    'Temperature',
                    '${primaryConditions.temperature.min}°C - ${primaryConditions.temperature.max}°C',
                    Icons.thermostat,
                  ),
                  _buildSimpleConditionItemTablet(
                    'Humidity',
                    '${primaryConditions.humidity.min}% - ${primaryConditions.humidity.max}%',
                    Icons.water_drop,
                  ),
                  _buildSimpleConditionItemTablet(
                    'pH Range',
                    '${primaryConditions.phRange.min} - ${primaryConditions.phRange.max}',
                    Icons.science,
                  ),
                  _buildSimpleConditionItemTablet(
                    'EC Range',
                    '${primaryConditions.ecRange.min} mS/cm - ${primaryConditions.ecRange.max} mS/cm',
                    Icons.electric_bolt,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withAlpha((0.05 * 255).round()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Switch to Advanced mode to view detailed conditions for each growth stage',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleConditionItemTablet(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withAlpha((0.1 * 255).round()),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStageExpansionTileTablet(String stageName, OptimalConditions conditions, IconData icon) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          stageName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _buildRangeRowTablet(
                  'Temperature', 
                  '${conditions.temperature.min}°C - ${conditions.temperature.max}°C',
                  Icons.thermostat
                ),
                const SizedBox(height: 12),
                _buildRangeRowTablet(
                  'Humidity', 
                  '${conditions.humidity.min}% - ${conditions.humidity.max}%',
                  Icons.water_drop
                ),
                const SizedBox(height: 12),
                _buildRangeRowTablet(
                  'pH Range', 
                  '${conditions.phRange.min} - ${conditions.phRange.max}',
                  Icons.science
                ),
                const SizedBox(height: 12),
                _buildRangeRowTablet(
                  'EC Range', 
                  '${conditions.ecRange.min} mS/cm - ${conditions.ecRange.max} mS/cm',
                  Icons.electric_bolt
                ),
                const SizedBox(height: 12),
                _buildRangeRowTablet(
                  'TDS Range', 
                  '${conditions.tdsRange.min} ppm - ${conditions.tdsRange.max} ppm',
                  Icons.opacity
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleConditionsViewDesktop(StageConditions conditions) {
    // Use vegetative stage as the primary reference for simple view
    final primaryConditions = conditions.vegetative;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha((0.05 * 255).round()),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withAlpha((0.2 * 255).round()),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Primary Growing Conditions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildSimpleConditionItemDesktop(
                    'Temperature',
                    '${primaryConditions.temperature.min}°C - ${primaryConditions.temperature.max}°C',
                    Icons.thermostat,
                  ),
                  _buildSimpleConditionItemDesktop(
                    'Humidity',
                    '${primaryConditions.humidity.min}% - ${primaryConditions.humidity.max}%',
                    Icons.water_drop,
                  ),
                  _buildSimpleConditionItemDesktop(
                    'pH Range',
                    '${primaryConditions.phRange.min} - ${primaryConditions.phRange.max}',
                    Icons.science,
                  ),
                  _buildSimpleConditionItemDesktop(
                    'EC Range',
                    '${primaryConditions.ecRange.min} mS/cm - ${primaryConditions.ecRange.max} mS/cm',
                    Icons.electric_bolt,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withAlpha((0.05 * 255).round()),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Switch to Advanced mode to view detailed conditions for each growth stage',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleConditionItemDesktop(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withAlpha((0.1 * 255).round()),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStageExpansionTileDesktop(String stageName, OptimalConditions conditions, IconData icon) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        title: Text(
          stageName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                SizedBox(
                  width: 280,
                  child: _buildRangeRowDesktop(
                    'Temperature', 
                    '${conditions.temperature.min}°C - ${conditions.temperature.max}°C',
                    Icons.thermostat
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: _buildRangeRowDesktop(
                    'Humidity', 
                    '${conditions.humidity.min}% - ${conditions.humidity.max}%',
                    Icons.water_drop
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: _buildRangeRowDesktop(
                    'pH Range', 
                    '${conditions.phRange.min} - ${conditions.phRange.max}',
                    Icons.science
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: _buildRangeRowDesktop(
                    'EC Range', 
                    '${conditions.ecRange.min} mS/cm - ${conditions.ecRange.max} mS/cm',
                    Icons.electric_bolt
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: _buildRangeRowDesktop(
                    'TDS Range', 
                    '${conditions.tdsRange.min} ppm - ${conditions.tdsRange.max} ppm',
                    Icons.opacity
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon, 
          size: 18, 
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRowTablet(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRowDesktop(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRangeRow(String label, String range, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                range,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildRangeRowTablet(String label, String range, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha((0.05 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  range,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRangeRowDesktop(String label, String range, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha((0.05 * 255).round()),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.03 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  range,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.edit),
        label: const Text('Edit Profile'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
        onPressed: () => _editProfile(),
      ),
    );
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          userId: userId,
          profile: profile,
        ),
      ),
    ).then((_) => _loadProfile());
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          userId: userId,
          profile: profile,
        ),
      ),
    ).then((_) => _loadProfile());
  }
}