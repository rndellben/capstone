import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/grow_model.dart';
import '../../../core/models/grow_profile_model.dart';
import '../../../core/models/device_model.dart';
import '../../../providers/grow_provider.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/grow_profile_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/utils.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/api/api_service.dart';
import '../../widgets/responsive_widget.dart';
import '../../widgets/connectivity_status_bar.dart';

class AddGrowPage extends StatefulWidget {
  final String userId;
  const AddGrowPage({super.key, required this.userId});

  @override
  _AddGrowPageState createState() => _AddGrowPageState();
}

class _AddGrowPageState extends State<AddGrowPage> {
  final _formKey = GlobalKey<FormState>();
  String? selectedDeviceId;
  String? selectedProfileId;
  String startDate = DateTime.now().toIso8601String();
  GrowProfile? selectedProfile;
  bool _showConnectivityBar = true;
  bool _isOfflineSubmission = false;
  bool _isAddingGrow = false;
  List<DeviceModel> _availableDevices = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Fetch and cache grow profiles
      final growProfileProvider = Provider.of<GrowProfileProvider>(context, listen: false);
      await growProfileProvider.fetchGrowProfiles(widget.userId);
      
      // Fetch and cache devices as well
      await Provider.of<DeviceProvider>(context, listen: false).fetchDevices(widget.userId);
      
      // Fetch grows to determine which devices are already assigned
      await Provider.of<GrowProvider>(context, listen: false).fetchGrows(widget.userId);
      
      // Filter available devices
      _filterAvailableDevices();
      
      if (mounted) {
        setState(() {}); // Only update state if the widget is still mounted
      }
      
