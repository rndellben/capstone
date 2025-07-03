import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/grow_profile_provider.dart';
import '../../../providers/plant_profile_provider.dart';
import '../../../core/models/grow_profile_model.dart' show GrowProfile, OptimalConditions, Range;
import '../../../core/models/plant_profile_model.dart' as plant;
import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/utils.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/sync_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/responsive_widget.dart';
import '../../widgets/connectivity_status_bar.dart';
import '../../components/custom_text_field.dart';

class EditProfilePage extends StatefulWidget {
  final String userId;
  final GrowProfile profile;
  
  const EditProfilePage({
    super.key,
    required this.userId,
    required this.profile,
  });

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _showConnectivityBar = true;
  bool _isOfflineSubmission = false;
  String? _selectedPlantProfileId;
  plant.PlantProfile? _selectedPlantProfile;
  
  // Add stage selection
  String _selectedStage = 'transplanting';
  
  // Add mode selection
  bool _isAdvancedMode = false;
  
  // Controllers for form fields
  late final TextEditingController _nameController;
  late final TextEditingController _growDurationController;
  
  // Simple mode controllers (for all stages)
  late final Map<String, TextEditingController> _simpleModeControllers;
  
  // Temperature controllers for each stage
  late final Map<String, TextEditingController> _minTempControllers;
  late final Map<String, TextEditingController> _maxTempControllers;
  
  // Humidity controllers for each stage
  late final Map<String, TextEditingController> _minHumidityControllers;
  late final Map<String, TextEditingController> _maxHumidityControllers;
  
  // pH controllers for each stage
  late final Map<String, TextEditingController> _minPHControllers;
  late final Map<String, TextEditingController> _maxPHControllers;
  
  // EC controllers for each stage
  late final Map<String, TextEditingController> _minECControllers;
  late final Map<String, TextEditingController> _maxECControllers;
  
  // TDS controllers for each stage
  late final Map<String, TextEditingController> _minTDSControllers;
  late final Map<String, TextEditingController> _maxTDSControllers;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlantProfileProvider>(context, listen: false).fetchPlantProfiles();
      
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

