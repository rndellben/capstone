import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../components/custom_button.dart';

class GrowProfileCompletionDialog extends StatelessWidget {
  final bool isOffline;

  const GrowProfileCompletionDialog({
    super.key,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon with animation
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isOffline ? Colors.amber.shade100 : Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOffline ? Icons.cloud_off : Icons.check_circle,
                      color: isOffline ? Colors.amber.shade700 : AppColors.success,
                      size: 50,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Title with animation
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Text(
                      isOffline ? "Saved Offline" : "Setup Complete!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isOffline ? Colors.amber.shade800 : AppColors.success,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Message with animation
            FutureBuilder(
              future: Future.delayed(const Duration(milliseconds: 200)),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox.shrink();
                }
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Text(
                          isOffline
                              ? "Your grow profile has been saved locally and will be synchronized when your device is back online."
                              : "Your grow profile has been successfully added and is ready to use.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            // Button with animation
            FutureBuilder(
              future: Future.delayed(const Duration(milliseconds: 400)),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox.shrink();
                }
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: "GOT IT",
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            Navigator.pop(context); // Return to previous screen
                          },
                          variant: ButtonVariant.primary,
                          backgroundColor: isOffline ? Colors.amber : AppColors.success,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 