      // Hide connectivity bar after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showConnectivityBar = false;
          });
        }
      });
    });
  }

  // Filter out devices that are already assigned to grows
  void _filterAvailableDevices() {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final growProvider = Provider.of<GrowProvider>(context, listen: false);
    
    // Get all devices
    final allDevices = deviceProvider.devices;
    
    // Get all active grows
    final activeGrows = growProvider.grows;
    
    // Create a set of device IDs that are already assigned to grows
    final assignedDeviceIds = activeGrows.map((grow) => grow.deviceId).toSet();
    
    // Filter out devices that are already assigned
    _availableDevices = allDevices.where((device) => 
      !assignedDeviceIds.contains(device.id)
    ).toList();
  }

  void _onProfileSelected(String? profileId) {
    if (profileId != null) {
      final profile = Provider.of<GrowProfileProvider>(context, listen: false)
          .growProfiles
          .firstWhere((profile) => profile.id == profileId);

      setState(() {
        selectedProfileId = profileId;
        selectedProfile = profile;
      });
    }
  }

  Future<void> _addGrow() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isAddingGrow = true;
      });

      // Create the grow object
      final grow = Grow(
        userId: widget.userId,
        deviceId: selectedDeviceId!,
        profileId: selectedProfileId!,
        startDate: startDate,
      );

      // Check connectivity status
      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
      final isConnected = connectivityService.isConnected;
      
      setState(() {
        _isOfflineSubmission = !isConnected;
      });

      try {
        final growProvider = Provider.of<GrowProvider>(context, listen: false);
        final growProfileProvider = Provider.of<GrowProfileProvider>(context, listen: false);
        final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
        final success = await growProvider.addGrow(grow);

        if (success) {
          // Set the grow profile as active
          final profile = growProfileProvider.growProfiles.firstWhere(
            (p) => p.id == selectedProfileId,
            orElse: () => GrowProfile(
              id: selectedProfileId!,
              userId: widget.userId,
              name: '',
              plantProfileId: '',
              growDurationDays: 0,
              isActive: false,
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
          if (!profile.isActive) {
            final updatedProfile = profile.copyWith(isActive: true);
            await growProfileProvider.updateGrowProfile(updatedProfile.toMap());
          }

          // Fetch and store current thresholds for the device
          if (isConnected) {
            try {
              await deviceProvider.getCurrentThresholds(selectedDeviceId!);
            } catch (e) {
              // Log error but don't block the grow creation
              print('Error fetching thresholds: $e');
            }
          }

          // If we were offline and the submission went through, it means it was saved locally
          if (_isOfflineSubmission) {
            // Trigger a sync when connection is restored
            Provider.of<SyncService>(context, listen: false).forceSyncAll();
            
            Navigator.pop(context);
            await showAlertDialog(
              context: context,
              title: 'Saved Offline',
              message: 'Your grow has been saved locally and will be synchronized when your device is back online.',
              type: AlertType.warning,
              showCancelButton: false,
              confirmButtonText: 'OK',
            );
          } else {
            Navigator.pop(context);
            await showAlertDialog(
              context: context,
              title: 'Success!',
              message: 'Grow added successfully! 🎉',
              type: AlertType.success,
              showCancelButton: false,
              confirmButtonText: 'OK',
            );
          }
        } else {
          // Check for specific error messages
          final errorMessage = growProvider.errorMessage;
          await showAlertDialog(
            context: context,
            title: 'Error',
            message: errorMessage ?? 'Error adding grow. Please try again.',
            type: AlertType.error,
            showCancelButton: false,
            confirmButtonText: 'OK',
          );
          
          // If we got a device conflict error, refresh the available devices
          if (errorMessage?.contains('already assigned') ?? false) {
            await growProvider.fetchGrows(widget.userId);
            _filterAvailableDevices();
            setState(() {
              selectedDeviceId = null; // Reset device selection
            });
          }
        }
      } catch (e) {
        await showAlertDialog(
          context: context,
          title: 'Error',
          message: 'An unexpected error occurred: ${e.toString()}',
          type: AlertType.error,
          showCancelButton: false,
          confirmButtonText: 'OK',
        );
      } finally {
        if (mounted) {
          setState(() {
            _isAddingGrow = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final growProfileProvider = Provider.of<GrowProfileProvider>(context);
    final connectivityService = Provider.of<ConnectivityService>(context);

    if (deviceProvider.isLoading || growProfileProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add Grow'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.leaf, AppColors.forest],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.accent,
          ),
        ),
      );
    }

    final growProfiles = growProfileProvider.growProfiles;
    final isOffline = !connectivityService.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Grow'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.leaf, AppColors.forest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Background decoration
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.grey[50],
              ),
            ),
          ),
          
          // Main content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
            Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                  ),
                ],
              ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.add_circle,
                                  color: AppColors.primary,
                                  size: 28,
                  ),
                ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Start a New Grow',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                  ),
                ),
              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Select a device and grow profile to begin tracking your new grow.',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              height: 1.5,
            ),
          ),
        ],
      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Device Selection
                    Card(
      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.devices,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Select Device',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_availableDevices.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
            children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                child: Text(
                                        'No available devices found. All devices are currently assigned to active grows.',
                  style: TextStyle(
                                          color: Colors.red,
                  ),
                ),
              ),
                                  ],
                                ),
                              )
                            else
                              DropdownButtonFormField<String>(
                    value: selectedDeviceId,
                                decoration: InputDecoration(
                                  labelText: 'Device',
                                  hintText: 'Select a device',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.devices),
                                ),
                                items: _availableDevices.map((device) {
                                  return DropdownMenuItem<String>(
                                    value: device.id,
                        child: Text(device.deviceName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDeviceId = value;
                      });
                    },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a device';
                                  }
                                  return null;
                                },
                              ),
            ],
          ),
        ),
      ),
                    const SizedBox(height: 24),
                    
                    // Profile Selection
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
                        padding: const EdgeInsets.all(20),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
                                  Icons.eco,
              color: AppColors.primary,
                                  size: 24,
            ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Select Grow Profile',
                                  style: TextStyle(
                                    fontSize: 18,
                fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
                            const SizedBox(height: 16),
                            if (growProfiles.isEmpty)
        Container(
                                padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
          ),
                                child: Row(
            children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'No grow profiles available. Please create a grow profile first.',
                                        style: TextStyle(
                                          color: Colors.orange,
                                        ),
          ),
        ),
      ],
                                ),
                              )
                            else
                              DropdownButtonFormField<String>(
                                value: selectedProfileId,
                                decoration: InputDecoration(
                                  labelText: 'Grow Profile',
                                  hintText: 'Select a grow profile',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.eco),
                                ),
                                items: growProfiles.map((profile) {
                                  return DropdownMenuItem<String>(
                                    value: profile.id,
                                    child: Text(profile.name),
                                  );
                                }).toList(),
                                onChanged: _onProfileSelected,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a grow profile';
                                  }
                                  return null;
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Start Date Selection
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
      children: [
        Icon(
                                  Icons.calendar_today,
                                  color: AppColors.primary,
                                  size: 24,
        ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Start Date',
                                  style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
          ),
        ),
      ],
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now().add(const Duration(days: 30)),
                                );
                                if (picked != null) {
                                  setState(() {
                                    startDate = picked.toIso8601String();
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Start Date',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.calendar_today),
            ),
            child: Text(
                                  _formatDate(startDate),
              style: const TextStyle(
                                    fontSize: 16,
              ),
            ),
          ),
        ),
      ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isAddingGrow ? null : _addGrow,
                        icon: _isAddingGrow 
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.add_circle),
                        label: Text(
                          _isAddingGrow ? 'Adding Grow...' : 'Start Grow',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Connectivity Status Bar
          if (_showConnectivityBar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ConnectivityStatusBar(
                isConnected: connectivityService.isConnected,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return 'Invalid date';
    
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}