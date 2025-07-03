import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/plant_profile_model.dart';
import '../../../../components/custom_text_field.dart';
import '../../../../components/custom_button.dart';
import '../../../../components/mode_selector.dart';
import 'grow_stages_preview.dart';

class ProfileSummary extends StatelessWidget {
  final PlantProfile? selectedPlantProfile;
  final TextEditingController nameController;
  final TextEditingController growDurationController;
  final VoidCallback onBack;
  final VoidCallback onCreateProfile;
  final bool isLoading;
  final String mode;
  final Function(String) onModeChanged;
  final TextEditingController transplantingTempMinController;
  final TextEditingController transplantingTempMaxController;
  final TextEditingController transplantingHumidityMinController;
  final TextEditingController transplantingHumidityMaxController;
  final TextEditingController transplantingPHMinController;
  final TextEditingController transplantingPHMaxController;
  final TextEditingController transplantingECMinController;
  final TextEditingController transplantingECMaxController;
  final TextEditingController transplantingTDSMinController;
  final TextEditingController transplantingTDSMaxController;
  final TextEditingController vegetativeTempMinController;
  final TextEditingController vegetativeTempMaxController;
  final TextEditingController vegetativeHumidityMinController;
  final TextEditingController vegetativeHumidityMaxController;
  final TextEditingController vegetativePHMinController;
  final TextEditingController vegetativePHMaxController;
  final TextEditingController vegetativeECMinController;
  final TextEditingController vegetativeECMaxController;
  final TextEditingController vegetativeTDSMinController;
  final TextEditingController vegetativeTDSMaxController;
  final TextEditingController maturationTempMinController;
  final TextEditingController maturationTempMaxController;
  final TextEditingController maturationHumidityMinController;
  final TextEditingController maturationHumidityMaxController;
  final TextEditingController maturationPHMinController;
  final TextEditingController maturationPHMaxController;
  final TextEditingController maturationECMinController;
  final TextEditingController maturationECMaxController;
  final TextEditingController maturationTDSMinController;
  final TextEditingController maturationTDSMaxController;

  const ProfileSummary({
    Key? key,
    this.selectedPlantProfile,
    required this.nameController,
    required this.growDurationController,
    required this.onBack,
    required this.onCreateProfile,
    required this.isLoading,
    required this.mode,
    required this.onModeChanged,
    required this.transplantingTempMinController,
    required this.transplantingTempMaxController,
    required this.transplantingHumidityMinController,
    required this.transplantingHumidityMaxController,
    required this.transplantingPHMinController,
    required this.transplantingPHMaxController,
    required this.transplantingECMinController,
    required this.transplantingECMaxController,
    required this.transplantingTDSMinController,
    required this.transplantingTDSMaxController,
    required this.vegetativeTempMinController,
    required this.vegetativeTempMaxController,
    required this.vegetativeHumidityMinController,
    required this.vegetativeHumidityMaxController,
    required this.vegetativePHMinController,
    required this.vegetativePHMaxController,
    required this.vegetativeECMinController,
    required this.vegetativeECMaxController,
    required this.vegetativeTDSMinController,
    required this.vegetativeTDSMaxController,
    required this.maturationTempMinController,
    required this.maturationTempMaxController,
    required this.maturationHumidityMinController,
    required this.maturationHumidityMaxController,
    required this.maturationPHMinController,
    required this.maturationPHMaxController,
    required this.maturationECMinController,
    required this.maturationECMaxController,
    required this.maturationTDSMinController,
    required this.maturationTDSMaxController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedPlantProfile != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
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
                    // Plant Details Section
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.leaf.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(Icons.eco, color: AppColors.leaf, size: 36),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedPlantProfile!.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, 
                                    size: 16, 
                                    color: Colors.grey[600]
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      "Total Growth Duration: ${growDurationController.text} days",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Add mode selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile Mode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                ModeSelector(
                  currentMode: mode,
                  onModeChanged: onModeChanged,
                ),
              ],
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: "Profile Name",
              hint: "Enter profile name",
              controller: nameController,
              prefixIcon: Icons.eco,
              enableBorder: true,
              filled: true,
              fillColor: Colors.white,
              validator: (value) => value!.isEmpty ? "Enter profile name" : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: "Grow Duration (days)",
              hint: "Enter grow duration in days",
              controller: growDurationController,
              prefixIcon: Icons.calendar_today,
              keyboardType: TextInputType.number,
              enableBorder: true,
              filled: true,
              fillColor: Colors.white,
              validator: (value) => value!.isEmpty || int.tryParse(value) == null
                  ? "Enter a valid number of days"
                  : null,
              readOnly: selectedPlantProfile != null,
              helperText: selectedPlantProfile != null ? "Recommended duration from plant profile" : null,
            ),
            const SizedBox(height: 24),
            if (mode == 'advanced') ...[
              const Text(
                'Stage Conditions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              GrowStagesPreview(
                transplantingTempMinController: transplantingTempMinController,
                transplantingTempMaxController: transplantingTempMaxController,
                transplantingHumidityMinController: transplantingHumidityMinController,
                transplantingHumidityMaxController: transplantingHumidityMaxController,
                transplantingPHMinController: transplantingPHMinController,
                transplantingPHMaxController: transplantingPHMaxController,
                transplantingECMinController: transplantingECMinController,
                transplantingECMaxController: transplantingECMaxController,
                transplantingTDSMinController: transplantingTDSMinController,
                transplantingTDSMaxController: transplantingTDSMaxController,
                vegetativeTempMinController: vegetativeTempMinController,
                vegetativeTempMaxController: vegetativeTempMaxController,
                vegetativeHumidityMinController: vegetativeHumidityMinController,
                vegetativeHumidityMaxController: vegetativeHumidityMaxController,
                vegetativePHMinController: vegetativePHMinController,
                vegetativePHMaxController: vegetativePHMaxController,
                vegetativeECMinController: vegetativeECMinController,
                vegetativeECMaxController: vegetativeECMaxController,
                vegetativeTDSMinController: vegetativeTDSMinController,
                vegetativeTDSMaxController: vegetativeTDSMaxController,
                maturationTempMinController: maturationTempMinController,
                maturationTempMaxController: maturationTempMaxController,
                maturationHumidityMinController: maturationHumidityMinController,
                maturationHumidityMaxController: maturationHumidityMaxController,
                maturationPHMinController: maturationPHMinController,
                maturationPHMaxController: maturationPHMaxController,
                maturationECMinController: maturationECMinController,
                maturationECMaxController: maturationECMaxController,
                maturationTDSMinController: maturationTDSMinController,
                maturationTDSMaxController: maturationTDSMaxController,
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: "Back",
                    onPressed: onBack,
                    backgroundColor: Colors.grey[300]!,
                    icon: Icons.arrow_back,
                    height: 50,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: "Create Profile",
                    onPressed: onCreateProfile,
                    backgroundColor: AppColors.primary,
                    icon: Icons.add_circle_outline,
                    height: 50,
                    isLoading: isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 