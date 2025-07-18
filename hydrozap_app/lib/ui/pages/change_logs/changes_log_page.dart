import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/profile_change_log_model.dart';
import '../../../providers/grow_profile_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/profile_change_log_repository.dart';
import '../../../core/models/grow_profile_model.dart'; // Added import for GrowProfile
import '../../../data/local/shared_prefs.dart';

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
  }
}

class ChangesLogPage extends StatefulWidget {
  const ChangesLogPage({Key? key}) : super(key: key);

  @override
  _ChangesLogPageState createState() => _ChangesLogPageState();
}

class _ChangesLogPageState extends State<ChangesLogPage> {
  bool _isLoading = true;
  List<ProfileChangeLog> _changeLogs = [];
  final ProfileChangeLogRepository _repository = ProfileChangeLogRepository();

  @override
  void initState() {
    super.initState();
    _loadChangeLogs();
    _checkCurrentUsername(); // Add this line
  }

  // Add this new method
  Future<void> _checkCurrentUsername() async {
    final username = await SharedPrefs.getUserName();
   
  }

  Future<void> _loadChangeLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch logs directly from the API (remote only)
      final logs = await _repository.fetchRemoteOnlyLogs();
      setState(() {
        _changeLogs = List<ProfileChangeLog>.from(logs);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading change logs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Changes Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChangeLogs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildChangeLogsList(),
    );
  }

