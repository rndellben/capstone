import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/grow_profile_provider.dart';
import '../grow_profile/add_profile/add_profile_page.dart';
import '../grow_profile/edit_profile_page.dart';
import '../grow_profile/profile_detail_page.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/responsive_widget.dart';

class ProfileListPage extends StatefulWidget {
  final String userId;
  const ProfileListPage({super.key, required this.userId});
  
  @override
  State<ProfileListPage> createState() => _ProfileListPageState();
}

class _ProfileListPageState extends State<ProfileListPage> {
  @override
  void initState() {
    super.initState();
    // Delay fetch until after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GrowProfileProvider>(context, listen: false)
          .fetchGrowProfiles(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<GrowProfileProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.leaf, AppColors.forest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: const [
            Icon(Icons.eco, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text(
          'Grow Profiles',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
          ],
        ),
      ),
      drawer: AppDrawer(userId: widget.userId),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withAlpha((0.1 * 255).round()),
              Colors.white,
            ],
          ),
        ),
        child: ResponsiveWidget(
          mobile: _buildProfileList(profileProvider, isMobile: true),
          tablet: _buildProfileList(profileProvider, isMobile: false),
          desktop: _buildProfileList(profileProvider, isMobile: false),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddProfilePage(userId: widget.userId)),
        ),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProfileList(GrowProfileProvider profileProvider, {required bool isMobile}) {
    if (profileProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (profileProvider.growProfiles.isEmpty) {
      return _buildEmptyState();
    }

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: profileProvider.growProfiles.length,
          itemBuilder: (context, index) {
            return _buildProfileCard(profileProvider.growProfiles[index], profileProvider);
          },
        ),
      );
    } else {
      // Desktop/tablet view
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200), // Set a max width for the grid
          child: GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 columns for desktop
              childAspectRatio: 1.3, // Less tall cards
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemCount: profileProvider.growProfiles.length,
            itemBuilder: (context, index) {
              return _buildProfileCard(profileProvider.growProfiles[index], profileProvider);
            },
          ),
        ),
      );
    }
  }

  Widget _buildProfileCard(dynamic profile, GrowProfileProvider profileProvider) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileDetailPage(profileId: profile.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.leaf, AppColors.forest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            // White overlay for content readability
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.90),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.forest,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (profile.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.timer, "${profile.growDurationDays} days duration"),
                  const SizedBox(height: 4),
                  _buildDivider(),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.forest,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfilePage(
                                userId: widget.userId,
                                profile: profile,
                              ),
                            ),
                          );
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: profile.isActive ? Colors.grey : AppColors.error,
                        ),
                        onPressed: profile.isActive 
                          ? () => _showActiveProfileMessage()
                          : () => _confirmDelete(profile, profileProvider),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(dynamic profile) {
    // This has been removed as per requirements
    return const SizedBox.shrink();
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey.withAlpha((0.2 * 255).round()),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grain_rounded,
            size: 64,
            color: AppColors.primary.withAlpha((0.5 * 255).round()),
          ),
          const SizedBox(height: 16),
          const Text(
            "No grow profiles found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Create a new profile to get started",
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Create Profile"),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddProfilePage(userId: widget.userId)),
            ),
          ),
        ],
      ),
    );
  }

  void _showActiveProfileMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cannot delete an active grow profile. Please deactivate the grow first.'),
        backgroundColor: AppColors.error,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _confirmDelete(dynamic profile, GrowProfileProvider profileProvider) {
    if (profile.isActive) {
      _showActiveProfileMessage();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Are you sure you want to delete ${profile.name}?"),
            const SizedBox(height: 8),
            const Text(
              "This action cannot be undone.",
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: AppColors.error)),
            onPressed: () {
              profileProvider.deleteGrowProfile(profile.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}