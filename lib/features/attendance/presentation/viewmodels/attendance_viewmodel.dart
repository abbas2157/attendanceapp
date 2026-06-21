import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_result.dart';
import '../../../../core/services/attendance_code_storage.dart';
import '../../../../core/services/device_info_service.dart';
import '../../../../core/utils/location_service.dart';
import '../../../home/data/models/warehouse_model.dart';
import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository.dart';

part 'attendance_viewmodel.g.dart';

enum AttendanceScreenState {
  claimEntry,
  scanReady,
  scanning,
  processing,
  result,
}

class AttendanceState {
  final AttendanceScreenState screenState;
  final Position position;
  final WarehouseModel activeWarehouse;
  final bool isFaceDetected;
  final AttendanceResponse? result;
  final String? errorMessage;
  final double? confidence;
  final AttendanceClaimType claimType;
  final String employeeCode;
  final String attendanceCode;
  final bool hasMultipleFaces;
  final bool isPreparing;
  final List<String> recentEmployeeCodes;
  final List<String> recentAttendanceCodes;
  final String? fatalErrorMessage;
  final String? precheckEmployeeName;
  final String? precheckWarehouseName;

  const AttendanceState({
    this.screenState = AttendanceScreenState.claimEntry,
    required this.position,
    required this.activeWarehouse,
    this.isFaceDetected = false,
    this.result,
    this.errorMessage,
    this.confidence,
    this.claimType = AttendanceClaimType.employeeCode,
    this.employeeCode = '',
    this.attendanceCode = '',
    this.hasMultipleFaces = false,
    this.isPreparing = false,
    this.recentEmployeeCodes = const [],
    this.recentAttendanceCodes = const [],
    this.fatalErrorMessage,
    this.precheckEmployeeName,
    this.precheckWarehouseName,
  });

  String get activeClaimCode {
    return claimType == AttendanceClaimType.employeeCode
        ? employeeCode
        : attendanceCode;
  }

  List<String> get activeRecentCodes {
    return claimType == AttendanceClaimType.employeeCode
        ? recentEmployeeCodes
        : recentAttendanceCodes;
  }

  AttendanceState copyWith({
    AttendanceScreenState? screenState,
    bool? isFaceDetected,
    AttendanceResponse? result,
    String? errorMessage,
    double? confidence,
    AttendanceClaimType? claimType,
    String? employeeCode,
    String? attendanceCode,
    bool? hasMultipleFaces,
    bool? isPreparing,
    List<String>? recentEmployeeCodes,
    List<String>? recentAttendanceCodes,
    String? fatalErrorMessage,
    String? precheckEmployeeName,
    String? precheckWarehouseName,
    bool clearResult = false,
    bool clearError = false,
    bool clearFatalError = false,
    bool clearPrecheck = false,
  }) {
    return AttendanceState(
      screenState: screenState ?? this.screenState,
      position: position,
      activeWarehouse: activeWarehouse,
      isFaceDetected: isFaceDetected ?? this.isFaceDetected,
      result: clearResult ? null : result ?? this.result,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      confidence: confidence ?? this.confidence,
      claimType: claimType ?? this.claimType,
      employeeCode: employeeCode ?? this.employeeCode,
      attendanceCode: attendanceCode ?? this.attendanceCode,
      hasMultipleFaces: hasMultipleFaces ?? this.hasMultipleFaces,
      isPreparing: isPreparing ?? this.isPreparing,
      recentEmployeeCodes: recentEmployeeCodes ?? this.recentEmployeeCodes,
      recentAttendanceCodes:
          recentAttendanceCodes ?? this.recentAttendanceCodes,
      fatalErrorMessage: clearFatalError
          ? null
          : fatalErrorMessage ?? this.fatalErrorMessage,
      precheckEmployeeName: clearPrecheck
          ? null
          : precheckEmployeeName ?? this.precheckEmployeeName,
      precheckWarehouseName: clearPrecheck
          ? null
          : precheckWarehouseName ?? this.precheckWarehouseName,
    );
  }
}

@riverpod
class AttendanceViewModel extends _$AttendanceViewModel {
  late final FaceDetector _faceDetector;

