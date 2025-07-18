import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/responsive_widget.dart';
import '../../../core/models/prediction_model.dart';
import 'prediction_card.dart';
import 'tipburn_predictor_page.dart';
import 'leaf_color_predictor_page.dart';
import 'plant_height_predictor_page.dart';
import 'leaf_count_predictor_page.dart';
import 'biomass_predictor_page.dart';
import 'crop_suggestion_predictor_page.dart';
import 'environment_recommendation_page.dart';
import '../../../routes/app_routes.dart';

class PredictorPage extends StatefulWidget {
  final String userId;

  const PredictorPage({
    super.key,
    required this.userId,
  });

  @override
  State<PredictorPage> createState() => _PredictorPageState();
}

class _PredictorPageState extends State<PredictorPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveWidget.isDesktop(context)
          ? null
          : AppBar(
              title: const Text(
                'Crop Suitability Analysis',
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
            ),
      drawer: ResponsiveWidget.isDesktop(context) ? null : AppDrawer(userId: widget.userId),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5FFF7), Color(0xFFE8F5E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ResponsiveWidget(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildPredictionOptions(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: SizedBox(
          width: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 32),
              _buildPredictionOptions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 280,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha((0.1 * 255).round()),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: AppDrawer(userId: widget.userId),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: SizedBox(
                width: 800,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 40),
                    _buildPredictionOptions(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
                child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 18),
              Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                  'Crop Suitability Analysis',
                  style: TextStyle(
                        fontSize: 22,
                    fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                  ),
                ),
                    SizedBox(height: 8),
                    Text(
                      'Explore which crops are suitable for your environment — or find the ideal growing conditions for your chosen crop. Select a category below to begin.',
                      style: TextStyle(fontSize: 15, color: Colors.white70),
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

  Widget _buildPredictionOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.leaf, AppColors.forest],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.forest.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'Select a Analysis Type',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
        
        // Environment Recommendation
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: PredictionOptionCard(
          title: 'Environment Recommendation',
          description: 'Get recommended environmental parameters for your crop and growth stage',
          icon: Icons.eco_outlined,
          iconColor: AppColors.success,
          inputFeatures: const ['Crop Type', 'Growth Stage'],
          onTap: () => _navigateToPredictionPage(context, PredictionType.environmentRecommendation),
              modeTag: 'Advanced',
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Crop Suggestion Prediction
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: PredictionOptionCard(
          title: 'Crop Suggestion',
          description: 'Get crop recommendations based on environmental conditions',
          icon: Icons.agriculture_outlined,
          iconColor: AppColors.forest,
          inputFeatures: const ['Temperature', 'Humidity', 'pH', 'EC'],
          onTap: () => _navigateToPredictionPage(context, PredictionType.cropSuggestion),
              modeTag: 'Simple',
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Tipburn Prediction
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: PredictionOptionCard(
          title: 'Tipburn Occurrence',
          description: 'Predict likelihood of tipburn based on environmental conditions',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.red,
          inputFeatures: const ['Temperature', 'Humidity', 'EC', 'pH'],
          onTap: () => _navigateToPredictionPage(context, PredictionType.tipburn),
              modeTag: 'Simple',
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Leaf Color Prediction
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: PredictionOptionCard(
          title: 'Leaf Color Index',
          description: 'Predict leaf color intensity (0-10 scale)',
          icon: Icons.color_lens_outlined,
          iconColor: Colors.green.shade700,
          inputFeatures: const ['EC', 'pH', 'Growth_Days', 'Temperature'],
          onTap: () => _navigateToPredictionPage(context, PredictionType.leafColor),
              modeTag: 'Simple',
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        
        
        
      ],
    );
  }

  void _navigateToPredictionPage(BuildContext context, PredictionType type) {
    if (type == PredictionType.environmentRecommendation) {
      // Use named route for environment recommendation
      Navigator.pushNamed(
        context,
        AppRoutes.environmentRecommendation,
        arguments: widget.userId,
      );
      return;
    }
    
    Widget page;
    
    switch (type) {
      case PredictionType.cropSuggestion:
        page = CropSuggestionPredictorPage(userId: widget.userId);
        break;
      case PredictionType.tipburn:
        page = TipburnPredictorPage(userId: widget.userId);
        break;
      case PredictionType.leafColor:
        page = LeafColorPredictorPage(userId: widget.userId);
        break;
      case PredictionType.plantHeight:
        page = PlantHeightPredictorPage(userId: widget.userId);
        break;
      case PredictionType.leafCount:
        page = LeafCountPredictorPage(userId: widget.userId);
        break;
      case PredictionType.biomass:
        page = BiomassPredictorPage(userId: widget.userId);
        break;
      case PredictionType.environmentRecommendation:
        // This case is handled above
        return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}