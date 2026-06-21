import 'dart:io';
import 'dart:math' as math;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_result.dart';
import '../../../home/data/models/warehouse_model.dart';
import '../../../home/data/repositories/warehouse_repository.dart';
import '../../data/models/employee_model.dart';
import '../../data/repositories/employee_repository.dart';

part 'add_user_viewmodel.g.dart';

enum AddUserStep { capture, form, processing, success }

class AddUserState {
  static const requiredAngleLabels = ['front', 'left', 'right'];

  final AddUserStep step;
  final List<File?> capturedImages;
  final List<WarehouseModel> warehouses;
  final bool isLoadingWarehouses;
  final WarehouseModel? selectedWarehouse;
  final bool isSubmitting;
  final String? successMessage;
  final String? errorMessage;

  const AddUserState({
    this.step = AddUserStep.capture,
    this.capturedImages = const [null, null, null],
    this.warehouses = const [],
    this.isLoadingWarehouses = true,
    this.selectedWarehouse,
    this.isSubmitting = false,
    this.successMessage,
    this.errorMessage,
  });

  bool get hasRequiredSamples => capturedImages.every((image) => image != null);

  AddUserState copyWith({
    AddUserStep? step,
    List<File?>? capturedImages,
    List<WarehouseModel>? warehouses,
    bool? isLoadingWarehouses,
    WarehouseModel? selectedWarehouse,
    bool? isSubmitting,
    String? successMessage,
    String? errorMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearWarehouse = false,
  }) {
    return AddUserState(
      step: step ?? this.step,
      capturedImages: capturedImages ?? this.capturedImages,
      warehouses: warehouses ?? this.warehouses,
      isLoadingWarehouses: isLoadingWarehouses ?? this.isLoadingWarehouses,
      selectedWarehouse: clearWarehouse
          ? null
          : selectedWarehouse ?? this.selectedWarehouse,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

@riverpod
class AddUserViewModel extends _$AddUserViewModel {
  late final FaceDetector _faceDetector;

  @override
  AddUserState build() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.18,
      ),
    );
    ref.onDispose(() => _faceDetector.close());
    Future.microtask(_loadWarehouses);
    return const AddUserState();
  }

  Future<void> _loadWarehouses() async {
    state = state.copyWith(isLoadingWarehouses: true);
    final result = await ref.read(warehouseRepositoryProvider).getWarehouses();

    switch (result) {
      case ApiSuccess(:final data):
        state = state.copyWith(
          isLoadingWarehouses: false,
          warehouses: data.where((w) => w.status == 1).toList(),
        );
      case ApiError(:final message):
        state = state.copyWith(
          isLoadingWarehouses: false,
          errorMessage: message,
        );
    }
  }

  Future<void> setPhotoAt(int index, File imageFile) async {
    final validationMessage = await _validateEnrollmentSample(
      imageFile,
      AddUserState.requiredAngleLabels[index],
    );
    if (validationMessage != null) {
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
      state = state.copyWith(errorMessage: validationMessage);
      return;
    }

    final images = List<File?>.from(state.capturedImages);
    images[index] = imageFile;
    state = state.copyWith(
      capturedImages: images,
      step: images.every((image) => image != null) ? AddUserStep.form : AddUserStep.capture,
      clearError: true,
    );
  }

  void goToForm() {
    if (!state.hasRequiredSamples) {
      state = state.copyWith(
        errorMessage: 'Capture all required face angles before continuing.',
      );
      return;
    }
    state = state.copyWith(step: AddUserStep.form, clearError: true);
  }

  void backToCapture() {
    state = state.copyWith(step: AddUserStep.capture, clearError: true);
  }

  void selectWarehouse(WarehouseModel warehouse) {
    state = state.copyWith(selectedWarehouse: warehouse);
  }

  Future<void> submitEmployee({
    required String employeecode,
    required String name,
    required String fathername,
    required String attendancecode,
  }) async {
    if (state.isSubmitting) return;
    if (!state.hasRequiredSamples) {
      state = state.copyWith(
        errorMessage: 'Capture all required face angles before submitting.',
      );
      return;
    }
    if (state.selectedWarehouse == null) {
      state = state.copyWith(errorMessage: 'Please select a warehouse.');
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      step: AddUserStep.processing,
      clearError: true,
    );

    final request = AddEmployeeRequest(
      employeecode: employeecode,
      name: name,
      fathername: fathername,
      attendancecode: attendancecode,
      warehouseid: state.selectedWarehouse!.shortName,
      latlong: state.selectedWarehouse!.latlong,
      photoPaths: state.capturedImages.map((file) => file!.path).toList(),
      angleLabels: AddUserState.requiredAngleLabels,
      captureSessionId: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    final result = await ref.read(employeeRepositoryProvider).addEmployee(request);

    switch (result) {
      case ApiSuccess(:final data):
        final createdName =
            ((data['data'] as Map<String, dynamic>?)?['name'] as String?) ?? name;
        state = state.copyWith(
          isSubmitting: false,
          step: AddUserStep.success,
          successMessage: 'Employee "$createdName" registered successfully.',
        );
      case ApiError(:final message):
        state = state.copyWith(
          isSubmitting: false,
          step: AddUserStep.form,
          errorMessage: message,
        );
    }
  }

  void reset() {
    state = const AddUserState();
    Future.microtask(_loadWarehouses);
  }

  Future<String?> _validateEnrollmentSample(File imageFile, String angleLabel) async {
    try {
      final faces = await _faceDetector.processImage(
        InputImage.fromFilePath(imageFile.path),
      );
      if (faces.isEmpty) {
        return 'No clear face detected in the $angleLabel sample.';
      }
      if (faces.length > 1) {
        return 'Only one face should be visible during enrollment.';
      }

      final face = faces.first;
      final box = face.boundingBox;
      if (box.width < 160 || box.height < 160) {
        return 'Move closer to the camera for the $angleLabel sample.';
      }

      final roll = face.headEulerAngleZ;
      if (roll != null && roll.abs() > 15) {
        return 'Keep the head upright while capturing the $angleLabel sample.';
      }

      final pitch = face.headEulerAngleX;
      if (pitch != null && pitch.abs() > 18) {
        return 'Keep the face level for the $angleLabel sample.';
      }

      final yaw = face.headEulerAngleY;
      if (angleLabel == 'front' && yaw != null && yaw.abs() > 12) {
        return 'Look straight at the camera for the front sample.';
      }
      if (angleLabel == 'left' && yaw != null && yaw > -8) {
        return 'Turn slightly left for the left sample.';
      }
      if (angleLabel == 'right' && yaw != null && yaw < 8) {
        return 'Turn slightly right for the right sample.';
      }

      final faceRatio =
          math.min(box.width, box.height) / math.max(box.width, box.height);
      if (faceRatio < 0.62) {
        return 'Keep the full face visible in the $angleLabel sample.';
      }

      return null;
    } catch (_) {
      return 'Unable to validate the $angleLabel sample. Please retake it.';
    }
  }
}
