import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../../providers/harvest_log_provider.dart';
import '../../../core/models/harvest_log_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/utils.dart';
import '../../widgets/responsive_widget.dart';
import '../performance/performance_results_page.dart';
import '../../../providers/performance_matrix_provider.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/models/performance_matrix_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HarvestLogPage extends StatefulWidget {
  final String deviceId;
  final String growId;
  final bool showDialogOnLoad;
  final String cropName;
  final bool isForcedHarvest;
  final String? forceHarvestReason;

  const HarvestLogPage({
    super.key,
    required this.deviceId,
    required this.growId,
    this.showDialogOnLoad = false,
    required this.cropName,
    this.isForcedHarvest = false,
    this.forceHarvestReason,
  });

  @override
  State<HarvestLogPage> createState() => _HarvestLogPageState();
}

class _HarvestLogPageState extends State<HarvestLogPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _yieldController = TextEditingController();
  final _ratingController = TextEditingController();
  final _remarksController = TextEditingController();
  bool _isSubmitting = false;
  Map<String, TextEditingController> _metricControllers = {};
  late AnimationController _successAnimationController;

  @override
  void initState() {
    super.initState();
    _successAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    if (widget.showDialogOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showHarvestDialog();
      });
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PerformanceMatrixProvider>(context, listen: false);
      provider.fetchHarvestData(widget.deviceId, growId: widget.growId);
    });
  }

  @override
  void dispose() {
    _yieldController.dispose();
    _ratingController.dispose();
    _remarksController.dispose();
    _successAnimationController.dispose();
    for (var controller in _metricControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showHarvestDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              widget.isForcedHarvest ? Icons.warning_amber_rounded : Icons.eco,
              color: widget.isForcedHarvest ? Colors.red : AppColors.accent,
            ),
            const SizedBox(width: 8),
            Text(widget.isForcedHarvest ? 'Force Harvest' : 'Harvest Grow'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isForcedHarvest) ...[
              const Text(
                '⚠️ This is a forced harvest. The grow is being harvested before reaching full maturity.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (widget.forceHarvestReason != null && widget.forceHarvestReason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Reason: ${widget.forceHarvestReason}'),
              ],
              const SizedBox(height: 16),
            ],
            const Text(
              'Please enter the harvest details below:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isForcedHarvest ? Colors.red : AppColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricInput(PerformanceMetric metric) {
    if (!_metricControllers.containsKey(metric.id)) {
      _metricControllers[metric.id] = TextEditingController();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: AppColors.forest,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      metric.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  metric.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextFormField(
              controller: _metricControllers[metric.id],
              decoration: InputDecoration(
                labelText: 'Value',
                hintText: 'Enter ${metric.name.toLowerCase()} value',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.forest),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                suffixText: metric.unit,
                prefixIcon: Icon(
                  Icons.edit_outlined,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                final number = double.tryParse(value);
                if (number == null) {
                  return 'Please enter a valid number';
                }
                if (metric.minValue != null && number < metric.minValue!) {
                  return 'Value must be at least ${metric.minValue}';
                }
                if (metric.maxValue != null && number > metric.maxValue!) {
                  return 'Value must be at most ${metric.maxValue}';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isForcedHarvest ? 'Force Harvest' : 'Harvest Log'),
        backgroundColor: widget.isForcedHarvest ? Colors.red : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Harvest Summary Card
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.forest.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.eco,
                              color: AppColors.forest,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.cropName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.forest,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Harvest Summary',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              icon: Icons.calendar_today,
                              label: 'Harvest Date',
                              value: DateTime.now().toString().split(' ')[0],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryItem(
                              icon: Icons.warning_amber_rounded,
                              label: 'Status',
                              value: widget.isForcedHarvest ? 'Forced Harvest' : 'Normal Harvest',
                              isWarning: widget.isForcedHarvest,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Performance Matrix Section
              Consumer<PerformanceMatrixProvider>(
                builder: (context, provider, child) {
                  final matrix = provider.currentMatrix;
                  final selectedMetrics = matrix?.selectedMetrics ?? [];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.forest.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.insights,
                                  color: AppColors.forest,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      matrix?.name ?? 'Performance Matrix',
                                      style: TextStyle(
                                        color: AppColors.forest,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    if (selectedMetrics.isEmpty)
                                      Text(
                                        'No active metrics',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (selectedMetrics.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 24),
                            const Text(
                              'Performance Metrics',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ...selectedMetrics.map((metric) => _buildMetricInput(metric)),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Harvest Details Section
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.forest.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.agriculture,
                              color: AppColors.forest,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Harvest Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _yieldController,
                        decoration: InputDecoration(
                          labelText: 'Yield Amount',
                          hintText: 'Enter the yield amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.forest),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          suffixText: 'units',
                          prefixIcon: Icon(
                            Icons.scale,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the yield amount';
                          }
                          final yield = double.tryParse(value);
                          if (yield == null || yield <= 0) {
                            return 'Please enter a valid positive number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _ratingController,
                        decoration: InputDecoration(
                          labelText: 'Rating (1-5)',
                          hintText: 'Enter a rating from 1 to 5',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.forest),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: Icon(
                            Icons.star,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a rating';
                          }
                          final rating = int.tryParse(value);
                          if (rating == null || rating < 1 || rating > 5) {
                            return 'Please enter a rating between 1 and 5';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _remarksController,
                        decoration: InputDecoration(
                          labelText: 'Remarks',
                          hintText: 'Enter any notes or observations about this harvest',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.forest),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: Icon(
                            Icons.note_alt,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ),
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                      ),
                    ],
                  ),
                ),
              ),

              // Submit Button
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitHarvest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isForcedHarvest ? Colors.red : AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.isForcedHarvest
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.isForcedHarvest
                                  ? 'Complete Force Harvest'
                                  : 'Submit Harvest',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWarning ? Colors.red.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWarning ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isWarning ? Colors.red : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isWarning ? Colors.red : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isWarning ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitHarvest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get the performance matrix provider
      final matrixProvider = Provider.of<PerformanceMatrixProvider>(context, listen: false);
      final matrix = matrixProvider.currentMatrix;
      
      // Collect performance metrics
      Map<String, double> performanceMetrics = {};
      for (var metric in matrix?.selectedMetrics ?? []) {
        final value = double.tryParse(_metricControllers[metric.id]?.text ?? '0');
        if (value != null) {
          performanceMetrics[metric.id] = value;
        }
      }

      final response = await http.post(
        Uri.parse('${ApiEndpoints.addHarvestLog}${widget.deviceId}/${widget.growId}/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'deviceId': widget.deviceId,
          'growId': widget.growId,
          'cropName': widget.cropName,
          'harvestDate': DateTime.now().toIso8601String(),
          'yieldAmount': double.parse(_yieldController.text),
          'rating': int.parse(_ratingController.text),
          'isForcedHarvest': widget.isForcedHarvest,
          'forceHarvestReason': widget.forceHarvestReason,
          'performanceMetrics': performanceMetrics,
          'remarks': _remarksController.text,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          // Reset animation controller before showing dialog
          _successAnimationController.reset();
          _showSuccessDialog();
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to create harvest log: ${errorData['error'] ?? response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lottie Animation
                SizedBox(
                  height: 150,
                  child: Lottie.asset(
                    'assets/animations/success.json',
                    controller: _successAnimationController,
                    onLoaded: (composition) {
                      _successAnimationController.duration = composition.duration;
                      _successAnimationController.forward();
                    },
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Success Title
                Text(
                  widget.isForcedHarvest ? 'Force Harvest Complete!' : 'Harvest Complete!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: widget.isForcedHarvest ? Colors.red : AppColors.forest,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Success Message
                Text(
                  widget.isForcedHarvest
                      ? 'Your forced harvest has been successfully logged.'
                      : 'Your harvest has been successfully logged and saved.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Return to previous screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isForcedHarvest ? Colors.red : AppColors.forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}