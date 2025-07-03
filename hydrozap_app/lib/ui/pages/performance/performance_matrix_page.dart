import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/performance_matrix_model.dart';
import '../../../providers/performance_matrix_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/responsive_widget.dart';
import '../../widgets/app_drawer.dart';
import '../../../core/helpers/utils.dart';
import '../../../core/utils/logger.dart';

class PerformanceMatrixPage extends StatefulWidget {
  final String userId;
  
  const PerformanceMatrixPage({super.key, required this.userId});

  @override
  State<PerformanceMatrixPage> createState() => _PerformanceMatrixPageState();
}

class _PerformanceMatrixPageState extends State<PerformanceMatrixPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _matrixNameController = TextEditingController();
  final TextEditingController _matrixDescriptionController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize the provider if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PerformanceMatrixProvider>(context, listen: false);
      if (provider.currentMatrix == null) {
        provider.initializeDefaultMatrix();
      }
      
      // Set initial text field values
      _matrixNameController.text = provider.currentMatrix?.name ?? 'Default Matrix';
      _matrixDescriptionController.text = provider.currentMatrix?.description ?? '';
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _matrixNameController.dispose();
    _matrixDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveWidget.isDesktop(context)
        ? AppBar(
            title: const Text(
              'Performance Matrix',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            backgroundColor: AppColors.forest,
            foregroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: 50,
            actions: [
              
              const SizedBox(width: 8),
            ],
          )
        : AppBar(
            title: const Text(
              'Performance Matrix',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.forest,
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.leaf,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              tabs: const [
                Tab(text: 'Growth Metrics'),
                Tab(text: 'Quality Metrics'),
              ],
            ),
          ),
      drawer: ResponsiveWidget.isDesktop(context) ? null : AppDrawer(userId: widget.userId),
      body: ResponsiveWidget(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMetricDialog(context),
        backgroundColor: AppColors.leaf,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildMatrixHeader(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMetricsList('growth'),
              _buildMetricsList('quality'),
            ],
          ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        _buildMatrixHeader(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMetricsList('growth'),
              _buildMetricsList('quality'),
            ],
          ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMatrixHeader(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: AppColors.forest.withOpacity(0.05),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.trending_up,
                                color: AppColors.forest,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Growth Metrics',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.forest,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _buildMetricsList('growth'),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: AppColors.leaf.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star_outline,
                                color: AppColors.leaf,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Quality Metrics',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.moss,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _buildMetricsList('quality'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }
  
  Widget _buildMatrixHeader() {
    return Consumer<PerformanceMatrixProvider>(
      builder: (context, provider, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insights,
                      color: Colors.blue.shade800,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Matrix Configuration',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Select metrics and adjust weights to prioritize what matters most for your plants. The matrix will then identify your top performers based on these criteria.',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMetricsList(String category) {
    return Consumer<PerformanceMatrixProvider>(
      builder: (context, provider, child) {
        final matrix = provider.currentMatrix;
        if (matrix == null) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final metrics = category == 'growth' 
            ? matrix.growthMetrics 
            : matrix.qualityMetrics;
        
        final primaryColor = category == 'growth' ? AppColors.forest : AppColors.moss;
        final accentColor = category == 'growth' ? AppColors.leaf : AppColors.moss;
        
        if (metrics.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category == 'growth' ? Icons.trending_up : Icons.star_outline,
                  size: 56,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No $category metrics defined yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text('Add $category metric'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showAddMetricDialog(context),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: metric.isSelected ? 
                    primaryColor.withOpacity(0.3) : 
                    Colors.transparent,
                  width: 1,
                ),
              ),
              child: ExpansionTile(
                leading: Icon(
                  category == 'growth' ? Icons.trending_up : Icons.star_outline,
                  color: primaryColor,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        metric.name,
                        style: TextStyle(
                          fontWeight: metric.isSelected ? FontWeight.bold : FontWeight.normal,
                          color: metric.isSelected ? primaryColor : Colors.grey[700],
                        ),
                      ),
                    ),
                    Switch(
                      value: metric.isSelected,
                      activeColor: accentColor,
                      onChanged: (value) {
                        provider.toggleMetricSelection(metric.id);
                      },
                    ),
                  ],
                ),
                subtitle: Text(
                  '${metric.description} (${metric.unit})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Weight: ${metric.weight.toStringAsFixed(1)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                metric.higherIsBetter ? 'Higher is better' : 'Lower is better',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Slider(
                          value: metric.weight,
                          min: 0.1,
                          max: 2.0,
                          divisions: 19,
                          label: metric.weight.toStringAsFixed(1),
                          activeColor: accentColor,
                          onChanged: metric.isSelected
                              ? (value) {
                                  provider.updateMetricWeight(metric.id, value);
                                }
                              : null,
                        ),
                        if (metric.minValue != null && metric.maxValue != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Range: ${metric.minValue} - ${metric.maxValue} ${metric.unit}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: BorderSide(color: primaryColor),
                              ),
                              onPressed: () => _showEditMetricDialog(context, metric),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.delete, size: 16),
                              label: const Text('Remove'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              onPressed: () => _showRemoveMetricDialog(context, metric),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildBottomActions() {
    final bool isMobile = ResponsiveWidget.isMobile(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(isMobile ? 'Reset' : 'Reset to Default'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              foregroundColor: AppColors.bark,
              side: BorderSide(color: AppColors.bark),
            ),
            onPressed: () {
              final provider = Provider.of<PerformanceMatrixProvider>(
                context, 
                listen: false,
              );
              provider.initializeDefaultMatrix();
              
              showAlertDialog(
                context: context,
                title: 'Reset Complete',
                message: 'Performance matrix has been reset to default settings.',
                type: AlertType.info,
                showCancelButton: false,
                confirmButtonText: 'OK',
              );
            },
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: Text(isMobile ? 'Apply' : 'Save & Apply'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.leaf,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              // Get provider
              final provider = Provider.of<PerformanceMatrixProvider>(
                context, 
                listen: false,
              );
              
              // Get active metrics count
              final activeMetricsCount = provider.currentMatrix?.selectedMetrics.length ?? 0;
              
              if (activeMetricsCount == 0) {
                // Show warning if no metrics are selected
                final shouldContinue = await showAlertDialog(
                  context: context,
                  title: 'No Metrics Selected',
                  message: 'You haven\'t selected any metrics. This will hide all performance metrics in harvest logs and results. Continue?',
                  type: AlertType.warning,
                  confirmButtonText: 'Continue',
                  cancelButtonText: 'Go Back',
                  onConfirm: () {
                    // This will be called in addition to returning true
                    logger.i('User confirmed saving with no metrics');
                  },
                  onCancel: () {
                    // This will be called in addition to returning false
                    logger.i('User canceled saving with no metrics');
                  },
                );
                
                if (shouldContinue != true) {
                  return; // User canceled
                }
              }
              
              // Show success dialog
              await showAlertDialog(
                context: context,
                title: 'Configuration Saved',
                message: activeMetricsCount > 0 
                  ? 'Your performance matrix with $activeMetricsCount metrics has been saved successfully.'
                  : 'Your performance matrix has been saved with no active metrics.',
                type: AlertType.success,
                showCancelButton: false,
                confirmButtonText: 'Done',
                onConfirm: () {
                  // This will be called after the dialog is dismissed
                  logger.i('Configuration saved successfully');
                },
              );
              
              // Apply and navigate back
              if (mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
  
  void _showEditMatrixDialog(BuildContext context) {
    final provider = Provider.of<PerformanceMatrixProvider>(context, listen: false);
    final matrix = provider.currentMatrix;
    
    _matrixNameController.text = matrix?.name ?? '';
    _matrixDescriptionController.text = matrix?.description ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Matrix'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _matrixNameController,
              decoration: const InputDecoration(
                labelText: 'Matrix Name',
                hintText: 'Enter a name for your matrix',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _matrixDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter a description',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (matrix != null) {
                final updatedMatrix = matrix.copyWith(
                  name: _matrixNameController.text,
                  description: _matrixDescriptionController.text,
                );
                provider.updateMatrix(updatedMatrix);
                
                // Show success confirmation using utils dialog
                Navigator.pop(context); // Close the edit dialog first
                
                showAlertDialog(
                  context: context,
                  title: 'Matrix Updated',
                  message: 'Matrix details have been updated successfully.',
                  type: AlertType.success,
                  showCancelButton: false,
                  confirmButtonText: 'OK',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.leaf,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showAddMetricDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final unitController = TextEditingController();
    String category = 'growth';
    bool higherIsBetter = true;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Metric'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Metric Name',
                    hintText: 'E.g., Leaf Width, Flavor Rating',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe what this metric measures',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    hintText: 'E.g., cm, g, rating (1-5)',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Category:'),
                RadioListTile<String>(
                  title: const Text('Growth Metric'),
                  value: 'growth',
                  groupValue: category,
                  onChanged: (value) {
                    setState(() {
                      category = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Quality Metric'),
                  value: 'quality',
                  groupValue: category,
                  onChanged: (value) {
                    setState(() {
                      category = value!;
                    });
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Higher values are better'),
                  subtitle: Text(
                    higherIsBetter 
                        ? 'Larger values indicate better performance' 
                        : 'Smaller values indicate better performance',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: higherIsBetter,
                  onChanged: (value) {
                    setState(() {
                      higherIsBetter = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty || unitController.text.isEmpty) {
                  return;
                }
                
                final provider = Provider.of<PerformanceMatrixProvider>(
                  context, 
                  listen: false,
                );
                
                final currentMatrix = provider.currentMatrix;
                if (currentMatrix != null) {
                  final newMetric = PerformanceMetric(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text,
                    description: descriptionController.text,
                    unit: unitController.text,
                    category: category,
                    isSelected: true,
                    weight: 1.0,
                    higherIsBetter: higherIsBetter,
                  );
                  
                  final updatedMetrics = [...currentMatrix.metrics, newMetric];
                  provider.updateMatrix(currentMatrix.copyWith(metrics: updatedMetrics));
                  
                  // Show success message using utils
                  Navigator.pop(context);
                  
                  // Show success dialog after adding metric
                  showAlertDialog(
                    context: context,
                    title: 'Metric Added',
                    message: '${nameController.text} has been added to your performance matrix.',
                    type: AlertType.success,
                    showCancelButton: false,
                    confirmButtonText: 'OK',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.leaf,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEditMetricDialog(BuildContext context, PerformanceMetric metric) {
    final nameController = TextEditingController(text: metric.name);
    final descriptionController = TextEditingController(text: metric.description);
    final unitController = TextEditingController(text: metric.unit);
    final minValueController = TextEditingController(
      text: metric.minValue?.toString() ?? '',
    );
    final maxValueController = TextEditingController(
      text: metric.maxValue?.toString() ?? '',
    );
    
    String category = metric.category;
    bool higherIsBetter = metric.higherIsBetter;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Metric'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Metric Name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minValueController,
                        decoration: const InputDecoration(
                          labelText: 'Min Value (optional)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: maxValueController,
                        decoration: const InputDecoration(
                          labelText: 'Max Value (optional)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Category:'),
                RadioListTile<String>(
                  title: const Text('Growth Metric'),
                  value: 'growth',
                  groupValue: category,
                  onChanged: (value) {
                    setState(() {
                      category = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Quality Metric'),
                  value: 'quality',
                  groupValue: category,
                  onChanged: (value) {
                    setState(() {
                      category = value!;
                    });
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Higher values are better'),
                  subtitle: Text(
                    higherIsBetter 
                        ? 'Larger values indicate better performance' 
                        : 'Smaller values indicate better performance',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: higherIsBetter,
                  onChanged: (value) {
                    setState(() {
                      higherIsBetter = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty || unitController.text.isEmpty) {
                  return;
                }
                
                final provider = Provider.of<PerformanceMatrixProvider>(
                  context, 
                  listen: false,
                );
                
                final currentMatrix = provider.currentMatrix;
                if (currentMatrix != null) {
                  // Parse min and max values if provided
                  double? minValue;
                  double? maxValue;
                  
                  try {
                    if (minValueController.text.isNotEmpty) {
                      minValue = double.parse(minValueController.text);
                    }
                    if (maxValueController.text.isNotEmpty) {
                      maxValue = double.parse(maxValueController.text);
                    }
                  } catch (e) {
                    // Handle parsing errors
                  }
                  
                  final updatedMetric = metric.copyWith(
                    name: nameController.text,
                    description: descriptionController.text,
                    unit: unitController.text,
                    category: category,
                    minValue: minValue,
                    maxValue: maxValue,
                    higherIsBetter: higherIsBetter,
                  );
                  
                  final updatedMetrics = currentMatrix.metrics.map((m) {
                    return m.id == metric.id ? updatedMetric : m;
                  }).toList();
                  
                  provider.updateMatrix(currentMatrix.copyWith(metrics: updatedMetrics));
                  
                  // Show success dialog
                  Navigator.pop(context);
                  
                  showAlertDialog(
                    context: context,
                    title: 'Metric Updated',
                    message: '${updatedMetric.name} has been updated successfully.',
                    type: AlertType.success,
                    showCancelButton: false,
                    confirmButtonText: 'OK',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.leaf,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showRemoveMetricDialog(BuildContext context, PerformanceMetric metric) {
    showAlertDialog(
      context: context,
      title: 'Remove Metric',
      message: 'Are you sure you want to remove "${metric.name}" from your matrix?',
      type: AlertType.warning,
      confirmButtonText: 'Remove',
      cancelButtonText: 'Cancel',
      onConfirm: () {
        final provider = Provider.of<PerformanceMatrixProvider>(
          context, 
          listen: false,
        );
        
        final currentMatrix = provider.currentMatrix;
        if (currentMatrix != null) {
          final updatedMetrics = currentMatrix.metrics
              .where((m) => m.id != metric.id)
              .toList();
          
          provider.updateMatrix(currentMatrix.copyWith(metrics: updatedMetrics));
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${metric.name} has been removed'),
              backgroundColor: AppColors.leaf,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }
} 