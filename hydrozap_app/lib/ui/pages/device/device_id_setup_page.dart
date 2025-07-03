import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../components/custom_button.dart';
import '../../widgets/responsive_widget.dart';
import '../../../core/helpers/utils.dart';
import '../../../core/api/api_service.dart';

class DeviceIdSetupPage extends StatefulWidget {
  final Function(String) onDeviceIdSelected;
  final String? initialDeviceId;
  final VoidCallback? onCancel;

  const DeviceIdSetupPage({
    Key? key, 
    required this.onDeviceIdSelected,
    this.initialDeviceId,
    this.onCancel,
  }) : super(key: key);

  @override
  _DeviceIdSetupPageState createState() => _DeviceIdSetupPageState();
}

class _DeviceIdSetupPageState extends State<DeviceIdSetupPage> {
  final TextEditingController _deviceIdController = TextEditingController();
  bool _isValid = false;
  bool _isLoading = false;
  String? _errorMessage;
  final ApiService _apiService = ApiService();
  
  @override
  void initState() {
    super.initState();
    
    if (widget.initialDeviceId != null) {
      _deviceIdController.text = widget.initialDeviceId!;
      _validateDeviceId(_deviceIdController.text);
    }
    
    _deviceIdController.addListener(() {
      _validateDeviceId(_deviceIdController.text);
      setState(() {
        _errorMessage = null;
      });
    });
  }
  
  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }
  
  void _validateDeviceId(String value) {
    setState(() {
      _isValid = value.trim().length >= 3;
    });
  }

  Future<void> _validateRegisteredDevice(String deviceId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final deviceData = await _apiService.checkRegisteredDevice(deviceId);
      
      if (deviceData != null && deviceData['device'] != null) {
        final device = deviceData['device'];
        if (device['registered'] == true && device['status'] == 'available') {
          widget.onDeviceIdSelected(deviceId);
        } else if (device['status'] != 'available') {
          setState(() {
            _errorMessage = 'This device is already in use by another user.';
          });
        } else {
          setState(() {
            _errorMessage = 'This device ID is not registered in our system.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'This device ID is not registered in our system.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error validating device. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _handleNext() {
    if (_isValid) {
      final deviceId = _deviceIdController.text.trim();
      _validateRegisteredDevice(deviceId);
    }
  }
  
  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ResponsiveWidget(
          mobile: _buildMobileLayout(),
          tablet: _buildTabletLayout(),
          desktop: _buildDesktopLayout(),
        ),
      ),
    );
  }
  
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildContent(),
      ),
    );
  }
  
  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24.0),
          child: _buildContent(),
        ),
      ),
    );
  }
  
  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(32.0),
          child: _buildContent(),
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderSection(),
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Device Identification",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              TextField(
                controller: _deviceIdController,
                decoration: InputDecoration(
                  labelText: "Device ID",
                  hintText: "Enter your device ID",
                  prefixIcon: const Icon(Icons.qr_code),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  errorText: _errorMessage,
                ),
              ),
              const SizedBox(height: 24),
              
              // Help info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Where to find your Device ID",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Your Device ID is printed on the label of your device or can be found in the device documentation.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Next button
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: "Cancel",
                onPressed: _handleCancel,
                variant: ButtonVariant.outline,
                backgroundColor: Colors.white,
                textColor: Colors.grey[800],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: _isLoading ? "Validating..." : "Next",
                onPressed: _isValid && !_isLoading ? _handleNext : () {},
                variant: ButtonVariant.primary,
                backgroundColor: AppColors.primary,
                icon: _isLoading ? null : Icons.arrow_forward,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildHeaderSection() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      height: isMobile ? 120 : 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/images/main.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.primary.withOpacity(0.8),
                    AppColors.forest.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.devices_other,
                    color: Colors.white,
                    size: isMobile ? 28 : 36,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Connect Your Device",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Enter your device ID to start the setup process",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 