import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';

class UnitsMeasurementsPage extends StatefulWidget {
  const UnitsMeasurementsPage({super.key});

  @override
  _UnitsMeasurementsPageState createState() => _UnitsMeasurementsPageState();
}

class _UnitsMeasurementsPageState extends State<UnitsMeasurementsPage> {
  bool _isLoading = true;
  
  // Temperature units
  String _temperatureUnit = 'celsius';
  
  // Volume units
  String _volumeUnit = 'liters';
  
  // Weight units
  String _weightUnit = 'grams';
  
  // Length units
  String _lengthUnit = 'cm';
  
  // pH scale
  double _minPh = 0.0;
  double _maxPh = 14.0;
  double _optimalMinPh = 5.5;
  double _optimalMaxPh = 6.5;
  
  // TDS/EC/PPM measurement preference
  String _nutrientMeasurementType = 'ppm';
  
  // Data refresh rate (in seconds)
  int _dataRefreshRate = 60;
  
  // Date and time format
  String _dateFormat = 'MM/dd/yyyy';
  String _timeFormat = '12hour';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        // Load temperature unit
        _temperatureUnit = prefs.getString('temperature_unit') ?? 'celsius';
        
        // Load volume unit
        _volumeUnit = prefs.getString('volume_unit') ?? 'liters';
        
        // Load weight unit
        _weightUnit = prefs.getString('weight_unit') ?? 'grams';
        
        // Load length unit
        _lengthUnit = prefs.getString('length_unit') ?? 'cm';
        
        // Load pH preferences
        _minPh = prefs.getDouble('min_ph') ?? 0.0;
        _maxPh = prefs.getDouble('max_ph') ?? 14.0;
        _optimalMinPh = prefs.getDouble('optimal_min_ph') ?? 5.5;
        _optimalMaxPh = prefs.getDouble('optimal_max_ph') ?? 6.5;
        
        // Load nutrient measurement preference
        _nutrientMeasurementType = prefs.getString('nutrient_measurement_type') ?? 'ppm';
        
        // Load data refresh rate
        _dataRefreshRate = prefs.getInt('data_refresh_rate') ?? 60;
        
        // Load date and time format
        _dateFormat = prefs.getString('date_format') ?? 'MM/dd/yyyy';
        _timeFormat = prefs.getString('time_format') ?? '12hour';
        
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading units settings: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save temperature unit
      await prefs.setString('temperature_unit', _temperatureUnit);
      
      // Save volume unit
      await prefs.setString('volume_unit', _volumeUnit);
      
      // Save weight unit
      await prefs.setString('weight_unit', _weightUnit);
      
      // Save length unit
      await prefs.setString('length_unit', _lengthUnit);
      
      // Save pH preferences
      await prefs.setDouble('min_ph', _minPh);
      await prefs.setDouble('max_ph', _maxPh);
      await prefs.setDouble('optimal_min_ph', _optimalMinPh);
      await prefs.setDouble('optimal_max_ph', _optimalMaxPh);
      
      // Save nutrient measurement preference
      await prefs.setString('nutrient_measurement_type', _nutrientMeasurementType);
      
      // Save data refresh rate
      await prefs.setInt('data_refresh_rate', _dataRefreshRate);
      
