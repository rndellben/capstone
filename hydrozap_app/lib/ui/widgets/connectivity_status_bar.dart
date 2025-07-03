import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/constants/app_colors.dart';

/// Widget that displays the current connectivity and sync status
class ConnectivityStatusBar extends StatelessWidget {
  final bool? isConnected;
  final VoidCallback? onDismissed;

  const ConnectivityStatusBar({
    super.key,
    this.isConnected,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final connectivityService = Provider.of<ConnectivityService>(context);
    final syncService = Provider.of<SyncService>(context);
    
    return StreamBuilder<bool>(
      stream: connectivityService.connectivityStream,
      initialData: isConnected ?? connectivityService.isConnected,
      builder: (context, connectivitySnapshot) {
        final isConnected = connectivitySnapshot.data ?? false;
        final isSyncing = syncService.isSyncing;
        
        // Determine status color
        Color statusColor;
        if (!isConnected) {
          statusColor = AppColors.error;
        } else if (isSyncing) {
          statusColor = AppColors.sunset;
        } else {
          statusColor = AppColors.forest;
        }
        
        // Determine status message
        String statusMessage = syncService.getSyncStatusText();
        
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          color: statusColor.withAlpha((0.1 * 255).round()),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status icon
              Icon(
                isConnected 
                    ? (isSyncing ? Icons.sync : Icons.cloud_done)
                    : Icons.cloud_off,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              // Status text
              Text(
                statusMessage,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // If offline, show retry button
              if (!isConnected) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    // Check connection again
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Checking connection...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    onDismissed?.call();
                  },
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
              // If syncing, show progress indicator
              if (isSyncing) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
} 