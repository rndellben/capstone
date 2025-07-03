// ui/pages/dashboard/device_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../device/edit_device_page.dart';

class DeviceListPage extends StatefulWidget {
  final String userId;
  final VoidCallback? onDeviceSelected;

  const DeviceListPage({
    super.key,
    required this.userId,
    this.onDeviceSelected,
  });

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);

    return Column(
      children: [
        _buildHeader(deviceProvider),
        Expanded(
          child: _buildDeviceList(deviceProvider),
        ),
      ],
    );
  }

  Widget _buildHeader(DeviceProvider deviceProvider) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final deviceCount = dashboardProvider.deviceCount;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Devices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deviceCount > 0 
                        ? '$deviceCount device${deviceCount > 1 ? 's' : ''} connected'
                        : 'No devices connected',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              _buildSortButton(),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.sort,
        color: Colors.grey[700],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tooltip: 'Sort devices',
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'name',
          child: Text('Sort by name'),
        ),
        const PopupMenuItem(
          value: 'status',
          child: Text('Sort by status'),
        ),
        const PopupMenuItem(
          value: 'type',
          child: Text('Sort by type'),
        ),
        const PopupMenuItem(
          value: 'recent',
          child: Text('Most recent'),
        ),
      ],
      onSelected: (value) {
        // Implement sorting logic
      },
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All'),
          _buildFilterChip('Online'),
          _buildFilterChip('Offline'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.grey[100],
        selectedColor: AppColors.secondary,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.secondary : Colors.grey.withAlpha((0.3 * 255).round()),
            width: 1,
          ),
        ),
        onSelected: (selected) {
          setState(() {
            _filter = label;
          });
          // Apply filtering logic here
        },
      ),
    );
  }

  Widget _buildDeviceList(DeviceProvider deviceProvider) {
    if (deviceProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (deviceProvider.devices.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await deviceProvider.fetchDevices(widget.userId);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Consumer<DeviceProvider>(
          builder: (context, deviceProvider, child) {
            final devices = deviceProvider.devices;
            
            // Filter devices based on selected filter
            final filteredDevices = devices.where((device) {
              switch (_filter) {
                case 'Online':
                  return (device.status == 'on' || device.status == 'available' || device.status == 'in_use') && !device.emergencyStop;
                case 'Offline':
                  return device.status == 'off' || device.emergencyStop;
                default: // 'All'
                  return true;
              }
            }).toList();
            
            return ListView.builder(
              itemCount: filteredDevices.length,
              itemBuilder: (context, index) {
                final device = filteredDevices[index];
                final isSelected = device.id == deviceProvider.selectedDevice?.id;

                return Card(
                  elevation: isSelected ? 3 : 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      deviceProvider.selectDevice(device);
                      widget.onDeviceSelected?.call();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha((0.1 * 255).round()),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.devices,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device.deviceName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  device.type,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 80),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: device.emergencyStop
                                        ? AppColors.error.withAlpha((0.1 * 255).round())
                                        : Colors.green.withAlpha((0.1 * 255).round()),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    device.emergencyStop ? 'Stopped' : 'Active',
                                    style: TextStyle(
                                      color: device.emergencyStop
                                          ? AppColors.error
                                          : Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints.tightFor(width: 20, height: 20),
                                  color: AppColors.primary,
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditDevicePage(device: device),
                                      ),
                                    );
                                    
                                    if (result == true) {
                                      deviceProvider.refreshDevices();
                                    }
                                  },
                                  tooltip: 'Edit Device',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Devices Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first device to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/add-device', arguments: widget.userId);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Device'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}