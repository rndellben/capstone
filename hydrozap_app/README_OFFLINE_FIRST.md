# HydroZap Offline-First Architecture

This document provides an overview of the offline-first architecture implemented in the HydroZap app.

## Overview

The HydroZap app uses an offline-first architecture to ensure that users can continue using the app even when they are offline. The app stores data locally using Hive, and synchronizes with Firebase Realtime Database when the device is online.

## Key Components

### Models

All models have been enhanced to support offline capabilities:

- `DeviceModel`
- `GrowProfileModel`
- `GrowModel`
- `AlertModel`
- `HarvestLogModel`
- `PendingSyncItem`

Each model includes:
- A `synced` flag to track synchronization status
- A `lastUpdated` timestamp for conflict resolution
- A `copyWith` method for immutability
- Integration with Hive for local storage

### Services

#### Connectivity Service

Monitors the device's network connectivity status and notifies the app when the status changes.

```dart
// Usage example
if (connectivityService.isConnected) {
  // Perform online operation
} else {
  // Perform offline operation
}

// Listen for connectivity changes
connectivityService.connectivityStream.listen((isConnected) {
  if (isConnected) {
    // Device is online
  } else {
    // Device is offline
  }
});
```

#### Hive Service

Manages all local storage operations using Hive.

```dart
// Usage example
// Save data
await hiveService.saveDevice(device);

// Get data
final device = hiveService.getDevice(deviceId);

// Get all data
final devices = hiveService.getAllDevices();

// Delete data
await hiveService.deleteDevice(deviceId);
```

#### Sync Service

Manages the synchronization of data between the local database and the remote server.

```dart
// Usage example
// Force synchronization
await syncService.syncAll();

// Get sync status
final isSyncing = syncService.isSyncing;
final syncStatusText = syncService.getSyncStatusText();

// Listen for sync changes
syncService.syncStatusStream.listen((isSyncing) {
  if (isSyncing) {
    // Show sync indicator
  } else {
    // Hide sync indicator
  }
});
```

### Repositories

Repositories abstract the data access logic and implement the offline-first strategy:

- `DeviceRepository`
- `GrowProfileRepository`
- `AlertRepository`

Each repository follows these principles:

1. **Read operations**:
   - First check local storage for data
   - If online, try to sync first
   - Return local data if offline or sync fails

2. **Write operations**:
   - If online, try to update remote first, then update local
   - If offline or remote update fails, save locally with `synced: false` and add to pending sync items
   - When back online, process pending sync items

3. **Delete operations**:
   - If online, delete from remote first, then local
   - If offline or remote delete fails, mark for deletion locally and add to pending sync items

```dart
// Usage example
// Get data
final devices = await deviceRepository.getDevices();

// Create data
final createdDevice = await deviceRepository.createDevice(device);

// Update data
await deviceRepository.updateDevice(device);

// Delete data
await deviceRepository.deleteDevice(deviceId);

// Force sync
await deviceRepository.forceSync();

// Listen for changes
deviceRepository.devicesStream.listen((devices) {
  // Update UI with new data
});
```

## Offline Sync Flow

1. **User creates/updates/deletes data while offline**:
   - Data is saved locally with `synced: false`
   - A `PendingSyncItem` is created to track the operation

2. **Device comes online**:
   - `ConnectivityService` detects the network change
   - `SyncService` is notified to start synchronization
   - `PendingSyncItems` are processed in the order they were created
   - Successfully synced items are removed from the pending sync queue
   - Failed items are marked for retry

3. **Periodic sync**:
   - `SyncService` performs periodic syncs when online
   - Fetches fresh data from remote server
   - Updates local data

## Adding Offline Support to New Models

1. Update the model class:
   - Add `@HiveType` and `@HiveField` annotations
   - Add `synced` and `lastUpdated` fields
   - Implement `copyWith` method
   - Update `toJson` and `fromJson` methods

2. Create a Hive adapter for the model:
   - Define `read` and `write` methods
   - Register the adapter in `HiveService.initialize()`

3. Add methods to `HiveService` for the model:
   - `save`, `get`, `getAll`, and `delete` methods

4. Create a repository for the model:
   - Implement offline-first logic

5. Update the `SyncService` to include the new repository.

## UI Integration

- `ConnectivityStatusBar` widget displays the current connectivity and sync status.
- Add it to your app's layout to provide visibility into the offline/online state.

## Best Practices

1. **Offline-first mindset**: Design features assuming that the user might be offline.
2. **Optimistic updates**: Update the UI immediately after a user action, without waiting for server confirmation.
3. **Clear indicators**: Provide clear visual feedback about sync status.
4. **Conflict resolution**: Implement strategies for handling conflicts when the same data was edited both locally and remotely.
5. **Error handling**: Gracefully handle sync failures and provide retry mechanisms.

## Troubleshooting

- **Data not syncing**: Check if `ConnectivityService` is reporting the correct status
- **Duplicate data**: Ensure that sync operations respect the `lastUpdated` timestamp
- **Missing data after sync**: Verify that repositories correctly merge local and remote data
- **Sync errors**: Check `syncAttempts` and `syncFailed` flags in `PendingSyncItem` 