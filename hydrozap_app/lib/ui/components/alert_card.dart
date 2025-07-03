import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:hydrozap_app/core/models/alert_model.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  final String deviceName;
  final VoidCallback? onTap;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onDismiss;
  final bool selectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;

  const AlertCard({
    super.key,
    required this.alert,
    required this.deviceName,
    this.onTap,
    this.onAcknowledge,
    this.onDismiss,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = _getSeverityColor();
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.transparent,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          onTap: selectionMode ? () => onSelectionChanged?.call(!isSelected) : onTap,
          borderRadius: BorderRadius.circular(18),
          child: Row(
            children: [
              // Accent bar
              Container(
                width: 6,
                height: 64,
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
              // Card content
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  leading: selectionMode 
                    ? Checkbox(
                        value: isSelected,
                        onChanged: onSelectionChanged,
                      )
                    : _buildSeverityIndicator(),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatAlertType(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      _buildStatusChip(),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        alert.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.device_hub, size: 14, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text(
                            deviceName,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          ),
                          const Spacer(),
                          const Icon(Icons.schedule, size: 14, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(),
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityIndicator() {
    IconData iconData;
    Color color;

    switch (_getSeverity()) {
      case 'info':
        iconData = Icons.info;
        color = Colors.blue;
        break;
      case 'warning':
        iconData = Icons.warning;
        color = Colors.orange;
        break;
      case 'critical':
        iconData = Icons.error;
        color = Colors.red;
        break;
      default:
        iconData = Icons.notifications;
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: color),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: alert.status == 'read' 
            ? Colors.green.withOpacity(0.2) 
            : Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        alert.status == 'read' ? 'Read' : 'Unread',
        style: TextStyle(
          fontSize: 12,
          color: alert.status == 'read' ? Colors.green.shade800 : Colors.orange.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatAlertType() {
    switch (alert.alertType) {
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
        return alert.alertType.split('_').map((word) => 
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' ');
    }
  }

  String _formatTimestamp() {
    try {
      final dateTime = DateTime.parse(alert.timestamp);
      final now = DateTime.now();
      
      // If today, show time
      if (dateTime.year == now.year && 
          dateTime.month == now.month && 
          dateTime.day == now.day) {
        return 'Today at ${DateFormat('h:mm a').format(dateTime)}';
      } 
      
      // If within 7 days, show relative time
      else if (now.difference(dateTime).inDays < 7) {
        return timeago.format(dateTime);
      } 
      
      // Otherwise show date
      else {
        return DateFormat('MMM d, yyyy').format(dateTime);
      }
    } catch (e) {
      return alert.timestamp;
    }
  }

  String _getSeverity() {
    if (alert.alertType.contains('high') || alert.alertType.contains('low')) {
      return 'warning';
    } else if (alert.alertType.contains('offline') || alert.alertType.contains('error')) {
      return 'critical';
    }
    return 'info';
  }

  Color _getSeverityColor() {
    switch (_getSeverity()) {
      case 'info':
        return const Color(0xFF2196F3); // blue
      case 'warning':
        return const Color(0xFFFFA726); // orange
      case 'critical':
        return const Color(0xFFE53935); // red
      default:
        return const Color(0xFF2196F3);
    }
  }
}
