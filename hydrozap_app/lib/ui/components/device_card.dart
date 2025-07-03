import 'package:flutter/material.dart';
import '../../../core/models/device_model.dart';
import '../../../core/constants/app_colors.dart';

class DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final bool isSelected;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.device,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppColors.secondary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.device_hub,
                color: isSelected ? AppColors.secondary : AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.deviceName.isNotEmpty ? device.deviceName : "Unnamed Device",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.secondary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type: ${device.type} - Kit: ${device.kit}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: device.emergencyStop ? AppColors.error : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  device.emergencyStop ? 'Emergency Stop' : 'Operational',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
