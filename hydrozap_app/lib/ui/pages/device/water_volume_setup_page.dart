import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/constants/app_colors.dart';
import '../../components/custom_button.dart';
import '../../widgets/responsive_widget.dart';

class WaterVolumeSetupPage extends StatefulWidget {
  final Function(double) onVolumeSelected;
  final double? initialVolume;
  final VoidCallback? onCancel;

  const WaterVolumeSetupPage({
    Key? key, 
    required this.onVolumeSelected,
    this.initialVolume,
    this.onCancel,
  }) : super(key: key);

  @override
  _WaterVolumeSetupPageState createState() => _WaterVolumeSetupPageState();
}

class _WaterVolumeSetupPageState extends State<WaterVolumeSetupPage> {
  bool _useMetric = true; // true for liters, false for gallons
  double? _selectedVolume;
  final TextEditingController _customVolumeController = TextEditingController();
  bool _isCustom = false;
  
  // Conversion factor: 1 gallon = 3.78541 liters
  static const double _gallonsToLiters = 3.78541;
  
  @override
  void initState() {
    super.initState();
    _selectedVolume = widget.initialVolume;
    
    if (_selectedVolume != null) {
      if (_selectedVolume == 20 || _selectedVolume == 60 || _selectedVolume == 100) {
        // It's one of the presets
        _isCustom = false;
      } else {
        // It's a custom value
        _isCustom = true;
        _customVolumeController.text = _useMetric
            ? _selectedVolume!.toStringAsFixed(1)
            : (_selectedVolume! / _gallonsToLiters).toStringAsFixed(1);
      }
    }
  }
  
  @override
  void dispose() {
    _customVolumeController.dispose();
    super.dispose();
  }
  
  void _switchUnits() {
    setState(() {
      _useMetric = !_useMetric;
      
      // Update the custom volume text if it's being used
      if (_isCustom && _customVolumeController.text.isNotEmpty) {
        try {
          double value = double.parse(_customVolumeController.text);
          if (_useMetric) {
            // Convert from gallons to liters
            _customVolumeController.text = (value * _gallonsToLiters).toStringAsFixed(1);
          } else {
            // Convert from liters to gallons
            _customVolumeController.text = (value / _gallonsToLiters).toStringAsFixed(1);
          }
        } catch (e) {
          // Ignore parsing errors
        }
      }
    });
  }
  
  void _selectVolume(double volume) {
    setState(() {
      _selectedVolume = volume;
      _isCustom = false;
    });
  }
  
  void _selectCustomVolume() {
    setState(() {
      _isCustom = true;
      _selectedVolume = null; // Clear the selection until a valid custom value is entered
    });
  }
  
