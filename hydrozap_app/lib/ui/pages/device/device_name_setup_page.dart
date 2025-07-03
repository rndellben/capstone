import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../components/custom_button.dart';
import '../../widgets/responsive_widget.dart';

class DeviceNameSetupPage extends StatefulWidget {
  final Function(String) onDeviceNameSelected;
  final String? initialDeviceName;
  final String deviceId;
  final VoidCallback? onCancel;

  const DeviceNameSetupPage({
    Key? key, 
    required this.onDeviceNameSelected,
    required this.deviceId,
    this.initialDeviceName,
    this.onCancel,
  }) : super(key: key);

  @override
  _DeviceNameSetupPageState createState() => _DeviceNameSetupPageState();
}

class _DeviceNameSetupPageState extends State<DeviceNameSetupPage> {
  final TextEditingController _deviceNameController = TextEditingController();
  bool _isValid = false;
  
  // Some naming suggestions
  final List<String> _suggestions = [
    "Kitchen Garden",
    "Herb Garden",
    "Lettuce System",
    "Tomato Tower",
    "Strawberry Farm",
    "Hydroponics Lab",
    "Green Tower"
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Set initial value or default
    if (widget.initialDeviceName != null && widget.initialDeviceName!.isNotEmpty) {
      _deviceNameController.text = widget.initialDeviceName!;
    } else {
      _deviceNameController.text = "Device ${widget.deviceId}";
    }
    
    _validateDeviceName(_deviceNameController.text);
    
    _deviceNameController.addListener(() {
      _validateDeviceName(_deviceNameController.text);
    });
  }
  
  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }
  
  void _validateDeviceName(String value) {
    setState(() {
      _isValid = value.trim().isNotEmpty;
    });
  }
  
  void _handleNext() {
    if (_isValid) {
      widget.onDeviceNameSelected(_deviceNameController.text.trim());
    }
  }
  
  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop();
    }
  }
  
  void _selectSuggestion(String suggestion) {
    setState(() {
      _deviceNameController.text = suggestion;
    });
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
                    Icons.drive_file_rename_outline,
                    color: AppColors.forest,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Device Name",
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
                controller: _deviceNameController,
                decoration: InputDecoration(
                  labelText: "Device Name",
                  hintText: "Enter a name for your device",
                  prefixIcon: const Icon(Icons.label_outline),
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
                      color: AppColors.forest,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Name suggestions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.forest,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Naming Suggestions",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.forest,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _suggestions.map((suggestion) => 
                        _buildNameSuggestion(suggestion)
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Navigation buttons
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: "Back",
                onPressed: _handleCancel,
                variant: ButtonVariant.outline,
                backgroundColor: Colors.white,
                textColor: Colors.grey[800],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: "Next",
                onPressed: _isValid ? _handleNext : () {},
                variant: ButtonVariant.primary,
                backgroundColor: AppColors.primary,
                icon: Icons.arrow_forward,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildNameSuggestion(String name) {
    return InkWell(
      onTap: () => _selectSuggestion(name),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.forest.withOpacity(0.3)),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: AppColors.forest,
            fontSize: 12,
          ),
        ),
      ),
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
                    AppColors.forest.withOpacity(0.8),
                    AppColors.leaf.withOpacity(0.7),
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
                    Icons.edit,
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
                        "Name Your Device",
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
                        "Give your device a friendly name to identify it easily",
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