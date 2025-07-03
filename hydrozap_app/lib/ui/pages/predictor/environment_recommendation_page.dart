import 'package:flutter/material.dart';
import 'package:hydrozap_app/core/api/api_service.dart';
import 'package:hydrozap_app/core/constants/app_colors.dart';
import 'package:hydrozap_app/routes/app_routes.dart';
import 'package:hydrozap_app/ui/components/custom_button.dart';
import 'package:hydrozap_app/ui/components/custom_text_field.dart';
import 'package:hydrozap_app/ui/widgets/responsive_widget.dart';
import 'package:hydrozap_app/core/utils/logger.dart';
import 'package:hydrozap_app/ui/pages/grow_profile/add_profile/add_profile_page.dart';

class EnvironmentRecommendationPage extends StatefulWidget {
  final String userId;

  const EnvironmentRecommendationPage({
    super.key,
    required this.userId,
  });

  @override
  State<EnvironmentRecommendationPage> createState() => _EnvironmentRecommendationPageState();
}

class _EnvironmentRecommendationPageState extends State<EnvironmentRecommendationPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;
  
  // Dropdown values
  final List<String> _cropTypes = [
    'Arugula',
    'Cabbage',
    'Kale',
    'Lettuce',
    'Spinach',
    'Mustard Greens',
    'Pechay',
  ];
  
  final List<String> _growthStages = [
    'transplanting',
    'vegetative',
    'maturation'
  ];
  
  String _selectedCropType = 'Lettuce';
  String _selectedGrowthStage = 'vegetative';
  
  // Recommendation results
  double? _recommendedTemperature;
  double? _recommendedHumidity;
  double? _recommendedEc;
  double? _recommendedPh;
  String? _recommendation;

  Future<void> _getRecommendation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _recommendedTemperature = null;
      _recommendedHumidity = null;
      _recommendedEc = null;
      _recommendedPh = null;
      _recommendation = null;
    });

    try {
      final result = await _apiService.predictEnvironmentRecommendation(
        cropType: _selectedCropType,
        growthStage: _selectedGrowthStage,
      );

      if (result != null) {
        setState(() {
          _recommendedTemperature = result['temperature'];
          _recommendedHumidity = result['humidity'];
          _recommendedEc = result['ec'];
          _recommendedPh = result['ph'];
          
          // Use the recommendation from the server
          _recommendation = result['recommendation'];
        });
        
      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to get recommendation. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      logger.e('ERROR in environment recommendation page: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting recommendation: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _recommendedTemperature = null;
      _recommendedHumidity = null;
      _recommendedEc = null;
      _recommendedPh = null;
      _recommendation = null;
    });
  }
  
  void _createGrowProfile() {
    if (_recommendedTemperature == null || 
        _recommendedHumidity == null || 
        _recommendedEc == null || 
        _recommendedPh == null) {
      return;
    }
    
    // Calculate min/max range values (10% range)
    final tempRange = _recommendedTemperature! * 0.05;
    final humidityRange = _recommendedHumidity! * 0.05;
    final ecRange = _recommendedEc! * 0.1;
    final phRange = 0.3; // Standard pH range
    
    // Create parameters to pass to the Add Profile page
    final Map<String, dynamic> recommendationData = {
      'crop_type': _selectedCropType,
      'growth_stage': _selectedGrowthStage,
      // Only include recommendations for the selected growth stage
      _selectedGrowthStage: {
        'temperature_range': {
          'min': (_recommendedTemperature! - tempRange).toStringAsFixed(1),
          'max': (_recommendedTemperature! + tempRange).toStringAsFixed(1),
        },
        'humidity_range': {
          'min': (_recommendedHumidity! - humidityRange).toStringAsFixed(1),
          'max': (_recommendedHumidity! + humidityRange).toStringAsFixed(1),
        },
        'ph_range': {
          'min': (_recommendedPh! - phRange).toStringAsFixed(1),
          'max': (_recommendedPh! + phRange).toStringAsFixed(1),
        },
        'ec_range': {
          'min': (_recommendedEc! - ecRange).toStringAsFixed(2),
          'max': (_recommendedEc! + ecRange).toStringAsFixed(2),
        },
        'tds_range': {
          'min': ((_recommendedEc! - ecRange) * 500).toStringAsFixed(0),
          'max': ((_recommendedEc! + ecRange) * 500).toStringAsFixed(0),
        },
      },
      'recommendation': _recommendation,
    };
    
    print('Creating grow profile with data: $recommendationData'); // Debug log
    
    // Navigate to Add Profile page with recommendation data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProfilePage(
          userId: widget.userId,
          recommendationData: recommendationData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Environment Recommendation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.leaf, AppColors.forest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5FFF7), Color(0xFFE8F5E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
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
      padding: const EdgeInsets.all(16.0),
      child: _recommendedTemperature == null
          ? _buildInputForm()
          : Column(
              children: [
                _buildResultCard(),
                const SizedBox(height: 16),
                _buildHelpText(),
              ],
            ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: SizedBox(
          width: 600,
          child: _recommendedTemperature == null
              ? _buildInputForm()
              : Column(
                  children: [
                    _buildResultCard(),
                    const SizedBox(height: 16),
                    _buildHelpText(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: SizedBox(
          width: 1000,
          child: _recommendedTemperature == null
              ? _buildInputForm()
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildInputForm(),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          _buildResultCard(),
                          const SizedBox(height: 16),
                          _buildHelpText(),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.only(bottom: 24),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.leaf, AppColors.forest],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.90),
            borderRadius: BorderRadius.circular(18),
          ),
      child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco_outlined, color: AppColors.success, size: 36),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                  'Environment Recommendation',
                  style: TextStyle(
                          fontSize: 22,
                    fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Get recommended environmental parameters tailored to your crop type and growth stage for optimal growth outcomes.',
                        style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ),
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crop Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Crop Type Dropdown
                  _buildDropdown(
                    label: 'Crop Type',
                    value: _selectedCropType,
                    items: _cropTypes,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCropType = value;
                        });
                      }
                    },
                    icon: Icons.spa_outlined,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Growth Stage Dropdown
                  _buildDropdown(
                    label: 'Growth Stage',
                    value: _selectedGrowthStage,
                    items: _growthStages,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedGrowthStage = value;
                        });
                      }
                    },
                    icon: Icons.eco_outlined,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : CustomButton(
                          text: 'Get Recommendation',
                          icon: Icons.lightbulb_outline,
                          onPressed: _getRecommendation,
                          backgroundColor: AppColors.primary,
                          width: double.infinity,
                          variant: ButtonVariant.primary,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    hint: Text(label),
                    items: items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          label == 'Growth Stage' 
                              ? _capitalizeGrowthStage(item)
                              : item
                        ),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper to capitalize growth stage for display purposes
  String _capitalizeGrowthStage(String stage) {
    return stage[0].toUpperCase() + stage.substring(1);
  }

  Widget _buildResultCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 600;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.only(bottom: 24),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.leaf, AppColors.forest],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(18),
          ),
      child: Padding(
            padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                    Icon(Icons.check_circle_outline, color: AppColors.success, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Recommended Environment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                        color: AppColors.forest,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.spa, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_selectedCropType - ${_capitalizeGrowthStage(_selectedGrowthStage)} Stage',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildParameterGrid(),
            const SizedBox(height: 16),
            if (_recommendation != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _recommendation!,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            isNarrow
                ? Column(
                    children: [
                      CustomButton(
                        text: 'New Recommendation',
                        icon: Icons.refresh,
                        onPressed: _resetForm,
                        backgroundColor: AppColors.secondary,
                        variant: ButtonVariant.primary,
                        useGradient: true,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: 'Create Grow Profile',
                        icon: Icons.add_circle_outline,
                        onPressed: _createGrowProfile,
                        backgroundColor: AppColors.success,
                        variant: ButtonVariant.primary,
                        useGradient: true,
                        width: double.infinity,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'New Recommendation',
                          icon: Icons.refresh,
                          onPressed: _resetForm,
                          backgroundColor: AppColors.secondary,
                          variant: ButtonVariant.primary,
                          useGradient: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Create Grow Profile',
                          icon: Icons.add_circle_outline,
                          onPressed: _createGrowProfile,
                          backgroundColor: AppColors.success,
                          variant: ButtonVariant.primary,
                          useGradient: true,
                        ),
                      ),
                    ],
                  ),
          ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParameterCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Adjust the GridView setup for different screen sizes
  Widget _buildParameterGrid() {
    final isLargeScreen = ResponsiveWidget.isDesktop(context) || 
                         (ResponsiveWidget.isTablet(context) && MediaQuery.of(context).size.width > 700);
    
    return GridView.count(
      crossAxisCount: isLargeScreen ? 2 : 1,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isLargeScreen ? 3.5 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildParameterCard(
          'Temperature',
          '${_recommendedTemperature?.toStringAsFixed(1) ?? "N/A"}°C',
          Icons.thermostat_outlined,
          Colors.red.shade400,
        ),
        _buildParameterCard(
          'Humidity',
          '${_recommendedHumidity?.toStringAsFixed(1) ?? "N/A"}%',
          Icons.water_drop_outlined,
          Colors.blue.shade400,
        ),
        _buildParameterCard(
          'EC (mS/cm)',
          _recommendedEc?.toStringAsFixed(2) ?? "N/A",
          Icons.electric_bolt_outlined,
          Colors.amber.shade700,
        ),
        _buildParameterCard(
          'pH Level',
          _recommendedPh?.toStringAsFixed(1) ?? "N/A",
          Icons.science_outlined,
          Colors.purple.shade400,
        ),
      ],
    );
  }

  Widget _buildHelpText() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'About This Recommendation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'These recommendations are generated using machine learning models trained on optimal growing conditions for hydroponics. Adjust parameters slightly based on your specific setup and plant response.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Keep in mind that different growth stages may require different environmental conditions to achieve the best results.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
} 