  void _validateAndContinue() {
    if (_isCustom) {
      // Parse the custom volume
      try {
        double customVolume = double.parse(_customVolumeController.text);
        if (customVolume <= 0) {
          _showError("Volume must be greater than zero");
          return;
        }
        
        // Convert to liters if necessary
        if (!_useMetric) {
          customVolume *= _gallonsToLiters;
        }
        
        widget.onVolumeSelected(customVolume);
      } catch (e) {
        _showError("Please enter a valid number");
      }
    } else if (_selectedVolume != null) {
      widget.onVolumeSelected(_selectedVolume!);
    } else {
      _showError("Please select a water volume");
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLandscape = screenSize.width > screenSize.height;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ResponsiveWidget(
          mobile: isLandscape ? _buildMobileLandscape() : _buildMobileLayout(),
          tablet: isLandscape ? _buildTabletLandscape() : _buildTabletLayout(),
          desktop: _buildDesktopLayout(),
        ),
      ),
    );
  }
  
  Widget _buildMobileLayout() {
    final Size screenSize = MediaQuery.of(context).size;
    // Calculate responsive spacing
    final double verticalSpacing = screenSize.height * 0.02; // 2% of screen height
    final double fontSize = screenSize.width < 360 ? 20 : 24; // Smaller font for very small devices
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.06, // 6% of screen width
        vertical: verticalSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _useMetric ? "How many liters?" : "How many gallons?",
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: verticalSpacing * 1.5),
          // Volume options grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double itemSize = constraints.maxWidth > 380 ? 90 : 80;
                final bool useGrid = constraints.maxHeight > 400;
                
                if (useGrid) {
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildVolumeOption(20, size: itemSize),
                      _buildVolumeOption(60, size: itemSize),
                      _buildVolumeOption(100, size: itemSize),
                      _buildCustomOption(size: itemSize),
                    ],
                  );
                } else {
                  // For very small height screens
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildVolumeOption(20, size: itemSize)),
                            SizedBox(width: 16),
                            Expanded(child: _buildVolumeOption(60, size: itemSize)),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildVolumeOption(100, size: itemSize)),
                            SizedBox(width: 16),
                            Expanded(child: _buildCustomOption(size: itemSize)),
                          ],
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
          SizedBox(height: verticalSpacing),
          // Unit switcher
          Center(
            child: InkWell(
              onTap: _switchUnits,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "Switch to ${_useMetric ? 'gallons' : 'liters'}",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: verticalSpacing),
          // Description
          Center(
            child: Text(
              "Enter the amount of water running in your hydroponic system.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: InkWell(
                onTap: _showHelpDialog,
                child: Text(
                  "Don't know?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: verticalSpacing * 1.5),
          // Buttons row
          Row(
            children: [
              // Cancel button
              Expanded(
                child: CustomButton(
                  text: "CANCEL",
                  onPressed: _handleCancel,
                  variant: ButtonVariant.outline,
                  backgroundColor: Colors.white,
                  textColor: Colors.grey[800],
                ),
              ),
              SizedBox(width: 16),
              // Next button
              Expanded(
                child: CustomButton(
                  text: "NEXT",
                  onPressed: _validateAndContinue,
                  variant: ButtonVariant.primary,
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabletLayout() {
    final Size screenSize = MediaQuery.of(context).size;
    // Calculate responsive sizing
    final double paddingSize = screenSize.width * 0.04; // 4% of screen width
    final double itemSize = screenSize.width * 0.15; // 15% of screen width, capped at 110
    
    return Padding(
      padding: EdgeInsets.all(paddingSize),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _useMetric ? "How many liters?" : "How many gallons?",
            style: TextStyle(
              fontSize: min(28, screenSize.width * 0.042), // Responsive font size
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Select your reservoir size",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: screenSize.height * 0.03), // 3% of screen height
          // Volume options in a grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 600, // Limit width for better readability
                    ),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 1.2,
                      children: [
                        _buildVolumeOption(20, size: min(itemSize, 110)),
                        _buildVolumeOption(60, size: min(itemSize, 110)),
                        _buildVolumeOption(100, size: min(itemSize, 110)),
                        _buildCustomOption(size: min(itemSize, 110)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: screenSize.height * 0.02),
          // Unit switcher
          Center(
            child: InkWell(
              onTap: _switchUnits,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Switch to ${_useMetric ? 'gallons' : 'liters'}",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: screenSize.height * 0.03),
          // Description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Text(
                  "Enter the amount of water running in your hydroponic system.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _showHelpDialog,
                  child: Text(
                    "Don't know?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenSize.height * 0.03),
          // Buttons
          Row(
            children: [
              // Cancel button
              Expanded(
                child: CustomButton(
                  text: "CANCEL",
                  onPressed: _handleCancel,
                  variant: ButtonVariant.outline,
                  backgroundColor: Colors.white,
                  textColor: Colors.grey[800],
                  height: 50,
                ),
              ),
              SizedBox(width: 20),
              // Next button
              Expanded(
                child: CustomButton(
                  text: "NEXT",
                  onPressed: _validateAndContinue,
                  variant: ButtonVariant.primary,
                  backgroundColor: AppColors.primary,
                  height: 50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDesktopLayout() {
    final Size screenSize = MediaQuery.of(context).size;
    // Calculate responsive sizing
    final double paddingSize = screenSize.width * 0.03; // 3% of screen width
    final double minPadding = 32;
    final double effectivePadding = max(paddingSize, minPadding);
    
    return Padding(
      padding: EdgeInsets.all(effectivePadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Illustration and info
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Set Up Your Hydroponic System",
                  style: TextStyle(
                    fontSize: min(32, screenSize.width * 0.025), // Responsive size capped at 32
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Let's configure your tank size for precise nutrient dosing",
                  style: TextStyle(
                    fontSize: min(18, screenSize.width * 0.014), // Responsive size capped at 18
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: screenSize.height * 0.04),
                // Illustration
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 450, // Limit illustration size
                        maxHeight: 350,
                      ),
                      child: _buildIllustration(),
                    ),
                  ),
                ),
                // Help text
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            "Why is tank volume important?",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Knowing your tank volume allows HydroZap to calculate precise dosing for nutrients and pH adjustments. This ensures your plants receive the optimal care without waste.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            width: 1,
            height: double.infinity,
            color: Colors.grey[200],
          ),
          // Right side - Selection
          Expanded(
            flex: 4,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isWideEnough = constraints.maxWidth > 400;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _useMetric ? "How many liters?" : "How many gallons?",
                      style: TextStyle(
                        fontSize: min(28, screenSize.width * 0.02),
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Select your reservoir size",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.03),
                    // Volume options in a grid
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: isWideEnough ? 2 : 1,
                        shrinkWrap: true,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.2,
                        children: [
                          _buildVolumeOption(20, size: 120),
                          _buildVolumeOption(60, size: 120),
                          _buildVolumeOption(100, size: 120),
                          _buildCustomOption(size: 120),
                        ],
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.03),
                    // Unit switcher
                    Center(
                      child: InkWell(
                        onTap: _switchUnits,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.swap_horiz, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "Switch to ${_useMetric ? 'gallons' : 'liters'}",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.03),
                    // Buttons
                    Row(
                      children: [
                        // Cancel button
                        Expanded(
                          child: CustomButton(
                            text: "CANCEL",
                            onPressed: _handleCancel,
                            variant: ButtonVariant.outline,
                            backgroundColor: Colors.white,
                            textColor: Colors.grey[800],
                            height: 50,
                          ),
                        ),
                        SizedBox(width: 20),
                        // Next button
                        Expanded(
                          child: CustomButton(
                            text: "NEXT",
                            onPressed: _validateAndContinue,
                            variant: ButtonVariant.primary,
                            backgroundColor: AppColors.primary,
                            height: 50,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIllustration() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;
        final double tankWidth = min(maxWidth * 0.9, 280);
        final double tankHeight = min(maxHeight * 0.8, 220);
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // Water tank/reservoir illustration
            Container(
              width: tankWidth,
              height: tankHeight,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[300]!, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              // Water level
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: tankHeight * 0.64, // 64% of tank height
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue[300]!.withOpacity(0.5),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(14),
                          bottomRight: Radius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  // Water ripples
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: tankHeight * 0.55),
                      child: Container(
                        height: 3,
                        width: tankWidth * 0.85, // 85% of tank width
                        decoration: BoxDecoration(
                          color: Colors.blue[300]!.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: tankHeight * 0.51),
                      child: Container(
                        height: 2,
                        width: tankWidth * 0.79, // 79% of tank width
                        decoration: BoxDecoration(
                          color: Colors.blue[300]!.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Measurement marks on the side
                  Positioned(
                    top: tankHeight * 0.14,
                    right: tankWidth * 0.07,
                    bottom: tankHeight * 0.14,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        5,
                        (index) => Container(
                          width: 12,
                          height: 2,
                          color: Colors.blue[400],
                        ),
                      ),
                    ),
                  ),
                  // Plants
                  Positioned(
                    top: tankHeight * 0.14,
                    left: tankWidth * 0.14,
                    child: _buildPlant(tankHeight * 0.41, 0.8),
                  ),
                  Positioned(
                    top: tankHeight * 0.09,
                    left: tankWidth * 0.43,
                    child: _buildPlant(tankHeight * 0.45, 1.0),
                  ),
                  Positioned(
                    top: tankHeight * 0.11,
                    left: tankWidth * 0.68,
                    child: _buildPlant(tankHeight * 0.39, 0.7),
                  ),
                  // Volume label
                  Positioned(
                    bottom: tankHeight * 0.05,
                    right: tankWidth * 0.04,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _useMetric ? "? Liters" : "? Gallons",
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                          fontSize: tankWidth * 0.05,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "How to Measure Your Tank Volume",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpItem(
                  "1. Empty Container Method", 
                  "Fill your tank using a container of known volume (like a 1-gallon jug). Count how many times you fill it."
                ),
                const SizedBox(height: 16),
                _buildHelpItem(
                  "2. Calculate by Dimensions", 
                  "For rectangular tanks: Length × Width × Height (in inches) ÷ 231 = gallons\nFor cylindrical tanks: π × radius² × height (in inches) ÷ 231 = gallons"
                ),
                const SizedBox(height: 16),
                _buildHelpItem(
                  "3. Water Meter", 
                  "If you have a water meter on your input line, check the reading before and after filling the tank."
                ),
                const SizedBox(height: 16),
                Text(
                  "Common Presets:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text("• Small systems: 20 liters (5.3 gallons)"),
                Text("• Medium systems: 60 liters (15.9 gallons)"),
                Text("• Large systems: 100 liters (26.4 gallons)"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "CLOSE",
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          elevation: 4,
        );
      },
    );
  }
  
  Widget _buildHelpItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPlant(double height, double scale) {
    return Transform.scale(
      scale: scale,
      child: Column(
        children: [
          // Leaves
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green[300],
              shape: BoxShape.circle,
            ),
          ),
          // Stem
          Container(
            width: 4,
            height: height - 40,
            color: Colors.green[700],
          ),
        ],
      ),
    );
  }
  
  Widget _buildVolumeOption(double volume, {double size = 90}) {
    final bool isSelected = !_isCustom && _selectedVolume == volume;
    final String displayVolume = _useMetric
        ? volume.toStringAsFixed(0)
        : (volume / _gallonsToLiters).toStringAsFixed(1);
    final String unit = _useMetric ? "Liters" : "Gallons";
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale font size based on the container size
        final double valueFontSize = min(size * 0.22, 22);
        final double unitFontSize = min(size * 0.16, 16);
        
        return GestureDetector(
          onTap: () => _selectVolume(volume),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: size,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ] : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayVolume,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : Colors.grey[800],
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: unitFontSize,
                      color: isSelected ? AppColors.primary : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCustomOption({double size = 90}) {
    final bool isSelected = _isCustom;
    final String unit = _useMetric ? "Liters" : "Gallons";
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale font size based on the container size
        final double valueFontSize = min(size * 0.22, 22);
        final double unitFontSize = min(size * 0.16, 16);
        final double inputWidth = min(size * 0.8, 90);
        
        return GestureDetector(
          onTap: _selectCustomVolume,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: size,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ] : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    SizedBox(
                      width: inputWidth,
                      child: TextField(
                        controller: _customVolumeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                          hintText: "0.0",
                          hintStyle: TextStyle(
                            color: AppColors.primary.withOpacity(0.5),
                            fontSize: valueFontSize,
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      "OTHER",
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.primary : Colors.grey[800],
                      ),
                    ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: unitFontSize,
                      color: isSelected ? AppColors.primary : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMobileLandscape() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Text and description
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _useMetric ? "How many liters?" : "How many gallons?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Enter the amount of water running in your hydroponic system.",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: InkWell(
                    onTap: _showHelpDialog,
                    child: Text(
                      "Don't know?",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                // Unit switcher
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: InkWell(
                    onTap: _switchUnits,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz, color: AppColors.primary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "Switch to ${_useMetric ? 'gallons' : 'liters'}",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Buttons
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: CustomButton(
                        text: "CANCEL",
                        onPressed: _handleCancel,
                        variant: ButtonVariant.outline,
                        backgroundColor: Colors.white,
                        textColor: Colors.grey[800],
                      ),
                    ),
                    SizedBox(width: 12),
                    // Next button
                    Expanded(
                      child: CustomButton(
                        text: "NEXT",
                        onPressed: _validateAndContinue,
                        variant: ButtonVariant.primary,
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right side - Volume options grid
          Expanded(
            flex: 4,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildVolumeOption(20, size: 80),
                _buildVolumeOption(60, size: 80),
                _buildVolumeOption(100, size: 80),
                _buildCustomOption(size: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabletLandscape() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Information
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Set Up Your Hydroponic System",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Configure your tank size for precise nutrient dosing",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildIllustration(),
                ),
                // Help box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            "Why is tank volume important?",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Knowing your tank volume allows HydroZap to calculate precise dosing for nutrients and pH adjustments.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _showHelpDialog,
                        child: Text(
                          "Not sure how to measure? Tap here for help",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right side - Volume selection
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _useMetric ? "How many liters?" : "How many gallons?",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Select your reservoir size",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                // Volume options
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildVolumeOption(20, size: 100),
                      _buildVolumeOption(60, size: 100),
                      _buildVolumeOption(100, size: 100),
                      _buildCustomOption(size: 100),
                    ],
                  ),
                ),
                // Unit switcher
                Center(
                  child: InkWell(
                    onTap: _switchUnits,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz, color: AppColors.primary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "Switch to ${_useMetric ? 'gallons' : 'liters'}",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Buttons
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: CustomButton(
                        text: "CANCEL",
                        onPressed: _handleCancel,
                        variant: ButtonVariant.outline,
                        backgroundColor: Colors.white,
                        textColor: Colors.grey[800],
                      ),
                    ),
                    SizedBox(width: 16),
                    // Next button
                    Expanded(
                      child: CustomButton(
                        text: "NEXT",
                        onPressed: _validateAndContinue,
                        variant: ButtonVariant.primary,
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 