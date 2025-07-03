import 'package:flutter/material.dart';
import 'package:hydrozap_app/core/api/api_service.dart';
import 'package:hydrozap_app/core/constants/app_colors.dart';
import 'package:hydrozap_app/routes/app_routes.dart';
import 'package:hydrozap_app/ui/components/custom_button.dart';
import 'package:hydrozap_app/ui/components/custom_text_field.dart';
import 'package:hydrozap_app/ui/widgets/responsive_widget.dart';

class CropSuggestionPredictorPage extends StatefulWidget {
  final String userId;

  const CropSuggestionPredictorPage({
    super.key,
    required this.userId,
  });

  @override
  State<CropSuggestionPredictorPage> createState() => _CropSuggestionPredictorPageState();
}

class _CropSuggestionPredictorPageState extends State<CropSuggestionPredictorPage> {
  final _formKey = GlobalKey<FormState>();
  final _temperatureController = TextEditingController(text: '22.0');
  final _humidityController = TextEditingController(text: '65.0');
  final _phController = TextEditingController(text: '6.5');
  final _ecController = TextEditingController(text: '1.8');
  final _tdsController = TextEditingController(text: '900');
  final _apiService = ApiService();
  bool _isLoading = false;
  String? _suggestedCrop;
  String? _recommendation;

  @override
  void dispose() {
    _temperatureController.dispose();
    _humidityController.dispose();
    _phController.dispose();
    _ecController.dispose();
    _tdsController.dispose();
    super.dispose();
  }

  String? _validateInput(String? value, String fieldName, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Please enter a valid number';
    }
    
    if (min != null && numValue < min) {
      return '$fieldName should be at least $min';
    }
    
    if (max != null && numValue > max) {
      return '$fieldName should not exceed $max';
    }
    
