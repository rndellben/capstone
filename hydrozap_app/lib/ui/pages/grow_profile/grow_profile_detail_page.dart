import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/grow_profile_model.dart';
import '../../../providers/grow_profile_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../change_logs/profile_change_history_page.dart';

class GrowProfileDetailPage extends StatelessWidget {
  final GrowProfile profile;
  
  const GrowProfileDetailPage({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(profile.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _viewChangeHistory(context),
            tooltip: 'View Change History',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editProfile(context),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildOptimalConditions(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.grass, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: profile.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    profile.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(Icons.calendar_today, 'Grow Duration', '${profile.growDurationDays} days'),
            _buildInfoRow(Icons.science, 'Mode', profile.mode.toUpperCase()),
            _buildInfoRow(Icons.local_florist, 'Plant Profile ID', profile.plantProfileId),
            _buildInfoRow(Icons.update, 'Last Updated', _formatDate(profile.lastUpdated)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimalConditions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Optimal Conditions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildStageCard('Transplanting', profile.optimalConditions.transplanting),
        const SizedBox(height: 16),
        _buildStageCard('Vegetative', profile.optimalConditions.vegetative),
        const SizedBox(height: 16),
        _buildStageCard('Maturation', profile.optimalConditions.maturation),
      ],
    );
  }

  Widget _buildStageCard(String stageName, OptimalConditions conditions) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stageName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildRangeRow('Temperature', conditions.temperature, '°C'),
            _buildRangeRow('Humidity', conditions.humidity, '%'),
            _buildRangeRow('pH', conditions.phRange, ''),
            _buildRangeRow('EC', conditions.ecRange, 'mS/cm'),
            _buildRangeRow('TDS', conditions.tdsRange, 'ppm'),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeRow(String label, Range range, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              '${range.min} - ${range.max} $unit',
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _viewChangeHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileChangeHistoryPage(
          profileId: profile.id,
          profileName: profile.name,
        ),
      ),
    );
  }

  void _editProfile(BuildContext context) {
    // Navigate to edit profile page
    // This will be implemented separately
  }
} 