import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_error_handler.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/auth_model.dart';
part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(dioClientProvider));
}

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<ApiResult<AuthModel>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: {'username': username, 'password': password},
      );
      return ApiSuccess(
        AuthModel.fromJson(response.data as Map<String, dynamic>),
      );
    } catch (e) {
      return NetworkErrorHandler.handle(e);
    }
  }
}
