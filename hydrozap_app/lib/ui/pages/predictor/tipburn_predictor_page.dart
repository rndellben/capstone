import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/responsive_widget.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../../core/models/prediction_model.dart';


class TipburnPredictorPage extends StatefulWidget {
  final String userId;

  const TipburnPredictorPage({
    super.key,
    required this.userId,
  });

  @override
  State<TipburnPredictorPage> createState() => _TipburnPredictorPageState();
}

class _TipburnPredictorPageState extends State<TipburnPredictorPage> {
  final _formKey = GlobalKey<FormState>();
  final _temperatureController = TextEditingController(text: '22.0');
  final _humidityController = TextEditingController(text: '65.0');
  final _ecController = TextEditingController(text: '1.8');
  final _phController = TextEditingController(text: '6.0');
  String _selectedCropType = 'Lettuce';
  
  final List<String> _cropTypes = ['Arugula', 'Cabbage', 'Kale', 'Lettuce', 'Mustard Greens', 'Pechay', 'Spinach'];
  bool _isLoading = false;
  PredictionResult? _predictionResult;

  @override
  void dispose() {
    _temperatureController.dispose();
    _humidityController.dispose();
    _ecController.dispose();
    _phController.dispose();
    super.dispose();
  }

  // Input validation
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

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final temperature = double.parse(_temperatureController.text);
      final humidity = double.parse(_humidityController.text);
      final ec = double.parse(_ecController.text);
      final ph = double.parse(_phController.text);

      // Call the prediction service
      final result = await PredictionService.predictTipburn(
        cropType: _selectedCropType,
        temperature: temperature,
        humidity: humidity,
        ec: ec,
        ph: ph,
      );

      setState(() {
        _predictionResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _predictionResult = null;
    });
  }
  
  void _createGrowProfile() {
    if (_predictionResult == null) return;
    
    // Get values from the current input
    final temperature = double.parse(_temperatureController.text);
    final humidity = double.parse(_humidityController.text);
    final ec = double.parse(_ecController.text);
    final ph = double.parse(_phController.text);
    
    // Calculate min/max range values
    final tempRange = temperature * 0.05;
    final humidityRange = humidity * 0.05;
    final ecRange = ec * 0.1;
    final phRange = 0.3; // Standard pH range
    
    // Create parameters to pass to the Add Profile page
    final Map<String, dynamic> recommendationData = {
      'crop_type': _selectedCropType,
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
          'min': ((ec - ecRange) * 500).toStringAsFixed(0), // TDS = EC × 500
          'max': ((ec + ecRange) * 500).toStringAsFixed(0),
        },
      },
      'recommendation': _predictionResult?.message ?? 
        'Profile created from Tipburn Prediction. Adjust parameters to minimize tipburn risk.',
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
          'Tipburn Predictor',
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
      child: _predictionResult == null
          ? _buildInputForm()
          : Column(
              children: [
                _buildCustomResultCard(),
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
          child: _predictionResult == null
              ? _buildInputForm()
              : Column(
                  children: [
                    _buildCustomResultCard(),
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
          child: _predictionResult == null
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
                          _buildCustomResultCard(),
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
  
  Widget _buildCustomResultCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 600;
    final hasTipburn = _predictionResult!.value as bool;
    final message = _predictionResult!.message;
    final color = hasTipburn ? _predictionResult!.getTypeColor() : Colors.green;
    final icon = _predictionResult!.getTypeIcon();
    final status = hasTipburn ? 'High Risk' : 'Low Risk';
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.only(bottom: 24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.leaf, AppColors.forest],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
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
                    Icon(icon, color: color, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Tipburn Prediction',
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
                  status,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                isNarrow
                    ? Column(
                        children: [
                          CustomButton(
                            text: 'Try Another Prediction',
                            onPressed: _resetForm,
                            variant: ButtonVariant.outline,
                            backgroundColor: color,
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
                              backgroundColor: color,
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
                  
                  // Crop Type dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Crop Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.grass_outlined),
                    ),
                    value: _selectedCropType,
                    items: _cropTypes.map((String cropType) {
                      return DropdownMenuItem<String>(
                        value: cropType,
                        child: Text(cropType[0].toUpperCase() + cropType.substring(1)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCropType = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Temperature input
                  _buildInputField(
                    controller: _temperatureController,
                    label: 'Temperature (°C)',
                    hint: '22.0',
                    icon: Icons.thermostat_outlined,
                    helperText: 'Optimal range: 18-24°C',
                    validator: (value) => _validateInput(value, 'Temperature', min: 10, max: 40),
                  ),
                  
                  // Humidity input
                  _buildInputField(
                    controller: _humidityController,
                    label: 'Humidity (%)',
                    hint: '65.0',
                    icon: Icons.water_outlined,
                    helperText: 'Optimal range: 50-70%',
                    validator: (value) => _validateInput(value, 'Humidity', min: 30, max: 90),
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
                  
                  // pH input
                  _buildInputField(
                    controller: _phController,
                    label: 'pH Level',
                    hint: '6.0',
                    icon: Icons.science_outlined,
                    helperText: 'Optimal range: 5.5-6.5',
                    validator: (value) => _validateInput(value, 'pH Level', min: 4, max: 8),
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
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.sunset, size: 36),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Tipburn Predictor',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Predict the likelihood of tipburn occurrence based on environmental conditions. Tipburn is a physiological disorder that affects leaf margins.',
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
    bool isInteger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextField(
        label: label,
        controller: controller,
        hint: hint,
        prefixIcon: icon,
        helperText: helperText,
        keyboardType: isInteger
            ? TextInputType.number
            : const TextInputType.numberWithOptions(decimal: true),
        validator: validator,
      ),
    );
  }

  Widget _buildPredictButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: CustomButton(
        text: 'Predict Tipburn Risk',
        onPressed: _predict,
        isLoading: _isLoading,
        backgroundColor: Colors.red,
        icon: Icons.science_outlined,
        useGradient: true,
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
                  'About Tipburn',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tipburn is a physiological disorder that appears as browning or necrosis at the leaf margins. It is often caused by calcium deficiency, high EC levels, or environmental stress.',
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
            ),
            const SizedBox(height: 8),
            Text(
              'To reduce tipburn risk, maintain proper calcium levels, avoid high EC, and ensure adequate humidity. Proper air circulation is also important.',
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
            ),
          ],
        ),
      ),
    );
  }
}