import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/responsive_widget.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../../core/models/prediction_model.dart';
import 'prediction_card.dart';

class BiomassPredictorPage extends StatefulWidget {
  final String userId;

  const BiomassPredictorPage({
    super.key,
    required this.userId,
  });

  @override
  State<BiomassPredictorPage> createState() => _BiomassPredictorPageState();
}

class _BiomassPredictorPageState extends State<BiomassPredictorPage> {
  final _formKey = GlobalKey<FormState>();
  final _plantHeightController = TextEditingController(text: '20.0');
  final _leafCountController = TextEditingController(text: '12');
  final _leafColorIndexController = TextEditingController(text: '7.0');
  
  bool _isLoading = false;
  PredictionResult? _predictionResult;
  double _leafColorValue = 7.0;

  @override
  void initState() {
    super.initState();
    _leafColorIndexController.text = _leafColorValue.toString();
  }

  @override
  void dispose() {
    _plantHeightController.dispose();
    _leafCountController.dispose();
    _leafColorIndexController.dispose();
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
      final plantHeight = double.parse(_plantHeightController.text);
      final leafCount = int.parse(_leafCountController.text);
      final leafColorIndex = double.parse(_leafColorIndexController.text);

      // Call the prediction service
      final result = await PredictionService.predictBiomass(
        plantHeight: plantHeight,
        leafCount: leafCount,
        leafColorIndex: leafColorIndex,
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
          'Biomass Predictor',
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
                    'Plant Metrics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Plant Height input
                  _buildInputField(
                    controller: _plantHeightController,
                    label: 'Plant Height (cm)',
                    hint: '20.0',
                    icon: Icons.height,
                    helperText: 'Measure from base to highest point',
                    validator: (value) => _validateInput(value, 'Plant Height', min: 1, max: 100),
                  ),
                  
                  // Leaf Count input
                  _buildInputField(
                    controller: _leafCountController,
                    label: 'Leaf Count',
                    hint: '12',
                    icon: Icons.eco_outlined,
                    helperText: 'Number of fully developed leaves',
                    validator: (value) => _validateInput(value, 'Leaf Count', min: 1, max: 30),
                    isInteger: true,
                  ),
                  
                  // Leaf Color slider
                  _buildSliderInput(
                    label: 'Leaf Color Index',
                    icon: Icons.color_lens_outlined,
                    helperText: '1 = pale yellow, 10 = deep green',
                    value: _leafColorValue,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (value) {
                      setState(() {
                        _leafColorValue = value;
                        _leafColorIndexController.text = value.toStringAsFixed(1);
                      });
                    },
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
                  Text('Analyzing plant metrics...'),
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
      color: Colors.purple.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.scale_outlined, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Biomass Predictor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Predict the estimated total plant biomass (in grams) based on plant height, leaf count, and leaf color. Biomass is a measure of total plant material and is correlated with yield.',
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

  Widget _buildSliderInput({
    required String label,
    required IconData icon,
    required String helperText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getLeafColor(value),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.normal.withAlpha((0.3 * 255).round()),
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  helperText,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    min.toInt().toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    width: 150,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.yellow.shade300, Colors.green.shade700],
                      ),
                    ),
                  ),
                  Text(
                    max.toInt().toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getLeafColor(double value) {
    // Map the value from 1-10 to a color gradient from yellow to green
    if (value <= 1) return Colors.yellow.shade300;
    if (value >= 10) return Colors.green.shade900;
    
    // Calculate intermediate colors
    final normalized = (value - 1) / 9;  // 0 to 1
    
    if (normalized < 0.5) {
      // Yellow to light green
      return Color.lerp(
        Colors.yellow.shade300, 
        Colors.green.shade400, 
        normalized * 2
      )!;
    } else {
      // Light green to dark green
      return Color.lerp(
        Colors.green.shade400, 
        Colors.green.shade900, 
        (normalized - 0.5) * 2
      )!;
    }
  }

  Widget _buildPredictButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: CustomButton(
        text: 'Predict Biomass',
        onPressed: _predict,
        isLoading: _isLoading,
        backgroundColor: Colors.purple,
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
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'About Biomass Estimation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Biomass is a measure of the total weight of plant material. It is influenced by plant height, leaf development, and overall plant health (indicated by leaf color).',
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
            ),
            const SizedBox(height: 8),
            Text(
              'Higher biomass typically correlates with higher yields. To maximize biomass, focus on optimizing growth conditions including nutrient availability, light intensity, and environmental parameters.',
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
            ),
          ],
        ),
      ),
    );
  }
} 