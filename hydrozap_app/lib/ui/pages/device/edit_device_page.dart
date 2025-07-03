// lib/ui/pages/device/edit_device_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/device_model.dart';
import '../../../providers/device_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/utils.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../widgets/responsive_widget.dart';

const List<Color> forestToLeafGradient = [
  Color(0xFF14532D), // Forest green
  Color(0xFF2E7D32), // Mid green
  Color(0xFF81C784), // Leaf green
];

class EditDevicePage extends StatefulWidget {
  final DeviceModel device;

  const EditDevicePage({super.key, required this.device});

  @override
  _EditDevicePageState createState() => _EditDevicePageState();
}

class _EditDevicePageState extends State<EditDevicePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _deviceNameController;
  late TextEditingController _waterVolumeController;
  late bool _emergencyStop;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _deviceNameController = TextEditingController(text: widget.device.deviceName);
    _waterVolumeController = TextEditingController(text: widget.device.waterVolumeInLiters.toString());
    _emergencyStop = widget.device.emergencyStop;
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _waterVolumeController.dispose();
    super.dispose();
  }

  Future<void> _saveDevice() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
        double waterVolume = 0.0;
        try {
          waterVolume = double.parse(_waterVolumeController.text);
        } catch (e) {
          waterVolume = 0.0;
        }
        Map<String, dynamic> updateData = {
          "device_name": _deviceNameController.text,
          "emergency_stop": _emergencyStop,
          "water_volume_liters": waterVolume
        };
        final success = await deviceProvider.updateDevice(widget.device.id, updateData);
        if (success) {
          if (mounted) {
            await showAlertDialog(
              context: context,
              title: 'Success',
              message: 'Device updated successfully',
              type: AlertType.success,
              showCancelButton: false,
              confirmButtonText: 'OK',
              onConfirm: () => Navigator.pop(context, true),
            );
          }
        } else {
          if (mounted) {
            await showAlertDialog(
              context: context,
              title: 'Error',
              message: 'Failed to update device',
              type: AlertType.error,
              showCancelButton: false,
              confirmButtonText: 'OK',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          await showAlertDialog(
            context: context,
            title: 'Error',
            message: 'An unexpected error occurred: ${e.toString()}',
            type: AlertType.error,
            showCancelButton: false,
            confirmButtonText: 'OK',
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          title: const Text('Edit Device'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: forestToLeafGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
      ),
      body: ResponsiveWidget(
        mobile: _buildForm(),
        tablet: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _buildForm(),
          ),
        ),
        desktop: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDeviceInfoCard(),
              const SizedBox(height: 32),
              CustomButton(
                text: "Save Changes",
                onPressed: _saveDevice,
                isLoading: _isLoading,
                icon: Icons.save,
                variant: ButtonVariant.primary,
                useGradient: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                "Edit Device Information",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          CustomTextField(
            label: "Device Name",
            hint: "Enter device name",
            controller: _deviceNameController,
            prefixIcon: Icons.device_hub,
            enableBorder: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Device name is required";
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: "Water Volume (liters)",
            hint: "Enter tank water volume",
            controller: _waterVolumeController,
            prefixIcon: Icons.water_drop,
            enableBorder: true,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Water volume is required";
              }
              try {
                final volume = double.parse(value);
                if (volume <= 0) {
                  return "Volume must be greater than zero";
                }
                if (volume > 1000) {
                  return "Volume must not exceed 1000 liters";
                }
              } catch (e) {
                return "Please enter a valid number";
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _emergencyStop ? Colors.red.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _emergencyStop ? Colors.red.shade200 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emergency,
                  color: _emergencyStop ? Colors.red : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Emergency Stop",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _emergencyStop ? Colors.red.shade700 : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Enable to prevent device operation",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _emergencyStop,
                  onChanged: (value) => setState(() => _emergencyStop = value),
                  activeColor: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
