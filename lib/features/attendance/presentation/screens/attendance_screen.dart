import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../home/data/models/warehouse_model.dart';
import '../../data/models/attendance_model.dart';
import '../viewmodels/attendance_viewmodel.dart';
import '../widgets/attendance_result_widget.dart';
import '../widgets/face_scanner_overlay.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  final Position initialPosition;
  final WarehouseModel activeWarehouse;

  const AttendanceScreen({
    super.key,
    required this.initialPosition,
    required this.activeWarehouse,
  });

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with WidgetsBindingObserver {
  final _claimController = TextEditingController();
  final _claimFocusNode = FocusNode();
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isScanning = false;
  bool _isShowingFatalDialog = false;
  DateTime? _scanWarmupUntil;
  AttendanceScreenState? _lastScreenState;

  late final attendanceProvider = attendanceViewModelProvider(
    initialPosition: widget.initialPosition,
    activeWarehouse: widget.activeWarehouse,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.inactive) {
      _stopScanLoop();
      _disposeCamera();
    } else if (appState == AppLifecycleState.resumed) {
      final state = ref.read(attendanceProvider);
      if (state.screenState != AttendanceScreenState.claimEntry) {
        _ensureCameraReady();
      }
    }
  }

  Future<void> _ensureCameraReady() async {
    if (_cameraController != null && _isCameraInitialized) {
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    var camera = cameras.first;
    for (final entry in cameras) {
      if (entry.lensDirection == CameraLensDirection.front) {
        camera = entry;
        break;
      }
    }

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _cameraController = controller;
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('Attendance camera init error: $e');
      await controller.dispose();
    }
  }

  Future<void> _beginScanner() async {
    final notifier = ref.read(attendanceProvider.notifier);
    notifier.setClaimCode(_claimController.text);
    if (!await notifier.startScanning()) return;

    if (!mounted) return;
    FocusScope.of(context).unfocus();
    await _ensureCameraReady();
    if (!mounted) return;
    setState(() {
      _scanWarmupUntil = DateTime.now().add(const Duration(seconds: 1));
    });
    await _startScanLoop();
  }

  Future<void> _startScanLoop() async {
    if (_isScanning) return;
    _isScanning = true;

    while (_isScanning && mounted) {
      final vmState = ref.read(attendanceProvider);

      if (vmState.screenState != AttendanceScreenState.scanReady) {
        await Future.delayed(const Duration(milliseconds: 400));
        continue;
      }

      final warmupUntil = _scanWarmupUntil;
      if (warmupUntil != null && DateTime.now().isBefore(warmupUntil)) {
        await Future.delayed(const Duration(milliseconds: 150));
        continue;
      }
      _scanWarmupUntil = null;
      if (mounted) setState(() {});

      try {
        final controller = _cameraController;
        if (controller == null ||
            !controller.value.isInitialized ||
            controller.value.isTakingPicture) {
          await Future.delayed(const Duration(milliseconds: 250));
          continue;
        }

        final photo = await controller.takePicture();
        final shouldContinue = await ref
            .read(attendanceProvider.notifier)
            .processPhoto(File(photo.path));

        if (!shouldContinue) {
          _isScanning = false;
          break;
        }

        await Future.delayed(const Duration(milliseconds: 1200));
      } catch (e) {
        debugPrint('Attendance scan loop error: $e');
        _isScanning = false;
        ref.read(attendanceProvider.notifier).editClaim();
        if (mounted) {
          _showFatalErrorDialog(
            'Camera capture failed. Please reopen attendance and try again.',
          );
        }
      }
    }
  }

  void _stopScanLoop() {
    _isScanning = false;
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (mounted) {
      setState(() => _isCameraInitialized = false);
    }
    await controller?.dispose();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _claimController.dispose();
    _claimFocusNode.dispose();
    _stopScanLoop();
    _disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceProvider);

    ref.listen(attendanceProvider, (previous, next) {
      if (next.screenState == AttendanceScreenState.result &&
          previous?.screenState != AttendanceScreenState.result) {
        HapticFeedback.mediumImpact();
      }

      final fatalMessage = next.fatalErrorMessage;
      if (fatalMessage != null && fatalMessage != previous?.fatalErrorMessage) {
        HapticFeedback.heavyImpact();
        _stopScanLoop();
        _disposeCamera();
        _showFatalErrorDialog(fatalMessage);
      }
    });

    if (_claimController.text != state.activeClaimCode &&
        state.screenState == AttendanceScreenState.claimEntry) {
      _claimController.value = TextEditingValue(
        text: state.activeClaimCode,
        selection: TextSelection.collapsed(
          offset: state.activeClaimCode.length,
        ),
      );
    }

    if (state.screenState == AttendanceScreenState.result &&
        _lastScreenState != AttendanceScreenState.result) {
      _stopScanLoop();
    }

    if (state.screenState == AttendanceScreenState.claimEntry &&
        _lastScreenState != AttendanceScreenState.claimEntry) {
      _stopScanLoop();
    }
    _lastScreenState = state.screenState;

    if (state.screenState == AttendanceScreenState.result &&
        state.result != null) {
      return Scaffold(
        body: AttendanceResultWidget(
          response: state.result!,
          onScanAgain: () async {
            ref.read(attendanceProvider.notifier).retry();
            await _ensureCameraReady();
            await _startScanLoop();
          },
          onDone: () => Navigator.pop(context),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (state.screenState == AttendanceScreenState.claimEntry)
            _buildClaimEntry(context, state)
          else ...[
            if (_isCameraInitialized && _cameraController != null)
              _buildCameraPreview()
            else
              _buildCameraPlaceholder(),
            FaceScannerOverlay(
              isFaceDetected: state.isFaceDetected,
              isProcessing:
                  state.screenState == AttendanceScreenState.processing,
              warehouseName: state.activeWarehouse.fullName,
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildBackButton(context),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            _stopScanLoop();
                            _disposeCamera();
                            ref.read(attendanceProvider.notifier).editClaim();
                            _claimFocusNode.requestFocus();
                          },
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit Code'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _buildScannerInfo(state),
                  ],
                ),
              ),
            ),
          ],
          if (state.screenState == AttendanceScreenState.processing)
            const LoadingOverlay(message: 'Verifying attendance...'),
        ],
      ),
    );
  }

  Widget _buildClaimEntry(BuildContext context, AttendanceState state) {
    return SafeArea(
      child: AppBackground(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildBackButton(context, dark: false),
                  const Spacer(),
                  StatusChip(
                    label: state.activeWarehouse.shortName,
                    color: AppColors.success,
                    icon: Icons.location_on_outlined,
                  ),
                ],
              ),
              const Gap(24),
              Text(
                'Attendance Verification',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const Gap(8),
              Text(
                'Enter the employee code or attendance code first. The camera will verify the claimed person only.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Gap(24),
              GlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Code Type',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Gap(14),
                    Row(
                      children: [
                        Expanded(
                          child: _ClaimTypeButton(
                            label: 'Employee Code',
                            isSelected:
                                state.claimType ==
                                AttendanceClaimType.employeeCode,
                            onTap: () {
                              final notifier = ref.read(
                                attendanceProvider.notifier,
                              );
                              notifier.setClaimCode(_claimController.text);
                              notifier.setClaimType(
                                AttendanceClaimType.employeeCode,
                              );
                              _claimFocusNode.requestFocus();
                            },
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: _ClaimTypeButton(
                            label: 'Attendance Code',
                            isSelected:
                                state.claimType ==
                                AttendanceClaimType.attendanceCode,
                            onTap: () {
                              final notifier = ref.read(
                                attendanceProvider.notifier,
                              );
                              notifier.setClaimCode(_claimController.text);
                              notifier.setClaimType(
                                AttendanceClaimType.attendanceCode,
                              );
                              _claimFocusNode.requestFocus();
                            },
                          ),
                        ),
                      ],
                    ),
                    const Gap(18),
                    TextFormField(
                      controller: _claimController,
                      focusNode: _claimFocusNode,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.username],
                      onChanged: (value) => ref
                          .read(attendanceProvider.notifier)
                          .setClaimCode(value),
                      onFieldSubmitted: (_) => _beginScanner(),
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            state.claimType == AttendanceClaimType.employeeCode
                            ? 'Employee Code'
                            : 'Attendance Code',
                        hintText:
                            state.claimType == AttendanceClaimType.employeeCode
                            ? 'Enter employee code'
                            : 'Enter attendance code',
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                      ),
                    ),
                    if (state.activeRecentCodes.isNotEmpty) ...[
                      const Gap(10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: state.activeRecentCodes
                            .map(
                              (code) => ActionChip(
                                label: Text(code),
                                onPressed: () {
                                  _claimController.text = code;
                                  ref
                                      .read(attendanceProvider.notifier)
                                      .setClaimCode(code);
                                  _claimFocusNode.requestFocus();
                                },
                                backgroundColor: AppColors.surface,
                                side: const BorderSide(color: AppColors.border),
                                labelStyle: GoogleFonts.spaceGrotesk(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const Gap(14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        'Location already verified for ${state.activeWarehouse.fullName}.',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.success,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (state.errorMessage != null) ...[
                      const Gap(12),
                      Text(
                        state.errorMessage!,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const Gap(18),
                    PrimaryButton(
                      label: state.isPreparing
                          ? 'Checking Code...'
                          : 'Start Face Verification',
                      icon: Icons.camera_alt_outlined,
                      isLoading: state.isPreparing,
                      onPressed: state.isPreparing ? null : _beginScanner,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerInfo(AttendanceState state) {
    final claimLabel = state.claimType == AttendanceClaimType.employeeCode
        ? 'Employee Code'
        : 'Attendance Code';
    final warmupActive =
        _scanWarmupUntil != null && DateTime.now().isBefore(_scanWarmupUntil!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$claimLabel: ${state.activeClaimCode}',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(6),
          if (state.precheckEmployeeName != null) ...[
            Text(
              '${state.precheckEmployeeName} at ${state.precheckWarehouseName ?? state.activeWarehouse.fullName}',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const Gap(6),
          ],
          Text(
            warmupActive
                ? 'Hold still. Scanning will start in a moment.'
                : state.hasMultipleFaces
                ? 'Only one face should be visible. Ask others to step out of frame.'
                : state.errorMessage ??
                      'Keep the face centered and wait for automatic capture.',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildCameraPreview() {
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _cameraController!.value.previewSize!.height,
            height: _cameraController!.value.previewSize!.width,
            child: CameraPreview(_cameraController!),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPlaceholder() {
    return Container(
      color: AppColors.primary,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, {bool dark = true}) {
    final background = dark
        ? Colors.black.withOpacity(0.5)
        : AppColors.surfaceCard;
    final border = dark ? Colors.white.withOpacity(0.15) : AppColors.border;
    final iconColor = dark ? Colors.white : AppColors.textPrimary;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Icon(Icons.arrow_back_ios_new, color: iconColor, size: 14),
      ),
    );
  }

  Future<void> _showFatalErrorDialog(String message) async {
    if (_isShowingFatalDialog || !mounted) return;
    _isShowingFatalDialog = true;

    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 34,
                ),
              ),
              const Gap(18),
              Text(
                'Verification Stopped',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const Gap(22),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Try Again',
                  icon: Icons.refresh,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    _isShowingFatalDialog = false;
  }
}

class _ClaimTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClaimTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.accent : AppColors.surface;
    final border = isSelected ? AppColors.accent : AppColors.border;
    final textColor = isSelected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
