import 'package:hive/hive.dart';

part 'pending_sync_item.g.dart';

/// PendingSyncItem is a generic model to track pending synchronization items.
/// Each item represents a record that needs to be synchronized with the remote database.
@HiveType(typeId: 10)
class PendingSyncItem {
  /// Unique identifier for the pending sync item
  @HiveField(0)
  final String id;
  
  /// Type of the item (e.g., 'device', 'grow_profile', 'harvest_log', etc.)
  @HiveField(1)
  final String itemType;
  
  /// The operation to perform (e.g., 'create', 'update', 'delete')
  @HiveField(2)
  final String operation;
  
  /// The serialized data of the item to sync
  @HiveField(3)
  final Map<String, dynamic> data;
  
  /// When this item was created locally
  @HiveField(4)
  final DateTime createdAt;
  
  /// Whether a sync has been attempted but failed
  @HiveField(5)
  final bool syncFailed;
  
  /// Number of failed sync attempts
  @HiveField(6)
  final int syncAttempts;
  
  /// Last time a sync was attempted
  @HiveField(7)
  final DateTime? lastSyncAttempt;

  PendingSyncItem({
    required this.id,
    required this.itemType,
    required this.operation,
    required this.data,
    DateTime? createdAt,
    this.syncFailed = false,
    this.syncAttempts = 0,
    this.lastSyncAttempt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  /// Convert to Map for storage or transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_type': itemType,
      'operation': operation,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'sync_failed': syncFailed,
      'sync_attempts': syncAttempts,
      'last_sync_attempt': lastSyncAttempt?.toIso8601String(),
    };
  }
  
  /// Create from Map for storage retrieval
  factory PendingSyncItem.fromJson(Map<String, dynamic> json) {
    return PendingSyncItem(
      id: json['id'],
      itemType: json['item_type'],
      operation: json['operation'],
      data: Map<String, dynamic>.from(json['data']),
      createdAt: DateTime.parse(json['created_at']),
      syncFailed: json['sync_failed'] ?? false,
      syncAttempts: json['sync_attempts'] ?? 0,
      lastSyncAttempt: json['last_sync_attempt'] != null 
          ? DateTime.parse(json['last_sync_attempt']) 
          : null,
    );
  }
  
  /// Create a copy with updated fields
  PendingSyncItem copyWith({
    String? id,
    String? itemType,
    String? operation,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? syncFailed,
    int? syncAttempts,
    DateTime? lastSyncAttempt,
  }) {
    return PendingSyncItem(
      id: id ?? this.id,
      itemType: itemType ?? this.itemType,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      syncFailed: syncFailed ?? this.syncFailed,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
    );
  }
  
  /// Mark this item as having a failed sync attempt
  PendingSyncItem markSyncFailed() {
    return copyWith(
      syncFailed: true,
      syncAttempts: syncAttempts + 1,
      lastSyncAttempt: DateTime.now(),
    );
  }
  
  /// Reset sync failure status (e.g., when trying again)
  PendingSyncItem resetSyncStatus() {
    return copyWith(
      syncFailed: false,
    );
  }
} 