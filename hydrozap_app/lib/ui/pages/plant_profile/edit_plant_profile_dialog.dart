import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/plant_profile_provider.dart';
import '../../../core/models/plant_profile_model.dart';
import '../../components/custom_text_field.dart';
import '../../components/custom_button.dart';
import '../../components/mode_selector.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';

class EditPlantProfileDialog extends StatefulWidget {
  final String? userId;
  final PlantProfile profile;
  
  const EditPlantProfileDialog({
    Key? key,
    this.userId,
    required this.profile,
  }) : super(key: key);

  @override
  State<EditPlantProfileDialog> createState() => _EditPlantProfileDialogState();
}

class _EditPlantProfileDialogState extends State<EditPlantProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _growDurationController = TextEditingController();
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
    _populateFormData();
  }

  void _populateFormData() {
    // Populate basic info
    _nameController.text = widget.profile.name;
    _descriptionController.text = widget.profile.notes;
    _growDurationController.text = widget.profile.growDurationDays.toString();
    _currentMode = widget.profile.mode;

    // Populate optimal conditions based on mode
    if (_currentMode == 'simple') {
      _populateSimpleModeData();
    } else {
      _populateAdvancedModeData();
    }
  }

  void _populateSimpleModeData() {
    // Get conditions from any stage (they should be the same in simple mode)
    final conditions = widget.profile.optimalConditions.stageConditions;
    if (conditions.isEmpty) return;
    
    final stageConditions = conditions.values.first;
    
    if (stageConditions.containsKey('temperature_range')) {
      final temp = stageConditions['temperature_range']!;
      _simpleModeControllers['temp_min']!.text = temp['min'].toString();
      _simpleModeControllers['temp_max']!.text = temp['max'].toString();
    }
    
    if (stageConditions.containsKey('humidity_range')) {
      final humidity = stageConditions['humidity_range']!;
      _simpleModeControllers['humidity_min']!.text = humidity['min'].toString();
      _simpleModeControllers['humidity_max']!.text = humidity['max'].toString();
    }
    
    if (stageConditions.containsKey('ec_range')) {
      final ec = stageConditions['ec_range']!;
      _simpleModeControllers['ec_min']!.text = ec['min'].toString();
      _simpleModeControllers['ec_max']!.text = ec['max'].toString();
    }
    
    if (stageConditions.containsKey('ph_range')) {
      final ph = stageConditions['ph_range']!;
      _simpleModeControllers['ph_min']!.text = ph['min'].toString();
      _simpleModeControllers['ph_max']!.text = ph['max'].toString();
    }
  }

  void _populateAdvancedModeData() {
    final conditions = widget.profile.optimalConditions.stageConditions;
    
    for (var stage in _stageControllers.keys) {
      if (conditions.containsKey(stage)) {
        final stageConditions = conditions[stage]!;
        final controllers = _stageControllers[stage]!;
        
        if (stageConditions.containsKey('temperature_range')) {
          final temp = stageConditions['temperature_range']!;
          controllers['temp_min']!.text = temp['min'].toString();
          controllers['temp_max']!.text = temp['max'].toString();
        }
        
        if (stageConditions.containsKey('humidity_range')) {
          final humidity = stageConditions['humidity_range']!;
          controllers['humidity_min']!.text = humidity['min'].toString();
          controllers['humidity_max']!.text = humidity['max'].toString();
        }
        
        if (stageConditions.containsKey('ec_range')) {
          final ec = stageConditions['ec_range']!;
          controllers['ec_min']!.text = ec['min'].toString();
          controllers['ec_max']!.text = ec['max'].toString();
        }
        
        if (stageConditions.containsKey('ph_range')) {
          final ph = stageConditions['ph_range']!;
          controllers['ph_min']!.text = ph['min'].toString();
          controllers['ph_max']!.text = ph['max'].toString();
        }
      }
    }
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
            child: Icon(Icons.edit, color: AppColors.leaf),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentPage == 0 ? 'Edit Plant Profile' : 'Growing Conditions',
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a plant name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Description',
            hint: 'Enter plant description',
            prefixIcon: Icons.description,
            controller: _descriptionController,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Grow Duration (days)',
            hint: 'Enter grow duration',
            prefixIcon: Icons.calendar_today,
            controller: _growDurationController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter grow duration';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.settings, color: AppColors.leaf),
              const SizedBox(width: 12),
              const Text(
                'Mode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              ModeSelector(
                currentMode: _currentMode,
                onModeChanged: (mode) {
                  setState(() {
                    _currentMode = mode;
                  });
                },
              ),
            ],
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
          if (_currentMode == 'simple') ...[
            _buildSimpleModeConditions(),
          ] else ...[
            _buildAdvancedModeConditions(),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleModeConditions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Optimal Growing Conditions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'Min Temperature (°C)',
                hint: 'Min temp',
                prefixIcon: Icons.thermostat,
                controller: _simpleModeControllers['temp_min']!,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'Max Temperature (°C)',
                hint: 'Max temp',
                prefixIcon: Icons.thermostat,
                controller: _simpleModeControllers['temp_max']!,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'Min Humidity (%)',
                hint: 'Min humidity',
                prefixIcon: Icons.water_drop,
                controller: _simpleModeControllers['humidity_min']!,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'Max Humidity (%)',
                hint: 'Max humidity',
                prefixIcon: Icons.water_drop,
                controller: _simpleModeControllers['humidity_max']!,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'Min EC (mS/cm)',
                hint: 'Min EC',
                prefixIcon: Icons.bolt,
                controller: _simpleModeControllers['ec_min']!,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'Max EC (mS/cm)',
                hint: 'Max EC',
                prefixIcon: Icons.bolt,
                controller: _simpleModeControllers['ec_max']!,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'Min pH',
                hint: 'Min pH',
                prefixIcon: Icons.science,
                controller: _simpleModeControllers['ph_min']!,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'Max pH',
                hint: 'Max pH',
                prefixIcon: Icons.science,
                controller: _simpleModeControllers['ph_max']!,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedModeConditions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Growth Stage Conditions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ..._stageControllers.keys.map((stage) => _buildStageConditions(stage)).toList(),
      ],
    );
  }

  Widget _buildStageConditions(String stage) {
    final controllers = _stageControllers[stage]!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _capitalize(stage),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Min Temp (°C)',
                    hint: 'Min temp',
                    prefixIcon: Icons.thermostat,
                    controller: controllers['temp_min']!,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextField(
                    label: 'Max Temp (°C)',
                    hint: 'Max temp',
                    prefixIcon: Icons.thermostat,
                    controller: controllers['temp_max']!,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Min Humidity (%)',
                    hint: 'Min humidity',
                    prefixIcon: Icons.water_drop,
                    controller: controllers['humidity_min']!,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextField(
                    label: 'Max Humidity (%)',
                    hint: 'Max humidity',
                    prefixIcon: Icons.water_drop,
                    controller: controllers['humidity_max']!,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Min EC (mS/cm)',
                    hint: 'Min EC',
                    prefixIcon: Icons.bolt,
                    controller: controllers['ec_min']!,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextField(
                    label: 'Max EC (mS/cm)',
                    hint: 'Max EC',
                    prefixIcon: Icons.bolt,
                    controller: controllers['ec_max']!,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Min pH',
                    hint: 'Min pH',
                    prefixIcon: Icons.science,
                    controller: controllers['ph_min']!,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextField(
                    label: 'Max pH',
                    hint: 'Max pH',
                    prefixIcon: Icons.science,
                    controller: controllers['ph_max']!,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousPage,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            child: _currentPage == 0
                ? ElevatedButton.icon(
                    onPressed: _nextPage,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.leaf,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
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
                    label: const Text('Update Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.leaf,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

        // Prepare update data
        final updateData = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'optimal_conditions': optimalConditions,
          'mode': _currentMode,
          'grow_duration_days': int.tryParse(_growDurationController.text) ?? widget.profile.growDurationDays,
        };
        
        // Get the provider and update the profile
        final provider = Provider.of<PlantProfileProvider>(context, listen: false);
        final result = await provider.updatePlantProfile(
          widget.profile.identifier, 
          updateData, 
          userId: userId
        );
            
        if (!mounted) return;
        
        if (result) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plant profile updated successfully!'),
              backgroundColor: AppColors.forest,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        } else {
          // Show error message from provider if available
          final errorMessage = provider.error ?? 'Failed to update plant profile';
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

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
} 