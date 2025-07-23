import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/performance_matrix_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/api/api_service.dart';
import '../../widgets/responsive_widget.dart';

class LeaderboardEntryDetailPage extends StatefulWidget {
  final LeaderboardEntry entry;
  
  const LeaderboardEntryDetailPage({
    super.key, 
    required this.entry,
  });

  @override
  State<LeaderboardEntryDetailPage> createState() => _LeaderboardEntryDetailPageState();
}

class _LeaderboardEntryDetailPageState extends State<LeaderboardEntryDetailPage> {
  final ApiService _apiService = ApiService();
  String _username = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await _apiService.getUserProfile(widget.entry.userId);
      if (userData != null && userData['username'] != null) {
        setState(() {
          _username = userData['username'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _username = 'Unknown User';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching username: $e');
      setState(() {
        _username = 'Unknown User';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Leaderboard Entry Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.leaf, AppColors.forest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveWidget(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }
  
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 400 ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(context),
          SizedBox(height: MediaQuery.of(context).size.width < 400 ? 16 : 24),
          _buildDetailsSection(context),
          SizedBox(height: MediaQuery.of(context).size.width < 400 ? 16 : 24),
          _buildPerformanceMetricsSection(context),
          SizedBox(height: MediaQuery.of(context).size.width < 400 ? 16 : 24),
          _buildGrowthConditionsSection(context),
          SizedBox(height: MediaQuery.of(context).size.width < 400 ? 16 : 24),
          _buildNotesSection(context),
        ],
      ),
    );
  }
  
  Widget _buildTabletLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMediumScreen = screenWidth < 900;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMediumScreen ? 20 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(context),
          SizedBox(height: isMediumScreen ? 24 : 32),
          if (isMediumScreen) ...[
            _buildDetailsSection(context),
            SizedBox(height: 24),
            _buildPerformanceMetricsSection(context),
            SizedBox(height: 24),
            _buildGrowthConditionsSection(context),
            SizedBox(height: 24),
            _buildNotesSection(context),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: _buildDetailsSection(context),
                ),
                SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildPerformanceMetricsSection(context),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            _buildGrowthConditionsSection(context),
            SizedBox(height: 32),
            _buildNotesSection(context),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDesktopLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 1200;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isLargeScreen ? 40 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(context),
          SizedBox(height: isLargeScreen ? 48 : 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildDetailsSection(context),
              ),
              SizedBox(width: isLargeScreen ? 40 : 32),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildPerformanceMetricsSection(context),
                  ],
                ),
              ),
              SizedBox(width: isLargeScreen ? 40 : 32),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGrowthConditionsSection(context),
                    SizedBox(height: isLargeScreen ? 40 : 32),
                    _buildNotesSection(context),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeaderSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenWidth < 400;
    
    // Determine the plant profile identifier (from optimalConditions or growProfileId)
    String? plantProfileIdentifier;
    if (widget.entry.optimalConditions != null && widget.entry.optimalConditions is Map) {
      final oc = widget.entry.optimalConditions as Map;
      if (oc.containsKey('identifier')) {
        plantProfileIdentifier = oc['identifier'] as String?;
      }
    }
    // Fallback: try to use growProfileId if identifier is not present
    plantProfileIdentifier ??= widget.entry.growProfileId;

    // Use growProfileId for CSV download
    final growProfileId = widget.entry.growProfileId;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isVerySmallScreen ? 16 : isSmallScreen ? 20 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSmallScreen) ...[
              // Stack layout for small screens
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildRankBadge(widget.entry.rank),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.entry.cropName,
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 20 : 22,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Profile: ${widget.entry.growProfileName}',
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 14 : 16,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Grower: ${_isLoading ? 'Loading...' : _username}',
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 14 : 16,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.forest.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 20,
                          color: AppColors.forest,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Score: ${widget.entry.score.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.forest,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Original layout for larger screens
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildRankBadge(widget.entry.rank),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.entry.cropName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Profile: ${widget.entry.growProfileName}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Grower: ${_isLoading ? 'Loading...' : _username}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.forest.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 20,
                          color: AppColors.forest,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Score: ${widget.entry.score.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.forest,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildInfoChipsRow(context)),
                if (growProfileId != null && growProfileId.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.download),
                      label: Text('Download Grow Profile CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forest,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () async {
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Center(child: CircularProgressIndicator()),
                        );
                        final filePath = await _apiService.downloadGrowProfileCsv(growProfileId);
                        Navigator.of(context).pop(); // Remove loading dialog
                        if (filePath != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('CSV downloaded to $filePath')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to download CSV.')),
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoChipsRow(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenWidth < 400;
    
    if (isVerySmallScreen) {
      // Stack vertically for very small screens
      return Column(
        children: [
          _buildInfoChip(
            icon: Icons.calendar_today,
            label: 'Harvest Date',
            value: DateFormat('MMM d, yyyy').format(widget.entry.harvestDate),
          ),
          SizedBox(height: 8),
          _buildInfoChip(
            icon: Icons.timelapse,
            label: 'Growth Duration',
            value: '${widget.entry.growthDuration} days',
          ),
          SizedBox(height: 8),
          _buildInfoChip(
            icon: Icons.spa,
            label: 'Yield',
            value: '${widget.entry.yieldAmount.toStringAsFixed(1)} g',
          ),
        ],
      );
    } else if (isSmallScreen) {
      // Wrap for small screens
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildInfoChip(
            icon: Icons.calendar_today,
            label: 'Harvest Date',
            value: DateFormat('MMM d, yyyy').format(widget.entry.harvestDate),
          ),
          _buildInfoChip(
            icon: Icons.timelapse,
            label: 'Growth Duration',
            value: '${widget.entry.growthDuration} days',
          ),
          _buildInfoChip(
            icon: Icons.spa,
            label: 'Yield',
            value: '${widget.entry.yieldAmount.toStringAsFixed(1)} g',
          ),
        ],
      );
    } else {
      // Original row layout for larger screens
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoChip(
            icon: Icons.calendar_today,
            label: 'Harvest Date',
            value: DateFormat('MMM d, yyyy').format(widget.entry.harvestDate),
          ),
          _buildInfoChip(
            icon: Icons.timelapse,
            label: 'Growth Duration',
            value: '${widget.entry.growthDuration} days',
          ),
          _buildInfoChip(
            icon: Icons.spa,
            label: 'Yield',
            value: '${widget.entry.yieldAmount.toStringAsFixed(1)} g',
          ),
        ],
      );
    }
  }
  
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12, 
        vertical: isSmallScreen ? 6 : 8
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 14 : 16, color: AppColors.forest),
          SizedBox(width: isSmallScreen ? 6 : 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 11 : 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailsSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Harvest Details',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: AppColors.forest,
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildDetailRow('Harvest Date', DateFormat('MMMM d, yyyy').format(widget.entry.harvestDate)),
            _buildDetailRow('Yield Amount', '${widget.entry.yieldAmount.toStringAsFixed(1)} grams'),
            _buildDetailRow('Growth Duration', '${widget.entry.growthDuration} days'),
            _buildDetailRow('Rating', '${widget.entry.rating}/5'),
            _buildDetailRow('Grower', _isLoading ? 'Loading...' : _username),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPerformanceMetricsSection(BuildContext context) {
    final performanceMetrics = widget.entry.performanceMetrics;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    if (performanceMetrics.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Details',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forest,
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                'No performance metrics available for this harvest.',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: AppColors.forest.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics,
                    color: AppColors.forest,
                    size: isSmallScreen ? 16 : 20,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Text(
                    'Performance Details',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forest,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            ...performanceMetrics.entries.map((entry) {
              final metricName = entry.key;
              final metricValue = entry.value;
              
              // Format metric name for display
              final displayName = _formatMetricName(metricName);
              
              // Determine color based on metric name
              final isGrowth = !metricName.toLowerCase().contains('color') && 
                              !metricName.toLowerCase().contains('tipburn') &&
                              !metricName.toLowerCase().contains('uniformity');
              final primaryColor = isGrowth ? AppColors.forest : AppColors.moss;
              
              // Calculate a weight based on metric name (mock data for display)
              final weight = isGrowth ? 1.0 : 0.8;
              
              // Calculate a contribution percentage (mock data for display)
              final contribution = isGrowth ? 0.15 : 0.05;
              
              return Padding(
                padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isSmallScreen) ...[
                      // Stack layout for small screens
                      Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${metricValue.toStringAsFixed(1)} ${_getUnitForMetric(metricName)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ] else ...[
                      // Row layout for larger screens
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${metricValue.toStringAsFixed(1)} ${_getUnitForMetric(metricName)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 1.0, // Full progress for actual values
                              backgroundColor: Colors.grey[200],
                              color: primaryColor,
                              minHeight: isSmallScreen ? 6 : 8,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        SizedBox(
                          width: isSmallScreen ? 32 : 40,
                          child: Text(
                            '100%',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Weight: ${weight.toStringAsFixed(1)} • Contribution: ${(contribution * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 9 : 10,
                        color: Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  String _formatMetricName(String metricName) {
    // Replace underscores and camelCase with spaces, then capitalize each word
    final spaced = metricName.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    ).replaceAll('_', ' ');
    return spaced.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  String _getUnitForMetric(String metricName) {
    final name = metricName.toLowerCase();
    if (name.contains('biomass') || name.contains('weight')) {
      return 'g';
    } else if (name.contains('height')) {
      return 'cm';
    } else if (name.contains('count')) {
      return 'count';
    } else if (name.contains('color') || name.contains('tipburn') || name.contains('uniformity')) {
      return 'rating';
    } else {
      return '';
    }
  }
  

  
  Widget _buildGrowthConditionsSection(BuildContext context) {
    // Extract optimal conditions from the entry
    final optimalConditions = widget.entry.optimalConditions;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    // Define default ranges to use if optimal conditions aren't available
    final defaultRanges = {
      'temperature': {'min': 18.0, 'max': 24.0},
      'humidity': {'min': 50.0, 'max': 70.0},
      'ph': {'min': 5.5, 'max': 6.5},
      'ec': {'min': 1.0, 'max': 2.0},
    };
    
    // Check if we have stage-based optimal conditions (preferred)
    final hasStages = optimalConditions != null && 
                      optimalConditions['stages'] != null && 
                      optimalConditions['stages'] is Map;

    // Get the maturation stage (most relevant for harvest) if available
    Map<String, dynamic>? stageData;
    if (hasStages) {
      final stages = optimalConditions!['stages'] as Map;
      if (stages.containsKey('maturation')) {
        stageData = stages['maturation'];
      } else if (stages.containsKey('vegetative')) {
        stageData = stages['vegetative'];
      } else if (stages.containsKey('transplanting')) {
        stageData = stages['transplanting'];
      }
    }
    
    // Extract temperature range - prioritize stage data
    Map<String, dynamic>? tempRange;
    if (stageData != null && stageData['temperature'] != null) {
      tempRange = Map<String, dynamic>.from(stageData['temperature']);
    } else if (optimalConditions != null && optimalConditions['temperature'] != null && 
              (optimalConditions['temperature']['min'] != null || optimalConditions['temperature']['max'] != null)) {
      tempRange = Map<String, dynamic>.from(optimalConditions['temperature']);
    } else {
      tempRange = defaultRanges['temperature'];
    }
    
    // Extract humidity range - prioritize stage data
    Map<String, dynamic>? humidityRange;
    if (stageData != null && stageData['humidity'] != null) {
      humidityRange = Map<String, dynamic>.from(stageData['humidity']);
    } else if (optimalConditions != null && optimalConditions['humidity'] != null && 
              (optimalConditions['humidity']['min'] != null || optimalConditions['humidity']['max'] != null)) {
      humidityRange = Map<String, dynamic>.from(optimalConditions['humidity']);
    } else {
      humidityRange = defaultRanges['humidity'];
    }
    
    // Extract pH range - prioritize stage data
    Map<String, dynamic>? phRange;
    if (stageData != null && stageData['ph'] != null) {
      phRange = Map<String, dynamic>.from(stageData['ph']);
    } else if (optimalConditions != null && optimalConditions['ph'] != null && 
              (optimalConditions['ph']['min'] != null || optimalConditions['ph']['max'] != null)) {
      phRange = Map<String, dynamic>.from(optimalConditions['ph']);
    } else {
      phRange = defaultRanges['ph'];
    }
    
    // Extract EC range - prioritize stage data
    Map<String, dynamic>? ecRange;
    if (stageData != null && stageData['ec'] != null) {
      ecRange = Map<String, dynamic>.from(stageData['ec']);
    } else if (optimalConditions != null && optimalConditions['ec'] != null && 
              (optimalConditions['ec']['min'] != null || optimalConditions['ec']['max'] != null)) {
      ecRange = Map<String, dynamic>.from(optimalConditions['ec']);
    } else {
      ecRange = defaultRanges['ec'];
    }

    // Helper function to get min/max values with null checks
    String getRangeText(Map<String, dynamic>? range, String unit, {bool isEc = false}) {
      final min = range?['min'];
      final max = range?['max'];
    
      if (min == null && max == null) {
        return 'Not specified';
      } else if (min == null) {
        return 'Up to ${isEc ? max.toStringAsFixed(2) : max.toStringAsFixed(1)}$unit';
      } else if (max == null) {
        return 'At least ${isEc ? min.toStringAsFixed(2) : min.toStringAsFixed(1)}$unit';
      } else {
        return '${isEc ? min.toStringAsFixed(2) : min.toStringAsFixed(1)} - ${isEc ? max.toStringAsFixed(2) : max.toStringAsFixed(1)}$unit';
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: AppColors.forest.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.eco,
                    color: AppColors.forest,
                    size: isSmallScreen ? 16 : 20,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Text(
                    'Optimal Growing Conditions',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forest,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildConditionRow(
              label: 'Temperature', 
              value: getRangeText(tempRange, '°C'),
              icon: Icons.thermostat,
            ),
            _buildConditionRow(
              label: 'Humidity', 
              value: getRangeText(humidityRange, '%'),
              icon: Icons.water_drop,
            ),
            _buildConditionRow(
              label: 'pH Level', 
              value: getRangeText(phRange, ''),
              icon: Icons.science,
            ),
            _buildConditionRow(
              label: 'EC Level', 
              value: getRangeText(ecRange, ' mS/cm', isEc: true),
              icon: Icons.bolt,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConditionRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Icon(icon, size: isSmallScreen ? 14 : 16, color: AppColors.forest),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotesSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    // Prefer remarks, then default message
    final String? remarks = (widget.entry as dynamic).remarks;
    String displayText;
    Color displayColor;
    if (remarks != null && remarks.trim().isNotEmpty) {
      displayText = remarks;
      displayColor = Colors.grey[800]!;
    } else {
      displayText = 'No remarks available for this harvest.';
      displayColor = Colors.grey[500]!;
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes & Observations',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: AppColors.forest,
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              displayText,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: displayColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricRow(String label, String value, double progress) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getColorForScore(double.parse(value)),
            ),
            minHeight: isSmallScreen ? 6 : 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
  
  Color _getColorForScore(double score) {
    if (score >= 90) {
      return Colors.green[700]!;
    } else if (score >= 75) {
      return Colors.green[500]!;
    } else if (score >= 60) {
      return Colors.amber[700]!;
    } else if (score >= 40) {
      return Colors.orange[700]!;
    } else {
      return Colors.red[700]!;
    }
  }
  
  Widget _buildRankBadge(int rank) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenWidth < 400;
    
    Color badgeColor;
    Color textColor = Colors.white;
    
    // Set colors based on rank
    if (rank == 1) {
      badgeColor = Colors.amber[700]!;
    } else if (rank == 2) {
      badgeColor = Colors.grey[400]!;
    } else if (rank == 3) {
      badgeColor = Colors.brown[300]!;
    } else {
      badgeColor = Colors.grey[200]!;
      textColor = Colors.grey[700]!;
    }
    
    final badgeSize = isVerySmallScreen ? 40.0 : isSmallScreen ? 44.0 : 48.0;
    final fontSize = isVerySmallScreen ? 16.0 : isSmallScreen ? 18.0 : 20.0;
    
    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
} 