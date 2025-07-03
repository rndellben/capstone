import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ModeSelector extends StatelessWidget {
  final String currentMode;
  final Function(String) onModeChanged;
  final bool enabled;

  const ModeSelector({
    Key? key,
    required this.currentMode,
    required this.onModeChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            context,
            'Simple',
            'simple',
            Icons.speed,
          ),
          const SizedBox(width: 8),
          _buildModeButton(
            context,
            'Advanced',
            'advanced',
            Icons.tune,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    String label,
    String mode,
    IconData icon,
  ) {
    final isSelected = currentMode == mode;
    final isEnabled = enabled;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? () => onModeChanged(mode) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 