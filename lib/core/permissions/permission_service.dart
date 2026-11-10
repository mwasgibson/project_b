import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

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
  final ph.PermissionStatus foreground;

  /// Always / background location granted.
  final ph.PermissionStatus background;

  bool get hasForeground =>
      foreground.isGranted || foreground.isLimited;

  bool get hasBackground => background.isGranted;

  bool get foregroundPermanentlyDenied =>
      foreground.isPermanentlyDenied;

  bool get backgroundPermanentlyDenied =>
      background.isPermanentlyDenied;
}

/// Wraps permission_handler so screens do not import the package directly.
/// Tracking itself stays behind LocationTracker (Phase 3).
class PermissionService {
  Future<bool> isLocationServiceEnabled() =>
      ph.Permission.location.serviceStatus.isEnabled;

  Future<LocationPermissionSnapshot> snapshot() async {
    final serviceEnabled = await isLocationServiceEnabled();
    final foreground = await ph.Permission.locationWhenInUse.status;
    final background = await ph.Permission.locationAlways.status;
    return LocationPermissionSnapshot(
      serviceEnabled: serviceEnabled,
      foreground: foreground,
      background: background,
    );
  }

  /// Request while-in-use first (F1 / Flow A step 2).
  Future<ph.PermissionStatus> requestForeground() =>
      ph.Permission.locationWhenInUse.request();

  /// Request Always / background. Call only after the in-app disclosure (S3).
  Future<ph.PermissionStatus> requestBackground() =>
      ph.Permission.locationAlways.request();

  Future<ph.PermissionStatus> requestNotifications() =>
      ph.Permission.notification.request();

  Future<ph.PermissionStatus> notificationStatus() =>
      ph.Permission.notification.status;

  /// Opens the OS settings page for this app.
  Future<bool> openSystemAppSettings() => ph.openAppSettings();

  /// Whether we are on a platform that supports these permission APIs.
  bool get isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);
}
