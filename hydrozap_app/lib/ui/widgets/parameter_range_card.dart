import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ParameterRangeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final TextEditingController minController;
  final TextEditingController maxController;
  final String minHint;
  final String maxHint;
  final TextInputType keyboardType;
  final Color iconColor;

  const ParameterRangeCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.minController,
    required this.maxController,
    required this.minHint,
    required this.maxHint,
    required this.keyboardType,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
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
                      Text(
                        subtitle,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    keyboardType: keyboardType,
                    decoration: InputDecoration(
                      hintText: minHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    keyboardType: keyboardType,
                    decoration: InputDecoration(
                      hintText: maxHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
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