import 'package:flutter/material.dart';
import 'package:hydrozap_app/core/models/device_model.dart';

class AlertsFilter extends StatefulWidget {
  final List<DeviceModel> devices;
  final Function(String?, String?, bool?, DateTime?, DateTime?) onFilterChanged;

  const AlertsFilter({
    super.key,
    required this.devices,
    required this.onFilterChanged,
  });

  @override
  State<AlertsFilter> createState() => _AlertsFilterState();
}

class _AlertsFilterState extends State<AlertsFilter> {
  String? _selectedDeviceId;
  Set<String> _selectedSeverities = {};
  bool _showOnlyUnacknowledged = false;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isExpanded = false;

  final List<Map<String, dynamic>> _severities = [
    {'value': 'info', 'label': 'Info', 'icon': Icons.info, 'color': Colors.blue},
    {'value': 'warning', 'label': 'Warning', 'icon': Icons.warning, 'color': Colors.orange},
    {'value': 'critical', 'label': 'Critical', 'icon': Icons.error, 'color': Colors.red},
  ];

  void _applyFilters() {
    widget.onFilterChanged(
      _selectedDeviceId,
      _selectedSeverities.isEmpty ? null : _selectedSeverities.join(','),
      _showOnlyUnacknowledged ? true : null,
      _fromDate,
      _toDate,
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedDeviceId = null;
      _selectedSeverities = {};
      _showOnlyUnacknowledged = false;
      _fromDate = null;
      _toDate = null;
    });
    widget.onFilterChanged(null, null, false, null, null);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with toggle
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.filter_list),
                  const SizedBox(width: 8),
                  Text(
                    'Filter Alerts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          
          // Expandable filter options
          if (_isExpanded) ...[
            const Divider(height: 1),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = MediaQuery.of(context).size.height * 0.7;
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: maxHeight,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Device dropdown
                          if (widget.devices.isNotEmpty) ...[
                            const Text('Device'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String?>(
                              isExpanded: true,
                              value: _selectedDeviceId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                hintText: 'All Devices',
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All Devices'),
                                ),
                                ...widget.devices.map((device) {
                                  return DropdownMenuItem<String>(
                                    value: device.id,
                                    child: Text(device.deviceName),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedDeviceId = value;
                                });
                                _applyFilters();
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Severity checkboxes
                          const Text('Severity', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _severities.map((severity) {
                              bool isSelected = _selectedSeverities.contains(severity['value']);
                              return FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      severity['icon'] as IconData,
                                      color: isSelected ? Colors.white : severity['color'] as Color,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      severity['label'] as String,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                selected: isSelected,
                                showCheckmark: false,
                                backgroundColor: Colors.grey.shade200,
                                selectedColor: severity['color'] as Color,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedSeverities.add(severity['value'] as String);
                                    } else {
                                      _selectedSeverities.remove(severity['value'] as String);
                                    }
                                  });
                                  _applyFilters();
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          
                          // Date Range picker
                          const Text('Date Range', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDateRange(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    _fromDate != null && _toDate != null
                                        ? '${_fromDate!.month}/${_fromDate!.day}/${_fromDate!.year} - '
                                            '${_toDate!.month}/${_toDate!.day}/${_toDate!.year}'
                                        : 'Select Date Range',
                                    style: TextStyle(
                                      color: _fromDate != null ? Colors.black : Colors.grey.shade600,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_fromDate != null)
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        setState(() {
                                          _fromDate = null;
                                          _toDate = null;
                                        });
                                        _applyFilters();
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Status toggle (Acknowledged/Unacknowledged)
                          const Text('Status', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _showOnlyUnacknowledged 
                                          ? 'Only Unacknowledged Alerts' 
                                          : 'All Alert Statuses',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Switch(
                                    value: _showOnlyUnacknowledged,
                                    activeColor: Colors.amber,
                                    onChanged: (value) {
                                      setState(() {
                                        _showOnlyUnacknowledged = value;
                                      });
                                      _applyFilters();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: _resetFilters,
                                child: const Text('Reset Filters'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
} 