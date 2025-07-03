import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ParameterRangeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final TextEditingController minController;
  final TextEditingController maxController;
  final String minHint;
  final String maxHint;
  final TextInputType keyboardType;

  const ParameterRangeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.minController,
    required this.maxController,
    required this.minHint,
    required this.maxHint,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: iconColor.withOpacity(0.1),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: minController,
                    keyboardType: keyboardType,
                    decoration: InputDecoration(
                      labelText: minHint,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Required";
                      }
                      if (double.tryParse(value) == null) {
                        return "Enter a valid number";
                      }
                      return null;
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  height: 2,
                  width: 12,
                  color: Colors.grey.withOpacity(0.5),
                ),
                Expanded(
                  child: TextFormField(
                    controller: maxController,
                    keyboardType: keyboardType,
                    decoration: InputDecoration(
                      labelText: maxHint,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Required";
                      }
                      if (double.tryParse(value) == null) {
                        return "Enter a valid number";
                      }
                      final min = double.tryParse(minController.text) ?? 0;
                      final max = double.tryParse(value) ?? 0;
                      if (max <= min) {
                        return "Max must be > Min";
                      }
                      return null;
                    },
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

class NutrientStageCard extends StatelessWidget {
  final int stageNumber;
  final TextEditingController daysController;
  final TextEditingController nutrientsController;
  final bool isHorizontal;

  const NutrientStageCard({
    super.key,
    required this.stageNumber,
    required this.daysController,
    required this.nutrientsController,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.accent.withOpacity(0.1),
                  child: Text(
                    "$stageNumber",
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Growth Stage $stageNumber",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Define nutrients and duration for stage $stageNumber",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildFields() {
    if (isHorizontal) {
      // Horizontal layout for tablet and desktop
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Days",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                prefixIcon: const Icon(Icons.calendar_today, size: 18),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Required";
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return "Enter a valid number";
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: nutrientsController,
              decoration: InputDecoration(
                labelText: "Nutrients",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                prefixIcon: const Icon(Icons.science, size: 18),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Required";
                }
                return null;
              },
            ),
          ),
        ],
      );
    } else {
      // Vertical layout for mobile
      return Column(
        children: [
          TextFormField(
            controller: daysController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Days",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              prefixIcon: const Icon(Icons.calendar_today, size: 18),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Required";
              }
              if (int.tryParse(value) == null || int.parse(value) <= 0) {
                return "Enter a valid number";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: nutrientsController,
            decoration: InputDecoration(
              labelText: "Nutrients",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              prefixIcon: const Icon(Icons.science, size: 18),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Required";
              }
              return null;
            },
          ),
        ],
      );
    }
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class CustomCard extends StatelessWidget {
  final Widget child;
  final double elevation;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const CustomCard({
    super.key,
    required this.child,
    this.elevation = 2,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      color: backgroundColor,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}