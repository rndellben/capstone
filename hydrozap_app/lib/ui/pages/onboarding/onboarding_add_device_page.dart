import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/device_provider.dart';
import '../../../core/helpers/utils.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/esp_credentials_service.dart';
import '../../components/custom_button.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/connectivity_status_bar.dart';
import '../device/device_id_setup_page.dart';
import '../device/device_name_setup_page.dart';
import '../device/water_volume_setup_page.dart';
import '../../../core/services/dosing_calculator.dart';

// Steps for the device setup wizard
enum DeviceSetupStep {
  deviceId,
  deviceName,
  waterVolume,
}

class OnboardingAddDevicePage extends StatefulWidget {
  final String userId;
  final void Function(String) onDeviceAdded;
  const OnboardingAddDevicePage({super.key, required this.userId, required this.onDeviceAdded});

  @override
  _OnboardingAddDevicePageState createState() => _OnboardingAddDevicePageState();
}

class _OnboardingAddDevicePageState extends State<OnboardingAddDevicePage> {
  String? _deviceId;
  String? _deviceName;
  double? _waterVolume = 20.0;
  bool _showConnectivityBar = true;
  bool _isOfflineSubmission = false;
  bool _isLoading = false;
  DeviceSetupStep _currentStep = DeviceSetupStep.deviceId;

  // Default actuators matching backend
  Map<String, dynamic> defaultActuators = {
    "nutrient_pump2": {
      "status": "off",
      "duration": 0
    },
    "phDowner_pump": {
      "status": "off",
      "duration": 0
    },
    "phUpper_pump": {
      "status": "off",
      "duration": 0
    },
    "nutrient_pump1": {
      "status": "off",
      "duration": 0
    },
    "flush": {
      "active": false,
      "type": "full",
      "duration": 0
    }
  };


  Map<String, dynamic> defaultSensors = {
    "temperature": 24.5,
    "humidity": 50.0,
    "ph": 6.5,
    "ec": 1.2,
  };

