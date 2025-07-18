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
  final _apiService = ApiService();
  bool _isLoading = false;
  String? _suggestedCrop;
  String? _recommendation;
  String? _errorMessage;
  List<dynamic> _allSuggestions = []; // Add a list to store all suggestions

  @override
  void dispose() {
    _temperatureController.dispose();
    _humidityController.dispose();
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
    
    return null;
  }

  // Helper method to normalize range text by replacing Unicode dashes with standard dash
  String normalizeRangeText(String text) {
    // Replace various Unicode dash characters with standard dash
    return text.replaceAll('–', '-')
              .replaceAll('—', '-')
              .replaceAll('−', '-')
              .replaceAll('\u2013', '-') // en dash
              .replaceAll('\u2014', '-'); // em dash
  }

  Future<void> _getPrediction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _suggestedCrop = null;
      _recommendation = null;
      _errorMessage = null;
      _allSuggestions = []; // Clear previous suggestions
    });

    try {
      final result = await _apiService.predictCropSuggestion(
        temperature: double.parse(_temperatureController.text),
        humidity: double.parse(_humidityController.text),
        ph: 6.5, // Default value
        ec: 1.8, // Default value
        tds: 900, // Default value
      );

      if (result != null && result.containsKey('error')) {
        // Store and show error message from the API
        setState(() {
          _errorMessage = result['error'];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        setState(() {
          _suggestedCrop = result?['suggested_crop'];
          _recommendation = normalizeRangeText(result?['recommendation'] ?? '');
          
          // Process all suggestions and normalize range text
          final suggestions = result?['all_suggestions'] ?? [];
          _allSuggestions = suggestions.map((suggestion) {
            return {
              'crop': suggestion['crop'],
              'temp_range': normalizeRangeText(suggestion['temp_range'] ?? ''),
              'humidity_range': normalizeRangeText(suggestion['humidity_range'] ?? ''),
              'pH_range': normalizeRangeText(suggestion['pH_range'] ?? ''),
              'EC_range': normalizeRangeText(suggestion['EC_range'] ?? ''),
            };
          }).toList();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting prediction: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
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
      _errorMessage = null;
      _allSuggestions = []; // Clear all suggestions
    });
  }
  
  void _createGrowProfile() {
    if (_suggestedCrop == null || _allSuggestions.isEmpty) return;
    
    // Show a dialog to select which crop to use if there are multiple suggestions
    if (_allSuggestions.length > 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Crop for Profile'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _allSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _allSuggestions[index];
                return ListTile(
                  leading: const Icon(Icons.eco_outlined, color: AppColors.leaf),
                  title: Text(suggestion['crop']),
                  subtitle: Text('${suggestion['temp_range']} | ${suggestion['humidity_range']}'),
                  onTap: () {
                    Navigator.pop(context);
                    _createProfileWithCrop(suggestion);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } else {
      // If there's only one suggestion, use it directly
      _createProfileWithCrop(_allSuggestions[0]);
    }
  }
  
  void _createProfileWithCrop(Map<String, dynamic> cropData) {
    final String cropName = cropData['crop'];
    
    // Parse range values - make sure to use normalized values
    final tempRange = cropData['temp_range'].toString().replaceAll('°C', '').split('-');
    final humidityRange = cropData['humidity_range'].toString().replaceAll('%', '').split('-');
    final phRange = cropData['pH_range'].toString().split('-');
    final ecRange = cropData['EC_range'].toString().replaceAll(' mS/cm', '').split('-');
    
    // Calculate TDS range based on EC (TDS ≈ EC × 640)
    final tdsMin = (double.tryParse(ecRange[0]) ?? 1.0) * 640;
    final tdsMax = (double.tryParse(ecRange[1]) ?? 2.0) * 640;
    
    // Create parameters to pass to the Add Profile page
    final Map<String, dynamic> recommendationData = {
      'crop_type': cropName,
      'growth_stage': 'transplanting', // Default to transplanting stage
      'transplanting': {
        'temperature_range': {
          'min': tempRange[0],
          'max': tempRange[1],
        },
        'humidity_range': {
          'min': humidityRange[0],
          'max': humidityRange[1],
        },
        'ec_range': {
          'min': ecRange[0],
          'max': ecRange[1],
        },
        'ph_range': {
          'min': phRange[0],
          'max': phRange[1],
        },
        'tds_range': {
          'min': tdsMin.toStringAsFixed(0),
          'max': tdsMax.toStringAsFixed(0),
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
      child: _errorMessage != null
          ? Column(
              children: [
                _buildErrorCard(),
                _buildHelpText(),
              ],
            )
          : _suggestedCrop == null
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
          child: _errorMessage != null
              ? Column(
                  children: [
                    _buildErrorCard(),
                    _buildHelpText(),
                  ],
                )
              : _suggestedCrop == null
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
          child: _errorMessage != null
              ? Row(
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
                          _buildErrorCard(),
                          const SizedBox(height: 24),
                          _buildHelpText(),
                        ],
                      ),
                    ),
                  ],
                )
              : _suggestedCrop == null
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
                    helperText: 'Enter any temperature value',
                    validator: (value) => _validateInput(value, 'Temperature'),
                  ),
                  
                  // Humidity input
                  _buildInputField(
                    controller: _humidityController,
                    label: 'Humidity (%)',
                    hint: '65.0',
                    icon: Icons.water_outlined,
                    helperText: 'Enter any humidity value',
                    validator: (value) => _validateInput(value, 'Humidity'),
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
                        'Get crop recommendations based on your temperature and humidity values. The system will suggest the most suitable crops for your growing environment.',
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
                
                // Display all suggestions if available
                if (_allSuggestions.isNotEmpty && _allSuggestions.length > 1) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Other Suitable Crops',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Skip the first suggestion as it's already shown above
                  for (int i = 1; i < _allSuggestions.length; i++) ...[
                    _buildSuggestionItem(_allSuggestions[i]),
                    if (i < _allSuggestions.length - 1) const Divider(height: 24),
                  ],
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
  
  Widget _buildErrorCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.only(bottom: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'No Suitable Crops Found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'No crops match the provided environmental parameters.',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Try Different Values',
                onPressed: _resetForm,
                backgroundColor: AppColors.leaf,
                icon: Icons.refresh,
                useGradient: true,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to build individual suggestion items
  Widget _buildSuggestionItem(Map<String, dynamic> suggestion) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_outlined, color: AppColors.leaf, size: 20),
              const SizedBox(width: 8),
              Text(
                suggestion['crop'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRangeRow(Icons.thermostat_outlined, 'Temperature:', suggestion['temp_range']),
                const SizedBox(height: 4),
                _buildRangeRow(Icons.water_outlined, 'Humidity:', suggestion['humidity_range']),
                const SizedBox(height: 4),
                _buildRangeRow(Icons.science_outlined, 'pH:', suggestion['pH_range']),
                const SizedBox(height: 4),
                _buildRangeRow(Icons.bolt_outlined, 'EC:', suggestion['EC_range']),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to build range rows
  Widget _buildRangeRow(IconData icon, String label, String range) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          range,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.forest,
          ),
        ),
      ],
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
              'The crop suggestion system analyzes your temperature and humidity values to recommend the most suitable crops for your growing environment. The recommendations are based on optimal growing ranges for various crops.',
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
            ),
            const SizedBox(height: 8),
            Text(
              'For best results, ensure your measurements are accurate and your growing environment is stable. Once you select a crop, the system will also provide recommended pH and EC levels for optimal growth.',
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
            ),
          ],
        ),
      ),
    );
  }
} 