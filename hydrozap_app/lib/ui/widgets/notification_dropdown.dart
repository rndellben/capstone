import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/models/notification_model.dart';
import '../../core/constants/app_colors.dart';
import 'responsive_widget.dart';

class NotificationDropdown extends StatelessWidget {
  const NotificationDropdown({super.key});

  void _handleNotificationTap(BuildContext context, AppNotification notification) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    
    // Mark as read first
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }
    
    // Only navigate if notification is tapped (not the action buttons)
    switch (notification.type) {
      case NotificationType.alert:
        // Navigate to device details or alert page
        Navigator.pushNamed(
          context,
          '/device-details',
          arguments: {
            'deviceId': notification.deviceId,
            'alertType': notification.alertType,
          },
        );
        break;
      case NotificationType.warning:
        // Navigate to system settings or warning page
        Navigator.pushNamed(
          context,
          '/system-settings',
          arguments: {
            'warningType': notification.alertType,
          },
        );
        break;
      case NotificationType.info:
      case NotificationType.success:
        // Navigate to relevant page based on the notification
        if (notification.alertType == 'harvest') {
          Navigator.pushNamed(
            context,
            '/harvest',
            arguments: {
              'deviceId': notification.deviceId,
            },
          );
        }
        break;
    }
  }

  void _showMobileNotifications(BuildContext context, NotificationProvider provider) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text('Notifications'),
            actions: [
              if (provider.unreadCount > 0)
                TextButton(
                  onPressed: provider.markAllAsRead,
                  child: const Text(
                    'Mark all as read',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear all notifications?'),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.clearNotifications();
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: provider.notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationList(context, provider),
        ),
      ),
    );
  }

  OverlayEntry _createOverlayEntry(BuildContext context, NotificationProvider provider) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx - 300,
        top: offset.dy + size.height + 5,
        width: 350,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.1 * 255).round()),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, provider),
                Flexible(
                  child: provider.notifications.isEmpty
                      ? _buildEmptyState()
                      : _buildNotificationList(context, provider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return IconButton(
          icon: Badge(
            label: Text(provider.unreadCount.toString()),
            isLabelVisible: provider.unreadCount > 0,
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: () {
            if (ResponsiveWidget.isMobile(context)) {
              // Show full-screen notifications on mobile
              _showMobileNotifications(context, provider);
            } else {
              // Show dropdown on tablet/desktop
              if (provider.showDropdown) {
                provider.toggleDropdown();
              } else {
                provider.toggleDropdown();
                final overlay = Overlay.of(context);
                final entry = _createOverlayEntry(context, provider);
                overlay.insert(entry);
                
                // Remove the overlay when the dropdown is toggled off
                Future.delayed(Duration.zero, () {
                  provider.addListener(() {
                    if (!provider.showDropdown) {
                      entry.remove();
                    }
                  });
                });
              }
            }
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, NotificationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withAlpha((0.2 * 255).round()),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  if (provider.unreadCount > 0)
                    TextButton(
                      onPressed: provider.markAllAsRead,
                      child: const Text('Mark all read'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Clear all',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear all notifications?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                provider.clearNotifications();
                                provider.toggleDropdown(); // Close dropdown
                                Navigator.pop(context);
                              },
                              child: const Text('Clear All'),
                            ),
                          ],
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (provider.notifications.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Tap notification to view details, or use buttons to mark as read/delete',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(BuildContext context, NotificationProvider provider) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: provider.notifications.length,
      itemBuilder: (context, index) {
        final notification = provider.notifications[index];
        return _buildNotificationItem(context, notification, provider);
      },
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    AppNotification notification,
    NotificationProvider provider,
  ) {
    return Material(
      color: notification.isRead
    ? Colors.white
    : Colors.blue.withAlpha((0.05 * 255).round()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withAlpha((0.2 * 255).round()),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: notification.typeColor.withAlpha((0.1 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.typeIcon,
                    color: notification.typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _handleNotificationTap(context, notification),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTimeAgo(notification.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Mark as read button
                if (!notification.isRead)
                  IconButton(
                    icon: const Icon(Icons.check, size: 20),
                    color: Colors.green,
                    tooltip: 'Mark as read',
                    onPressed: () {
                      provider.markAsRead(notification.id);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                
                // Delete button
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.red,
                  tooltip: 'Delete notification',
                  onPressed: () {
                    provider.deleteNotification(notification.id);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 