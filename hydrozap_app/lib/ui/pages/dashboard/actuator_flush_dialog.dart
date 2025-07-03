import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/device_model.dart';
import '../../../core/api/api_service.dart';

class ActuatorFlushDialog extends StatefulWidget {
  final DeviceModel device;
  final Function(String actuatorId, int duration) onFlushActuator;

  const ActuatorFlushDialog({
    Key? key,
    required this.device,
    required this.onFlushActuator,
  }) : super(key: key);

  @override
  State<ActuatorFlushDialog> createState() => _ActuatorFlushDialogState();
}

class _ActuatorFlushDialogState extends State<ActuatorFlushDialog> {
  Map<String, bool> _flushingStates = {};
  Map<String, int> _remainingTimes = {};
  Map<String, int> _selectedDurations = {};
  String _selectedFlushType = 'full';
  bool _isFlushActive = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Initialize states for all actuators
    for (var entry in widget.device.actuators.entries) {
      if (entry.key != 'flush') {
      _flushingStates[entry.key] = false;
      _remainingTimes[entry.key] = 0;
      _selectedDurations[entry.key] = 5; // Default 5 seconds
    }
    }
    // Initialize flush state
    _isFlushActive = widget.device.actuators['flush']?['active'] ?? false;
    _selectedFlushType = widget.device.actuators['flush']?['type'] ?? 'full';
  }

  Future<void> _handleFlushActuator(String actuatorId) async {
    final duration = _selectedDurations[actuatorId] ?? 5;
    setState(() {
      _flushingStates[actuatorId] = true;
      _remainingTimes[actuatorId] = duration;
      widget.device.actuators[actuatorId]['status'] = 'on';
    });

    try {
      await _apiService.updateDeviceActuator(
        widget.device.id,
        actuatorId,
        duration,
      );
      widget.onFlushActuator(actuatorId, duration);

    // Start countdown timer
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      
      final remaining = _remainingTimes[actuatorId] ?? 0;
      if (remaining > 0) {
        setState(() {
          _remainingTimes[actuatorId] = remaining - 1;
        });
        return true;
      } else {
        setState(() {
          _flushingStates[actuatorId] = false;
          widget.device.actuators[actuatorId]['status'] = 'off';
        });
        return false;
      }
    });
    } catch (e) {
      setState(() {
        _flushingStates[actuatorId] = false;
        widget.device.actuators[actuatorId]['status'] = 'off';
      });
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to flush actuator: $e')),
        );
      }
    }
  }

  Future<void> _handleSystemFlush() async {
    final duration = _selectedDurations['flush'] ?? 30;
    setState(() {
      _isFlushActive = true;
    });

    try {
      await _apiService.updateDeviceFlush(
        widget.device.id,
        duration,
        _selectedFlushType,
      );

      // Start countdown timer
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return false;
        
        final remaining = _remainingTimes['flush'] ?? 0;
        if (remaining > 0) {
          setState(() {
            _remainingTimes['flush'] = remaining - 1;
          });
          return true;
        } else {
          setState(() {
            _isFlushActive = false;
          });
          return false;
        }
      });
    } catch (e) {
      setState(() {
        _isFlushActive = false;
      });
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start system flush: $e')),
        );
      }
    }
  }

  void _adjustDuration(String actuatorId, int delta) {
    setState(() {
      final currentDuration = _selectedDurations[actuatorId] ?? 5;
      final newDuration = currentDuration + delta;
      if (newDuration >= 1 && newDuration <= 60) {
        _selectedDurations[actuatorId] = newDuration;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Flush Actuators',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select an actuator to flush. Adjust the volume as needed.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              // Individual Actuators
              ...widget.device.actuators.entries
                  .where((entry) => entry.key != 'flush')
                  .map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildActuatorTile(
                    _prettifyActuatorName(entry.key),
                    entry.value,
                    entry.key,
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to prettify actuator names
  String _prettifyActuatorName(String key) {
    // Replace underscores with spaces, capitalize each word
    return key.replaceAll('_', ' ').split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' ');
  }

  Widget _buildActuatorTile(String prettyName, dynamic actuatorData, String actuatorKey) {
    final bool isFlushing = _flushingStates[actuatorKey] ?? false;
    final int remainingTime = _remainingTimes[actuatorKey] ?? 0;
    final int selectedDuration = _selectedDurations[actuatorKey] ?? 5;

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
          color: isFlushing ? AppColors.primary.withOpacity(0.07) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isFlushing ? AppColors.primary : Colors.grey.shade200,
            width: isFlushing ? 2 : 1,
        ),
      ),
      child: Padding(
          padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                  Icon(Icons.settings, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                Expanded(
                    child: Text(
                      prettyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                  ),
                ),
                  if (!isFlushing) _buildDurationSelector(actuatorKey, selectedDuration),
              ],
            ),
              const SizedBox(height: 8),
            Row(
              children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (actuatorData['status'] == 'on') ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Status: ${actuatorData['status'] ?? 'off'}',
                      style: TextStyle(
                        color: (actuatorData['status'] == 'on') ? Colors.green.shade800 : Colors.red.shade800,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
        ),
      ),
                  ),
                  const Spacer(),
                  if (isFlushing)
            Row(
              children: [
                        const SizedBox(width: 8),
                        const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                        const SizedBox(width: 8),
                      Text(
                          'Flushing: ${remainingTime}ml',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                        ),
                      ],
                  )
                else
                    ElevatedButton.icon(
                      onPressed: () => _handleFlushActuator(actuatorKey),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.water_drop, size: 18),
                      label: const Text('Flush'),
                  ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationSelector(String actuatorId, int duration) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 20),
            onPressed: () => _adjustDuration(actuatorId, -1),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$duration ml',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: () => _adjustDuration(actuatorId, 1),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
} 