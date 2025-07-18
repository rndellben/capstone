import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../providers/auth_provider.dart';
import '../grow_profile/add_profile/controllers/profile_controller.dart';
import '../grow_profile/add_profile/models/grow_profile_step.dart';
import '../grow_profile/add_profile/widgets/plant_selection.dart';
import '../grow_profile/add_profile/widgets/stage_conditions.dart';
import '../grow_profile/add_profile/widgets/profile_summary.dart';
import '../../../providers/plant_profile_provider.dart';
import '../../../ui/components/mode_selector.dart';
import '../grow_profile/add_profile/widgets/completion_dialog.dart';

class OnboardingAddProfilePage extends StatefulWidget {
  final Map<String, dynamic>? recommendationData;
  final String userId;
  final void Function(String) onProfileAdded;
  const OnboardingAddProfilePage({Key? key, this.recommendationData, required this.userId, required this.onProfileAdded}) : super(key: key);

  @override
  State<OnboardingAddProfilePage> createState() => _OnboardingAddProfilePageState();
}

class _OnboardingAddProfilePageState extends State<OnboardingAddProfilePage> {
  late ProfileController _controller;
  bool _showConnectivityBar = true;
  bool _isControllerInitialized = false;
  final ScrollController _scrollController = ScrollController();

  bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _controller = ProfileController(
      userId: await authProvider.getCurrentUserId() ?? '',
      recommendationData: widget.recommendationData,
    );
    final plantProfileProvider = Provider.of<PlantProfileProvider>(context, listen: false);
    await plantProfileProvider.fetchPlantProfiles(userId: widget.userId);
    if (widget.recommendationData != null) {
      final cropType = widget.recommendationData!['crop_type'] as String;
      final matchingProfile = plantProfileProvider.plantProfiles.firstWhere(
        (profile) => profile.name.toLowerCase() == cropType.toLowerCase(),
        orElse: () => plantProfileProvider.plantProfiles.first,
      );
      await _controller.onPlantProfileSelected(context, matchingProfile.id);
      _controller.applyRecommendationData(widget.recommendationData!);
    }
    setState(() {
      _isControllerInitialized = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isControllerInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Grow Profile'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Consumer<ConnectivityService>(
        builder: (context, connectivityService, child) {
          return Column(
            children: [
              if (_showConnectivityBar && !connectivityService.isConnected)
                Container(
                  color: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'You are offline. Changes will be saved locally.',
                        style: TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _showConnectivityBar = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Form(
                  key: _controller.formKey,
                  child: _controller.currentStep == GrowProfileStep.selectPlant
                      ? Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: _buildStepIndicator(),
                            ),
                            const SizedBox(height: 24),
                            Expanded(child: _buildCurrentStep()),
                          ],
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          controller: _scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildStepIndicator(),
                              const SizedBox(height: 24),
                              _buildCurrentStep(),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = GrowProfileStepExtension.stepsForMode(_controller.mode);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        steps.length,
        (index) {
          final step = steps[index];
          final isActive = _controller.currentStep == step;
          final isCompleted = steps.indexOf(_controller.currentStep) > index;

          return Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppColors.primary
                      : isCompleted
                          ? AppColors.success
                          : AppColors.stone,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive || isCompleted ? Colors.white : AppColors.stone,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (index < steps.length - 1)
                Container(
                  width: 48,
                  height: 2,
                  color: isCompleted ? AppColors.success : AppColors.stone,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentStep() {
    // Determine if mode selector should be shown
    final bool showModeSelector = widget.recommendationData == null || widget.recommendationData?['force_simple_mode'] != true;
    switch (_controller.currentStep) {
      case GrowProfileStep.selectPlant:
        return PlantSelection(
          selectedPlantProfileId: _controller.selectedPlantProfileId,
          onPlantProfileSelected: (profileId) async {
            await _controller.onPlantProfileSelected(context, profileId);
            setState(() {});
          },
          onNext: () {
            if (_controller.selectedPlantProfileId != null) {
              _controller.nextStep();
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              setState(() {});
            }
          },
          isLoading: _controller.isLoading,
        );

      case GrowProfileStep.transplantingStage:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _controller.currentStep.getTitleForMode(_controller.mode),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (showModeSelector)
              ModeSelector(
                currentMode: _controller.mode,
                onModeChanged: (mode) {
                  setState(() {
                    _controller.setMode(mode);
                  });
                },
              ),
            if (!showModeSelector)
              const SizedBox(height: 16),
            const SizedBox(height: 16),
            StageConditions(
              stage: 'Transplanting Stage',
              tempMinController: _controller.stageParamControllers['transplanting']?['temperature_range']?['min'] ?? TextEditingController(),
              tempMaxController: _controller.stageParamControllers['transplanting']?['temperature_range']?['max'] ?? TextEditingController(),
              humidityMinController: _controller.stageParamControllers['transplanting']?['humidity_range']?['min'] ?? TextEditingController(),
              humidityMaxController: _controller.stageParamControllers['transplanting']?['humidity_range']?['max'] ?? TextEditingController(),
              phMinController: _controller.stageParamControllers['transplanting']?['ph_range']?['min'] ?? TextEditingController(),
              phMaxController: _controller.stageParamControllers['transplanting']?['ph_range']?['max'] ?? TextEditingController(),
              ecMinController: _controller.stageParamControllers['transplanting']?['ec_range']?['min'] ?? TextEditingController(),
              ecMaxController: _controller.stageParamControllers['transplanting']?['ec_range']?['max'] ?? TextEditingController(),
              tdsMinController: _controller.stageParamControllers['transplanting']?['tds_range']?['min'] ?? TextEditingController(),
              tdsMaxController: _controller.stageParamControllers['transplanting']?['tds_range']?['max'] ?? TextEditingController(),
              onBack: () {}, // handled below
              onNext: () {}, // handled below
              isSimpleMode: _controller.mode == 'simple',
              isTransplantingStage: true,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _controller.previousStep();
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      setState(() {});
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.stone,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile(context) ? 12 : MediaQuery.of(context).size.height * 0.025,
                      ),
                      minimumSize: Size(
                        double.infinity,
                        isMobile(context) ? 48 : MediaQuery.of(context).size.height * 0.08,
                      ),
                      textStyle: TextStyle(
                        fontSize: isMobile(context) ? 16 : MediaQuery.of(context).size.height * 0.02,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _controller.nextStep();
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      setState(() {});
                    },
                    icon: Icon(Icons.arrow_forward, size: isMobile(context) ? 20 : MediaQuery.of(context).size.height * 0.025),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile(context) ? 12 : MediaQuery.of(context).size.height * 0.025,
                      ),
                      minimumSize: Size(
                        double.infinity,
                        isMobile(context) ? 48 : MediaQuery.of(context).size.height * 0.08,
                      ),
                      textStyle: TextStyle(
                        fontSize: isMobile(context) ? 16 : MediaQuery.of(context).size.height * 0.02,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case GrowProfileStep.vegetativeStage:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _controller.currentStep.getTitleForMode(_controller.mode),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            StageConditions(
              stage: 'Vegetative Stage',
              tempMinController: _controller.stageParamControllers['vegetative']?['temperature_range']?['min'] ?? TextEditingController(),
              tempMaxController: _controller.stageParamControllers['vegetative']?['temperature_range']?['max'] ?? TextEditingController(),
              humidityMinController: _controller.stageParamControllers['vegetative']?['humidity_range']?['min'] ?? TextEditingController(),
              humidityMaxController: _controller.stageParamControllers['vegetative']?['humidity_range']?['max'] ?? TextEditingController(),
              phMinController: _controller.stageParamControllers['vegetative']?['ph_range']?['min'] ?? TextEditingController(),
              phMaxController: _controller.stageParamControllers['vegetative']?['ph_range']?['max'] ?? TextEditingController(),
              ecMinController: _controller.stageParamControllers['vegetative']?['ec_range']?['min'] ?? TextEditingController(),
              ecMaxController: _controller.stageParamControllers['vegetative']?['ec_range']?['max'] ?? TextEditingController(),
              tdsMinController: _controller.stageParamControllers['vegetative']?['tds_range']?['min'] ?? TextEditingController(),
              tdsMaxController: _controller.stageParamControllers['vegetative']?['tds_range']?['max'] ?? TextEditingController(),
              onBack: () {}, // handled below
              onNext: () {}, // handled below
              isSimpleMode: _controller.mode == 'simple',
              isTransplantingStage: false,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _controller.previousStep();
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      setState(() {});
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.stone,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile(context) ? 12 : MediaQuery.of(context).size.height * 0.025,
                      ),
                      minimumSize: Size(
                        double.infinity,
                        isMobile(context) ? 48 : MediaQuery.of(context).size.height * 0.08,
                      ),
                      textStyle: TextStyle(
                        fontSize: isMobile(context) ? 16 : MediaQuery.of(context).size.height * 0.02,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _controller.nextStep();
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      setState(() {});
                    },
                    icon: Icon(Icons.arrow_forward, size: isMobile(context) ? 20 : MediaQuery.of(context).size.height * 0.025),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile(context) ? 12 : MediaQuery.of(context).size.height * 0.025,
                      ),
                      minimumSize: Size(
                        double.infinity,
                        isMobile(context) ? 48 : MediaQuery.of(context).size.height * 0.08,
                      ),
                      textStyle: TextStyle(
                        fontSize: isMobile(context) ? 16 : MediaQuery.of(context).size.height * 0.02,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case GrowProfileStep.maturationStage:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _controller.currentStep.getTitleForMode(_controller.mode),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            StageConditions(
              stage: 'Maturation Stage',
              tempMinController: _controller.stageParamControllers['maturation']?['temperature_range']?['min'] ?? TextEditingController(),
              tempMaxController: _controller.stageParamControllers['maturation']?['temperature_range']?['max'] ?? TextEditingController(),
              humidityMinController: _controller.stageParamControllers['maturation']?['humidity_range']?['min'] ?? TextEditingController(),
              humidityMaxController: _controller.stageParamControllers['maturation']?['humidity_range']?['max'] ?? TextEditingController(),
              phMinController: _controller.stageParamControllers['maturation']?['ph_range']?['min'] ?? TextEditingController(),
              phMaxController: _controller.stageParamControllers['maturation']?['ph_range']?['max'] ?? TextEditingController(),
              ecMinController: _controller.stageParamControllers['maturation']?['ec_range']?['min'] ?? TextEditingController(),
              ecMaxController: _controller.stageParamControllers['maturation']?['ec_range']?['max'] ?? TextEditingController(),
              tdsMinController: _controller.stageParamControllers['maturation']?['tds_range']?['min'] ?? TextEditingController(),
              tdsMaxController: _controller.stageParamControllers['maturation']?['tds_range']?['max'] ?? TextEditingController(),
              onBack: () {}, // handled below
              onNext: () {}, // handled below
              isSimpleMode: _controller.mode == 'simple',
              isTransplantingStage: false,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _controller.previousStep();
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      setState(() {});
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.stone,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile(context) ? 12 : MediaQuery.of(context).size.height * 0.025,
                      ),
                      minimumSize: Size(
                        double.infinity,
                        isMobile(context) ? 48 : MediaQuery.of(context).size.height * 0.08,
                      ),
                      textStyle: TextStyle(
                        fontSize: isMobile(context) ? 16 : MediaQuery.of(context).size.height * 0.02,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _controller.nextStep();
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      setState(() {});
                    },
                    icon: Icon(Icons.arrow_forward, size: isMobile(context) ? 20 : MediaQuery.of(context).size.height * 0.025),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile(context) ? 12 : MediaQuery.of(context).size.height * 0.025,
                      ),
                      minimumSize: Size(
                        double.infinity,
                        isMobile(context) ? 48 : MediaQuery.of(context).size.height * 0.08,
                      ),
                      textStyle: TextStyle(
                        fontSize: isMobile(context) ? 16 : MediaQuery.of(context).size.height * 0.02,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case GrowProfileStep.finalizeProfile:
        return ProfileSummary(
          selectedPlantProfile: _controller.selectedPlantProfile,
          nameController: _controller.nameController,
          growDurationController: _controller.growDurationController,
          mode: _controller.mode,
          onModeChanged: (mode) {
            setState(() {
              _controller.mode = mode;
            });
          },
          onBack: () {
            _controller.previousStep();
            setState(() {});
          },
          onCreateProfile: () async {
            try {
              final success = await _controller.addProfile(context);
              if (success && mounted) {
                _showCompletionDialog(_controller.isOfflineSubmission);
                if (widget.onProfileAdded != null) {
                  widget.onProfileAdded(_controller.selectedPlantProfile!.id);
                }
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
          isLoading: _controller.isLoading,
          transplantingTempMinController: _controller.stageParamControllers['transplanting']?['temperature_range']?['min'] ?? TextEditingController(),
          transplantingTempMaxController: _controller.stageParamControllers['transplanting']?['temperature_range']?['max'] ?? TextEditingController(),
          transplantingHumidityMinController: _controller.stageParamControllers['transplanting']?['humidity_range']?['min'] ?? TextEditingController(),
          transplantingHumidityMaxController: _controller.stageParamControllers['transplanting']?['humidity_range']?['max'] ?? TextEditingController(),
          transplantingPHMinController: _controller.stageParamControllers['transplanting']?['ph_range']?['min'] ?? TextEditingController(),
          transplantingPHMaxController: _controller.stageParamControllers['transplanting']?['ph_range']?['max'] ?? TextEditingController(),
          transplantingECMinController: _controller.stageParamControllers['transplanting']?['ec_range']?['min'] ?? TextEditingController(),
          transplantingECMaxController: _controller.stageParamControllers['transplanting']?['ec_range']?['max'] ?? TextEditingController(),
          transplantingTDSMinController: _controller.stageParamControllers['transplanting']?['tds_range']?['min'] ?? TextEditingController(),
          transplantingTDSMaxController: _controller.stageParamControllers['transplanting']?['tds_range']?['max'] ?? TextEditingController(),
          vegetativeTempMinController: _controller.stageParamControllers['vegetative']?['temperature_range']?['min'] ?? TextEditingController(),
          vegetativeTempMaxController: _controller.stageParamControllers['vegetative']?['temperature_range']?['max'] ?? TextEditingController(),
          vegetativeHumidityMinController: _controller.stageParamControllers['vegetative']?['humidity_range']?['min'] ?? TextEditingController(),
          vegetativeHumidityMaxController: _controller.stageParamControllers['vegetative']?['humidity_range']?['max'] ?? TextEditingController(),
          vegetativePHMinController: _controller.stageParamControllers['vegetative']?['ph_range']?['min'] ?? TextEditingController(),
          vegetativePHMaxController: _controller.stageParamControllers['vegetative']?['ph_range']?['max'] ?? TextEditingController(),
          vegetativeECMinController: _controller.stageParamControllers['vegetative']?['ec_range']?['min'] ?? TextEditingController(),
          vegetativeECMaxController: _controller.stageParamControllers['vegetative']?['ec_range']?['max'] ?? TextEditingController(),
          vegetativeTDSMinController: _controller.stageParamControllers['vegetative']?['tds_range']?['min'] ?? TextEditingController(),
          vegetativeTDSMaxController: _controller.stageParamControllers['vegetative']?['tds_range']?['max'] ?? TextEditingController(),
          maturationTempMinController: _controller.stageParamControllers['maturation']?['temperature_range']?['min'] ?? TextEditingController(),
          maturationTempMaxController: _controller.stageParamControllers['maturation']?['temperature_range']?['max'] ?? TextEditingController(),
          maturationHumidityMinController: _controller.stageParamControllers['maturation']?['humidity_range']?['min'] ?? TextEditingController(),
          maturationHumidityMaxController: _controller.stageParamControllers['maturation']?['humidity_range']?['max'] ?? TextEditingController(),
          maturationPHMinController: _controller.stageParamControllers['maturation']?['ph_range']?['min'] ?? TextEditingController(),
          maturationPHMaxController: _controller.stageParamControllers['maturation']?['ph_range']?['max'] ?? TextEditingController(),
          maturationECMinController: _controller.stageParamControllers['maturation']?['ec_range']?['min'] ?? TextEditingController(),
          maturationECMaxController: _controller.stageParamControllers['maturation']?['ec_range']?['max'] ?? TextEditingController(),
          maturationTDSMinController: _controller.stageParamControllers['maturation']?['tds_range']?['min'] ?? TextEditingController(),
          maturationTDSMaxController: _controller.stageParamControllers['maturation']?['tds_range']?['max'] ?? TextEditingController(),
        );
    }
    return Container(); // Fallback return
  }

  void _showCompletionDialog(bool isOffline) {
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
                          isOffline ? "Saved Offline" : "Setup Complete!",
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
                                  ? "Your profile has been saved locally and will be synchronized when your device is back online."
                                  : "Your grow profile has been successfully created and is ready to use.",
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
                                Navigator.pop(context); // Close dialog
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOffline ? Colors.amber : AppColors.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("GOT IT", style: TextStyle(fontWeight: FontWeight.bold)),
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
} 