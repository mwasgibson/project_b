import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Snapshot of the location-related permissions the app cares about.
class LocationPermissionSnapshot {
  const LocationPermissionSnapshot({
    required this.serviceEnabled,
    required this.foreground,
    required this.background,
  });

  /// Phone-level location services (GPS etc.) are on.
  final bool serviceEnabled;

  /// While-in-use / fine location granted.
  final PermissionStatus foreground;

  /// Always / background location granted.
  final PermissionStatus background;

  bool get hasForeground =>
      foreground.isGranted || foreground.isLimited;

  bool get hasBackground => background.isGranted;

  bool get foregroundPermanentlyDenied =>
      foreground.isPermanentlyDenied;

  bool get backgroundPermanentlyDenied =>
      background.isPermanentlyDenied;
}

/// Wraps [permission_handler] so screens do not import the package directly.
/// Tracking itself stays behind [LocationTracker] (Phase 3).
class PermissionService {
  Future<bool> isLocationServiceEnabled() =>
      Permission.location.serviceStatus.isEnabled;

  Future<LocationPermissionSnapshot> snapshot() async {
    final serviceEnabled = await isLocationServiceEnabled();
    final foreground = await Permission.locationWhenInUse.status;
    // On Android, background is a separate permission; on iOS, Always.
    final background = await Permission.locationAlways.status;
    return LocationPermissionSnapshot(
      serviceEnabled: serviceEnabled,
      foreground: foreground,
      background: background,
    );
  }

  /// Request while-in-use first (F1 / Flow A step 2).
  Future<PermissionStatus> requestForeground() =>
      Permission.locationWhenInUse.request();

  /// Request Always / background. Call only after the in-app disclosure (S3).
  Future<PermissionStatus> requestBackground() =>
      Permission.locationAlways.request();

  Future<PermissionStatus> requestNotifications() =>
      Permission.notification.request();

  Future<PermissionStatus> notificationStatus() =>
      Permission.notification.status;

  /// Opens the OS settings page for this app.
  Future<bool> openAppSettings() => openAppSettings();

  /// Whether we are on a platform that supports these permission APIs.
  bool get isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);
}
