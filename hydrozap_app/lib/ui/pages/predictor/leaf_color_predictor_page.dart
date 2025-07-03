import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/responsive_widget.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../../core/models/prediction_model.dart';
import 'prediction_card.dart';

class LeafColorPredictorPage extends StatefulWidget {
  final String userId;

  const LeafColorPredictorPage({
    super.key,
    required this.userId,
  });

  @override
  State<LeafColorPredictorPage> createState() => _LeafColorPredictorPageState();
}

class _LeafColorPredictorPageState extends State<LeafColorPredictorPage> {
  final _formKey = GlobalKey<FormState>();
  final _ecController = TextEditingController(text: '1.8');
  final _phController = TextEditingController(text: '6.0');
  final _growthDaysController = TextEditingController(text: '21');
  final _temperatureController = TextEditingController(text: '22.0');
  
  bool _isLoading = false;
  PredictionResult? _predictionResult;

  @override
  void dispose() {
    _ecController.dispose();
    _phController.dispose();
    _growthDaysController.dispose();
    _temperatureController.dispose();
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
      final ec = double.parse(_ecController.text);
      final ph = double.parse(_phController.text);
      final growthDays = int.parse(_growthDaysController.text);
      final temperature = double.parse(_temperatureController.text);

      // Call the prediction service
      final result = await PredictionService.predictLeafColor(
        ec: ec,
        ph: ph,
        growthDays: growthDays,
        temperature: temperature,
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
          'Leaf Color Predictor',
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
      color: Colors.green.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.color_lens_outlined, color: AppColors.forest),
                const SizedBox(width: 8),
                const Text(
                  'Leaf Color Predictor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Predict the leaf color index (0-10 scale) based on growth parameters. Darker green leaves typically indicate healthier plants with good nutrient uptake.',
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
        text: 'Predict Leaf Color',
        onPressed: _predict,
        isLoading: _isLoading,
        backgroundColor: Colors.green.shade700,
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
                  'About Leaf Color',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Leaf color is a strong indicator of plant health. Yellow or pale green leaves often indicate nutrient deficiencies or stress, while dark green leaves suggest optimal growing conditions.',
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
            ),
            const SizedBox(height: 8),
            Text(
              'For deeper green leaves, ensure proper nutrient balance (especially nitrogen), maintain pH in the optimal range, and provide consistent temperature and environmental conditions.',
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
            ),
          ],
        ),
      ),
    );
  }
} 