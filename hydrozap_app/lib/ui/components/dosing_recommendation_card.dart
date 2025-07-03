import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/dosing_calculator.dart';

class DosingRecommendationCard extends StatelessWidget {
  final double waterVolumeInLiters;
  final double currentPh;
  final double targetPh;
  final double currentEc;
  final double targetEc;
  final VoidCallback? onRefresh;

  // Default targets if not provided
  static const double DEFAULT_TARGET_PH = 6.0;
  static const double DEFAULT_TARGET_EC = 1.8;

  const DosingRecommendationCard({
    Key? key,
    required this.waterVolumeInLiters,
    required this.currentPh,
    this.targetPh = DEFAULT_TARGET_PH,
    required this.currentEc,
    this.targetEc = DEFAULT_TARGET_EC,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Don't show recommendations if water volume is not set
    if (waterVolumeInLiters <= 0) {
      return _buildSetupPrompt(context);
    }

    // Calculate dosing recommendations
    final phUpDose = DosingCalculator.calculatePhUpDose(
      waterVolumeInLiters: waterVolumeInLiters,
      currentPh: currentPh,
      targetPh: targetPh,
    );

    final phDownDose = DosingCalculator.calculatePhDownDose(
      waterVolumeInLiters: waterVolumeInLiters,
      currentPh: currentPh,
      targetPh: targetPh,
    );

    final nutrientADose = DosingCalculator.calculateNutrientADose(
      waterVolumeInLiters: waterVolumeInLiters,
      currentEC: currentEc,
      targetEC: targetEc,
    );

    final nutrientBDose = DosingCalculator.calculateNutrientBDose(
      waterVolumeInLiters: waterVolumeInLiters,
      currentEC: currentEc,
      targetEC: targetEc,
    );

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.science, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      "Dosing Recommendations",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: onRefresh,
                    color: AppColors.primary,
                    tooltip: "Refresh recommendations",
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Based on your ${waterVolumeInLiters.toStringAsFixed(1)}L reservoir volume:",
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            
            // pH dosing recommendations
            if (phUpDose > 0)
              _buildDosingItem(
                "pH Up Solution",
                "${phUpDose.toStringAsFixed(1)} ml",
                "To raise pH from ${currentPh.toStringAsFixed(1)} to ${targetPh.toStringAsFixed(1)}",
                Icons.arrow_upward,
                Colors.blue,
              ),
              
            if (phDownDose > 0)
              _buildDosingItem(
                "pH Down Solution",
                "${phDownDose.toStringAsFixed(1)} ml",
                "To lower pH from ${currentPh.toStringAsFixed(1)} to ${targetPh.toStringAsFixed(1)}",
                Icons.arrow_downward,
                Colors.orange,
              ),
              
            if (phUpDose == 0 && phDownDose == 0)
              _buildDosingItem(
                "pH Adjustment",
                "No adjustment needed",
                "Current pH ${currentPh.toStringAsFixed(1)} is close to target ${targetPh.toStringAsFixed(1)}",
                Icons.check_circle,
                Colors.green,
              ),
              
            const Divider(height: 24),
            
            // Nutrient dosing recommendations
            if (nutrientADose > 0 || nutrientBDose > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDosingItem(
                    "Nutrient Solution A",
                    "${nutrientADose.toStringAsFixed(1)} ml",
                    "To increase EC from ${currentEc.toStringAsFixed(2)} to ${targetEc.toStringAsFixed(2)} mS/cm",
                    Icons.opacity,
                    AppColors.accent,
                  ),
                  _buildDosingItem(
                    "Nutrient Solution B",
                    "${nutrientBDose.toStringAsFixed(1)} ml",
                    "To increase EC from ${currentEc.toStringAsFixed(2)} to ${targetEc.toStringAsFixed(2)} mS/cm",
                    Icons.opacity,
                    AppColors.accent,
                  ),
                ],
              ),
              
            if (nutrientADose == 0 && nutrientBDose == 0)
              _buildDosingItem(
                "Nutrient Solution",
                "No adjustment needed",
                "Current EC ${currentEc.toStringAsFixed(2)} is close to target ${targetEc.toStringAsFixed(2)} mS/cm",
                Icons.check_circle,
                Colors.green,
              ),
              
            const SizedBox(height: 8),
            
            // Disclaimer
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade800,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "These are recommendations only. Actual dosing amounts may vary based on specific nutrient brands and plant needs.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupPrompt(BuildContext context) {
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
                Icon(Icons.science, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  "Dosing Recommendations",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.water_drop_outlined,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Set up your reservoir",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please add your water tank volume in the device settings to see accurate dosing recommendations for pH and nutrients.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to edit device page (to be handled by parent)
                      if (onRefresh != null) {
                        onRefresh!();
                      }
                    },
                    icon: Icon(
                      Icons.settings,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      "Go to Device Settings",
                      style: TextStyle(
                        color: AppColors.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDosingItem(
    String name,
    String amount,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 