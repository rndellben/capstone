import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/models/plant_profile_model.dart';
import '../../../../../providers/plant_profile_provider.dart';
import '../../../../../providers/grow_profile_provider.dart';
import '../../../../../core/services/connectivity_service.dart';
import '../../../../../core/services/sync_service.dart';
import '../models/grow_profile_step.dart';
import '../../../../../core/utils/logger.dart';

class ProfileController {
  final String userId;
  final Map<String, dynamic>? recommendationData;
  
  // Form key
  final formKey = GlobalKey<FormState>();
  
  // Current step
  GrowProfileStep currentStep = GrowProfileStep.selectPlant;
  
  // Selected plant profile
  String? selectedPlantProfileId;
  PlantProfile? selectedPlantProfile;
  
  // Form controllers
  final nameController = TextEditingController();
  final growDurationController = TextEditingController(text: '30');
  
  // Mode
  String mode = 'simple';  // Add mode field with default 'simple'
  
  // Dynamic controllers for each stage and parameter
  final Map<String, Map<String, Map<String, TextEditingController>>> stageParamControllers = {};
  
  // State flags
  bool isLoading = false;
  bool showConnectivityBar = true;
  bool isOfflineSubmission = false;
  bool usingRecommendationData = false;
  String? recommendationNote;

  ProfileController({
    required this.userId,
    this.recommendationData,
  }) {
    logger.i('Initializing ProfileController');
    logger.i('Recommendation data in constructor: $recommendationData');
    
    // Initialize controllers for all stages
    _initializeAllStageControllers();
    
    // If recommendation data is provided, start at the transplanting stage
    if (recommendationData != null) {
      logger.i('Setting up for recommendation data');
      currentStep = GrowProfileStep.transplantingStage;
      usingRecommendationData = true;
      // Enforce simple mode if flagged
      if (recommendationData?['force_simple_mode'] == true) {
        mode = 'simple';
      } else {
        mode = 'advanced';
      }
      _setPlantProfileFromRecommendation(recommendationData!);
    }
  }

  void _initializeAllStageControllers() {
    logger.i('Initializing controllers for all stages');
    try {
      // Initialize controllers for each stage
      for (final stage in ['transplanting', 'vegetative', 'maturation']) {
        stageParamControllers[stage] = {
          'temperature_range': {
            'min': TextEditingController(),
            'max': TextEditingController(),
          },
          'humidity_range': {
            'min': TextEditingController(),
            'max': TextEditingController(),
          },
          'ph_range': {
            'min': TextEditingController(),
            'max': TextEditingController(),
          },
          'ec_range': {
            'min': TextEditingController(),
            'max': TextEditingController(),
          },
          'tds_range': {
            'min': TextEditingController(),
            'max': TextEditingController(),
          },
        };
      }
      logger.i('Successfully initialized all stage controllers');
    } catch (e) {
      logger.e('Error initializing stage controllers: $e');
    }
  }

  void _setPlantProfileFromRecommendation(Map<String, dynamic> data) {
    // Set the plant profile ID based on the crop type
    final cropType = data['crop_type'] as String;
    // Find the matching plant profile ID from the available profiles
    // This will be populated when the plant profiles are fetched
    selectedPlantProfileId = cropType;
  }

  void setMode(String newMode) {
    mode = newMode;
    if (newMode == 'simple') {
      // When switching to simple mode, sync parameters from transplanting stage
      syncParametersAcrossStages();
    }
  }

  void syncParametersAcrossStages() {
    // Get the transplanting stage parameters as the base
    final transplantingParams = stageParamControllers['transplanting'];
    if (transplantingParams == null) return;

    // Copy transplanting parameters to vegetative and maturation stages
    ['vegetative', 'maturation'].forEach((stage) {
      stageParamControllers[stage] = {};
      transplantingParams.forEach((param, ctrls) {
        stageParamControllers[stage]![param] = {
          'min': TextEditingController(text: ctrls['min']!.text),
          'max': TextEditingController(text: ctrls['max']!.text),
        };
      });
    });
  }

