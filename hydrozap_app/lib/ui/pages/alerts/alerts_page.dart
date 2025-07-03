// ui/pages/alerts/alerts_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hydrozap_app/providers/alert_provider.dart';
import 'package:hydrozap_app/providers/device_provider.dart';
import 'package:hydrozap_app/providers/notification_provider.dart';
import 'package:hydrozap_app/core/models/alert_model.dart';
import 'package:hydrozap_app/core/models/device_model.dart';
import 'package:hydrozap_app/ui/components/alert_card.dart';
import 'package:hydrozap_app/ui/components/alerts_filter.dart';
import 'package:hydrozap_app/ui/pages/alerts/alert_detail_page.dart';

class AlertsPage extends StatefulWidget {
  final String userId;
  const AlertsPage({super.key, required this.userId});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  // Filter state
  String? _deviceFilter;
  String? _severityFilter;
  bool _onlyUnacknowledged = false;
  DateTime? _fromDate;
  DateTime? _toDate;
  Map<String, List<Alert>> _groupedAlerts = {};
  bool _isChronological = true;
  
  // Selection state
  bool _selectionMode = false;
  final Set<String> _selectedAlertIds = {};
  
  // Loading states
  bool _isAcknowledging = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // Load alerts when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final alertProvider = Provider.of<AlertProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      
      // Load alerts
      alertProvider.fetchAlerts(widget.userId).then((_) {
        // Check if we need to navigate to a specific alert (from notification tap)
        _checkForAlertNavigation(alertProvider, notificationProvider);
      });
      
