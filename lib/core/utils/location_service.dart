// lib/core/utils/location_service.dart
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_service.g.dart';

@riverpod
LocationService locationService(Ref ref) => LocationService();

enum LocationFailReason {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  timeout,
}

class LocationResult {
  final Position? position;
  final LocationFailReason? failReason;

  const LocationResult.success(this.position) : failReason = null;
  const LocationResult.failure(this.failReason) : position = null;

  bool get isSuccess => position != null;
}

class LocationService {
  /// Returns a LocationResult so callers know WHY it failed.
  Future<LocationResult> getCurrentPositionWithReason() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult.failure(LocationFailReason.serviceDisabled);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationResult.failure(
          LocationFailReason.permissionDenied,
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult.failure(
        LocationFailReason.permissionDeniedForever,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).timeout(const Duration(seconds: 15));
      return LocationResult.success(position);
    } catch (_) {
      return const LocationResult.failure(LocationFailReason.timeout);
    }
  }

  /// Original method kept for backward compatibility (home screen address fetch etc.)
  Future<Position?> getCurrentPosition() async {
    final result = await getCurrentPositionWithReason();
    return result.position;
  }

  String positionToString(Position pos) => '${pos.latitude},${pos.longitude}';

  Future<String> getReadableAddress(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return 'Unknown location';
      final p = placemarks.first;
      final parts = [
        p.name,
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
      ].where((e) => e != null && e.isNotEmpty).toList();
      return parts.take(3).join(', ');
    } catch (_) {
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }

  double distanceInMeters(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;
}
