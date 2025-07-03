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
import '../../widgets/connectivity_status_bar.dart';

class OnboardingAddGrowPage extends StatefulWidget {
  final String userId;
  final String deviceId;
  final String profileId;
  final VoidCallback onGrowAdded;
  
  const OnboardingAddGrowPage({
    super.key, 
    required this.userId,
    required this.deviceId,
    required this.profileId,
    required this.onGrowAdded,
  });

  @override
  _OnboardingAddGrowPageState createState() => _OnboardingAddGrowPageState();
}

class _OnboardingAddGrowPageState extends State<OnboardingAddGrowPage> {
  final _formKey = GlobalKey<FormState>();
  String? selectedDeviceId;
  String? selectedProfileId;
  String startDate = DateTime.now().toIso8601String();
  GrowProfile? selectedProfile;
  bool _showConnectivityBar = true;
  bool _isOfflineSubmission = false;
  List<DeviceModel> _availableDevices = [];

  @override
  void initState() {
    super.initState();
    selectedDeviceId = widget.deviceId;
    selectedProfileId = widget.profileId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final growProfileProvider = Provider.of<GrowProfileProvider>(context, listen: false);
      await growProfileProvider.fetchGrowProfiles(widget.userId);
      await Provider.of<DeviceProvider>(context, listen: false).fetchDevices(widget.userId);
      await Provider.of<GrowProvider>(context, listen: false).fetchGrows(widget.userId);
      _filterAvailableDevices();
      if (mounted) {
        setState(() {});
      }
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showConnectivityBar = false;
          });
        }
      });
    });
  }

  void _filterAvailableDevices() {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final growProvider = Provider.of<GrowProvider>(context, listen: false);
    final allDevices = deviceProvider.devices;
    final activeGrows = growProvider.grows;
    final assignedDeviceIds = activeGrows.map((grow) => grow.deviceId).toSet();
    _availableDevices = allDevices.where((device) => !assignedDeviceIds.contains(device.id)).toList();
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
      final grow = Grow(
        userId: widget.userId,
        deviceId: selectedDeviceId!,
        profileId: selectedProfileId!,
        startDate: startDate,
      );
      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
      final isConnected = connectivityService.isConnected;
      setState(() {
        _isOfflineSubmission = !isConnected;
      });
      try {
        final growProvider = Provider.of<GrowProvider>(context, listen: false);
        final growProfileProvider = Provider.of<GrowProfileProvider>(context, listen: false);
        final success = await growProvider.addGrow(grow);
        if (success) {
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
              final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
              await deviceProvider.getCurrentThresholds(selectedDeviceId!);
            } catch (e) {
              // Log error but don't block the grow creation
              print('Error fetching thresholds: $e');
            }
          }

          if (_isOfflineSubmission) {
            Provider.of<SyncService>(context, listen: false).forceSyncAll();
            _showCompletionDialog(isOffline: true);
          } else {
            _showCompletionDialog(isOffline: false);
          }
        } else {
          final errorMessage = growProvider.errorMessage;
          await showAlertDialog(
            context: context,
            title: 'Error',
            message: errorMessage ?? 'Error adding grow. Please try again.',
            type: AlertType.error,
            showCancelButton: false,
            confirmButtonText: 'OK',
          );
          if (errorMessage?.contains('already assigned') ?? false) {
            await growProvider.fetchGrows(widget.userId);
            _filterAvailableDevices();
            setState(() {
              selectedDeviceId = '';
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
      }
    }
  }

  void _showCompletionDialog({required bool isOffline}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: isOffline ? Colors.amber.shade100 : Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOffline ? Icons.cloud_off : Icons.check_circle,
                          color: isOffline ? Colors.amber.shade700 : AppColors.success,
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Text(
                          "You're all set!",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isOffline ? Colors.amber.shade800 : AppColors.success,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                FutureBuilder(
                  future: Future.delayed(const Duration(milliseconds: 200)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SizedBox.shrink();
                    }
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Text(
                              isOffline
                                  ? "Your grow has been saved locally and will be synchronized when your device is back online."
                                  : "Your grow has been successfully added and is ready to go!",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                FutureBuilder(
                  future: Future.delayed(const Duration(milliseconds: 400)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SizedBox.shrink();
                    }
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/dashboard',
                                  (route) => false,
                                  arguments: widget.userId,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOffline ? Colors.amber : AppColors.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("Go to Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final growProfileProvider = Provider.of<GrowProfileProvider>(context);
    final connectivityService = Provider.of<ConnectivityService>(context);

    final growProfiles = growProfileProvider.growProfiles;
    final isOffline = !connectivityService.isConnected;

    // Ensure selectedProfileId and selectedDeviceId are valid
    if (!growProfiles.any((profile) => profile.id == selectedProfileId)) {
      selectedProfileId = null;
    }
    if (!_availableDevices.any((device) => device.id == selectedDeviceId)) {
      selectedDeviceId = null;
    }

    if (deviceProvider.isLoading || growProfileProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add Grow'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.accent,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Grow'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.grey[50],
              ),
            ),
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _addGrow,
                        icon: const Icon(Icons.add_circle),
                        label: const Text(
                          'Start Grow',
                          style: TextStyle(
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