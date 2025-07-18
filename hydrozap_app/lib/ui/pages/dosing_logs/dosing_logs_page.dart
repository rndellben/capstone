// Dosing Logs Page - displays dosing logs for a device in a list
// To use: DosingLogsPage(deviceId: 'YOUR_DEVICE_ID')
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_service.dart';
import '../../../core/models/device_model.dart';
import '../../../providers/device_provider.dart';
import '../../../core/constants/app_colors.dart';

class DosingLogsPage extends StatefulWidget {
  final String? deviceId;
  const DosingLogsPage({Key? key, this.deviceId}) : super(key: key);

  @override
  State<DosingLogsPage> createState() => _DosingLogsPageState();
}

class _DosingLogsPageState extends State<DosingLogsPage> {
  String? _selectedDeviceId;
  late Future<List<Map<String, dynamic>>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _selectedDeviceId = widget.deviceId;
    if (_selectedDeviceId != null) {
      _logsFuture = ApiService().getDosingLogs(_selectedDeviceId!);
    }
  }

  void _onDeviceChanged(String? deviceId) {
    setState(() {
      _selectedDeviceId = deviceId;
      if (deviceId != null) {
        _logsFuture = ApiService().getDosingLogs(deviceId);
      }
    });
  }

  String _normalize(String? value) {
    if (value == null) return '-';
    final cleaned = value.replaceAll('\\', '').replaceAll('_', ' ');
    return cleaned.isNotEmpty
        ? cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase()
        : '-';
  }

  String _formatTimestamp(String? iso) {
    if (iso == null) return '-';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('yyyy-MM-dd  HH:mm:ss').format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final devices = deviceProvider.devices;
    final hasDevices = devices.isNotEmpty;
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.leaf, AppColors.forest],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Dosing Logs', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: false,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.leaf, AppColors.forest],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: kToolbarHeight + 8),
              Row(
                children: [
                  const Text('Device:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedDeviceId ?? (hasDevices ? devices.first.id : null),
                      isExpanded: true,
                      hint: const Text('Select Device'),
                      items: devices.map((device) {
                        return DropdownMenuItem<String>(
                          value: device.id,
                          child: Text(device.deviceName),
                        );
                      }).toList(),
                      onChanged: hasDevices ? _onDeviceChanged : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _selectedDeviceId == null
                    ? const Center(child: Text('Please select a device.'))
                    : FutureBuilder<List<Map<String, dynamic>>>(
                        future: _logsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No dosing logs found.'));
                          }
                          final logs = snapshot.data!;
                          // Sort logs by timestamp descending (latest first)
                          logs.sort((a, b) {
                            final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(1970);
                            final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(1970);
                            return bTime.compareTo(aTime);
                          });
                          return ListView.separated(
                            itemCount: logs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final log = logs[index];
                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Dosing Log Details', style: TextStyle(fontWeight: FontWeight.bold)),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: log.entries.map((e) => ListTile(
                                              dense: true,
                                              title: Text(_normalize(e.key), style: const TextStyle(fontWeight: FontWeight.w600)),
                                              subtitle: Text(_normalize(e.value?.toString())),
                                            )).toList(),
                                          ),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [AppColors.leaf, AppColors.forest],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(14),
                                            color: Colors.white.withOpacity(0.82),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  _normalize(log['type']),
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.1),
                                                ),
                                                if (log['log_id'] != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: theme.primaryColor.withOpacity(0.08),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      '#${log['log_id'].toString().substring(0, 6)}',
                                                      style: TextStyle(
                                                        color: theme.primaryColorDark,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 13,
                                                        letterSpacing: 1.1,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                const Icon(Icons.settings, size: 18, color: Colors.grey),
                                                const SizedBox(width: 6),
                                                Text('Mode: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                                                Text(_normalize(log['mode'])),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.opacity, size: 18, color: Colors.grey),
                                                const SizedBox(width: 6),
                                                Text('Volume (ml): ', style: const TextStyle(fontWeight: FontWeight.w500)),
                                                Text(log['volume_ml']?.toString() ?? '-'),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                                                const SizedBox(width: 6),
                                                Text('Timestamp: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                                                Text(_formatTimestamp(log['timestamp'])),
                                              ],
                                            ),
                                            ...log.entries
                                                .where((e) => !['type', 'mode', 'volume_ml', 'timestamp', 'log_id'].contains(e.key))
                                                .map((e) => Padding(
                                                      padding: const EdgeInsets.only(top: 2),
                                                      child: Text('${_normalize(e.key)}: ${_normalize(e.value?.toString())}', style: const TextStyle(color: Colors.grey)),
                                                    ))
                                                .toList(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 