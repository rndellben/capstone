import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../providers/plant_profile_provider.dart';
import '../../../../../services/unsplash_service.dart';
import '../../../../components/section_header.dart';
import '../../../../components/custom_button.dart';
import '../../../../components/team_profile_card.dart';

class PlantSelection extends StatefulWidget {
  final String? selectedPlantProfileId;
  final Function(String?) onPlantProfileSelected;
  final VoidCallback onNext;
  final bool isLoading;

  const PlantSelection({
    super.key,
    required this.selectedPlantProfileId,
    required this.onPlantProfileSelected,
    required this.onNext,
    required this.isLoading,
  });

  @override
  State<PlantSelection> createState() => _PlantSelectionState();
}

class _PlantSelectionState extends State<PlantSelection> {
  final UnsplashService _unsplashService = UnsplashService();
  final Map<String, String> _imageCache = {};

  Future<String> _getImageUrl(String profileName) async {
    if (_imageCache.containsKey(profileName)) {
      return _imageCache[profileName]!;
    }

    final imageUrl = await _unsplashService.getPlantImageUrl(profileName);
    if (imageUrl != null) {
      _imageCache[profileName] = imageUrl;
      return imageUrl;
    }

    // Fallback to UI Avatars if Unsplash fails
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(profileName)}&background=eee&color=555';
  }

  Widget _buildErrorView(PlantProfileProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Failed to load plant profiles. Please try again.",
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          TextButton(
            onPressed: () => provider.fetchPlantProfiles(),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_outlined, 
            color: Colors.amber[700],
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            "No Plant Profiles Found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Please add plant profiles first to create a grow profile.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantProfileGrid(PlantProfileProvider provider) {
    // Separate user profiles and default profiles
    final userProfiles = provider.plantProfiles.where((profile) => profile.userId != null).toList();
    final defaultProfiles = provider.plantProfiles.where((profile) => profile.userId == null).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 600 ? 2 : 1;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userProfiles.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  "Your Plant Profiles",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildProfileGrid(userProfiles, crossAxisCount),
              const SizedBox(height: 24),
            ],
            
            if (defaultProfiles.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  "Default Plant Profiles",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildProfileGrid(defaultProfiles, crossAxisCount),
            ],
          ],
        );
      },
    );
  }

  Widget _buildProfileGrid(List<dynamic> profiles, int crossAxisCount) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.85,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return FutureBuilder<String>(
          future: _getImageUrl(profile.name),
          builder: (context, snapshot) {
            return TeamProfileCard(
              name: profile.name,
              role: 'Plant Profile',
              imageUrl: snapshot.data ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(profile.name)}&background=eee&color=555',
              socialIcons: [
                Icon(Icons.eco, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Icon(Icons.thermostat, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Icon(Icons.water_drop, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Icon(Icons.science, color: Colors.grey[600], size: 20),
              ],
              description: profile.notes,
              isSelected: widget.selectedPlantProfileId == profile.id,
              onTap: () => widget.onPlantProfileSelected(profile.id),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final plantProfileProvider = Provider.of<PlantProfileProvider>(context);
    
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: "Select Plant Profile",
                    icon: Icons.eco,
                  ),
                  const SizedBox(height: 16),
                  if (plantProfileProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (plantProfileProvider.error != null)
                    _buildErrorView(plantProfileProvider)
                  else if (plantProfileProvider.plantProfiles.isEmpty)
                    _buildEmptyState()
                  else
                    _buildPlantProfileGrid(plantProfileProvider),
                  // Add extra padding at bottom to ensure content doesn't get hidden behind the button
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
        // Fixed button at bottom
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: CustomButton(
            text: "Next",
            onPressed: widget.selectedPlantProfileId != null ? () => widget.onNext() : () {},
            isLoading: widget.isLoading,
            backgroundColor: widget.selectedPlantProfileId != null ? AppColors.primary : AppColors.stone,
            icon: Icons.arrow_forward,
            height: 50,
          ),
        ),
      ],
    );
  }
} 