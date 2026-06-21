// lib/features/home/presentation/viewmodels/home_viewmodel.dart
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/location_service.dart';
import '../../data/models/warehouse_model.dart';
import '../../data/repositories/warehouse_repository.dart';

part 'home_viewmodel.g.dart';

// ── Result returned to HomeScreen when user taps "Mark Attendance" ────────────
sealed class AttendanceCheckResult {}

class AttendanceCheckSuccess extends AttendanceCheckResult {
  final Position position;
  final WarehouseModel warehouse;
  AttendanceCheckSuccess({required this.position, required this.warehouse});
}

class AttendanceCheckFailure extends AttendanceCheckResult {
  final AttendanceCheckError error;
  final String message;
  AttendanceCheckFailure({required this.error, required this.message});
}

enum AttendanceCheckError {
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
  locationTimeout,
  outsidePremises,
  warehouseFetchFailed,
}

// ── Home State ────────────────────────────────────────────────────────────────
class HomeState {
  final bool isLoadingLocation;
  final bool isLoadingWarehouses;
  final bool isCheckingAttendanceLocation; // spinner on Mark Attendance button
  final Position? position;
  final String? address;
  final List<WarehouseModel> warehouses;
  final WarehouseModel? activeWarehouse;
  final String? errorMessage;

  const HomeState({
    this.isLoadingLocation = true,
    this.isLoadingWarehouses = true,
    this.isCheckingAttendanceLocation = false,
    this.position,
    this.address,
    this.warehouses = const [],
    this.activeWarehouse,
    this.errorMessage,
  });

  bool get isInPremises => activeWarehouse != null;
  String get locationString =>
      position != null ? '${position!.latitude},${position!.longitude}' : '';

