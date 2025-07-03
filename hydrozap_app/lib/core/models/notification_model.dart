import 'package:flutter/material.dart';

enum NotificationType {
  alert,
  warning,
  info,
  success
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? deviceId;
  final String? alertType;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.deviceId,
    this.alertType,
    this.data,
  });

  Color get typeColor {
    switch (type) {
      case NotificationType.alert:
        return Colors.red;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.success:
        return Colors.green;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case NotificationType.alert:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.success:
        return Icons.check_circle_outline;
    }
  }
} 