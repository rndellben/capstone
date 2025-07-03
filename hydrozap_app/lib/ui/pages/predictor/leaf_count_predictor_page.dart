import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/responsive_widget.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../../core/models/prediction_model.dart';
import 'prediction_card.dart';

class LeafCountPredictorPage extends StatefulWidget {
  final String userId;

  const LeafCountPredictorPage({
    super.key,
    required this.userId,
  });

  @override
  State<LeafCountPredictorPage> createState() => _LeafCountPredictorPageState();
}

class _LeafCountPredictorPageState extends State<LeafCountPredictorPage> {
  final _formKey = GlobalKey<FormState>();
  final _growthDaysController = TextEditingController(text: '21');
  final _temperatureController = TextEditingController(text: '22.0');
  final _phController = TextEditingController(text: '6.0');
  String _selectedCropType = 'Lettuce';
  
  final List<String> _cropTypes = ['Lettuce', 'Kale', 'Spinach', 'Basil', 'Arugula'];
  bool _isLoading = false;
  PredictionResult? _predictionResult;

  @override
  void dispose() {
    _growthDaysController.dispose();
    _temperatureController.dispose();
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
      final growthDays = int.parse(_growthDaysController.text);
      final temperature = double.parse(_temperatureController.text);
      final ph = double.parse(_phController.text);

      // Call the prediction service
      final result = await PredictionService.predictLeafCount(
        cropType: _selectedCropType,
        growthDays: growthDays,
        temperature: temperature,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Leaf Count Predictor',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ResponsiveWidget(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
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
                PredictionResultCard(
                  result: _predictionResult!,
                  onReset: _resetForm,
                ),
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
                    PredictionResultCard(
                      result: _predictionResult!,
                      onReset: _resetForm,
                    ),
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
          width: 800,
          child: _predictionResult == null
              ? _buildInputForm()
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInputForm(),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          PredictionResultCard(
                            result: _predictionResult!,
                            onReset: _resetForm,
                          ),
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
                    'Growth Parameters',
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
                  
                  // Growth Days input
                  _buildInputField(
                    controller: _growthDaysController,
                    label: 'Growth Days',
                    hint: '21',
                    icon: Icons.calendar_today_outlined,
                    helperText: 'Number of days since planting',
                    validator: (value) => _validateInput(value, 'Growth Days', min: 1, max: 60),
                    isInteger: true,
                  ),
                  
                  // Temperature input
                  _buildInputField(
                    controller: _temperatureController,
                    label: 'Temperature (°C)',
                    hint: '22.0',
                    icon: Icons.thermostat_outlined,
                    helperText: 'Optimal range: 18-24°C',
                    validator: (value) => _validateInput(value, 'Temperature', min: 10, max: 40),
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
                  Text('Analyzing growth parameters...'),
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.orange.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.eco_outlined, color: AppColors.sunset),
                const SizedBox(width: 8),
                const Text(
                  'Leaf Count Predictor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Predict the expected number of fully developed leaves based on growth days, temperature, and pH level. Leaf count is an important indicator of plant development.',
              style: TextStyle(fontSize: 14),
            ),
          ],
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
        text: 'Predict Leaf Count',
        onPressed: _predict,
        isLoading: _isLoading,
        backgroundColor: Colors.orange,
        icon: Icons.science_outlined,
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
                Icon(Icons.info_outline, color: AppColors.water, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'About Leaf Count',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Leaf count is affected by growth rate, environmental conditions, and nutrient availability. More leaves typically indicate healthier plants with greater photosynthetic capacity.',
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
            ),
            const SizedBox(height: 8),
            Text(
              'To optimize leaf development, maintain optimal temperature range, balanced pH, and adequate nutrients. Each plant variety has a typical leaf development pattern that can be influenced by growing conditions.',
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
            ),
          ],
        ),
      ),
    );
  }
} 