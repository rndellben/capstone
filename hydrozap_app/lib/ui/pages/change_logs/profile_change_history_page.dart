import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/profile_change_log_model.dart';
import '../../../providers/grow_profile_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/local/shared_prefs.dart';

class ProfileChangeHistoryPage extends StatefulWidget {
  final String profileId;
  final String profileName;

  const ProfileChangeHistoryPage({
    Key? key,
    required this.profileId,
    required this.profileName,
  }) : super(key: key);

  @override
  _ProfileChangeHistoryPageState createState() => _ProfileChangeHistoryPageState();
}

class _ProfileChangeHistoryPageState extends State<ProfileChangeHistoryPage> {
  bool _isLoading = true;
  List<ProfileChangeLog> _changeLogs = [];

  @override
  void initState() {
    super.initState();
    _loadChangeLogs();
    _checkCurrentUsername(); // Add this line
  }

  // Add this new method
  Future<void> _checkCurrentUsername() async {
    final username = await SharedPrefs.getUserName();
    print('Current username in SharedPrefs (profile history): $username');
  }

  Future<void> _loadChangeLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<GrowProfileProvider>(context, listen: false);
      final logs = await provider.getProfileChangeLogs(widget.profileId);
      
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
        title: Text('Change History: ${widget.profileName}'),
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
      return const Center(
        child: Text(
          'No changes have been recorded for this profile yet.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
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

    return InkWell(
      onTap: () => _showDetailedChangeLog(changeLog),
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
                        changeTypeText,
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
  void _showDetailedChangeLog(ProfileChangeLog changeLog) {
    final formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(changeLog.timestamp);
    final changedFields = changeLog.changedFields.keys.toList();
    
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
                      '${_capitalize(changeLog.changeType)} Profile',
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
                      _buildDetailRow('Profile', widget.profileName),
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
        ...changedFields.map((field) => _buildChangedFieldItem(field, changeLog)),
      ],
    );
  }

  Widget _buildChangedFieldItem(String field, ProfileChangeLog changeLog, {bool detailed = false}) {
    // Format field name for display
    String displayField = field.replaceAll('_', ' ')
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
        final parameter = parts.sublist(3).join(' ');
        displayField = 'Optimal Conditions › ${_capitalize(stage)} › ${_capitalize(parameter)}';
      }
    } else if (field.startsWith('optimal_conditions.')) {
      // Handle dot notation format
      final parts = field.split('.');
      if (parts.length >= 3) {
        final stage = parts[1];
        final parameter = parts[2].replaceAll('_', ' ');
        displayField = 'Optimal Conditions › ${_capitalize(stage)} › ${_capitalize(parameter)}';
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
          if (changeLog.changeType != 'create')
            Row(
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
                  ),
                ),
              ],
            ),
          if (changeLog.changeType != 'delete')
            Row(
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
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  // Helper method to capitalize first letter
  String _capitalize(String text) {
    return text.isNotEmpty ? '${text[0].toUpperCase()}${text.substring(1)}' : '';
  }
  
  // Helper method to get a nested value from a map using dot notation
  dynamic _getNestedValue(Map<String, dynamic> map, String path) {
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
        
        if (map.containsKey('optimal_conditions') && 
            map['optimal_conditions'] is Map && 
            map['optimal_conditions'].containsKey(stage) &&
            map['optimal_conditions'][stage] is Map &&
            map['optimal_conditions'][stage].containsKey(parameter)) {
          return map['optimal_conditions'][stage][parameter];
        }
      }
    }
    
    return null;
  }
  
  // Helper method to format a value for display
  String _formatValueForDisplay(dynamic value) {
    if (value == null) {
      return 'Not set';
    } else if (value is bool) {
      return value ? 'Yes' : 'No';
    } else if (value is Map) {
      if (value.containsKey('min') && value.containsKey('max')) {
        return 'Min: ${value['min']}, Max: ${value['max']}';
      }
      return value.toString();
    } else if (value is List) {
      return value.join(', ');
    } else {
      return value.toString();
    }
  }
} 