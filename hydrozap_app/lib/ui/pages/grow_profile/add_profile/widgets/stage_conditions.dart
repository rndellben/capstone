import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../widgets/parameter_range_card.dart';
import 'responsive_layout.dart';

class StageConditions extends StatelessWidget {
  final String stage;
  final TextEditingController tempMinController;
  final TextEditingController tempMaxController;
  final TextEditingController humidityMinController;
  final TextEditingController humidityMaxController;
  final TextEditingController phMinController;
  final TextEditingController phMaxController;
  final TextEditingController ecMinController;
  final TextEditingController ecMaxController;
  final TextEditingController tdsMinController;
  final TextEditingController tdsMaxController;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool isSimpleMode;
  final bool isTransplantingStage;

  const StageConditions({
    super.key,
    required this.stage,
    required this.tempMinController,
    required this.tempMaxController,
    required this.humidityMinController,
    required this.humidityMaxController,
    required this.phMinController,
    required this.phMaxController,
    required this.ecMinController,
    required this.ecMaxController,
    required this.tdsMinController,
    required this.tdsMaxController,
    required this.onBack,
    required this.onNext,
    this.isSimpleMode = false,
    this.isTransplantingStage = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSimpleMode && !isTransplantingStage) {
      return const Center(
        child: Text(
          'Using parameters from Transplanting Stage',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ResponsiveConditionsLayout(
      children: [
        _buildConditionGroup(
          title: "Environmental Conditions",
          children: [
            ParameterRangeCard(
              title: "Temperature",
              subtitle: "Set the optimal temperature range for $stage stage",
              icon: Icons.thermostat_outlined,
              minController: tempMinController,
              maxController: tempMaxController,
              minHint: "Min °C",
              maxHint: "Max °C",
              keyboardType: TextInputType.number,
              iconColor: Colors.orange,
            ),
            const SizedBox(height: 16),
            ParameterRangeCard(
              title: "Humidity",
              subtitle: "Set the optimal humidity range for $stage stage",
              icon: Icons.water_drop_outlined,
              minController: humidityMinController,
              maxController: humidityMaxController,
              minHint: "Min %",
              maxHint: "Max %",
              keyboardType: TextInputType.number,
              iconColor: AppColors.primary,
            ),
          ],
        ),
        _buildConditionGroup(
          title: "Nutrient Conditions",
          children: [
            ParameterRangeCard(
              title: "pH Level",
              subtitle: "Set the optimal pH range for $stage stage",
              icon: Icons.science_outlined,
              minController: phMinController,
              maxController: phMaxController,
              minHint: "Min pH",
              maxHint: "Max pH",
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              iconColor: Colors.purple,
            ),
            const SizedBox(height: 16),
            ParameterRangeCard(
              title: "EC Level",
              subtitle: "Set the optimal electrical conductivity range for $stage stage",
              icon: Icons.bolt_outlined,
              minController: ecMinController,
              maxController: ecMaxController,
              minHint: "Min EC",
              maxHint: "Max EC",
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              iconColor: Colors.amber,
            ),
            const SizedBox(height: 16),
            ParameterRangeCard(
              title: "TDS Level",
              subtitle: "Set the optimal total dissolved solids range for $stage stage",
              icon: Icons.opacity,
              minController: tdsMinController,
              maxController: tdsMaxController,
              minHint: "Min ppm",
              maxHint: "Max ppm",
              keyboardType: TextInputType.number,
              iconColor: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConditionGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
} 