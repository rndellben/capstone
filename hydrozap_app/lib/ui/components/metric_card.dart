// File: lib/ui/widgets/metric_card.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/responsive_widget.dart';
import 'dart:ui';

enum TrendDirection {
  up,
  down,
  neutral,
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool showBorder;
  final String? trend;
  final TrendDirection trendDirection;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.showBorder = false,
    this.trend,
    this.trendDirection = TrendDirection.neutral,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobile: _buildMobileCard(context),
      tablet: _buildTabletCard(context),
      desktop: _buildDesktopCard(context),
    );
  }

  // Generates a lighter version of the icon color for gradient effect
  Color _getLighterColor() {
    final HSLColor hslColor = HSLColor.fromColor(iconColor);
    return hslColor.withLightness((hslColor.lightness + 0.4).clamp(0.0, 1.0)).toColor();
  }

  // Generates a darker version of the icon color for gradient effect
  Color _getDarkerColor() {
    final HSLColor hslColor = HSLColor.fromColor(iconColor);
    return hslColor.withLightness((hslColor.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }

  // Mobile card design
  Widget _buildMobileCard(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: iconColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              _getLighterColor().withOpacity(0.15),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Circular icon container with gradient
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor,
                      _getDarkerColor(),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: iconColor.withOpacity(0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tablet card design
  Widget _buildTabletCard(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: iconColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              _getLighterColor().withOpacity(0.15),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Circular icon container with gradient
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor,
                      _getDarkerColor(),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
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
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: iconColor.withOpacity(0.8),
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Desktop card design
  Widget _buildDesktopCard(BuildContext context) {
    return Card(
      elevation: 5,
      shadowColor: iconColor.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: iconColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              _getLighterColor().withOpacity(0.18),
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title with a subtle underline
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            height: 2,
                            width: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [iconColor, Colors.transparent],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                      // Circular icon container with gradient
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              iconColor,
                              _getDarkerColor(),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Value with larger font and custom styling
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: iconColor.withOpacity(0.8),
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}