      // Save date and time format
      await prefs.setString('date_format', _dateFormat);
      await prefs.setString('time_format', _timeFormat);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Units & measurements settings saved'),
            backgroundColor: AppColors.moss,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving units settings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Units & Measurements',
          style: TextStyle(
            color: AppColors.textOnDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.forest,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnDark),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.textOnDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.moss))
          : Container(
              color: Colors.grey[100],
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Basic Units'),
                        _buildBasicUnitsSection(),
                        const SizedBox(height: 24),
                        
                        _buildSectionHeader('Hydroponics Measurements'),
                        _buildHydroponicsSection(),
                        const SizedBox(height: 24),
                        
                        _buildSectionHeader('Display Settings'),
                        _buildDisplaySettingsSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 60,
            decoration: BoxDecoration(
              color: AppColors.forest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicUnitsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTemperatureUnitSelector(),
            const Divider(),
            _buildVolumeUnitSelector(),
            const Divider(),
            _buildWeightUnitSelector(),
            const Divider(),
            _buildLengthUnitSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureUnitSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Temperature',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose your preferred temperature unit',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Celsius (°C)'),
                value: 'celsius',
                groupValue: _temperatureUnit,
                onChanged: (String? value) {
                  setState(() {
                    _temperatureUnit = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Fahrenheit (°F)'),
                value: 'fahrenheit',
                groupValue: _temperatureUnit,
                onChanged: (String? value) {
                  setState(() {
                    _temperatureUnit = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVolumeUnitSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Volume',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose your preferred volume unit',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Liters (L)'),
                value: 'liters',
                groupValue: _volumeUnit,
                onChanged: (String? value) {
                  setState(() {
                    _volumeUnit = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Gallons (gal)'),
                value: 'gallons',
                groupValue: _volumeUnit,
                onChanged: (String? value) {
                  setState(() {
                    _volumeUnit = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Milliliters (mL)'),
                value: 'milliliters',
                groupValue: _volumeUnit,
                onChanged: (String? value) {
                  setState(() {
                    _volumeUnit = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Fluid Ounces (fl oz)'),
                value: 'fluid_ounces',
                groupValue: _volumeUnit,
                onChanged: (String? value) {
                  setState(() {
                    _volumeUnit = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightUnitSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weight',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose your preferred weight unit',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Grams (g)'),
                value: 'grams',
                groupValue: _weightUnit,
                onChanged: (String? value) {
                  setState(() {
                    _weightUnit = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Ounces (oz)'),
                value: 'ounces',
                groupValue: _weightUnit,
                onChanged: (String? value) {
                  setState(() {
                    _weightUnit = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Kilograms (kg)'),
                value: 'kilograms',
                groupValue: _weightUnit,
                onChanged: (String? value) {
                  setState(() {
                    _weightUnit = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Pounds (lb)'),
                value: 'pounds',
                groupValue: _weightUnit,
                onChanged: (String? value) {
                  setState(() {
                    _weightUnit = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLengthUnitSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Length',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose your preferred length unit',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Centimeters (cm)'),
                value: 'cm',
                groupValue: _lengthUnit,
                onChanged: (String? value) {
                  setState(() {
                    _lengthUnit = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Inches (in)'),
                value: 'inches',
                groupValue: _lengthUnit,
                onChanged: (String? value) {
                  setState(() {
                    _lengthUnit = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Meters (m)'),
                value: 'meters',
                groupValue: _lengthUnit,
                onChanged: (String? value) {
                  setState(() {
                    _lengthUnit = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Feet (ft)'),
                value: 'feet',
                groupValue: _lengthUnit,
                onChanged: (String? value) {
                  setState(() {
                    _lengthUnit = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHydroponicsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPHRangeSettings(),
            const Divider(),
            _buildNutrientMeasurementSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildPHRangeSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'pH Range Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Set your optimal pH range for alerts',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Minimum pH',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _optimalMinPh,
                          min: _minPh,
                          max: _optimalMaxPh,
                          divisions: ((_optimalMaxPh - _minPh) * 10).round(),
                          label: _optimalMinPh.toStringAsFixed(1),
                          activeColor: AppColors.moss,
                          inactiveColor: AppColors.sand.withOpacity(0.3),
                          onChanged: (double value) {
                            setState(() {
                              _optimalMinPh = double.parse(value.toStringAsFixed(1));
                            });
                          },
                        ),
                      ),
                      Container(
                        width: 45,
                        alignment: Alignment.center,
                        child: Text(
                          _optimalMinPh.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Maximum pH',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _optimalMaxPh,
                          min: _optimalMinPh,
                          max: _maxPh,
                          divisions: ((_maxPh - _optimalMinPh) * 10).round(),
                          label: _optimalMaxPh.toStringAsFixed(1),
                          activeColor: AppColors.moss,
                          inactiveColor: AppColors.sand.withOpacity(0.3),
                          onChanged: (double value) {
                            setState(() {
                              _optimalMaxPh = double.parse(value.toStringAsFixed(1));
                            });
                          },
                        ),
                      ),
                      Container(
                        width: 45,
                        alignment: Alignment.center,
                        child: Text(
                          _optimalMaxPh.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.moss.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.moss.withOpacity(0.3), width: 1),
          ),
          child: Text(
            'You will receive alerts when pH levels fall outside ${_optimalMinPh.toStringAsFixed(1)} - ${_optimalMaxPh.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.forest,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientMeasurementSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nutrient Measurement',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose your preferred nutrient concentration measurement',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('PPM (TDS)'),
                subtitle: const Text('Parts Per Million'),
                value: 'ppm',
                groupValue: _nutrientMeasurementType,
                onChanged: (String? value) {
                  setState(() {
                    _nutrientMeasurementType = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('EC'),
                subtitle: const Text('Electrical Conductivity'),
                value: 'ec',
                groupValue: _nutrientMeasurementType,
                onChanged: (String? value) {
                  setState(() {
                    _nutrientMeasurementType = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisplaySettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDataRefreshRateSelector(),
            const Divider(),
            _buildDateFormatSelector(),
            const Divider(),
            _buildTimeFormatSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRefreshRateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Refresh Rate',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'How often sensor data should be updated',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _dataRefreshRate.toDouble(),
                min: 10,
                max: 300,
                divisions: 29,
                label: _formatRefreshRate(_dataRefreshRate),
                activeColor: AppColors.moss,
                inactiveColor: AppColors.sand.withOpacity(0.3),
                onChanged: (double value) {
                  setState(() {
                    _dataRefreshRate = value.round();
                  });
                },
              ),
            ),
            Container(
              width: 100,
              alignment: Alignment.center,
              child: Text(
                _formatRefreshRate(_dataRefreshRate),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatRefreshRate(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '$minutes min';
      } else {
        return '$minutes min $remainingSeconds sec';
      }
    }
  }

  Widget _buildDateFormatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Format',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose your preferred date format',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('MM/DD/YYYY'),
                subtitle: const Text('Example: 09/30/2023'),
                value: 'MM/dd/yyyy',
                groupValue: _dateFormat,
                onChanged: (String? value) {
                  setState(() {
                    _dateFormat = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('DD/MM/YYYY'),
                subtitle: const Text('Example: 30/09/2023'),
                value: 'dd/MM/yyyy',
                groupValue: _dateFormat,
                onChanged: (String? value) {
                  setState(() {
                    _dateFormat = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('YYYY-MM-DD'),
                subtitle: const Text('Example: 2023-09-30'),
                value: 'yyyy-MM-dd',
                groupValue: _dateFormat,
                onChanged: (String? value) {
                  setState(() {
                    _dateFormat = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('DD-MMM-YYYY'),
                subtitle: const Text('Example: 30-Sep-2023'),
                value: 'dd-MMM-yyyy',
                groupValue: _dateFormat,
                onChanged: (String? value) {
                  setState(() {
                    _dateFormat = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeFormatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time Format',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose your preferred time format',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('12-hour'),
                subtitle: const Text('Example: 2:30 PM'),
                value: '12hour',
                groupValue: _timeFormat,
                onChanged: (String? value) {
                  setState(() {
                    _timeFormat = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('24-hour'),
                subtitle: const Text('Example: 14:30'),
                value: '24hour',
                groupValue: _timeFormat,
                onChanged: (String? value) {
                  setState(() {
                    _timeFormat = value!;
                  });
                },
                activeColor: AppColors.moss,
              ),
            ),
          ],
        ),
      ],
    );
  }
} 