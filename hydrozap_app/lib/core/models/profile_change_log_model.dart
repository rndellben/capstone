import 'package:hive/hive.dart';
import 'dart:convert'; // Added for json.decode

part 'profile_change_log_model.g.dart';

@HiveType(typeId: 12)
class ProfileChangeLog {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String profileId;
  
  @HiveField(2)
  final String userId;
  
  @HiveField(3)
  final String userName;
  
  @HiveField(4)
  final DateTime timestamp;
  
  @HiveField(5)
  final Map<String, dynamic> changedFields;
  
  @HiveField(6)
  final Map<String, dynamic> previousValues;
  
  @HiveField(7)
  final Map<String, dynamic> newValues;
  
  @HiveField(8)
  final String changeType; // 'create', 'update', 'delete'
  
  @HiveField(9)
  final bool synced;

  ProfileChangeLog({
    required this.id,
    required this.profileId,
    required this.userId,
    required this.userName,
    required this.timestamp,
    required this.changedFields,
    required this.previousValues,
    required this.newValues,
    required this.changeType,
    this.synced = false,
  });

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'user_id': userId,
      'user_name': userName,
      'timestamp': timestamp.toIso8601String(),
      'changed_fields': changedFields,
      'previous_values': previousValues,
      'new_values': newValues,
      'change_type': changeType,
    };
  }

  // Create from Map
  factory ProfileChangeLog.fromMap(String id, Map<String, dynamic> data) {
  
    
    // Ensure changed_fields is properly formatted as a Map
    Map<String, dynamic> changedFields = {};
    if (data['changed_fields'] != null) {
      if (data['changed_fields'] is Map) {
        changedFields = Map<String, dynamic>.from(data['changed_fields']);
      } else if (data['changed_fields'] is String) {
        try {
          // Try to parse from JSON string if it's stored that way
          changedFields = Map<String, dynamic>.from(
            json.decode(data['changed_fields'] as String)
          );
        } catch (e) {
          print('Error parsing changed_fields: $e');
        }
      }
    }
    
    // Ensure previous_values is properly formatted as a Map
    Map<String, dynamic> previousValues = {};
    if (data['previous_values'] != null) {
      if (data['previous_values'] is Map) {
        previousValues = Map<String, dynamic>.from(data['previous_values']);
      } else if (data['previous_values'] is String) {
        try {
          previousValues = Map<String, dynamic>.from(
            json.decode(data['previous_values'] as String)
          );
        } catch (e) {
          print('Error parsing previous_values: $e');
        }
      }
    }
    
    // Ensure new_values is properly formatted as a Map
    Map<String, dynamic> newValues = {};
    if (data['new_values'] != null) {
      if (data['new_values'] is Map) {
        newValues = Map<String, dynamic>.from(data['new_values']);
      } else if (data['new_values'] is String) {
        try {
          newValues = Map<String, dynamic>.from(
            json.decode(data['new_values'] as String)
          );
        } catch (e) {
          print('Error parsing new_values: $e');
        }
      }
    }
    
    return ProfileChangeLog(
      id: id,
      profileId: data['profile_id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      timestamp: data['timestamp'] != null 
          ? DateTime.parse(data['timestamp']) 
          : DateTime.now(),
      changedFields: changedFields,
      previousValues: previousValues,
      newValues: newValues,
      changeType: data['change_type'] ?? 'update',
      synced: data['synced'] ?? false,
    );
  }
  
  // Copy with method for updating fields
  ProfileChangeLog copyWith({
    String? id,
    String? profileId,
    String? userId,
    String? userName,
    DateTime? timestamp,
    Map<String, dynamic>? changedFields,
    Map<String, dynamic>? previousValues,
    Map<String, dynamic>? newValues,
    String? changeType,
    bool? synced,
  }) {
    return ProfileChangeLog(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      timestamp: timestamp ?? this.timestamp,
      changedFields: changedFields ?? this.changedFields,
      previousValues: previousValues ?? this.previousValues,
      newValues: newValues ?? this.newValues,
      changeType: changeType ?? this.changeType,
      synced: synced ?? this.synced,
    );
  }
} 