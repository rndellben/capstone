import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class GrowStagesPreview extends StatelessWidget {
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

  const GrowStagesPreview({
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Growth Stages",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildStageCard(
          context,
          "Transplanting Stage",
          tempMin: transplantingTempMinController.text,
          tempMax: transplantingTempMaxController.text,
          humidityMin: transplantingHumidityMinController.text,
          humidityMax: transplantingHumidityMaxController.text,
          phMin: transplantingPHMinController.text,
          phMax: transplantingPHMaxController.text,
          ecMin: transplantingECMinController.text,
          ecMax: transplantingECMaxController.text,
          tdsMin: transplantingTDSMinController.text,
          tdsMax: transplantingTDSMaxController.text,
        ),
        _buildStageCard(
          context,
          "Vegetative Stage",
          tempMin: vegetativeTempMinController.text,
          tempMax: vegetativeTempMaxController.text,
          humidityMin: vegetativeHumidityMinController.text,
          humidityMax: vegetativeHumidityMaxController.text,
          phMin: vegetativePHMinController.text,
          phMax: vegetativePHMaxController.text,
          ecMin: vegetativeECMinController.text,
          ecMax: vegetativeECMaxController.text,
          tdsMin: vegetativeTDSMinController.text,
          tdsMax: vegetativeTDSMaxController.text,
        ),
        _buildStageCard(
          context,
          "Maturation Stage",
          tempMin: maturationTempMinController.text,
          tempMax: maturationTempMaxController.text,
          humidityMin: maturationHumidityMinController.text,
          humidityMax: maturationHumidityMaxController.text,
          phMin: maturationPHMinController.text,
          phMax: maturationPHMaxController.text,
          ecMin: maturationECMinController.text,
          ecMax: maturationECMaxController.text,
          tdsMin: maturationTDSMinController.text,
          tdsMax: maturationTDSMaxController.text,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStageCard(
    BuildContext context,
    String stageName, {
    required String tempMin,
    required String tempMax,
    required String humidityMin,
    required String humidityMax,
    required String phMin,
    required String phMax,
    required String ecMin,
    required String ecMax,
    required String tdsMin,
    required String tdsMax,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stageName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildParamChip("Temperature", "$tempMin°C - $tempMax°C", Colors.orange),
                _buildParamChip("Humidity", "$humidityMin% - $humidityMax%", Colors.blue),
                _buildParamChip("pH Level", "$phMin - $phMax", Colors.purple),
                _buildParamChip("EC Level", "$ecMin - $ecMax", Colors.amber),
                _buildParamChip("TDS Level", "$tdsMin - $tdsMax ppm", Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParamChip(String label, String value, Color color) {
    return Chip(
      label: Text("$label: $value"),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color.withOpacity(0.8)),
    );
  }
} 