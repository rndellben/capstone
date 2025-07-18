import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/plant_profile_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/models/plant_profile_model.dart';
import '../../components/custom_text_field.dart';
import '../../components/loading_indicator.dart';
import '../../components/error_view.dart';
import '../../components/mode_selector.dart';
import '../../../core/constants/app_colors.dart';
import '../grow_profile/add_profile/add_profile_page.dart';
import 'add_plant_profile_dialog.dart';
import 'edit_plant_profile_dialog.dart';

class PlantProfilePage extends StatefulWidget {
  final String? userId;
  
  const PlantProfilePage({super.key, this.userId});

  @override
  State<PlantProfilePage> createState() => _PlantProfilePageState();
}

class _PlantProfilePageState extends State<PlantProfilePage> {
  String _mode = 'simple';  // Add mode state
  String _searchText = '';  // Add search text state
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlantProfileProvider>().fetchPlantProfiles(userId: widget.userId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onModeChanged(String newMode) {
    setState(() {
      _mode = newMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FFF6), Color(0xFFE8F5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Builder(
            builder: (context) {
              final width = MediaQuery.of(context).size.width;
              return Container(
                width: width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.leaf.withOpacity(0.97),
                      AppColors.forest.withOpacity(0.97),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
          foregroundColor: Colors.white,
          title: const Text(
            'Plant Profiles',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ModeSelector(
                currentMode: _mode,
                onModeChanged: _onModeChanged,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showAddProfileDialog(context),
            ),
          ],
        ),
        body: Consumer<PlantProfileProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const LoadingIndicator();
            }

            if (provider.error != null) {
              return ErrorView(
                message: provider.error!,
                onRetry: () => provider.fetchPlantProfiles(userId: widget.userId),
              );
            }

            if (provider.plantProfiles.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: _buildProfileList(provider),
                ),
              ],
            );
          },
        ),
        floatingActionButton: SizedBox(
          height: 68,
          width: 68,
          child: FloatingActionButton(
            backgroundColor: AppColors.leaf,
            foregroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () => _showAddProfileDialog(context),
            child: const Icon(Icons.add, size: 34),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search plant profiles...',
            prefixIcon: const Icon(Icons.search, color: AppColors.leaf),
            suffixIcon: _searchText.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.leaf),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchText = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
          onChanged: (value) {
            setState(() {
              _searchText = value.trim();
            });
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.leaf.withOpacity(0.18), AppColors.primary.withOpacity(0.10)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(32),
            child: const Icon(
              Icons.eco_outlined,
              size: 72,
              color: AppColors.leaf,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Plant Profiles Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create your first plant profile to get started',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddProfileDialog(context),
            icon: const Icon(Icons.add, size: 22),
            label: const Text(
              'Add Plant Profile',
              style: TextStyle(fontSize: 17),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.leaf,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileList(PlantProfileProvider provider) {
    // Filter profiles based on mode and search text
    final filteredProfiles = provider.plantProfiles.where((profile) {
      // Mode filter
      bool modeMatch = true;
      if (_mode == 'simple') {
        modeMatch = profile.mode == 'simple';
      }
      
      // Search filter
      bool searchMatch = true;
      if (_searchText.isNotEmpty) {
        searchMatch = profile.name.toLowerCase().contains(_searchText.toLowerCase()) ||
                     (profile.notes.isNotEmpty && profile.notes.toLowerCase().contains(_searchText.toLowerCase()));
      }
      
      return modeMatch && searchMatch;
    }).toList();

    if (filteredProfiles.isEmpty && _searchText.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.leaf,
            ),
            const SizedBox(height: 16),
            Text(
              'No profiles match "$_searchText"',
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchText = '';
                });
              },
              child: const Text('Clear Search'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.leaf,
      onRefresh: () async {
        await provider.fetchPlantProfiles(userId: widget.userId);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredProfiles.length,
        cacheExtent: 500,
        itemBuilder: (context, index) {
          final profile = filteredProfiles[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildProfileCard(profile),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(PlantProfile profile) {
    // Using Hero widget for smooth transitions to detail view
    return Hero(
      tag: 'profile-${profile.id}',
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            gradient: const LinearGradient(
              colors: [AppColors.leaf, AppColors.forest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Card(
            elevation: 0,
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showProfileDetails(context, profile),
              splashColor: AppColors.leaf.withOpacity(0.08),
              highlightColor: AppColors.leaf.withOpacity(0.04),
              child: Container(
                // White overlay for content readability
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.90),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.leaf.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.eco, color: AppColors.leaf, size: 32),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    profile.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: profile.mode == 'simple'
                                        ? AppColors.forest
                                        : Colors.redAccent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    profile.mode == 'simple' ? 'Simple' : 'Advanced',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (profile.notes.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  profile.notes,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
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

  void _showAddProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddPlantProfileDialog(
        userId: widget.userId,
        mode: _mode,  // Pass current mode
      ),
    );
  }

  void _showProfileDetails(BuildContext context, PlantProfile profile) {
    showDialog(
      context: context,
      builder: (context) => PlantProfileDetailsDialog(
        profile: profile,
        mode: _mode,  // Pass current mode
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.leaf),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class PlantProfileDetailsDialog extends StatefulWidget {
  final PlantProfile profile;
  final String mode;

  const PlantProfileDetailsDialog({
    super.key,
    required this.profile,
    required this.mode,
  });

  @override
  State<PlantProfileDetailsDialog> createState() => _PlantProfileDetailsDialogState();
}

class _PlantProfileDetailsDialogState extends State<PlantProfileDetailsDialog> {
  bool _showAdvanced = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 600 ? 550.0 : width * 0.92;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Hero(
        tag: 'profile-${profile.id}',
        child: Material(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (profile.notes.isNotEmpty) ...[
                          const SectionHeader(
                            title: "Description",
                            icon: Icons.description_outlined,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              profile.notes,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        const SectionHeader(
                          title: "Optimal Growing Conditions",
                          icon: Icons.wb_sunny_outlined,
                        ),
                        const SizedBox(height: 16),
                        // Toggle for advanced/simple
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _showAdvanced ? 'Advanced' : 'Simple',
                              style: TextStyle(
                                color: AppColors.forest,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Switch(
                              value: _showAdvanced,
                              onChanged: (val) {
                                setState(() {
                                  _showAdvanced = val;
                                });
                              },
                              activeColor: AppColors.leaf,
                            ),
                          ],
                        ),
                        _buildNestedConditionsSection(),
                        const SizedBox(height: 24),
                        if (profile.growDurationDays > 0) ...[
                          // Use RepaintBoundary for static content 
                          RepaintBoundary(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.leaf.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    color: AppColors.forest,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Recommended Grow Duration",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${profile.growDurationDays} days",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.eco, color: AppColors.leaf, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.profile.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Plant Profile Details",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          CloseButton(color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildNestedConditionsSection() {
    final conditions = widget.profile.optimalConditions.stageConditions;
    if (conditions.isEmpty) return const SizedBox();
    // Define the desired order
    final List<String> orderedStages = [
      'transplanting',
      'vegetative',
      'maturation',
    ];
    final keys = orderedStages.where((stage) => conditions.containsKey(stage)).toList();
    final extraStages = conditions.keys.where((k) => !orderedStages.contains(k)).toList();
    final List<String> allKeys = [...keys, ...extraStages];
    final showAll = _showAdvanced;
    final isSimple = widget.mode == 'simple';
    // If simple mode and not advanced, just show transplanting parameters as a grid (no header or stage name)
    if (isSimple && !showAll && conditions.containsKey('transplanting')) {
      return _buildStageConditionGrid(conditions['transplanting']!);
    }
    // Otherwise, show the full section as before
    final stagesToShow = showAll ? allKeys : (allKeys.isNotEmpty ? [allKeys.first] : []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: "Growth Stages",
          icon: Icons.timeline,
        ),
        const SizedBox(height: 12),
        ...stagesToShow.map((stage) {
          final stageData = conditions[stage]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _capitalize(stage),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              _buildStageConditionGrid(stageData),
              const SizedBox(height: 18),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStageConditionGrid(Map<String, Map<String, double>> data) {
    final items = <Widget>[];
    void addItem(String label, String value, IconData icon, Color color) {
      items.add(_buildConditionCard(label, value, icon, color));
    }
    if (data.containsKey('temperature_range')) {
      final r = data['temperature_range']!;
      addItem('Temp', '${r['min']} - ${r['max']}°C', Icons.thermostat_outlined, AppColors.sunset);
    }   
    if (data.containsKey('humidity_range')) {
      final r = data['humidity_range']!;
      addItem('Humidity', '${r['min']} - ${r['max']}%', Icons.water_drop_outlined, AppColors.water);
    }
    if (data.containsKey('ph_range')) {
      final r = data['ph_range']!;
      addItem('pH', '${r['min']} - ${r['max']}', Icons.science_outlined, AppColors.forest);
    }
    if (data.containsKey('ec_range')) {
      final r = data['ec_range']!;
      addItem('EC', '${r['min']} - ${r['max']} mS/cm', Icons.bolt_outlined, AppColors.moss);
    }
    if (data.containsKey('tds_range')) {
      final r = data['tds_range']!;
      addItem('TDS', '${r['min']} - ${r['max']} ppm', Icons.opacity, AppColors.primary);
    }
    if (items.isEmpty) return const SizedBox();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items,
    );
  }

  Widget _buildConditionCard(String label, String value, IconData icon, Color color) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color.withOpacity(0.8),
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildFooter(BuildContext context) {
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final userId = await authProvider.getCurrentUserId();
                if (userId == null || (widget.profile.name == null || widget.profile.name.isEmpty)) return;

                if (!context.mounted) return;
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddProfilePage(
                      userId: userId,
                      recommendationData: {
                        'crop_type': widget.profile.name,
                        'force_simple_mode': widget.mode == 'simple',
                        'growth_stage': 'transplanting',
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_task),
              label: const Text('Apply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.leaf,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
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

  void _showEditProfileDialog(BuildContext context, PlantProfile profile) {
    Navigator.pop(context); // Close the details dialog first
    showDialog(
      context: context,
      builder: (context) => EditPlantProfileDialog(
        userId: profile.userId,
        profile: profile,
      ),
    );
  }
} 