  @override
  AttendanceState build({
    required Position initialPosition,
    required WarehouseModel activeWarehouse,
  }) {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.15,
      ),
    );
    ref.onDispose(() => _faceDetector.close());

    Future.microtask(_loadRecentCodes);

    return AttendanceState(
      position: initialPosition,
      activeWarehouse: activeWarehouse,
    );
  }

  Future<void> _loadRecentCodes() async {
    final employeeCodes = await AttendanceCodeStorage.loadCodes(
      AttendanceClaimType.employeeCode,
    );
    final attendanceCodes = await AttendanceCodeStorage.loadCodes(
      AttendanceClaimType.attendanceCode,
    );
    state = state.copyWith(
      recentEmployeeCodes: employeeCodes,
      recentAttendanceCodes: attendanceCodes,
    );
  }

  void setClaimType(AttendanceClaimType value) {
    state = state.copyWith(
      claimType: value,
      clearError: true,
      clearFatalError: true,
    );
  }

  void setClaimCode(String value) {
    final cleaned = value.trim();
    if (state.claimType == AttendanceClaimType.employeeCode) {
      state = state.copyWith(
        employeeCode: cleaned,
        clearError: true,
        clearFatalError: true,
        clearPrecheck: true,
      );
      return;
    }

    state = state.copyWith(
      attendanceCode: cleaned,
      clearError: true,
      clearFatalError: true,
      clearPrecheck: true,
    );
  }

  Future<bool> startScanning() async {
    final claimCode = state.activeClaimCode.trim();
    if (claimCode.isEmpty) {
      state = state.copyWith(
        errorMessage: state.claimType == AttendanceClaimType.employeeCode
            ? 'Enter employee code before scanning.'
            : 'Enter attendance code before scanning.',
      );
      return false;
    }

    state = state.copyWith(
      isPreparing: true,
      clearError: true,
      clearFatalError: true,
      clearPrecheck: true,
    );
    final locationService = ref.read(locationServiceProvider);
    final result = await ref
        .read(attendanceRepositoryProvider)
        .precheckAttendance(
          currentLocation: locationService.positionToString(state.position),
          claimType: state.claimType,
          claimCode: claimCode,
        );

    switch (result) {
      case ApiSuccess(:final data):
        if (!data.allowed) {
          state = state.copyWith(
            isPreparing: false,
            errorMessage: data.message,
          );
          return false;
        }
        state = state.copyWith(
          precheckEmployeeName: data.employeeName,
          precheckWarehouseName:
              data.warehouseFullName ?? data.warehouseShortName,
        );
      case ApiError(:final message):
        state = state.copyWith(isPreparing: false, errorMessage: message);
        return false;
    }

    state = state.copyWith(
      screenState: AttendanceScreenState.scanReady,
      isPreparing: false,
      clearError: true,
      clearResult: true,
      isFaceDetected: false,
      hasMultipleFaces: false,
    );
    return true;
  }

  Future<bool> processPhoto(File photo) async {
    try {
      final faces = await _faceDetector.processImage(
        InputImage.fromFilePath(photo.path),
      );

      if (faces.isEmpty) {
        state = state.copyWith(
          isFaceDetected: false,
          hasMultipleFaces: false,
          clearError: true,
        );
        await photo.delete();
        return true;
      }

      if (faces.length > 1) {
        state = state.copyWith(
          isFaceDetected: false,
          hasMultipleFaces: true,
          errorMessage: 'Only one face should be visible in the frame.',
        );
        await photo.delete();
        return true;
      }

      final faceIssue = _validateVerificationFace(faces.first);
      if (faceIssue != null) {
        state = state.copyWith(
          isFaceDetected: false,
          hasMultipleFaces: false,
          errorMessage: faceIssue,
        );
        await photo.delete();
        return true;
      }

      state = state.copyWith(
        isFaceDetected: true,
        hasMultipleFaces: false,
        screenState: AttendanceScreenState.scanning,
        clearError: true,
      );
      await Future.delayed(const Duration(milliseconds: 250));

      await _submitFrame(photo);
      return false;
    } catch (e) {
      debugPrint('Attendance processPhoto error: $e');
      await photo.delete();
      state = state.copyWith(
        screenState: AttendanceScreenState.claimEntry,
        fatalErrorMessage: 'Unable to process camera frame. Please try again.',
        isFaceDetected: false,
      );
      return false;
    }
  }

  Future<void> _submitFrame(File photo) async {
    state = state.copyWith(screenState: AttendanceScreenState.processing);

    final locationService = ref.read(locationServiceProvider);

    try {
      final deviceInfo = await DeviceInfoService.attendanceDeviceInfo();
      final result = await ref
          .read(attendanceRepositoryProvider)
          .markAttendance(
            framePath: photo.path,
            currentLocation: locationService.positionToString(state.position),
            claimType: state.claimType,
            claimCode: state.activeClaimCode,
            deviceInfo: deviceInfo,
          );

      switch (result) {
        case ApiSuccess(:final data):
          await AttendanceCodeStorage.saveCode(
            state.claimType,
            state.activeClaimCode,
          );
          await _loadRecentCodes();
          state = state.copyWith(
            screenState: AttendanceScreenState.result,
            result: data,
            confidence: data.confidence,
          );
        case ApiError(:final message):
          state = state.copyWith(
            screenState: AttendanceScreenState.claimEntry,
            isFaceDetected: false,
            fatalErrorMessage: message,
          );
      }
    } catch (e) {
      debugPrint('Attendance submit error: $e');
      state = state.copyWith(
        screenState: AttendanceScreenState.claimEntry,
        isFaceDetected: false,
        fatalErrorMessage: 'Unexpected error. Please try again.',
      );
    } finally {
      if (await photo.exists()) {
        await photo.delete();
      }
    }
  }

  void retry() {
    state = state.copyWith(
      screenState: AttendanceScreenState.scanReady,
      clearResult: true,
      clearError: true,
      clearFatalError: true,
      isFaceDetected: false,
      hasMultipleFaces: false,
    );
  }

  void editClaim() {
    state = state.copyWith(
      screenState: AttendanceScreenState.claimEntry,
      clearError: true,
      clearFatalError: true,
      clearResult: true,
      isFaceDetected: false,
      hasMultipleFaces: false,
    );
  }

  String? _validateVerificationFace(Face face) {
    final box = face.boundingBox;
    if (box.width < 140 || box.height < 140) {
      return 'Move closer to the camera so the face fills more of the frame.';
    }

    final yaw = face.headEulerAngleY;
    if (yaw != null && yaw.abs() > 18) {
      return 'Look straight at the camera before attendance is captured.';
    }

    final roll = face.headEulerAngleZ;
    if (roll != null && roll.abs() > 15) {
      return 'Keep your head upright for attendance capture.';
    }

    final faceRatio =
        math.min(box.width, box.height) / math.max(box.width, box.height);
    if (faceRatio < 0.65) {
      return 'Hold the camera steady and keep the full face visible.';
    }

    return null;
  }
}