  // ESP credentials service
  final EspCredentialsService _espCredentialsService = EspCredentialsService();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showConnectivityBar = false;
        });
      }
    });
  }

  void _nextStep() {
    setState(() {
      switch (_currentStep) {
        case DeviceSetupStep.deviceId:
          _currentStep = DeviceSetupStep.deviceName;
          break;
        case DeviceSetupStep.deviceName:
          _currentStep = DeviceSetupStep.waterVolume;
          break;
        case DeviceSetupStep.waterVolume:
          _submitDeviceSetup();
          break;
      }
    });
  }

  void _previousStep() {
    setState(() {
      switch (_currentStep) {
        case DeviceSetupStep.deviceId:
          Navigator.pop(context);
          break;
        case DeviceSetupStep.deviceName:
          _currentStep = DeviceSetupStep.deviceId;
          break;
        case DeviceSetupStep.waterVolume:
          _currentStep = DeviceSetupStep.deviceName;
          break;
      }
    });
  }

  int _getStepNumber() {
    switch (_currentStep) {
      case DeviceSetupStep.deviceId:
        return 1;
      case DeviceSetupStep.deviceName:
        return 2;
      case DeviceSetupStep.waterVolume:
        return 3;
    }
  }

  int _getTotalSteps() {
    return 3;
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case DeviceSetupStep.deviceId:
        return "Enter Device ID";
      case DeviceSetupStep.deviceName:
        return "Name Your Device";
      case DeviceSetupStep.waterVolume:
        return "Set Water Volume";
    }
  }

  void _handleDeviceIdSelected(String deviceId) {
    setState(() {
      _deviceId = deviceId;
      _deviceName = "Device $deviceId";
      _nextStep();
    });
  }

  void _handleDeviceNameSelected(String deviceName) {
    setState(() {
      _deviceName = deviceName;
      _nextStep();
    });
  }

  void _handleWaterVolumeSelected(double volume) {
    setState(() {
      _waterVolume = volume;
      _submitDeviceSetup();
    });
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
                                  ? "Your device has been saved locally and will be synchronized when your device is back online."
                                  : "Your device has been successfully set up and is ready to use.",
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
                            child: CustomButton(
                              text: "GOT IT",
                              onPressed: () {
                                Navigator.pop(context); // Close dialog
                                // For onboarding, pop only once or use a callback to advance onboarding flow
                              },
                              variant: ButtonVariant.primary,
                              backgroundColor: isOffline ? Colors.amber : AppColors.success,
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

  Future<void> _submitDeviceSetup() async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    if (_deviceId == null || _deviceName == null || _waterVolume == null) {
      await showAlertDialog(
        context: context,
        title: 'Missing Information',
        message: 'Please complete all setup steps before continuing.',
        type: AlertType.error,
        showCancelButton: false,
        confirmButtonText: 'OK',
      );
      return;
    }
    final deviceData = {
      "device_id": _deviceId,
      "user_id": widget.userId,
      "device_name": _deviceName,
      "type": "Arduino",
      "kit": "standard",
      "emergency_stop": false,
      "auto_dose_enabled": false,
      "actuators": defaultActuators,
      "sensors": defaultSensors,
      "actuator_conditions": [],
      "water_volume_liters": _waterVolume,
    };
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final isConnected = connectivityService.isConnected;
    setState(() {
      _isOfflineSubmission = !isConnected;
      _isLoading = true;
    });
    try {
      final success = await deviceProvider.addDevice(deviceData);
      if (success) {
        if (_isOfflineSubmission) {
          Provider.of<SyncService>(context, listen: false).forceSyncAll();
        }
        
        // Calculate initial nutrient dosing
        final currentEC = defaultSensors['ec'] ?? 0.0;
        final targetEC = 1.2; // Default target EC for new systems
        
        // Calculate nutrient A dose
        final nutrientADose = DosingCalculator.calculateNutrientADose(
          waterVolumeInLiters: _waterVolume!,
          currentEC: currentEC,
          targetEC: targetEC,
        );
        
        // Calculate nutrient B dose
        final nutrientBDose = DosingCalculator.calculateNutrientBDose(
          waterVolumeInLiters: _waterVolume!,
          currentEC: currentEC,
          targetEC: targetEC,
        );
        
        // Calculate nutrient C dose
        final nutrientCDose = DosingCalculator.calculateNutrientCDose(
          waterVolumeInLiters: _waterVolume!,
          currentEC: currentEC,
          targetEC: targetEC,
        );
        
        // Trigger nutrient pumps with calculated doses
        if (nutrientADose > 0) {
          await deviceProvider.flushActuator(_deviceId!, 'nutrient_pump2', duration: (nutrientADose * 10).round());
        }
        if (nutrientBDose > 0) {
          await deviceProvider.flushActuator(_deviceId!, 'phDowner_pump', duration: (nutrientBDose * 10).round());
        }
        if (nutrientCDose > 0) {
          await deviceProvider.flushActuator(_deviceId!, 'phUpper_pump', duration: (nutrientCDose * 10).round());
        }
        
        // Send Firebase credentials to ESP8266 device
        if (isConnected) {
          try {
            // Get current user credentials
            final credentials = await _espCredentialsService.getCurrentUserCredentials();
            final userEmail = credentials['email'];
            
            if (userEmail != null) {
              // Try to send credentials to ESP8266
              // The service will automatically get the ESP8266 IP address from configuration
              final credentialsSent = await _espCredentialsService.sendCredentialsToEsp(
                email: userEmail,
                password: credentials['password'], // This will be null for Firebase users
              );
              
              if (credentialsSent) {
                print('Firebase credentials sent successfully to ESP8266');
              } else {
                print('Failed to send Firebase credentials to ESP8266');
                
                // Try alternative method using Firebase ID token
                final tokenSent = await _espCredentialsService.sendFirebaseTokenToEsp();
                
                if (tokenSent) {
                  print('Firebase ID token sent successfully to ESP8266');
                } else {
                  print('Failed to send Firebase ID token to ESP8266');
                }
              }
            } else {
              print('No user email available to send to ESP8266');
            }
          } catch (e) {
            print('Error sending credentials to ESP8266: $e');
            // Don't fail the device setup if ESP credential sending fails
          }
        } else {
          print('Device is offline - skipping ESP credential sending');
        }
        
        if (mounted) {
          setState(() => _isLoading = false);
          widget.onDeviceAdded(_deviceId!);
          _showCompletionDialog(_isOfflineSubmission);
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          await showAlertDialog(
            context: context,
            title: 'Error',
            message: 'Error adding device. Please try again.',
            type: AlertType.error,
            showCancelButton: false,
            confirmButtonText: 'OK',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
      appBar: AppBar(
        title: Text(
          _getStepTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        ),
      ),
      // No AppDrawer in onboarding
      body: Column(
        children: [
          _buildStepProgressIndicator(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showConnectivityBar ? null : 0,
            child: AnimatedOpacity(
              opacity: _showConnectivityBar ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const ConnectivityStatusBar(),
            ),
          ),
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
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withAlpha((0.1 * 255).round()),
                    Colors.white,
                  ],
                ),
              ),
              child: _buildCurrentStepContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgressIndicator() {
    final int currentStepNumber = _getStepNumber();
    final int totalSteps = _getTotalSteps();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                currentStepNumber.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: List.generate(
                totalSteps,
                (index) {
                  final bool isActive = index < currentStepNumber;
                  final bool isCurrent = index == currentStepNumber - 1;
                  return Row(
                    children: [
                      Container(
                        width: isCurrent ? 12 : 8,
                        height: isCurrent ? 12 : 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : Colors.grey[300],
                          shape: BoxShape.circle,
                          border: isCurrent ? Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 3,
                          ) : null,
                        ),
                      ),
                      if (index < totalSteps - 1)
                        Container(
                          width: 20,
                          height: 2,
                          color: isActive && index < currentStepNumber - 1
                              ? AppColors.primary
                              : Colors.grey[300],
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          Text(
            "Step $currentStepNumber of $totalSteps",
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case DeviceSetupStep.deviceId:
        return DeviceIdSetupPage(
          onDeviceIdSelected: _handleDeviceIdSelected,
          initialDeviceId: _deviceId,
          onCancel: () => Navigator.pop(context),
        );
      case DeviceSetupStep.deviceName:
        return DeviceNameSetupPage(
          onDeviceNameSelected: _handleDeviceNameSelected,
          deviceId: _deviceId ?? '',
          initialDeviceName: _deviceName,
          onCancel: _previousStep,
        );
      case DeviceSetupStep.waterVolume:
        return WaterVolumeSetupPage(
          onVolumeSelected: _handleWaterVolumeSelected,
          initialVolume: _waterVolume,
          onCancel: _previousStep,
        );
    }
  }
} 