    return null;
  }

  Future<void> _getPrediction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _suggestedCrop = null;
      _recommendation = null;
    });

    try {
      final result = await _apiService.predictCropSuggestion(
        temperature: double.parse(_temperatureController.text),
        humidity: double.parse(_humidityController.text),
        ph: double.parse(_phController.text),
        ec: double.parse(_ecController.text),
        tds: double.parse(_tdsController.text),
      );

      setState(() {
        _suggestedCrop = result?['suggested_crop'];
        _recommendation = result?['recommendation'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting prediction: $e'),
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
      _suggestedCrop = null;
      _recommendation = null;
    });
  }
  
  void _createGrowProfile() {
    if (_suggestedCrop == null) return;
    
    // Get values from the current input
    final temperature = double.parse(_temperatureController.text);
    final humidity = double.parse(_humidityController.text);
    final ph = double.parse(_phController.text);
    final ec = double.parse(_ecController.text);
    final tds = double.parse(_tdsController.text);
    
    // Calculate min/max range values (10% range)
    final tempRange = temperature * 0.05;
    final humidityRange = humidity * 0.05;
    final ecRange = ec * 0.1;
    final phRange = 0.3; // Standard pH range
    final tdsRange = tds * 0.1; // 10% range for TDS
    
    // Create parameters to pass to the Add Profile page
    final Map<String, dynamic> recommendationData = {
      'crop_type': _suggestedCrop!,
      'growth_stage': 'transplanting', // Default to transplanting stage
      'transplanting': {
        'temperature_range': {
          'min': (temperature - tempRange).toStringAsFixed(1),
          'max': (temperature + tempRange).toStringAsFixed(1),
        },
        'humidity_range': {
          'min': (humidity - humidityRange).toStringAsFixed(1),
          'max': (humidity + humidityRange).toStringAsFixed(1),
        },
        'ec_range': {
          'min': (ec - ecRange).toStringAsFixed(2),
          'max': (ec + ecRange).toStringAsFixed(2),
        },
        'ph_range': {
          'min': (ph - phRange).toStringAsFixed(1),
          'max': (ph + phRange).toStringAsFixed(1),
        },
        'tds_range': {
          'min': (tds - tdsRange).toStringAsFixed(0),
          'max': (tds + tdsRange).toStringAsFixed(0),
        },
      },
      'recommendation': _recommendation,
      'force_simple_mode': true,
    };
    
    // Navigate to Add Profile page with recommendation data
    Navigator.pushNamed(
      context, 
      AppRoutes.addProfile,
      arguments: {
        'userId': widget.userId,
        'recommendation_data': recommendationData,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crop Suggestion Predictor',
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
      child: _suggestedCrop == null
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
          child: _suggestedCrop == null
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
          child: _suggestedCrop == null
              ? _buildInputForm()
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildInputForm(),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          _buildResultCard(),
                          const SizedBox(height: 24),
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
                    'Environmental Parameters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Temperature input
                  _buildInputField(
                    controller: _temperatureController,
                    label: 'Temperature (°C)',
                    hint: '22.0',
                    icon: Icons.thermostat_outlined,
                    helperText: 'Optimal range: 18-28°C',
                    validator: (value) => _validateInput(value, 'Temperature', min: 10, max: 40),
                  ),
                  
                  // Humidity input
                  _buildInputField(
                    controller: _humidityController,
                    label: 'Humidity (%)',
                    hint: '65.0',
                    icon: Icons.water_outlined,
                    helperText: 'Optimal range: 50-80%',
                    validator: (value) => _validateInput(value, 'Humidity', min: 30, max: 90),
                  ),
                  
                  // pH input
                  _buildInputField(
                    controller: _phController,
                    label: 'pH Level',
                    hint: '6.5',
                    icon: Icons.science_outlined,
                    helperText: 'Optimal range: 5.5-7.0',
                    validator: (value) => _validateInput(value, 'pH Level', min: 4, max: 9),
                  ),
                  
                  // EC input
                  _buildInputField(
                    controller: _ecController,
                    label: 'EC Level (mS/cm)',
                    hint: '1.8',
                    icon: Icons.bolt_outlined,
                    helperText: 'Electrical conductivity',
                    validator: (value) => _validateInput(value, 'EC Level', min: 0.5, max: 3),
                  ),
                  
                  // TDS input
                  _buildInputField(
                    controller: _tdsController,
                    label: 'TDS (ppm)',
                    hint: '900',
                    icon: Icons.water_drop_outlined,
                    helperText: 'Total dissolved solids',
                    validator: (value) => _validateInput(value, 'TDS', min: 100, max: 2000),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildPredictButton(),
          if (_isLoading) ...[
            const SizedBox(height: 24),
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing environmental parameters...'),
                ],
              ),
            ),
          ],
        ],
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
                  child: const Icon(Icons.agriculture_outlined, color: AppColors.forest, size: 36),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Crop Suggestion Predictor',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Get crop recommendations based on your environmental conditions. The system will suggest the most suitable crops for your growing environment.',
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String helperText,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextField(
        label: label,
        controller: controller,
        hint: hint,
        prefixIcon: icon,
        helperText: helperText,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: validator,
      ),
    );
  }

  Widget _buildPredictButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: CustomButton(
        text: 'Get Crop Suggestion',
        onPressed: _getPrediction,
        isLoading: _isLoading,
        backgroundColor: AppColors.leaf,
        icon: Icons.agriculture_outlined,
        useGradient: true,
      ),
    );
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
                    Icon(Icons.agriculture_outlined, color: AppColors.forest, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Suggested Crop',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _suggestedCrop!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 16),
                if (_recommendation != null) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    _recommendation!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: AppColors.forest,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                isNarrow
                    ? Column(
                        children: [
                          CustomButton(
                            text: 'Try Another Prediction',
                            onPressed: _resetForm,
                            variant: ButtonVariant.outline,
                            backgroundColor: AppColors.moss,
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
                              text: 'Try Another Prediction',
                              onPressed: _resetForm,
                              variant: ButtonVariant.outline,
                              backgroundColor: AppColors.moss,
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

  Widget _buildHelpText() {
    return Card(
      elevation: 1,
      color: Colors.blue.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'About Crop Suggestions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The crop suggestion system analyzes your environmental parameters to recommend the most suitable crops for your growing conditions. The recommendations are based on optimal growing ranges for various crops.',
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
            ),
            const SizedBox(height: 8),
            Text(
              'For best results, ensure your measurements are accurate and your growing environment is stable. Different crops have different requirements for temperature, humidity, pH, and nutrient levels.',
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
            ),
          ],
        ),
      ),
    );
  }
} 