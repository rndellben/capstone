import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum AlertType {
  success,
  error,
  warning,
  info,
}

class AlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final AlertType type;
  final bool showCancelButton;
  final String confirmButtonText;
  final String? cancelButtonText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const AlertDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.type,
    this.showCancelButton = true,
    this.confirmButtonText = 'OK',
    this.cancelButtonText,
    this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  Color _getColorForType() {
    switch (type) {
      case AlertType.success:
        return Colors.green;
      case AlertType.error:
        return Colors.red;
      case AlertType.warning:
        return Colors.orange;
      case AlertType.info:
        return AppColors.primary;
    }
  }

  IconData _getIconForType() {
    switch (type) {
      case AlertType.success:
        return Icons.check_circle_outline;
      case AlertType.error:
        return Icons.error_outline;
      case AlertType.warning:
        return Icons.warning_amber_outlined;
      case AlertType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForType(),
              color: _getColorForType(),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showCancelButton)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onCancel != null) {
                          onCancel!();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        cancelButtonText ?? 'Cancel',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                if (showCancelButton) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onConfirm != null) {
                        onConfirm!();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getColorForType(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      confirmButtonText,
                      style: const TextStyle(
                        color: Colors.white,
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

Future<void> showAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  required AlertType type,
  bool showCancelButton = true,
  String confirmButtonText = 'OK',
  String? cancelButtonText,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: title,
        message: message,
        type: type,
        showCancelButton: showCancelButton,
        confirmButtonText: confirmButtonText,
        cancelButtonText: cancelButtonText,
        onConfirm: onConfirm,
        onCancel: onCancel,
      );
    },
  );
} 