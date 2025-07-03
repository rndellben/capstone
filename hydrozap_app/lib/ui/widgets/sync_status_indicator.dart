import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../data/local/shared_prefs.dart';
import '../../core/constants/app_colors.dart';

class SyncStatusIndicator extends StatelessWidget {
  final bool isCompact;
  
  const SyncStatusIndicator({
    super.key,
    this.isCompact = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final userProfileProvider = Provider.of<UserProfileProvider>(context);
    final isOffline = userProfileProvider.isOffline;
    
    return FutureBuilder<DateTime?>(
      future: SharedPrefs.getLastSyncTime(),
      builder: (context, snapshot) {
        final lastSyncTime = snapshot.data;
        String formattedDate = lastSyncTime != null 
            ? '${lastSyncTime.day}/${lastSyncTime.month}/${lastSyncTime.year} ${lastSyncTime.hour}:${lastSyncTime.minute.toString().padLeft(2, '0')}'
            : 'Never';
            
        if (isCompact) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOffline ? Icons.wifi_off : Icons.sync,
                size: 16,
                color: isOffline ? Colors.amber : Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                isOffline ? 'Offline' : 'Synced',
                style: TextStyle(
                  fontSize: 12,
                  color: isOffline ? Colors.amber : Colors.green,
                ),
              ),
            ],
          );
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isOffline ? Colors.amber.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isOffline ? Colors.amber.shade300 : Colors.green.shade300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isOffline ? Icons.wifi_off : Icons.sync,
                color: isOffline ? Colors.amber : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isOffline ? 'You are offline' : 'Data is synced',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOffline ? Colors.amber.shade800 : Colors.green.shade800,
                      ),
                    ),
                    Text(
                      'Last sync: $formattedDate',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isOffline)
                TextButton.icon(
                  onPressed: () {
                    // Try to sync when the button is pressed
                    final userProfileProvider = Provider.of<UserProfileProvider>(
                      context, 
                      listen: false
                    );
                    
                    // We need to do this in a way that avoids BuildContext issues
                    Future.microtask(() async {
                      try {
                        final userId = await SharedPrefs.getUserId();
                        if (userId != null) {
                          await userProfileProvider.syncProfile(userId);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sync failed: $e')),
                        );
                      }
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('SYNC'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
} 