  void dispose() {
    nameController.dispose();
    growDurationController.dispose();
    // Dispose all dynamic controllers
    for (var stage in stageParamControllers.values) {
      for (var param in stage.values) {
        for (var ctrl in param.values) {
          ctrl.dispose();
        }
      }
    }
  }

  void applyRecommendationData(Map<String, dynamic> data) {
    logger.i('Applying recommendation data: $data');
    usingRecommendationData = true;
    
    // Set name based on crop type and growth stage
    final cropType = data['crop_type'] as String;
    final growthStage = data['growth_stage'] as String;
    logger.i('Setting up profile for $cropType in $growthStage stage');
    
    nameController.text = "$cropType - ${_capitalizeFirst(growthStage)} Grow Profile";
    
    // If force_simple_mode, apply the same values to all stages
    if (data['force_simple_mode'] == true) {
      final stageData = data['transplanting'];
      for (final stage in ['transplanting', 'vegetative', 'maturation']) {
        if (stageData != null) {
          if (stageData['temperature_range'] != null) {
            final tempMin = stageData['temperature_range']['min'].toString();
            final tempMax = stageData['temperature_range']['max'].toString();
            stageParamControllers[stage]?['temperature_range']?['min']?.text = tempMin;
            stageParamControllers[stage]?['temperature_range']?['max']?.text = tempMax;
          }
          if (stageData['humidity_range'] != null) {
            final humidityMin = stageData['humidity_range']['min'].toString();
            final humidityMax = stageData['humidity_range']['max'].toString();
            stageParamControllers[stage]?['humidity_range']?['min']?.text = humidityMin;
            stageParamControllers[stage]?['humidity_range']?['max']?.text = humidityMax;
          }
          if (stageData['ph_range'] != null) {
            final phMin = stageData['ph_range']['min'].toString();
            final phMax = stageData['ph_range']['max'].toString();
            stageParamControllers[stage]?['ph_range']?['min']?.text = phMin;
            stageParamControllers[stage]?['ph_range']?['max']?.text = phMax;
          }
          if (stageData['ec_range'] != null) {
            final ecMin = stageData['ec_range']['min'].toString();
            final ecMax = stageData['ec_range']['max'].toString();
            stageParamControllers[stage]?['ec_range']?['min']?.text = ecMin;
            stageParamControllers[stage]?['ec_range']?['max']?.text = ecMax;
          }
          if (stageData['tds_range'] != null) {
            final tdsMin = stageData['tds_range']['min'].toString();
            final tdsMax = stageData['tds_range']['max'].toString();
            stageParamControllers[stage]?['tds_range']?['min']?.text = tdsMin;
            stageParamControllers[stage]?['tds_range']?['max']?.text = tdsMax;
          }
        }
      }
      if (data['recommendation'] != null) {
        recommendationNote = data['recommendation'].toString();
      }
      return;
    }
    
    // Apply recommendations ONLY to the specific growth stage
    final stageData = data[growthStage];
    logger.i('Stage data for $growthStage: $stageData');
    
    if (stageData != null) {
      // Apply temperature range
      if (stageData['temperature_range'] != null) {
        final tempMin = stageData['temperature_range']['min'].toString();
        final tempMax = stageData['temperature_range']['max'].toString();
        logger.i('Setting temperature range: $tempMin - $tempMax');
        
        final tempMinController = stageParamControllers[growthStage]?['temperature_range']?['min'];
        final tempMaxController = stageParamControllers[growthStage]?['temperature_range']?['max'];
        
        if (tempMinController != null && tempMaxController != null) {
          tempMinController.text = tempMin;
          tempMaxController.text = tempMax;
        } else {
          logger.e('Temperature controllers not found for stage $growthStage');
        }
      }
      
      // Apply humidity range
      if (stageData['humidity_range'] != null) {
        final humidityMin = stageData['humidity_range']['min'].toString();
        final humidityMax = stageData['humidity_range']['max'].toString();
        logger.i('Setting humidity range: $humidityMin - $humidityMax');
        
        final humidityMinController = stageParamControllers[growthStage]?['humidity_range']?['min'];
        final humidityMaxController = stageParamControllers[growthStage]?['humidity_range']?['max'];
        
        if (humidityMinController != null && humidityMaxController != null) {
          humidityMinController.text = humidityMin;
          humidityMaxController.text = humidityMax;
        } else {
          logger.e('Humidity controllers not found for stage $growthStage');
        }
      }
      
      // Apply pH range
      if (stageData['ph_range'] != null) {
        final phMin = stageData['ph_range']['min'].toString();
        final phMax = stageData['ph_range']['max'].toString();
        logger.i('Setting pH range: $phMin - $phMax');
        
        final phMinController = stageParamControllers[growthStage]?['ph_range']?['min'];
        final phMaxController = stageParamControllers[growthStage]?['ph_range']?['max'];
        
        if (phMinController != null && phMaxController != null) {
          phMinController.text = phMin;
          phMaxController.text = phMax;
        } else {
          logger.e('pH controllers not found for stage $growthStage');
        }
      }
      
      // Apply EC range
      if (stageData['ec_range'] != null) {
        final ecMin = stageData['ec_range']['min'].toString();
        final ecMax = stageData['ec_range']['max'].toString();
        logger.i('Setting EC range: $ecMin - $ecMax');
        
        final ecMinController = stageParamControllers[growthStage]?['ec_range']?['min'];
        final ecMaxController = stageParamControllers[growthStage]?['ec_range']?['max'];
        
        if (ecMinController != null && ecMaxController != null) {
          ecMinController.text = ecMin;
          ecMaxController.text = ecMax;
        } else {
          logger.e('EC controllers not found for stage $growthStage');
        }
      }
      
      // Apply TDS range if available
      if (stageData['tds_range'] != null) {
        final tdsMin = stageData['tds_range']['min'].toString();
        final tdsMax = stageData['tds_range']['max'].toString();
        logger.i('Setting TDS range: $tdsMin - $tdsMax');
            
            final tdsMinController = stageParamControllers[growthStage]?['tds_range']?['min'];
            final tdsMaxController = stageParamControllers[growthStage]?['tds_range']?['max'];
            
            if (tdsMinController != null && tdsMaxController != null) {
              tdsMinController.text = tdsMin;
              tdsMaxController.text = tdsMax;
            } else {
              logger.e('TDS controllers not found for stage $growthStage');
        }
      }
    }
    
    // Store recommendation note if available
    if (data['recommendation'] != null) {
      recommendationNote = data['recommendation'].toString();
    }

    // Apply default values from plant profile for other stages
    if (selectedPlantProfile != null) {
      logger.i('Applying default values from plant profile for other stages');
      final defaultConditions = selectedPlantProfile!.optimalConditions.stageConditions;
      
      // Apply defaults for each stage except the one with recommendations
      for (final stage in ['transplanting', 'vegetative', 'maturation']) {
        if (stage != growthStage && defaultConditions.containsKey(stage)) {
          logger.i('Applying defaults for $stage stage');
          final stageDefaults = defaultConditions[stage]!;
          
          // Apply temperature range
          if (stageDefaults['temperature_range'] != null) {
            final tempMin = stageDefaults['temperature_range']!['min'].toString();
            final tempMax = stageDefaults['temperature_range']!['max'].toString();
            stageParamControllers[stage]?['temperature_range']?['min']?.text = tempMin;
            stageParamControllers[stage]?['temperature_range']?['max']?.text = tempMax;
          }
          
          // Apply humidity range
          if (stageDefaults['humidity_range'] != null) {
            final humidityMin = stageDefaults['humidity_range']!['min'].toString();
            final humidityMax = stageDefaults['humidity_range']!['max'].toString();
            stageParamControllers[stage]?['humidity_range']?['min']?.text = humidityMin;
            stageParamControllers[stage]?['humidity_range']?['max']?.text = humidityMax;
          }
          
          // Apply pH range
          if (stageDefaults['ph_range'] != null) {
            final phMin = stageDefaults['ph_range']!['min'].toString();
            final phMax = stageDefaults['ph_range']!['max'].toString();
            stageParamControllers[stage]?['ph_range']?['min']?.text = phMin;
            stageParamControllers[stage]?['ph_range']?['max']?.text = phMax;
          }
          
          // Apply EC range
          if (stageDefaults['ec_range'] != null) {
            final ecMin = stageDefaults['ec_range']!['min'].toString();
            final ecMax = stageDefaults['ec_range']!['max'].toString();
            stageParamControllers[stage]?['ec_range']?['min']?.text = ecMin;
            stageParamControllers[stage]?['ec_range']?['max']?.text = ecMax;
          }
          
          // Apply TDS range
          if (stageDefaults['tds_range'] != null) {
            final tdsMin = stageDefaults['tds_range']!['min'].toString();
            final tdsMax = stageDefaults['tds_range']!['max'].toString();
            stageParamControllers[stage]?['tds_range']?['min']?.text = tdsMin;
            stageParamControllers[stage]?['tds_range']?['max']?.text = tdsMax;
          }
        }
      }
    } else {
      logger.w('No plant profile available for default values');
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> onPlantProfileSelected(BuildContext context, String? profileId) async {
    if (profileId == null) return;
    
    selectedPlantProfileId = profileId;
    isLoading = true;
    
    final plantProfileProvider = Provider.of<PlantProfileProvider>(context, listen: false);
    await plantProfileProvider.fetchPlantProfile(profileId);
    
    selectedPlantProfile = plantProfileProvider.selectedProfile;
    
    // Always populate form fields with plant profile defaults
    _populateFormFields();
    
    isLoading = false;
  }

  void _initializeStageParamControllers(Map<String, dynamic> optimalConditions) {
    print('Initializing controllers with: $optimalConditions'); // Debug log
    optimalConditions.forEach((stage, params) {
      if (params is Map<String, dynamic>) {
        stageParamControllers[stage] = {};
        params.forEach((param, value) {
          if (value is Map<String, dynamic> && value.containsKey('min') && value.containsKey('max')) {
            stageParamControllers[stage]![param] = {
              'min': TextEditingController(text: value['min'].toString()),
              'max': TextEditingController(text: value['max'].toString()),
            };
          }
        });
      }
    });
    print('Initialized controllers: $stageParamControllers'); // Debug log
  }

  void _populateFormFields() {
    if (selectedPlantProfile == null) return;
    final profileData = selectedPlantProfile!;
    nameController.text = "${profileData.name} Grow Profile";
    if (profileData.growDurationDays > 0) {
      growDurationController.text = profileData.growDurationDays.toString();
    } else {
      final growDuration = profileData.toJson()['grow_duration_days'] ?? 0;
      growDurationController.text = growDuration.toString();
    }
    final json = profileData.toJson();
    if (json.containsKey('optimal_conditions')) {
      _initializeStageParamControllers(json['optimal_conditions']);
    }
  }

  Future<bool> addProfile(BuildContext context) async {
    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      throw Exception('Please fill in all required fields correctly');
    }
    isLoading = true;
    try {
      final profileProvider = Provider.of<GrowProfileProvider>(context, listen: false);
      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
      if (profileProvider == null || connectivityService == null) {
        throw Exception('Required providers are not initialized');
      }
      final isConnected = connectivityService.isConnected;
      isOfflineSubmission = !isConnected;
      if (selectedPlantProfileId == null || selectedPlantProfileId!.isEmpty) {
        throw Exception('Plant profile must be selected');
      }
      if (nameController.text.isEmpty) {
        throw Exception('Profile name is required');
      }
      final growDuration = int.tryParse(growDurationController.text);
      if (growDuration == null || growDuration <= 0) {
        throw Exception('Invalid grow duration');
      }
      // Validate all numeric fields
      for (var stage in stageParamControllers.values) {
        for (var param in stage.values) {
          for (var ctrl in param.values) {
            try {
              double.parse(ctrl.text);
            } catch (e) {
              throw Exception('Invalid numeric values in form fields');
            }
          }
        }
      }
      // Build optimal_conditions dynamically
      final Map<String, dynamic> optimalConditions = {};
      stageParamControllers.forEach((stage, params) {
        optimalConditions[stage] = {};
        params.forEach((param, ctrls) {
          optimalConditions[stage][param] = {
            'min': double.parse(ctrls['min']!.text),
            'max': double.parse(ctrls['max']!.text),
          };
        });
      });
      final profileData = {
        "user_id": userId,
        "name": nameController.text,
        "plant_profile_id": selectedPlantProfileId,
        "grow_duration_days": growDuration,
        "is_active": false,
        "created_at": DateTime.now().toIso8601String(),
        "optimal_conditions": optimalConditions,
        "mode": mode,
      };
      if (recommendationNote != null) {
        profileData["recommendation_note"] = recommendationNote;
      }
      final success = await profileProvider.addGrowProfile(profileData);
      if (success) {
        if (isOfflineSubmission) {
          final syncService = Provider.of<SyncService>(context, listen: false);
          if (syncService != null) {
            syncService.forceSyncAll();
          }
        }
        return true;
      } else {
        throw Exception('Failed to save grow profile');
      }
    } finally {
      isLoading = false;
    }
  }

  void nextStep() {
    if (mode == 'simple') {
      switch (currentStep) {
        case GrowProfileStep.selectPlant:
          currentStep = GrowProfileStep.transplantingStage;
          break;
        case GrowProfileStep.transplantingStage:
          currentStep = GrowProfileStep.finalizeProfile;
          break;
        case GrowProfileStep.finalizeProfile:
          // Handle profile creation
          break;
        default:
          break;
      }
    } else {
      switch (currentStep) {
        case GrowProfileStep.selectPlant:
          currentStep = GrowProfileStep.transplantingStage;
          break;
        case GrowProfileStep.transplantingStage:
          currentStep = GrowProfileStep.vegetativeStage;
          break;
        case GrowProfileStep.vegetativeStage:
          currentStep = GrowProfileStep.maturationStage;
          break;
        case GrowProfileStep.maturationStage:
          currentStep = GrowProfileStep.finalizeProfile;
          break;
        case GrowProfileStep.finalizeProfile:
          // Handle profile creation
          break;
      }
    }
  }

  void previousStep() {
    if (mode == 'simple') {
      switch (currentStep) {
        case GrowProfileStep.transplantingStage:
          currentStep = GrowProfileStep.selectPlant;
          break;
        case GrowProfileStep.finalizeProfile:
          currentStep = GrowProfileStep.transplantingStage;
          break;
        default:
          break;
      }
    } else {
      switch (currentStep) {
        case GrowProfileStep.selectPlant:
          // Already at first step
          break;
        case GrowProfileStep.transplantingStage:
          currentStep = GrowProfileStep.selectPlant;
          break;
        case GrowProfileStep.vegetativeStage:
          currentStep = GrowProfileStep.transplantingStage;
          break;
        case GrowProfileStep.maturationStage:
          currentStep = GrowProfileStep.vegetativeStage;
          break;
        case GrowProfileStep.finalizeProfile:
          currentStep = GrowProfileStep.maturationStage;
          break;
      }
    }
  }
} 