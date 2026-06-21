import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_error_handler.dart';
import '../models/attendance_model.dart';

part 'attendance_repository.g.dart';

@riverpod
AttendanceRepository attendanceRepository(Ref ref) {
  return AttendanceRepository(ref.watch(dioClientProvider));
}

class AttendanceRepository {
  final Dio _dio;

  AttendanceRepository(this._dio);

  Future<ApiResult<AttendancePrecheckResponse>> precheckAttendance({
    required String currentLocation,
    required AttendanceClaimType claimType,
    required String claimCode,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.precheckAttendanceEndpoint,
        data: {
          'currentlocation': currentLocation,
          if (claimType == AttendanceClaimType.employeeCode)
            'employeecode': claimCode
          else
            'attendancecode': claimCode,
        },
      );

      return ApiSuccess(
        AttendancePrecheckResponse.fromJson(
          response.data as Map<String, dynamic>,
        ),
      );
    } catch (e) {
      return NetworkErrorHandler.handle(e);
    }
  }

  Future<ApiResult<AttendanceResponse>> markAttendance({
    required String framePath,
    required String currentLocation,
    required AttendanceClaimType claimType,
    required String claimCode,
    String? deviceInfo,
  }) async {
    try {
      final formData = FormData.fromMap({
        'currentlocation': currentLocation,
        if (claimType == AttendanceClaimType.employeeCode)
          'employeecode': claimCode
        else
          'attendancecode': claimCode,
        if (deviceInfo != null && deviceInfo.isNotEmpty)
          'deviceinfo': deviceInfo,
        'frame': await MultipartFile.fromFile(framePath, filename: 'frame.jpg'),
      });

      final response = await _dio.post(
        AppConstants.markAttendanceEndpoint,
        data: formData,
      );

      return ApiSuccess(
        AttendanceResponse.fromJson(response.data as Map<String, dynamic>),
      );
    } catch (e) {
      return NetworkErrorHandler.handle(e);
    }
  }
}