  void _initializeControllers() {
    // Initialize basic fields
    _nameController = TextEditingController(text: widget.profile.name);
    _growDurationController = TextEditingController(text: widget.profile.growDurationDays.toString());
    
    // Set initial mode
    _isAdvancedMode = widget.profile.mode == 'advanced';
    
    // Initialize simple mode controllers
    _simpleModeControllers = {
      'temp_min': TextEditingController(),
      'temp_max': TextEditingController(),
      'humidity_min': TextEditingController(),
      'humidity_max': TextEditingController(),
      'ph_min': TextEditingController(),
      'ph_max': TextEditingController(),
      'ec_min': TextEditingController(),
      'ec_max': TextEditingController(),
    };
    
    // Initialize maps for controllers
    _minTempControllers = {};
    _maxTempControllers = {};
    _minHumidityControllers = {};
    _maxHumidityControllers = {};
    _minPHControllers = {};
    _maxPHControllers = {};
    _minECControllers = {};
    _maxECControllers = {};
    _minTDSControllers = {};
    _maxTDSControllers = {};
    
    // Initialize controllers for each stage
    final stages = ['transplanting', 'vegetative', 'maturation'];
    
    for (final stage in stages) {
      OptimalConditions conditions;
      if (widget.profile.optimalConditions != null) {
        switch (stage) {
          case 'transplanting':
            conditions = widget.profile.optimalConditions.transplanting;
            break;
          case 'vegetative':
            conditions = widget.profile.optimalConditions.vegetative;
            break;
          case 'maturation':
            conditions = widget.profile.optimalConditions.maturation;
            break;
          default:
            conditions = OptimalConditions(
              temperature: Range(min: 18.0, max: 22.0),
              humidity: Range(min: 60.0, max: 75.0),
              phRange: Range(min: 5.5, max: 6.5),
              ecRange: Range(min: 1.2, max: 1.8),
              tdsRange: Range(min: 600, max: 900),
            );
        }
      } else {
        conditions = OptimalConditions(
          temperature: Range(min: 18.0, max: 22.0),
          humidity: Range(min: 60.0, max: 75.0),
          phRange: Range(min: 5.5, max: 6.5),
          ecRange: Range(min: 1.2, max: 1.8),
          tdsRange: Range(min: 600, max: 900),
        );
      }
      
      _minTempControllers[stage] = TextEditingController(text: conditions.temperature.min.toString());
      _maxTempControllers[stage] = TextEditingController(text: conditions.temperature.max.toString());
      _minHumidityControllers[stage] = TextEditingController(text: conditions.humidity.min.toString());
      _maxHumidityControllers[stage] = TextEditingController(text: conditions.humidity.max.toString());
      _minPHControllers[stage] = TextEditingController(text: conditions.phRange.min.toString());
      _maxPHControllers[stage] = TextEditingController(text: conditions.phRange.max.toString());
      _minECControllers[stage] = TextEditingController(text: conditions.ecRange.min.toString());
      _maxECControllers[stage] = TextEditingController(text: conditions.ecRange.max.toString());
      _minTDSControllers[stage] = TextEditingController(text: conditions.tdsRange.min.toString());
      _maxTDSControllers[stage] = TextEditingController(text: conditions.tdsRange.max.toString());
    }
    
    // Initialize simple mode controllers with vegetative stage values (most common)
    if (widget.profile.optimalConditions != null) {
      final vegetativeConditions = widget.profile.optimalConditions.vegetative;
      _simpleModeControllers['temp_min']!.text = vegetativeConditions.temperature.min.toString();
      _simpleModeControllers['temp_max']!.text = vegetativeConditions.temperature.max.toString();
      _simpleModeControllers['humidity_min']!.text = vegetativeConditions.humidity.min.toString();
      _simpleModeControllers['humidity_max']!.text = vegetativeConditions.humidity.max.toString();
      _simpleModeControllers['ph_min']!.text = vegetativeConditions.phRange.min.toString();
      _simpleModeControllers['ph_max']!.text = vegetativeConditions.phRange.max.toString();
      _simpleModeControllers['ec_min']!.text = vegetativeConditions.ecRange.min.toString();
      _simpleModeControllers['ec_max']!.text = vegetativeConditions.ecRange.max.toString();
    } else {
      // Default values
      _simpleModeControllers['temp_min']!.text = '18.0';
      _simpleModeControllers['temp_max']!.text = '22.0';
      _simpleModeControllers['humidity_min']!.text = '60.0';
      _simpleModeControllers['humidity_max']!.text = '75.0';
      _simpleModeControllers['ph_min']!.text = '5.5';
      _simpleModeControllers['ph_max']!.text = '6.5';
      _simpleModeControllers['ec_min']!.text = '1.2';
      _simpleModeControllers['ec_max']!.text = '1.8';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _growDurationController.dispose();
    
    // Dispose simple mode controllers
    _simpleModeControllers.values.forEach((controller) => controller.dispose());
    
    // Dispose all stage controllers
    for (final stage in ['transplanting', 'vegetative', 'maturation']) {
      _minTempControllers[stage]?.dispose();
      _maxTempControllers[stage]?.dispose();
      _minHumidityControllers[stage]?.dispose();
      _maxHumidityControllers[stage]?.dispose();
      _minPHControllers[stage]?.dispose();
      _maxPHControllers[stage]?.dispose();
      _minECControllers[stage]?.dispose();
      _maxECControllers[stage]?.dispose();
      _minTDSControllers[stage]?.dispose();
      _maxTDSControllers[stage]?.dispose();
    }
    
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final profileProvider = Provider.of<GrowProfileProvider>(context, listen: false);
      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
      final isConnected = connectivityService.isConnected;
      
      setState(() {
        _isOfflineSubmission = !isConnected;
      });

      // Create a map of only the changed fields
      final Map<String, dynamic> profileData = {
        "id": widget.profile.id,
        "user_id": widget.userId,
      };

      // Only add fields that have changed
      if (_nameController.text != widget.profile.name) {
        profileData["name"] = _nameController.text;
      }

      if (_growDurationController.text != widget.profile.growDurationDays.toString()) {
        profileData["grow_duration_days"] = int.parse(_growDurationController.text);
      }

      // Add mode to profile data
      final newMode = _isAdvancedMode ? 'advanced' : 'simple';
      if (newMode != widget.profile.mode) {
        profileData["mode"] = newMode;
      }

      // Check if any optimal conditions have changed
      final Map<String, dynamic> optimalConditions = {};
      bool hasChanges = false;

      if (_isAdvancedMode) {
        // Advanced mode - check each stage individually
        for (final stage in ['transplanting', 'vegetative', 'maturation']) {
          final stageConditions = widget.profile.optimalConditions;
          if (stageConditions == null) continue;

          final currentStage = stage == 'transplanting' ? stageConditions.transplanting :
                             stage == 'vegetative' ? stageConditions.vegetative :
                             stageConditions.maturation;

          final newMinTemp = double.parse(_minTempControllers[stage]!.text);
          final newMaxTemp = double.parse(_maxTempControllers[stage]!.text);
          final newMinHumidity = double.parse(_minHumidityControllers[stage]!.text);
          final newMaxHumidity = double.parse(_maxHumidityControllers[stage]!.text);
          final newMinPH = double.parse(_minPHControllers[stage]!.text);
          final newMaxPH = double.parse(_maxPHControllers[stage]!.text);
          final newMinEC = double.parse(_minECControllers[stage]!.text);
          final newMaxEC = double.parse(_maxECControllers[stage]!.text);
          final newMinTDS = double.parse(_minTDSControllers[stage]!.text);
          final newMaxTDS = double.parse(_maxTDSControllers[stage]!.text);

          if (newMinTemp != currentStage.temperature.min ||
              newMaxTemp != currentStage.temperature.max ||
              newMinHumidity != currentStage.humidity.min ||
              newMaxHumidity != currentStage.humidity.max ||
              newMinPH != currentStage.phRange.min ||
              newMaxPH != currentStage.phRange.max ||
              newMinEC != currentStage.ecRange.min ||
              newMaxEC != currentStage.ecRange.max ||
              newMinTDS != currentStage.tdsRange.min ||
              newMaxTDS != currentStage.tdsRange.max) {
            
            hasChanges = true;
            optimalConditions[stage] = {
              "temperature_range": {
                "min": newMinTemp,
                "max": newMaxTemp
              },
              "humidity_range": {
                "min": newMinHumidity,
                "max": newMaxHumidity
              },
              "ph_range": {
                "min": newMinPH,
                "max": newMaxPH
              },
              "ec_range": {
                "min": newMinEC,
                "max": newMaxEC
              },
              "tds_range": {
                "min": newMinTDS,
                "max": newMaxTDS
              },
            };
          }
        }
      } else {
        // Simple mode - apply same conditions to all stages
        final newMinTemp = double.parse(_simpleModeControllers['temp_min']!.text);
        final newMaxTemp = double.parse(_simpleModeControllers['temp_max']!.text);
        final newMinHumidity = double.parse(_simpleModeControllers['humidity_min']!.text);
        final newMaxHumidity = double.parse(_simpleModeControllers['humidity_max']!.text);
        final newMinPH = double.parse(_simpleModeControllers['ph_min']!.text);
        final newMaxPH = double.parse(_simpleModeControllers['ph_max']!.text);
        final newMinEC = double.parse(_simpleModeControllers['ec_min']!.text);
        final newMaxEC = double.parse(_simpleModeControllers['ec_max']!.text);
        final newMinTDS = newMinEC * 640; // Calculate TDS from EC
        final newMaxTDS = newMaxEC * 640;

        // Check if values have changed from current vegetative stage (used for simple mode)
        final currentConditions = widget.profile.optimalConditions?.vegetative;
        if (currentConditions == null ||
            newMinTemp != currentConditions.temperature.min ||
            newMaxTemp != currentConditions.temperature.max ||
            newMinHumidity != currentConditions.humidity.min ||
            newMaxHumidity != currentConditions.humidity.max ||
            newMinPH != currentConditions.phRange.min ||
            newMaxPH != currentConditions.phRange.max ||
            newMinEC != currentConditions.ecRange.min ||
            newMaxEC != currentConditions.ecRange.max) {
          
          hasChanges = true;
          
          // Apply same conditions to all stages
          for (final stage in ['transplanting', 'vegetative', 'maturation']) {
            optimalConditions[stage] = {
              "temperature_range": {
                "min": newMinTemp,
                "max": newMaxTemp
              },
              "humidity_range": {
                "min": newMinHumidity,
                "max": newMaxHumidity
              },
              "ph_range": {
                "min": newMinPH,
                "max": newMaxPH
              },
              "ec_range": {
                "min": newMinEC,
                "max": newMaxEC
              },
              "tds_range": {
                "min": newMinTDS,
                "max": newMaxTDS
              },
            };
          }
        }
      }

      if (hasChanges) {
        profileData["optimal_conditions"] = optimalConditions;
      }

      try {
        final success = await profileProvider.updateGrowProfile(profileData);

        setState(() {
          _isLoading = false;
        });

        if (success) {
          await profileProvider.fetchGrowProfiles(widget.userId);
          
          if (_isOfflineSubmission) {
            Provider.of<SyncService>(context, listen: false).forceSyncAll();
            
            Navigator.pop(context);
            await showAlertDialog(
              context: context,
              title: 'Saved Offline',
              message: 'Your grow profile has been updated locally and will be synchronized when your device is back online.',
              type: AlertType.warning,
              showCancelButton: false,
              confirmButtonText: 'OK',
            );
          } else {
            Navigator.pop(context);
            await showAlertDialog(
              context: context,
              title: 'Success!',
              message: 'Grow profile updated successfully!',
              type: AlertType.success,
              showCancelButton: false,
              confirmButtonText: 'OK',
            );
          }
        } else {
          await showAlertDialog(
            context: context,
            title: 'Error',
            message: 'Error updating grow profile. Please try again.',
            type: AlertType.error,
            showCancelButton: false,
            confirmButtonText: 'OK',
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
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

  @override
  Widget build(BuildContext context) {
    final connectivityService = Provider.of<ConnectivityService>(context);
    final isOffline = !connectivityService.isConnected;
    
    return Scaffold(
      appBar: ResponsiveWidget.isDesktop(context)
          ? null
          : AppBar(
              title: const Text(
                'Edit Grow Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
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
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
      drawer: ResponsiveWidget.isDesktop(context) ? null : AppDrawer(userId: widget.userId),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5FFF7), Color(0xFFE8F5E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Show connectivity status bar with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showConnectivityBar ? null : 0,
              child: AnimatedOpacity(
                opacity: _showConnectivityBar ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: ConnectivityStatusBar(
                  isConnected: connectivityService.isConnected,
                  onDismissed: () => setState(() => _showConnectivityBar = false),
                ),
              ),
            ),
            // Show offline indicator if we're offline
            if (isOffline)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.amber.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, color: Colors.amber.shade800, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'You are currently offline. Changes will be saved locally and synced later.',
                      style: TextStyle(color: Colors.amber.shade800, fontSize: 12),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ResponsiveWidget(
                mobile: _buildMobileLayout(context),
                tablet: _buildTabletLayout(context),
                desktop: _buildDesktopLayout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildFormContent(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: SizedBox(
          width: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 32),
              _buildFormContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        // AppBar for desktop
        Container(
          height: 50,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.leaf, AppColors.forest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Edit Grow Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        // Main content
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: SizedBox(
                width: 1000,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 40),
                    _buildFormContent(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.only(bottom: 24),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.leaf, AppColors.forest],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.90),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco_outlined, color: AppColors.primary, size: 36),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Grow Profile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Update your grow profile settings and optimal conditions for your plants.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Information Section
          _buildSectionCard(
            title: 'Profile Information',
            icon: Icons.account_circle,
            iconColor: AppColors.primary,
            content: _buildProfileInfoSection(),
          ),
          
          const SizedBox(height: 24),
          
          // Optimal Conditions Section
          _buildSectionCard(
            title: 'Optimal Conditions',
            icon: Icons.tune,
            iconColor: AppColors.forest,
            content: _buildOptimalConditionsSection(),
          ),
          
          const SizedBox(height: 24),
          
          // Update Button Section
          _buildSectionCard(
            title: 'Save Changes',
            icon: Icons.save,
            iconColor: AppColors.success,
            content: _buildUpdateButtonSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.leaf, AppColors.forest],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forest,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: "Profile Name",
          hint: "Enter profile name",
          controller: _nameController,
          prefixIcon: Icons.eco,
          enableBorder: true,
          filled: true,
          fillColor: Colors.white,
          validator: (value) => value!.isEmpty ? "Enter profile name" : null,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: "Grow Duration (days)",
          hint: "Enter grow duration in days",
          controller: _growDurationController,
          prefixIcon: Icons.calendar_today,
          keyboardType: TextInputType.number,
          enableBorder: true,
          filled: true,
          fillColor: Colors.white,
          helperText: "The expected duration of the growing cycle",
          validator: (value) => value!.isEmpty || int.tryParse(value) == null
              ? "Enter a valid number of days"
              : null,
        ),
        const SizedBox(height: 16),
        // Tip card for better UX
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Accurate grow duration helps with scheduling and notifications throughout the growing cycle.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptimalConditionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode toggle
        Row(
          children: [
            const Text(
              'Mode:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 16),
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
                        _isAdvancedMode = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isAdvancedMode ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'Simple',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: !_isAdvancedMode ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isAdvancedMode = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isAdvancedMode ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'Advanced',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _isAdvancedMode ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        if (!_isAdvancedMode) ...[
          // Simple mode - show unified conditions
          _buildSimpleModeConditions(),
        ] else ...[
          // Advanced mode - show stage selector and individual conditions
          _buildAdvancedModeConditions(),
        ],
      ],
    );
  }

  Widget _buildSimpleModeConditions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info card for simple mode
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Simple mode applies the same optimal conditions to all growth stages. Switch to Advanced mode for stage-specific settings.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildRangeFields(
          'Temperature',
          _simpleModeControllers['temp_min']!,
          _simpleModeControllers['temp_max']!,
          Icons.thermostat,
          '°C',
          'Set the ideal temperature range for all growth stages'
        ),
        const SizedBox(height: 24),
        _buildRangeFields(
          'Humidity',
          _simpleModeControllers['humidity_min']!,
          _simpleModeControllers['humidity_max']!,
          Icons.water_drop,
          '%',
          'Set the ideal humidity range for all growth stages'
        ),
        const SizedBox(height: 24),
        _buildRangeFields(
          'pH Range',
          _simpleModeControllers['ph_min']!,
          _simpleModeControllers['ph_max']!,
          Icons.science,
          '',
          'Set the ideal pH level range for all growth stages'
        ),
        const SizedBox(height: 24),
        _buildRangeFields(
          'EC Range',
          _simpleModeControllers['ec_min']!,
          _simpleModeControllers['ec_max']!,
          Icons.electric_bolt,
          'mS/cm',
          'Set the ideal electrical conductivity range for all growth stages (TDS will be calculated automatically)'
        ),
      ],
    );
  }

  Widget _buildAdvancedModeConditions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stage selector
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Growth Stage',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withAlpha((0.3 * 255).round())),
              ),
              child: Row(
                children: [
                  _buildStageButton('transplanting', 'Transplanting'),
                  _buildStageButton('vegetative', 'Vegetative'),
                  _buildStageButton('maturation', 'Maturation'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildRangeFields(
          'Temperature',
          _minTempControllers[_selectedStage]!,
          _maxTempControllers[_selectedStage]!,
          Icons.thermostat,
          '°C',
          'Set the ideal temperature range for your plants'
        ),
        const SizedBox(height: 24),
        _buildRangeFields(
          'Humidity',
          _minHumidityControllers[_selectedStage]!,
          _maxHumidityControllers[_selectedStage]!,
          Icons.water_drop,
          '%',
          'Set the ideal humidity range for your plants'
        ),
        const SizedBox(height: 24),
        _buildRangeFields(
          'pH Range',
          _minPHControllers[_selectedStage]!,
          _maxPHControllers[_selectedStage]!,
          Icons.science,
          '',
          'Set the ideal pH level range for your growing medium'
        ),
        const SizedBox(height: 24),
        _buildRangeFields(
          'EC Range',
          _minECControllers[_selectedStage]!,
          _maxECControllers[_selectedStage]!,
          Icons.electric_bolt,
          'mS/cm',
          'Set the ideal electrical conductivity range for nutrient solution'
        ),
        const SizedBox(height: 24),
        _buildRangeFields(
          'TDS Range',
          _minTDSControllers[_selectedStage]!,
          _maxTDSControllers[_selectedStage]!,
          Icons.opacity,
          'ppm',
          'Set the ideal total dissolved solids range for nutrient solution'
        ),
      ],
    );
  }

  Widget _buildStageButton(String stage, String label) {
    final isSelected = _selectedStage == stage;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedStage = stage),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeFields(
    String label,
    TextEditingController minController,
    TextEditingController maxController,
    IconData icon,
    String unit,
    String helperText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              "$label ${unit.isNotEmpty ? '($unit)' : ''}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          helperText,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textPrimary.withAlpha((0.6 * 255).round()),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: "Min",
                hint: "Minimum value",
                controller: minController,
                prefixIcon: icon,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enableBorder: true,
                filled: true,
                fillColor: Colors.white,
                validator: (value) => value!.isEmpty || double.tryParse(value) == null
                    ? "Enter a valid number"
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                label: "Max",
                hint: "Maximum value",
                controller: maxController,
                prefixIcon: icon,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enableBorder: true,
                filled: true,
                fillColor: Colors.white,
                validator: (value) => value!.isEmpty || double.tryParse(value) == null
                    ? "Enter a valid number"
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpdateButtonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _updateProfile(),
                icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
                label: Text(
                  _isLoading ? 'Updating...' : 'Save Changes',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.textPrimary.withAlpha((0.3 * 255).round())),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}