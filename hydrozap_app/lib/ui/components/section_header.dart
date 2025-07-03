import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

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
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.accent.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.accent, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
} 