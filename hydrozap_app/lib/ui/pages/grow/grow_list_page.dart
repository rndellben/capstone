import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/grow_model.dart';
import '../../../core/models/device_model.dart';
import '../../../core/models/grow_profile_model.dart';
import '../../../providers/grow_provider.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/grow_profile_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/responsive_widget.dart';
import 'add_grow_page.dart';
import 'grow_details_page.dart';

class GrowListPage extends StatefulWidget {
  final String userId;
  const GrowListPage({super.key, required this.userId});

  @override
  _GrowListPageState createState() => _GrowListPageState();
}

class _GrowListPageState extends State<GrowListPage> {
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Provider.of<GrowProvider>(context, listen: false).fetchGrows(widget.userId);
    await Provider.of<DeviceProvider>(context, listen: false).fetchDevices(widget.userId);
    await Provider.of<GrowProfileProvider>(context, listen: false)
        .fetchGrowProfiles(widget.userId);
  }

  String _formatDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return 'Invalid date';
    
    // Format date without using intl package
    final month = _getMonthName(date.month);
    return '$month ${date.day}, ${date.year}';
  }
  
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _getDeviceName(String deviceId) {
    final devices = Provider.of<DeviceProvider>(context, listen: false).devices;
    final device = devices.firstWhere(
      (device) => device.id.toString() == deviceId,
      orElse: () => DeviceModel(
        id: '',
        deviceName: 'Unknown Device',
        kit: '',
        userId: '',
        type: '',
        emergencyStop: false,
        status: 'off',
        sensors: {},
        actuators: {},
      ),
    );
    return device.deviceName;
  }

String _getProfileName(String profileId) {
  final profiles = Provider.of<GrowProfileProvider>(context).growProfiles;
  final profile = profiles.firstWhere(
    (profile) => profile.id == profileId,
    orElse: () => GrowProfile(
      id: '',
      name: 'Unknown Profile',
      userId: '',
      growDurationDays: 0,
      isActive: false,
      plantProfileId: '',
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
    ),
  );
  return profile.name;
}

  @override
  Widget build(BuildContext context) {
    final growProvider = Provider.of<GrowProvider>(context);
    final grows = growProvider.grows;
    final isLoading = growProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grow Records'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.leaf, AppColors.forest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddGrowPage(userId: widget.userId),
              ),
            ).then((_) => _fetchData()), // Refresh list when returning
          ),
        ],
      ),
      body: Container(
        color: AppColors.normal,
        child: ResponsiveWidget(
          mobile: _buildGrowList(context, grows, isLoading),
          tablet: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildGrowList(context, grows, isLoading),
          ),
          desktop: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildGrowList(context, grows, isLoading),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddGrowPage(userId: widget.userId),
          ),
        ).then((_) => _fetchData()),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGrowList(BuildContext context, List<Grow> grows, bool isLoading) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
        ),
      );
    }

    if (grows.isEmpty) {
      return _buildEmptyState();
    }

    return ResponsiveWidget(
      mobile: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: grows.length,
        itemBuilder: (context, index) => _buildGrowCard(context, grows[index]),
      ),
      tablet: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: grows.length,
        itemBuilder: (context, index) => _buildGrowCard(context, grows[index]),
      ),
      desktop: GridView.builder(
        padding: const EdgeInsets.all(24.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.5,
        ),
        itemCount: grows.length,
        itemBuilder: (context, index) => _buildGrowCard(context, grows[index]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.eco,
            size: 80,
            color: AppColors.accent.withAlpha((0.5 * 255).round()),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Grows Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to add your first grow',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddGrowPage(userId: widget.userId),
              ),
            ).then((_) => _fetchData()),
            icon: const Icon(Icons.add),
            label: const Text('Add Grow'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowCard(BuildContext context, Grow grow) {
    final deviceName = _getDeviceName(grow.deviceId);
    final profileName = _getProfileName(grow.profileId);
    final startDate = _formatDate(grow.startDate);
    final growthDuration = _getProfileGrowthDuration(grow.profileId);
    
    // Calculate progress
    final startDateTime = DateTime.tryParse(grow.startDate);
    final now = DateTime.now();
    final daysElapsed = startDateTime != null ? now.difference(startDateTime).inDays : 0;
    final progress = (daysElapsed / growthDuration).clamp(0.0, 1.0);
    
    // Determine status color
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (grow.status == 'harvested' || grow.harvestDate != null) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Harvested';
    } else if (progress >= 1.0) {
      statusColor = Colors.orange;
      statusIcon = Icons.timer;
      statusText = 'Ready for Harvest';
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.spa;
      statusText = 'In Progress';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GrowDetailsPage(
                grow: grow,
                deviceName: deviceName,
                profileName: profileName,
                growDuration: growthDuration,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppColors.primary.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.spa,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                statusIcon,
                                size: 16,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (grow.status == 'harvested' || grow.harvestDate != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(context, grow),
                        tooltip: 'Delete Grow',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Progress: ${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.devices,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  deviceName,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Started: $startDate',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (grow.status != 'harvested' && grow.harvestDate == null)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GrowDetailsPage(
                                grow: grow,
                                deviceName: deviceName,
                                profileName: profileName,
                                growDuration: growthDuration,
                                showHarvestOnLoad: true, // Immediately show harvest dialog
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.grass, size: 18),
                        label: const Text('Harvest'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          minimumSize: const Size(120, 44),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToHarvestLog(BuildContext context, Grow grow) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GrowDetailsPage(
          grow: grow,
          deviceName: _getDeviceName(grow.deviceId),
          profileName: _getProfileName(grow.profileId),
          growDuration: _getProfileGrowthDuration(grow.profileId),
        ),
      ),
    );
  }
  
  // Helper method to get profile growth duration
  int _getProfileGrowthDuration(String profileId) {
    final profiles = Provider.of<GrowProfileProvider>(context, listen: false).growProfiles;
    final profile = profiles.firstWhere(
      (profile) => profile.id == profileId,
      orElse: () => GrowProfile(
        id: '',
        name: 'Unknown Profile',
        userId: '',
        growDurationDays: 60, // Default 60 days
        isActive: false,
        plantProfileId: '',
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
      ),
    );
    return profile.growDurationDays;
  }
  
  // Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(BuildContext context, Grow grow) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Grow'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Are you sure you want to delete this grow record?'),
                const SizedBox(height: 8),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteGrow(grow);
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
  
  // Delete grow record
  Future<void> _deleteGrow(Grow grow) async {
    try {
      final growProvider = Provider.of<GrowProvider>(context, listen: false);
      final success = await growProvider.deleteGrow(grow.growId!, widget.userId);
      
      if (success) {
        // Refresh the list
        await _fetchData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Grow record deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete grow record'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}