  Widget _buildChangeLogsList() {
    if (_changeLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No changes have been recorded yet.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _changeLogs.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final changeLog = _changeLogs[index];
        return _buildChangeLogCard(changeLog);
      },
    );
  }

  Widget _buildChangeLogCard(ProfileChangeLog changeLog) {
    // Format timestamp
    final formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(changeLog.timestamp);
    
    // Set gradient color based on change type
    List<Color> gradientColors;
    IconData changeIcon;
    String changeTypeText;
    
    switch (changeLog.changeType) {
      case 'create':
        gradientColors = [Colors.green.shade300, Colors.green.shade700];
        changeIcon = Icons.add_circle_outline;
        changeTypeText = 'Created';
        break;
      case 'update':
        gradientColors = [Colors.blue.shade300, Colors.blue.shade700];
        changeIcon = Icons.edit_outlined;
        changeTypeText = 'Updated';
        break;
      case 'delete':
        gradientColors = [Colors.red.shade300, Colors.red.shade700];
        changeIcon = Icons.delete_outline;
        changeTypeText = 'Deleted';
        break;
      default:
        gradientColors = [Colors.grey.shade300, Colors.grey.shade700];
        changeIcon = Icons.info_outline;
        changeTypeText = 'Changed';
    }

    // Get profile name from provider if available
    final profileProvider = Provider.of<GrowProfileProvider>(context, listen: false);
    String profileName = 'Unknown Profile';
    
    try {
      // For newly created profiles, check the change log first
      if (changeLog.changeType == 'create' && 
          changeLog.newValues != null &&
          changeLog.newValues.containsKey('name')) {
        profileName = changeLog.newValues['name'];
      } 
      // For deleted profiles, check the previous values
      else if (changeLog.changeType == 'delete' && 
               changeLog.previousValues != null &&
               changeLog.previousValues.containsKey('name')) {
        profileName = changeLog.previousValues['name'];
      }
      else {
        // Try to find profile by ID in existing profiles
        final matchingProfiles = profileProvider.growProfiles
            .where((p) => p.id == changeLog.profileId)
            .toList();
            
        if (matchingProfiles.isNotEmpty) {
          profileName = matchingProfiles.first.name;
        }
      }
    } catch (e) {
      // Profile not found, keep default name
      print('Error finding profile: $e');
    }

    return InkWell(
      onTap: () => _showDetailedChangeLog(changeLog, profileName),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with timestamp and user
                  Row(
                    children: [
                      Icon(changeIcon, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '$changeTypeText Profile',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(),
                  
                  // Profile name
                  Row(
                    children: [
                      const Icon(Icons.grain_rounded, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Profile: $profileName',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // User who made the change
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Changed by: ${changeLog.userName}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Changed fields
                  if (changeLog.changeType != 'delete')
                    _buildChangedFieldsList(changeLog),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Add this new method to show detailed change log
  void _showDetailedChangeLog(ProfileChangeLog changeLog, String profileName) {
    final formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(changeLog.timestamp);
    final changedFields = changeLog.changedFields.keys.toList();
    
    // Double-check if we need to extract name from change log data
    if (profileName == 'Unknown Profile') {
      if (changeLog.changeType == 'create' && 
          changeLog.newValues != null &&
          changeLog.newValues.containsKey('name')) {
        profileName = changeLog.newValues['name'];
      } else if (changeLog.changeType == 'delete' && 
                changeLog.previousValues != null &&
                changeLog.previousValues.containsKey('name')) {
        profileName = changeLog.previousValues['name'];
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      changeLog.changeType == 'create'
                          ? Icons.add_circle_outline
                          : changeLog.changeType == 'update'
                              ? Icons.edit_outlined
                              : Icons.delete_outline,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${changeLog.changeType[0].toUpperCase()}${changeLog.changeType.substring(1)} Profile',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile info
                      _buildDetailRow('Profile', profileName),
                      _buildDetailRow('Changed By', changeLog.userName),
                      _buildDetailRow('Date & Time', formattedDate),
                      _buildDetailRow('Change ID', changeLog.id),
                      
                      const Divider(height: 32),
                      
                      // Changed fields
                      const Text(
                        'Changed Fields:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (changedFields.isEmpty)
                        const Text('No fields were changed.')
                      else
                        ...changedFields.map((field) => _buildChangedFieldItem(field, changeLog, detailed: true)),
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
  
  // Helper method to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangedFieldsList(ProfileChangeLog changeLog) {
    // Get the list of changed fields
    final changedFields = changeLog.changedFields.keys.toList();

    
    if (changedFields.isEmpty) {
      return const Text('No fields were changed.');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Changed Fields:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        ...changedFields.take(3).map((field) => _buildChangedFieldItem(field, changeLog)),
        if (changedFields.length > 3)
          TextButton(
            onPressed: () {
              _showAllChanges(context, changeLog);
            },
            child: Text(
              'View all ${changedFields.length} changes',
              style: TextStyle(color: AppColors.secondary),
            ),
          ),
      ],
    );
  }

  void _showAllChanges(BuildContext context, ProfileChangeLog changeLog) {
    final changedFields = changeLog.changedFields.keys.toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.list_alt),
                  const SizedBox(width: 8),
                  const Text(
                    'All Changed Fields',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: changedFields.map((field) => _buildChangedFieldItem(field, changeLog)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangedFieldItem(String field, ProfileChangeLog changeLog, {bool detailed = false}) {
    // Format field name for display
    String displayField = field
        .replaceAll('_', ' ')
        .replaceAll('.', ' › ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
    
    // Special handling for the optimal conditions format
    if (field.startsWith('optimal_conditions_')) {
      // Extract stage and parameter from the field name
      final parts = field.split('_');
      if (parts.length >= 4) {
        final stage = parts[2];
        // Join the remaining parts and properly format them
        final parameter = parts.sublist(3).join(' ')
            .split(' ')
            .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
            .join(' ');
        displayField = 'Optimal Conditions › ${stage[0].toUpperCase()}${stage.substring(1)} › $parameter';
      }
    }
    
    // Get previous and new values
    dynamic previousValue = _getNestedValue(changeLog.previousValues, field);
    dynamic newValue = _getNestedValue(changeLog.newValues, field);
    
    // Format values for display
    String previousValueText = _formatValueForDisplay(previousValue);
    String newValueText = _formatValueForDisplay(newValue);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayField,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          if (changeLog.changeType != 'create')
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.remove_circle_outline, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    previousValueText,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 13,
                    ),
                    overflow: detailed ? TextOverflow.visible : TextOverflow.ellipsis,
                    maxLines: detailed ? null : 1,
                  ),
                ),
              ],
            ),
          if (changeLog.changeType != 'create' && changeLog.changeType != 'delete')
            const SizedBox(height: 2),
          if (changeLog.changeType != 'delete')
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.add_circle_outline, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    newValueText,
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 13,
                    ),
                    overflow: detailed ? TextOverflow.visible : TextOverflow.ellipsis,
                    maxLines: detailed ? null : 1,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  // Helper method to format a value for display
  String _formatValueForDisplay(dynamic value) {
    if (value == null) {
      return 'Not set';
    } else if (value is bool) {
      return value ? 'Yes' : 'No';
    } else if (value is Map) {
      if (value.containsKey('min') && value.containsKey('max')) {
        // Format range values more nicely
        return 'Min: ${value['min']}, Max: ${value['max']}';
      } else if (value.containsKey('ec_range') || value.containsKey('humidity_range') || 
                value.containsKey('ph_range') || value.containsKey('tds_range') || 
                value.containsKey('temperature_range')) {
        // Format nested range objects
        final parts = <String>[];
        value.forEach((key, val) {
          if (val is Map && val.containsKey('min') && val.containsKey('max')) {
            final formattedKey = key.toString()
                .replaceAll('_range', '')
                .replaceAll('_', ' ')
                .split(' ')
                .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
                .join(' ');
            parts.add('$formattedKey: Min ${val['min']}, Max ${val['max']}');
          }
        });
        return parts.join(' | ');
      }
      // Handle regular maps
      return value.entries
          .map((e) => '${e.key}: ${_formatMapValue(e.value)}')
          .join(', ');
    } else if (value is List) {
      if (value.isEmpty) return 'Empty list';
      return value.map((item) => _formatMapValue(item)).join(', ');
    } else {
      return value.toString();
    }
  }

  // Helper to format nested map values
  String _formatMapValue(dynamic value) {
    if (value is Map) {
      if (value.isEmpty) return '{}';
      if (value.containsKey('min') && value.containsKey('max')) {
        return 'Min: ${value['min']}, Max: ${value['max']}';
      }
      return '{${value.entries.map((e) => '${e.key}: ${e.value}').join(', ')}}';
    }
    return value?.toString() ?? 'null';
  }
  
  // Helper method to get a nested value from a map using dot notation
  dynamic _getNestedValue(Map<String, dynamic>? map, String path) {
    if (map == null) return null;
    
    // For backward compatibility, try direct access first
    if (map.containsKey(path)) {
      return map[path];
    }
    
    // If not found directly, try dot notation
    final keys = path.split('.');
    dynamic value = map;
    
    try {
      for (final key in keys) {
        if (value is Map && value.containsKey(key)) {
          value = value[key];
        } else {
          // Key not found in dot notation
          value = null;
          break;
        }
      }
      
      // If value found with dot notation, return it
      if (value != null) {
        return value;
      }
    } catch (e) {
      // Error in dot notation access, continue to try underscore notation
    }
    
    // If not found with dot notation, try underscore notation
    final underscorePath = path.replaceAll('.', '_');
    if (map.containsKey(underscorePath)) {
      return map[underscorePath];
    }
    
    // Try to handle optimal_conditions special case
    if (path.startsWith('optimal_conditions_')) {
      final parts = path.split('_');
      if (parts.length >= 4) {
        // Try to reconstruct the path for nested access
        final stage = parts[2];
        final parameter = parts.sublist(3).join('_');
        
        // Try to access the value in various formats
        if (map.containsKey('optimal_conditions')) {
          final optimalConditions = map['optimal_conditions'];
          
          // Check if directly accessible
          if (optimalConditions is Map) {
            // Try direct stage access first
            if (optimalConditions.containsKey(stage)) {
              final stageData = optimalConditions[stage];
              if (stageData is Map && stageData.containsKey(parameter)) {
                return stageData[parameter];
              }
            }
            
            // Try with various parameter formats
            final possibleParams = [
              parameter,
              '${parameter}_range',
              parameter.replaceAll('_', '.')
            ];
            
            for (final param in possibleParams) {
              if (optimalConditions.containsKey('$stage.$param')) {
                return optimalConditions['$stage.$param'];
              }
            }
            
            // Try looking for stage as a direct key with a different format
            final stageKeys = optimalConditions.keys.where(
              (key) => key.toString().startsWith('$stage.')
            );
            
            for (final stageKey in stageKeys) {
              final stageData = optimalConditions[stageKey];
              if (stageData is Map) {
                final possibleKeys = [parameter, parameter.replaceAll('_', '.')];
                for (final possibleKey in possibleKeys) {
                  if (stageData.containsKey(possibleKey)) {
                    return stageData[possibleKey];
                  }
                }
              }
            }
          }
        }
      }
    }
    
    return null;
  }
} 