  HomeState copyWith({
    bool? isLoadingLocation,
    bool? isLoadingWarehouses,
    bool? isCheckingAttendanceLocation,
    Position? position,
    String? address,
    List<WarehouseModel>? warehouses,
    WarehouseModel? activeWarehouse,
    String? errorMessage,
    bool clearWarehouse = false,
    bool clearError = false,
  }) {
    return HomeState(
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      isLoadingWarehouses: isLoadingWarehouses ?? this.isLoadingWarehouses,
      isCheckingAttendanceLocation:
          isCheckingAttendanceLocation ?? this.isCheckingAttendanceLocation,
      position: position ?? this.position,
      address: address ?? this.address,
      warehouses: warehouses ?? this.warehouses,
      activeWarehouse: clearWarehouse
          ? null
          : activeWarehouse ?? this.activeWarehouse,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────
@riverpod
class HomeViewModel extends _$HomeViewModel {
  @override
  HomeState build() {
    Future.microtask(_initialize);
    return const HomeState();
  }

  Future<void> _initialize() async {
    await Future.wait([_fetchLocation(), _fetchWarehouses()]);
    _checkGeofence();
  }

  Future<void> _fetchLocation() async {
    state = state.copyWith(isLoadingLocation: true);
    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentPosition();

    if (position == null) {
      state = state.copyWith(
        isLoadingLocation: false,
        errorMessage: 'Location permission denied.',
      );
      return;
    }

    final address = await locationService.getReadableAddress(
      position.latitude,
      position.longitude,
    );

    state = state.copyWith(
      isLoadingLocation: false,
      position: position,
      address: address,
    );
  }

  Future<void> _fetchWarehouses() async {
    state = state.copyWith(isLoadingWarehouses: true);
    final result = await ref.read(warehouseRepositoryProvider).getWarehouses();
    switch (result) {
      case ApiSuccess(:final data):
        state = state.copyWith(isLoadingWarehouses: false, warehouses: data);
      case ApiError(:final message):
        state = state.copyWith(
          isLoadingWarehouses: false,
          errorMessage: message,
        );
    }
  }

  void _checkGeofence() {
    final pos = state.position;
    if (pos == null || state.warehouses.isEmpty) return;

    final locationService = ref.read(locationServiceProvider);
    WarehouseModel? found;

    for (final w in state.warehouses) {
      if (w.latlong == null || w.latlong == '0,0' || w.status != 1) continue;
      final parts = w.latlong!.split(',');
      if (parts.length != 2) continue;
      final wLat = double.tryParse(parts[0].trim()) ?? 0;
      final wLng = double.tryParse(parts[1].trim()) ?? 0;
      final distance = locationService.distanceInMeters(
        pos.latitude,
        pos.longitude,
        wLat,
        wLng,
      );
      if (distance <= AppConstants.geofenceRadius) {
        found = w;
        break;
      }
    }

    state = state.copyWith(
      activeWarehouse: found,
      clearWarehouse: found == null,
    );
  }

  /// Called when user taps "Mark Attendance".
  /// Re-fetches location fresh (user may have moved since home loaded),
  /// checks geofence, returns a sealed result for the UI to act on.
  Future<AttendanceCheckResult> checkLocationForAttendance() async {
    state = state.copyWith(isCheckingAttendanceLocation: true);

    final locationService = ref.read(locationServiceProvider);

    // Fresh location fetch with failure reason
    final locationResult = await locationService.getCurrentPositionWithReason();

    if (!locationResult.isSuccess) {
      state = state.copyWith(isCheckingAttendanceLocation: false);
      return switch (locationResult.failReason!) {
        LocationFailReason.permissionDenied => AttendanceCheckFailure(
          error: AttendanceCheckError.permissionDenied,
          message: 'Location permission is required to mark attendance.',
        ),
        LocationFailReason.permissionDeniedForever => AttendanceCheckFailure(
          error: AttendanceCheckError.permissionPermanentlyDenied,
          message:
              'Location permission is permanently denied. Please enable it from app settings.',
        ),
        LocationFailReason.serviceDisabled => AttendanceCheckFailure(
          error: AttendanceCheckError.serviceDisabled,
          message: 'GPS is turned off. Please enable location services.',
        ),
        LocationFailReason.timeout => AttendanceCheckFailure(
          error: AttendanceCheckError.locationTimeout,
          message:
              'Could not fetch your location. Please check your GPS signal and try again.',
        ),
      };
    }

    final pos = locationResult.position!;

    // Fetch warehouses if not loaded yet
    if (state.warehouses.isEmpty) {
      final result = await ref
          .read(warehouseRepositoryProvider)
          .getWarehouses();
      switch (result) {
        case ApiSuccess(:final data):
          state = state.copyWith(warehouses: data);
        case ApiError(:final message):
          state = state.copyWith(isCheckingAttendanceLocation: false);
          return AttendanceCheckFailure(
            error: AttendanceCheckError.warehouseFetchFailed,
            message: message,
          );
      }
    }

    // Geofence check
    WarehouseModel? found;
    for (final w in state.warehouses) {
      if (w.latlong == null || w.latlong == '0,0' || w.status != 1) continue;
      final parts = w.latlong!.split(',');
      if (parts.length != 2) continue;
      final wLat = double.tryParse(parts[0].trim()) ?? 0;
      final wLng = double.tryParse(parts[1].trim()) ?? 0;
      final distance = locationService.distanceInMeters(
        pos.latitude,
        pos.longitude,
        wLat,
        wLng,
      );
      if (distance <= AppConstants.geofenceRadius) {
        found = w;
        break;
      }
    }

    state = state.copyWith(isCheckingAttendanceLocation: false);

    if (found == null) {
      return AttendanceCheckFailure(
        error: AttendanceCheckError.outsidePremises,
        message:
            'You are not within any authorized warehouse premises.\n\nPlease move to your assigned location and try again.',
      );
    }

    return AttendanceCheckSuccess(position: pos, warehouse: found);
  }

  Future<void> refresh() async {
    state = const HomeState();
    await _initialize();
  }
}
