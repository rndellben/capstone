import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../../providers/plant_profile_provider.dart';
import '../../../core/models/plant_profile_model.dart';
import '../../components/custom_text_field.dart';
import '../../components/custom_button.dart';
import '../../components/mode_selector.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';

class AddPlantProfileDialog extends StatefulWidget {
  final String? userId;
  final String mode;
  
  const AddPlantProfileDialog({
    Key? key,
    this.userId,
    required this.mode,
  }) : super(key: key);

  @override
  State<AddPlantProfileDialog> createState() => _AddPlantProfileDialogState();
}

class _AddPlantProfileDialogState extends State<AddPlantProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _growDurationController = TextEditingController(text: '30');
  String _currentMode = 'simple';
  bool _isSubmitting = false;
  final _pageController = PageController();
  int _currentPage = 0;

  // Controllers for simple mode
  final Map<String, TextEditingController> _simpleModeControllers = {
    'temp_min': TextEditingController(),
    'temp_max': TextEditingController(),
    'humidity_min': TextEditingController(),
    'humidity_max': TextEditingController(),
    'ec_min': TextEditingController(),
    'ec_max': TextEditingController(),
    'ph_min': TextEditingController(),
    'ph_max': TextEditingController(),
  };

  // Controllers for each growth stage (advanced mode)
  final Map<String, Map<String, TextEditingController>> _stageControllers = {
    'transplanting': {
      'temp_min': TextEditingController(),
      'temp_max': TextEditingController(),
      'humidity_min': TextEditingController(),
      'humidity_max': TextEditingController(),
      'ec_min': TextEditingController(),
      'ec_max': TextEditingController(),
      'ph_min': TextEditingController(),
      'ph_max': TextEditingController(),
    },
    'vegetative': {
      'temp_min': TextEditingController(),
      'temp_max': TextEditingController(),
      'humidity_min': TextEditingController(),
      'humidity_max': TextEditingController(),
      'ec_min': TextEditingController(),
      'ec_max': TextEditingController(),
      'ph_min': TextEditingController(),
      'ph_max': TextEditingController(),
    },
    'maturation': {
      'temp_min': TextEditingController(),
      'temp_max': TextEditingController(),
      'humidity_min': TextEditingController(),
      'humidity_max': TextEditingController(),
      'ec_min': TextEditingController(),
      'ec_max': TextEditingController(),
      'ph_min': TextEditingController(),
      'ph_max': TextEditingController(),
    },
  };

  @override
  void initState() {
    super.initState();
    _currentMode = widget.mode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _growDurationController.dispose();
    _pageController.dispose();
    // Dispose simple mode controllers
    for (var controller in _simpleModeControllers.values) {
      controller.dispose();
    }
    // Dispose all stage controllers
    for (var stage in _stageControllers.values) {
      for (var controller in stage.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width > 600 
            ? 500 
            : MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildBasicInfoPage(),
                    _buildConditionsPage(),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.eco, color: AppColors.leaf),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentPage == 0 ? 'Add Plant Profile' : 'Growing Conditions',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _currentPage == 0 
                      ? 'Step 1: Basic Information' 
                      : 'Step 2: Growth Stage Conditions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: 'Plant Name',
            hint: 'Enter plant name',
            prefixIcon: Icons.local_florist,
            controller: _nameController,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Description',
            hint: 'Enter plant description',
            prefixIcon: Icons.description_outlined,
            controller: _descriptionController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Grow Duration (days)',
            hint: 'Enter recommended grow duration',
            prefixIcon: Icons.calendar_today,
            controller: _growDurationController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Duration is required';
              if (int.tryParse(value!) == null) return 'Please enter a valid number';
              return null;
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Add a detailed description of your plant including variety, expected size, flowering period, or any other helpful information.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                const Text(
                  'Mode:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Simple'),
                  selected: _currentMode == 'simple',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _currentMode = 'simple');
                    }
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: AppColors.leaf.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _currentMode == 'simple' ? AppColors.leaf : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Advanced'),
                  selected: _currentMode == 'advanced',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _currentMode = 'advanced');
                    }
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: AppColors.leaf.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _currentMode == 'advanced' ? AppColors.leaf : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_currentMode == 'simple')
            _buildSimpleModeConditions()
          else
            _buildAdvancedModeConditions(),
        ],
      ),
    );
  }

  Widget _buildSimpleModeConditions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Environmental Parameters',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildRangeField(
          label: 'Temperature (°C)',
          minController: _simpleModeControllers['temp_min']!,
          maxController: _simpleModeControllers['temp_max']!,
          icon: Icons.thermostat_outlined,
          color: AppColors.sunset,
        ),
        _buildRangeField(
          label: 'Humidity (%)',
          minController: _simpleModeControllers['humidity_min']!,
          maxController: _simpleModeControllers['humidity_max']!,
          icon: Icons.water_drop_outlined,
          color: AppColors.water,
        ),
        _buildRangeField(
          label: 'EC (mS/cm)',
          minController: _simpleModeControllers['ec_min']!,
          maxController: _simpleModeControllers['ec_max']!,
          icon: Icons.bolt_outlined,
          color: AppColors.forest,
        ),
        _buildRangeField(
          label: 'pH Level',
          minController: _simpleModeControllers['ph_min']!,
          maxController: _simpleModeControllers['ph_max']!,
          icon: Icons.science_outlined,
          color: AppColors.moss,
        ),
      ],
    );
  }

  Widget _buildAdvancedModeConditions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...['transplanting', 'vegetative', 'maturation'].map((stage) => 
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _capitalize(stage),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildStageConditions(stage),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStageConditions(String stage) {
    final controllers = _stageControllers[stage]!;
    return Column(
      children: [
        _buildRangeField(
          label: 'Temperature (°C)',
          minController: controllers['temp_min']!,
          maxController: controllers['temp_max']!,
          icon: Icons.thermostat_outlined,
          color: AppColors.sunset,
        ),
        _buildRangeField(
          label: 'Humidity (%)',
          minController: controllers['humidity_min']!,
          maxController: controllers['humidity_max']!,
          icon: Icons.water_drop_outlined,
          color: AppColors.water,
        ),
        _buildRangeField(
          label: 'EC (mS/cm)',
          minController: controllers['ec_min']!,
          maxController: controllers['ec_max']!,
          icon: Icons.bolt_outlined,
          color: AppColors.forest,
        ),
        _buildRangeField(
          label: 'pH Level',
          minController: controllers['ph_min']!,
          maxController: controllers['ph_max']!,
          icon: Icons.science_outlined,
          color: AppColors.moss,
        ),
      ],
    );
  }

  Widget _buildRangeField({
    required String label,
    required TextEditingController minController,
    required TextEditingController maxController,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: minController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Min',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: color.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: color),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: maxController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Max',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: color.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: color),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton.icon(
              onPressed: _isSubmitting ? null : _previousPage,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
            )
          else
            const SizedBox.shrink(),
          if (_currentPage < 1)
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _nextPage,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.leaf,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitForm,
              icon: _isSubmitting 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check),
              label: const Text('Save Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.leaf,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (_nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide a plant name before continuing'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_growDurationController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide a grow duration before continuing'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    _pageController.animateToPage(
      _currentPage + 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.animateToPage(
      _currentPage - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Get the current user ID from auth provider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = await authProvider.getCurrentUserId();

        // Create the optimal conditions map
        final optimalConditions = <String, Map<String, Map<String, double>>>{};
        
        if (_currentMode == 'simple') {
          // Apply simple mode conditions to all stages
          for (var stage in ['transplanting', 'vegetative', 'maturation']) {
            optimalConditions[stage] = {
              'temperature_range': {
                'min': double.tryParse(_simpleModeControllers['temp_min']!.text) ?? 0.0,
                'max': double.tryParse(_simpleModeControllers['temp_max']!.text) ?? 0.0,
              },
              'humidity_range': {
                'min': double.tryParse(_simpleModeControllers['humidity_min']!.text) ?? 0.0,
                'max': double.tryParse(_simpleModeControllers['humidity_max']!.text) ?? 0.0,
              },
              'ec_range': {
                'min': double.tryParse(_simpleModeControllers['ec_min']!.text) ?? 0.0,
                'max': double.tryParse(_simpleModeControllers['ec_max']!.text) ?? 0.0,
              },
              'ph_range': {
                'min': double.tryParse(_simpleModeControllers['ph_min']!.text) ?? 0.0,
                'max': double.tryParse(_simpleModeControllers['ph_max']!.text) ?? 0.0,
              },
              'tds_range': {
                'min': (double.tryParse(_simpleModeControllers['ec_min']!.text) ?? 0.0) * 640,
                'max': (double.tryParse(_simpleModeControllers['ec_max']!.text) ?? 0.0) * 640,
              },
            };
          }
        } else {
          // Use advanced mode stage-specific conditions
          for (var stage in _stageControllers.keys) {
            final controllers = _stageControllers[stage]!;
            optimalConditions[stage] = {
              'temperature_range': {
                'min': double.tryParse(controllers['temp_min']!.text) ?? 0.0,
                'max': double.tryParse(controllers['temp_max']!.text) ?? 0.0,
              },
              'humidity_range': {
                'min': double.tryParse(controllers['humidity_min']!.text) ?? 0.0,
                'max': double.tryParse(controllers['humidity_max']!.text) ?? 0.0,
              },
              'ec_range': {
                'min': double.tryParse(controllers['ec_min']!.text) ?? 0.0,
                'max': double.tryParse(controllers['ec_max']!.text) ?? 0.0,
              },
              'ph_range': {
                'min': double.tryParse(controllers['ph_min']!.text) ?? 0.0,
                'max': double.tryParse(controllers['ph_max']!.text) ?? 0.0,
              },
              'tds_range': {
                'min': (double.tryParse(controllers['ec_min']!.text) ?? 0.0) * 640,
                'max': (double.tryParse(controllers['ec_max']!.text) ?? 0.0) * 640,
              },
            };
          }
        }

        // Create the plant profile object
        final newProfile = PlantProfile(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          identifier: _generateRandomIdentifier(),
          notes: _descriptionController.text,
          optimalConditions: OptimalConditions(stageConditions: optimalConditions),
          growDurationDays: int.parse(_growDurationController.text),
          userId: userId,
          mode: _currentMode,
        );
        
        // Get the provider and add the profile
        final provider = Provider.of<PlantProfileProvider>(context, listen: false);
        final result = await provider.addPlantProfile(newProfile);
            
        if (!mounted) return;
        
        if (result) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plant profile added successfully!'),
              backgroundColor: AppColors.forest,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        } else {
          // Show error message from provider if available
          final errorMessage = provider.error ?? 'Failed to add plant profile';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          setState(() {
            _isSubmitting = false;
          });
        }
      } catch (e) {
        if (!mounted) return;
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _generateRandomIdentifier() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
} 