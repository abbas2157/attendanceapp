// lib/features/home/data/repositories/warehouse_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_error_handler.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/warehouse_model.dart';

part 'warehouse_repository.g.dart';

@riverpod
WarehouseRepository warehouseRepository(Ref ref) {
  return WarehouseRepository(ref.watch(dioClientProvider));
}

class WarehouseRepository {
  final Dio _dio;

  WarehouseRepository(this._dio);

  Future<ApiResult<List<WarehouseModel>>> getWarehouses() async {
    try {
      final response = await _dio.get(AppConstants.warehousesEndpoint);
      final data = response.data as List;
      final warehouses = data
          .map((e) => WarehouseModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (kDebugMode) {
        print('Fetched Warehouses: ${warehouses.length}');
      }
      return ApiSuccess(warehouses);
    } catch (e) {
      return NetworkErrorHandler.handle(e);
    }
  }
}
