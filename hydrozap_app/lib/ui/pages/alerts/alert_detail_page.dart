import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hydrozap_app/core/models/alert_model.dart';
import 'package:hydrozap_app/providers/alert_provider.dart';
import 'package:hydrozap_app/providers/device_provider.dart';

class AlertDetailPage extends StatelessWidget {
  final Alert alert;
  final String userId;

  const AlertDetailPage({
    super.key,
    required this.alert,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final alertProvider = Provider.of<AlertProvider>(context);
    final theme = Theme.of(context);

    // Determine card background color based on alert type
    final Color cardColor = _getCardColor(alert.alertType, theme);
    final Color iconColor = _getIconColor(alert.alertType, theme);
    final IconData alertIcon = _getAlertIcon(alert.alertType);
    final String alertEmoji = _getAlertEmoji(alert.alertType);

    return Scaffold(
      // Gradient AppBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFFFB300)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Row(
            children: [
              Text(alertEmoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              const Text('Alert Details'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Read Alert',
              onPressed: () async {
                await alertProvider.acknowledgeAlert(userId, alert.alertId);
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Alert Card
            Card(
              color: cardColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alert Icon, Title, and Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Icon(alertIcon, color: iconColor, size: 32),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatAlertType(alert.alertType),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatTimestamp(alert.timestamp),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(
                            alert.status == 'read' ? 'Read' : 'Unread',
                            style: TextStyle(
                              color: alert.status == 'read'
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          backgroundColor: alert.status == 'read'
                              ? Colors.green
                              : Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Description Section
                    Text(
                      'Description',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.message,
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (alert.suggestedAction != null || _getSuggestedAction(alert.alertType, alert.message).isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Suggested Action',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: iconColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              alert.suggestedAction ?? _getSuggestedAction(alert.alertType, alert.message),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Device Information
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: const Color(0xFFF5F7FA),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.device_hub, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Device Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.memory, color: Colors.grey),
                        const SizedBox(width: 8),
                        FutureBuilder(
                          future: deviceProvider.getDeviceById(alert.deviceId),
                          builder: (context, snapshot) {
                            String deviceName = 'Unknown Device';
                            if (snapshot.hasData && snapshot.data != null) {
                              deviceName = snapshot.data!.deviceName;
                            }
                            return Text(
                              deviceName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (alert.sensorData != null && alert.sensorData!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 20, color: Colors.grey.shade300),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.sensors, color: Colors.teal.shade400, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Sensor Readings at Alert Time',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        children: [
                          ...alert.sensorData!.entries
                              .where((entry) => entry.key != 'timestamp' && entry.value != null && entry.value.toString().isNotEmpty)
                              .map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.circle, size: 10, color: Colors.grey.shade400),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatSensorName(entry.key),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _formatSensorValue(entry.key, entry.value),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    if (alert.sensorData!['timestamp'] != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Text(
                          'Sensor reading time: \\${_formatTimestamp(alert.sensorData!['timestamp'])}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Read'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await alertProvider.acknowledgeAlert(userId, alert.alertId);
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Dismiss'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () async {
                    await alertProvider.deleteAlert(userId, alert.alertId);
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to get card background color based on alert type
  Color _getCardColor(String alertType, ThemeData theme) {
    switch (_getSeverity(alertType)) {
      case 'critical':
        return const Color(0xFFFFEBEE); // light red
      case 'warning':
        return const Color(0xFFFFF8E1); // light yellow
      case 'info':
      default:
        return const Color(0xFFE3F2FD); // light blue
    }
  }

  // Helper function to get icon color based on alert type
  Color _getIconColor(String alertType, ThemeData theme) {
    switch (_getSeverity(alertType)) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  // Helper function to get alert icon based on alert type
  IconData _getAlertIcon(String alertType) {
    switch (_getSeverity(alertType)) {
      case 'critical':
        return Icons.error_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'info':
      default:
        return Icons.info_rounded;
    }
  }

  // Helper function to get alert emoji based on alert type
  String _getAlertEmoji(String alertType) {
    switch (_getSeverity(alertType)) {
      case 'critical':
        return '⛔';
      case 'warning':
        return '⚠️';
      case 'info':
      default:
        return 'ℹ️';
    }
  }

  // Helper functions to format data
  String _formatAlertType(String alertType) {
    switch (alertType) {
      case 'ph_low':
        return 'Low pH';
      case 'ph_high':
        return 'High pH';
      case 'ec_low':
        return 'Low EC/TDS';
      case 'ec_high':
        return 'High EC/TDS';
      case 'temp_low':
        return 'Low Temperature';
      case 'temp_high':
        return 'High Temperature';
      case 'water_low':
        return 'Low Water Level';
      case 'device_offline':
        return 'Device Disconnected';
      default:
        return alertType.split('_').map((word) => 
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' ');
    }
  }

  String _formatSensorName(String sensorKey) {
    switch (sensorKey.toLowerCase()) {
      case 'ph':
        return 'pH Level';
      case 'ec':
        return 'EC Level';
      case 'tds':
        return 'TDS';
      case 'temperature':
        return 'Water Temperature';
      case 'waterlevel':
        return 'Water Level';
      case 'humidity':
        return 'Humidity';
      case 'ambienttemperature':
        return 'Ambient Temperature';
      default:
        return sensorKey.split('_').map((word) => 
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' ');
    }
  }

  String _formatSensorValue(String sensorKey, dynamic value) {
    if (value == null) return 'N/A';
    
    try {
      if (value is num || value.toString().isNotEmpty) {
        final numValue = value is num ? value : double.tryParse(value.toString());
        if (numValue != null) {
          switch (sensorKey.toLowerCase()) {
            case 'ph':
              return numValue.toStringAsFixed(1);
            case 'ec':
              return '${numValue.toStringAsFixed(0)} μS/cm';
            case 'tds':
              return '${numValue.toStringAsFixed(0)} ppm';
            case 'temperature':
            case 'ambienttemperature':
              return '${numValue.toStringAsFixed(1)} °C';
            case 'waterlevel':
              if (numValue is int || numValue % 1 == 0) {
                return '${numValue.toInt()}%';
              }
              return '${numValue.toStringAsFixed(1)}%';
            case 'humidity':
              return '${numValue.toStringAsFixed(1)}%';
            default:
              if (numValue % 1 == 0) {
                return numValue.toInt().toString();
              }
              return numValue.toStringAsFixed(1);
          }
        }
      }
      return value.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  String _getSeverity(String alertType) {
    if (alertType.contains('high') || alertType.contains('low')) {
      return 'warning';
    } else if (alertType.contains('offline') || alertType.contains('error')) {
      return 'critical';
    }
    return 'info';
  }

  String _getSuggestedAction(String alertType, String message) {
    switch (alertType) {
      case 'ph_low':
        return 'Add pH Up solution to your reservoir. Check system for pH Down overdosing.';
      case 'ph_high':
        return 'Add pH Down solution to your reservoir. Check system for pH Up overdosing.';
      case 'ec_low':
        return 'Add nutrients to your reservoir according to your feeding schedule.';
      case 'ec_high':
        return 'Dilute your reservoir with fresh water. Consider replacing with fresh nutrient solution if extremely high.';
      case 'temp_low':
        return 'Increase environmental temperature or add a water heater to your reservoir.';
      case 'temp_high':
        return 'Decrease environmental temperature or add cooling to your reservoir. Consider adding shade if outdoors.';
      case 'water_low':
        return 'Refill your reservoir with water and nutrients as needed.';
      case 'device_offline':
        return 'Check your device power and internet connection. Ensure the device is plugged in and properly connected.';
      default:
        return 'Check your system and address the issue according to the alert message.';
    }
  }
} 