      // Load devices for filtering
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      deviceProvider.fetchDevices(widget.userId);
    });
  }
  
  // Check if we need to navigate to a specific alert's details
  Future<void> _checkForAlertNavigation(
    AlertProvider alertProvider,
    NotificationProvider notificationProvider
  ) async {
    try {
      // Get notification navigation intent
      final navigationIntent = await notificationProvider.getNavigationIntent();
      
      if (navigationIntent != null && 
          navigationIntent['route'] == '/alerts' &&
          navigationIntent['arguments'] != null) {
        
        final args = navigationIntent['arguments'] as Map<String, dynamic>;
        
        // Check if we have an alert_id to navigate to
        if (args.containsKey('alert_id')) {
          final alertId = args['alert_id'] as String;
          
          // Find the alert in the provider
          final alert = alertProvider.getAlertById(alertId);
          
          if (alert != null && mounted) {
            // Navigate to the alert details page
            _showAlertDetails(alert, context);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for alert navigation: $e');
    }
  }

  // Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      // Clear selections when exiting selection mode
      if (!_selectionMode) {
        _selectedAlertIds.clear();
      }
    });
  }

  // Handle selection changes
  void _handleAlertSelection(String alertId, bool? isSelected) {
    setState(() {
      if (isSelected == true) {
        _selectedAlertIds.add(alertId);
      } else {
        _selectedAlertIds.remove(alertId);
      }
    });
  }

  // Select or deselect all visible alerts
  void _toggleSelectAll() {
    setState(() {
      List<String> allVisibleAlertIds = [];
      
      // Collect all visible alert IDs
      _groupedAlerts.forEach((_, alerts) {
        for (var alert in alerts) {
          allVisibleAlertIds.add(alert.alertId);
        }
      });
      
      // If all visible are already selected, deselect all
      if (allVisibleAlertIds.every((id) => _selectedAlertIds.contains(id))) {
        _selectedAlertIds.clear();
      } 
      // Otherwise select all visible
      else {
        _selectedAlertIds.addAll(allVisibleAlertIds);
      }
    });
  }

  // Perform bulk acknowledgment
  Future<void> _acknowledgeSelectedAlerts() async {
    if (_isAcknowledging) return; // Prevent multiple simultaneous calls
    
    setState(() {
      _isAcknowledging = true;
    });
    
    final alertProvider = Provider.of<AlertProvider>(context, listen: false);
    
    try {
      final results = await alertProvider.acknowledgeMultipleAlerts(
        widget.userId, 
        _selectedAlertIds.toList(),
      );
      
      // Count successful operations
      int successCount = results.values.where((success) => success).length;
      
      if (mounted) {
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$successCount alerts acknowledged successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Update UI
          setState(() {
            _selectedAlertIds.clear();
            if (successCount == results.length) {
              _selectionMode = false;
            }
          });
          
          // Refresh the filtered alerts
          _handleFilterChanged(
            _deviceFilter,
            _severityFilter,
            _onlyUnacknowledged,
            _fromDate,
            _toDate,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to acknowledge alerts'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAcknowledging = false;
        });
      }
    }
  }

  // Perform bulk deletion
  Future<void> _deleteSelectedAlerts() async {
    final alertProvider = Provider.of<AlertProvider>(context, listen: false);
    
    // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_selectedAlertIds.length} alerts?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    if (_isDeleting) return; // Prevent multiple simultaneous calls
    
    setState(() {
      _isDeleting = true;
    });
    
    try {
      final results = await alertProvider.deleteMultipleAlerts(
        widget.userId, 
        _selectedAlertIds.toList(),
      );
      
      // Count successful operations
      int successCount = results.values.where((success) => success).length;
      
      if (mounted) {
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$successCount alerts deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Update UI
          setState(() {
            for (final entry in results.entries) {
              if (entry.value) {
                _selectedAlertIds.remove(entry.key);
              }
            }
            
            if (_selectedAlertIds.isEmpty) {
              _selectionMode = false;
            }
          });
          
          // Refresh the filtered alerts
          _refreshAlerts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete alerts'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // Handle filter changes
  void _handleFilterChanged(
    String? deviceId,
    String? severity,
    bool? onlyUnacknowledged,
    DateTime? fromDate,
    DateTime? toDate,
  ) {
    if (!mounted) return;
    
    setState(() {
      _deviceFilter = deviceId;
      _severityFilter = severity;
      _onlyUnacknowledged = onlyUnacknowledged ?? false;
      _fromDate = fromDate;
      _toDate = toDate;
    });
    
    // Apply filters through AlertProvider
    final alertProvider = Provider.of<AlertProvider>(context, listen: false);
    
    if (_isChronological) {
      _groupedAlerts = alertProvider.getGroupedAlerts(
        deviceId: _deviceFilter,
        severity: _severityFilter,
        onlyUnacknowledged: _onlyUnacknowledged,
        fromDate: _fromDate,
        toDate: _toDate,
      );
    } else {
      // For flat list view, convert filtered alerts to a single group
      final filteredAlerts = alertProvider.filterAlerts(
        deviceId: _deviceFilter,
        severity: _severityFilter,
        onlyUnacknowledged: _onlyUnacknowledged,
        fromDate: _fromDate,
        toDate: _toDate,
      );
      _groupedAlerts = {'All': filteredAlerts};
    }
  }

  // Helper function to get severity count
  int _getSeverityCount() {
    if (_severityFilter == null || _severityFilter!.isEmpty) return 0;
    return _severityFilter!.split(',').length;
  }

  // Helper function to get active filter count
  int _getActiveFilterCount() {
    int count = 0;
    if (_deviceFilter != null) count++;
    count += _getSeverityCount();
    if (_onlyUnacknowledged) count++;
    if (_fromDate != null) count++;
    return count;
  }

  // Get device name from deviceId
  String _getDeviceName(String deviceId, List<DeviceModel> devices) {
    try {
      final device = devices.firstWhere(
        (device) => device.id == deviceId,
      );
      return device.deviceName;
    } catch (e) {
      return 'Unknown Device';
    }
  }

  // Navigate to alert detail page
  Future<void> _showAlertDetails(Alert alert, BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertDetailPage(
          alert: alert,
          userId: widget.userId,
        ),
      ),
    );
    
    // If changes were made, refresh the alerts list
    if (result == true) {
      if (!mounted) return;
      _refreshAlerts();
    }
  }

  // Refresh alerts and apply current filters
  void _refreshAlerts() {
    final alertProvider = Provider.of<AlertProvider>(context, listen: false);
    alertProvider.fetchAlerts(widget.userId).then((_) {
      if (mounted) {
        setState(() {
          if (_isChronological) {
            _groupedAlerts = alertProvider.getGroupedAlerts(
              deviceId: _deviceFilter,
              severity: _severityFilter,
              onlyUnacknowledged: _onlyUnacknowledged,
              fromDate: _fromDate,
              toDate: _toDate,
            );
          } else {
            final filteredAlerts = alertProvider.filterAlerts(
              deviceId: _deviceFilter,
              severity: _severityFilter,
              onlyUnacknowledged: _onlyUnacknowledged,
              fromDate: _fromDate,
              toDate: _toDate,
            );
            _groupedAlerts = {'All': filteredAlerts};
          }
        });
      }
    });
  }

  // Toggle between chronological and flat view
  void _toggleChronologicalView() {
    if (!mounted) return;
    
    setState(() {
      _isChronological = !_isChronological;
    });
    _handleFilterChanged(
      _deviceFilter,
      _severityFilter,
      _onlyUnacknowledged,
      _fromDate,
      _toDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define gradient colors
    const List<Color> backgroundGradient = [
      Color(0xFF2193b0), // blue
      Color(0xFF6dd5ed), // light blue
      Color(0xFFb2fefa), // teal
    ];
    const List<Color> appBarGradient = [
      Color(0xFF2193b0),
      Color(0xFF6dd5ed),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent, // Make background transparent for gradient
      extendBodyBehindAppBar: true, // Let gradient go behind AppBar
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent, // Transparent to show gradient
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: appBarGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: _selectionMode 
            ? Text('${_selectedAlertIds.length} selected', style: const TextStyle(color: Colors.white))
            : const Text('Alerts', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: _selectionMode 
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: _selectionMode 
            ? [
                // Select/deselect all
                IconButton(
                  icon: const Icon(Icons.select_all),
                  tooltip: 'Select all',
                  onPressed: _toggleSelectAll,
                ),
                // Mark as read
                _isAcknowledging
                    ? const SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.check),
                        tooltip: 'Mark as read',
                        onPressed: _selectedAlertIds.isEmpty ? null : _acknowledgeSelectedAlerts,
                      ),
                // Delete selected
                _isDeleting
                    ? const SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                            ),
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Delete',
                        onPressed: _selectedAlertIds.isEmpty ? null : _deleteSelectedAlerts,
                      ),
              ]
            : [
                // Selection mode toggle
                IconButton(
                  icon: const Icon(Icons.checklist),
                  tooltip: 'Select multiple',
                  onPressed: _toggleSelectionMode,
                ),
                // View toggle
                IconButton(
                  icon: Icon(_isChronological ? Icons.view_agenda : Icons.view_day),
                  tooltip: _isChronological ? 'Show as flat list' : 'Group by date',
                  onPressed: _toggleChronologicalView,
                ),
                // Refresh
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshAlerts,
                ),
              ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Consumer2<AlertProvider, DeviceProvider>(
        builder: (context, alertProvider, deviceProvider, child) {
          if (alertProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // If no filters have been applied yet, initialize grouped alerts
          if (_groupedAlerts.isEmpty) {
            _groupedAlerts = alertProvider.getGroupedAlerts();
          }
          
          // Calculate total alerts count across all groups
          int totalAlerts = 0;
          _groupedAlerts.forEach((_, alerts) => totalAlerts += alerts.length);
          
          return Column(
            children: [
              // Filter component (hide in selection mode)
              if (!_selectionMode)
                AlertsFilter(
                  devices: deviceProvider.devices,
                  onFilterChanged: _handleFilterChanged,
                ),
              
              // Alert count summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$totalAlerts ${totalAlerts == 1 ? 'Alert' : 'Alerts'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (!_selectionMode && 
                        (_deviceFilter != null || 
                         _getSeverityCount() > 0 || 
                         _onlyUnacknowledged || 
                         _fromDate != null))
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.filter_list, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${_getActiveFilterCount()} active',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              _handleFilterChanged(null, null, false, null, null);
                            },
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              // Alert list
              Expanded(
                child: totalAlerts == 0
                  ? const Center(child: Text("No alerts found."))
                  : ListView.builder(
                    itemCount: _groupedAlerts.length,
                    itemBuilder: (context, groupIndex) {
                      final groupKey = _groupedAlerts.keys.elementAt(groupIndex);
                      final alerts = _groupedAlerts[groupKey]!;
                      
                      // Skip empty groups
                      if (alerts.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date header for chronological view
                          if (_isChronological && groupKey != 'All')
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                              child: Text(
                                groupKey,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ),
                          
                          // Alerts in this group
                          ...alerts.map((alert) {
                            return AlertCard(
                              alert: alert,
                              deviceName: _getDeviceName(alert.deviceId, deviceProvider.devices),
                              onTap: _selectionMode 
                                  ? null 
                                  : () => _showAlertDetails(alert, context),
                              onAcknowledge: () async {
                                // Show a loading indicator while acknowledging
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Acknowledging alert...'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                                
                                final success = await alertProvider.acknowledgeAlert(
                                  widget.userId, 
                                  alert.alertId,
                                );
                                
                                if (success) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Alert acknowledged successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    
                                    // Manually refresh the UI with updated filter state
                                    setState(() {
                                      if (_isChronological) {
                                        _groupedAlerts = alertProvider.getGroupedAlerts(
                                          deviceId: _deviceFilter,
                                          severity: _severityFilter,
                                          onlyUnacknowledged: _onlyUnacknowledged,
                                          fromDate: _fromDate,
                                          toDate: _toDate,
                                        );
                                      } else {
                                        final filteredAlerts = alertProvider.filterAlerts(
                                          deviceId: _deviceFilter,
                                          severity: _severityFilter,
                                          onlyUnacknowledged: _onlyUnacknowledged,
                                          fromDate: _fromDate,
                                          toDate: _toDate,
                                        );
                                        _groupedAlerts = {'All': filteredAlerts};
                                      }
                                    });
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to acknowledge alert'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    _refreshAlerts();
                                  }
                                }
                              },
                              onDismiss: () async {
                                // Show a loading indicator while dismissing
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Dismissing alert...'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                                
                                final success = await alertProvider.deleteAlert(
                                  widget.userId, 
                                  alert.alertId,
                                );
                                
                                if (mounted) {
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Alert dismissed successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    _refreshAlerts();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to dismiss alert'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    _refreshAlerts();
                                  }
                                }
                              },
                              // Selection mode properties
                              selectionMode: _selectionMode,
                              isSelected: _selectedAlertIds.contains(alert.alertId),
                              onSelectionChanged: (selected) => 
                                _handleAlertSelection(alert.alertId, selected),
                            );
                          }),
                        ],
                      );
                    },
                  ),
              ),
            ],
          );
        },
          ),
        ),
      ),
    );
  }
}
