import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_error_handler.dart';
import '../models/employee_model.dart';

part 'employee_repository.g.dart';

@riverpod
EmployeeRepository employeeRepository(Ref ref) {
  return EmployeeRepository(ref.watch(dioClientProvider));
}

class EmployeeRepository {
  final Dio _dio;

  EmployeeRepository(this._dio);

  Future<ApiResult<Map<String, dynamic>>> addEmployee(
    AddEmployeeRequest request,
  ) async {
    try {
      final photoFiles = <MultipartFile>[];
      for (var index = 0; index < request.photoPaths.length; index++) {
        photoFiles.add(
          await MultipartFile.fromFile(
            request.photoPaths[index],
            filename: 'employee_sample_${index + 1}.jpg',
          ),
        );
      }

      final formData = FormData.fromMap({
        'employeecode': request.employeecode,
        'name': request.name,
        'fathername': request.fathername,
        'attendancecode': request.attendancecode,
        'warehouseid': request.warehouseid,
        'capture_session_id': request.captureSessionId,
        if (request.latlong != null) 'latlong': request.latlong,
        'photos': photoFiles,
        'angle_labels': request.angleLabels,
      });

      final response = await _dio.post(
        AppConstants.addEmployeeEndpoint,
        data: formData,
      );

      return ApiSuccess(response.data as Map<String, dynamic>);
    } catch (e) {
      return NetworkErrorHandler.handle(e);
    }
  }

  Future<ApiResult<List<EmployeeModel>>> getEmployees() async {
    try {
      final response = await _dio.get(AppConstants.addEmployeeEndpoint);
      final list = (response.data as List)
          .map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiSuccess(list);
    } catch (e) {
      return NetworkErrorHandler.handle(e);
    }
  }
}
