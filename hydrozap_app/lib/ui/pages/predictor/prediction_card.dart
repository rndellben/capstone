import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/prediction_model.dart';

/// A card widget that displays a prediction option
class PredictionOptionCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<String> inputFeatures;
  final VoidCallback onTap;
  final Color iconColor;
  final String modeTag; // 'Advanced' or 'Simple'

  const PredictionOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.inputFeatures,
    required this.onTap,
    required this.modeTag,
    this.iconColor = AppColors.primary,
  });

  @override
  State<PredictionOptionCard> createState() => _PredictionOptionCardState();
}

class _PredictionOptionCardState extends State<PredictionOptionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    return MouseRegion(
      onEnter: (_) {
        if (isDesktop) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (isDesktop) setState(() => _isHovered = false);
      },
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: _isHovered ? Matrix4.identity().scaled(1.025) : Matrix4.identity(),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Card(
            elevation: _isHovered ? 10 : 3,
      shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
      ),
            margin: EdgeInsets.zero,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.leaf, AppColors.forest],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                // White overlay for content readability
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.90),
                  borderRadius: BorderRadius.circular(16),
                ),
        child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                            padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                              color: widget.iconColor.withAlpha((0.15 * 255).round()),
                              borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                              widget.icon,
                              color: widget.iconColor,
                              size: 36,
                    ),
                  ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                  Expanded(
                    child: Text(
                                        widget.title,
                      style: const TextStyle(
                                          fontSize: 20,
                        fontWeight: FontWeight.bold,
                                          color: AppColors.forest,
                      ),
                    ),
                  ),
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      child: Chip(
                                        label: Text(
                                          widget.modeTag,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        backgroundColor: widget.modeTag.toLowerCase() == 'advanced'
                                            ? Colors.redAccent
                                            : AppColors.forest,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
                                const SizedBox(height: 6),
              Text(
                                  widget.description,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                  color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                ),
                          ),
                        ],
              ),
                      const SizedBox(height: 18),
                      Divider(color: AppColors.leaf.withOpacity(0.25)),
              const SizedBox(height: 8),
              Row(
                        children: const [
                          Icon(
                    Icons.input,
                            size: 18,
                    color: AppColors.textSecondary,
                  ),
                          SizedBox(width: 8),
                          Text(
                    'Required inputs:',
                    style: TextStyle(
                              fontSize: 13.5,
                      color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                        spacing: 10,
                runSpacing: 8,
                        children: widget.inputFeatures.map((feature) {
                  return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                              color: AppColors.leaf.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(14),
                    ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline, size: 15, color: AppColors.forest),
                                const SizedBox(width: 5),
                                Text(
                      feature,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.forest,
                                    fontWeight: FontWeight.w500,
                                  ),
                      ),
                              ],
                    ),
                  );
                }).toList(),
              ),
            ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A card widget that displays a prediction result
class PredictionResultCard extends StatelessWidget {
  final PredictionResult result;
  final VoidCallback onReset;

  const PredictionResultCard({
    super.key,
    required this.result,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildResultContent(context),
            const SizedBox(height: 16),
            _buildMessage(context),
            const SizedBox(height: 24),
            _buildResetButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          result.getTypeIcon(),
          color: result.getTypeColor(),
          size: 28,
        ),
        const SizedBox(width: 12),
        Text(
          _getTitle(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getTitle() {
    switch (result.type) {
      case PredictionType.tipburn:
        return 'Tipburn Prediction';
      case PredictionType.leafColor:
        return 'Leaf Color Index';
      case PredictionType.plantHeight:
        return 'Plant Height Prediction';
      case PredictionType.leafCount:
        return 'Leaf Count Prediction';
      case PredictionType.biomass:
        return 'Biomass Prediction';
      case PredictionType.cropSuggestion:
        return 'Crop Suggestion';
      case PredictionType.environmentRecommendation:
        return 'Environment Recommendation';
    }
  }

  Widget _buildResultContent(BuildContext context) {
    if (result.isLeafColor) {
      return _buildLeafColorResult(context);
    } else if (result.isTipburn) {
      return _buildTipburnResult(context);
    } else {
      return _buildStandardResult(context);
    }
  }

  Widget _buildLeafColorResult(BuildContext context) {
    final double colorIndex = result.value as double;
    
    // Map the color index to a color from the LCC scale
    final Color leafColor = _getLeafColorFromIndex(colorIndex);
    
    // Get the LCC category based on the color index
    final String lccCategory = _getLCCCategory(colorIndex);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: leafColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LCC: $lccCategory',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Index: ${colorIndex.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Leaf Color Chart Scale:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildColorScale(),
      ],
    );
  }

  Widget _buildColorScale() {
    return Column(
      children: [
        _buildColorScaleItem('LCC 1', Colors.yellow.shade200, 'Low chlorophyll'),
        _buildColorScaleItem('LCC 2', Colors.green.shade200, 'Light Green'),
        _buildColorScaleItem('LCC 3', Colors.green.shade300, 'Medium Light Green'),
        _buildColorScaleItem('LCC 4', Colors.green.shade400, 'Medium Green'),
        _buildColorScaleItem('LCC 5', Colors.green.shade500, 'Standard Green'),
        _buildColorScaleItem('LCC 6', Colors.green.shade600, 'Medium Dark Green'),
        _buildColorScaleItem('LCC 7', Colors.green.shade700, 'Dark Green'),
        _buildColorScaleItem('LCC 8', Colors.green.shade800, 'Very Dark Green'),
      ],
    );
  }

  Widget _buildColorScaleItem(String label, Color color, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLeafColorFromIndex(double index) {
  // Map the 0.1–1.0 scale to LCC colors (yellowish to dark green)
  if (index <= 0.125) return Colors.yellow.shade200;       // Low chlorophyll (yellow)
  if (index <= 0.25) return Colors.lightGreen.shade300;
  if (index <= 0.375) return Colors.green.shade300;
  if (index <= 0.5) return Colors.green.shade400;
  if (index <= 0.625) return Colors.green.shade500;
  if (index <= 0.75) return Colors.green.shade600;
  if (index <= 0.875) return Colors.green.shade700;
  return Colors.green.shade800;                             // Very dark green
}


String _getLCCCategory(double index) {
  // Map the 0.1–1.0 scale to LCC categories
  if (index <= 0.125) return '1 - Yellow / Very Low Chlorophyll';
  if (index <= 0.25) return '2 - Light Green';
  if (index <= 0.375) return '3 - Medium Light Green';
  if (index <= 0.5) return '4 - Medium Green';
  if (index <= 0.625) return '5 - Standard Green';
  if (index <= 0.75) return '6 - Medium Dark Green';
  if (index <= 0.875) return '7 - Dark Green';
  return '8 - Very Dark Green';
}

  Widget _buildTipburnResult(BuildContext context) {
    final bool hasTipburn = result.value as bool;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          hasTipburn ? Icons.warning_amber_rounded : Icons.check_circle_outline,
          color: hasTipburn ? Colors.red : Colors.green,
          size: 64,
        ),
        const SizedBox(width: 16),
        Text(
          hasTipburn ? 'Tipburn Risk Detected' : 'No Tipburn Risk',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: hasTipburn ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStandardResult(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          result.getTypeIcon(),
          color: result.getTypeColor(),
          size: 48,
        ),
        const SizedBox(width: 16),
        Text(
          result.displayValue,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              result.message,
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onReset,
        icon: const Icon(Icons.refresh),
        label: const Text('Make Another Prediction'),
        style: ElevatedButton.styleFrom(
          backgroundColor: result.getTypeColor(),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
} 