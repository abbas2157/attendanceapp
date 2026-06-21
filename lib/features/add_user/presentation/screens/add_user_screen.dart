import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../viewmodels/add_user_viewmodel.dart';

class AddUserScreen extends ConsumerStatefulWidget {
  const AddUserScreen({super.key});

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeCodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _attendanceCodeCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _employeeCodeCtrl.dispose();
    _nameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _attendanceCodeCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureSample(int index) async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 1600,
      maxHeight: 1600,
      preferredCameraDevice: CameraDevice.front,
    );

    if (picked == null) return;
    await ref
        .read(addUserViewModelProvider.notifier)
        .setPhotoAt(index, File(picked.path));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(addUserViewModelProvider.notifier).submitEmployee(
          employeecode: _employeeCodeCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          fathername: _fatherNameCtrl.text.trim(),
          attendancecode: _attendanceCodeCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addUserViewModelProvider);

    ref.listen(addUserViewModelProvider, (prev, next) {
      if (next.selectedWarehouse != null &&
          prev?.selectedWarehouse != next.selectedWarehouse) {
        _locationCtrl.text = next.selectedWarehouse!.latlong ?? 'N/A';
      }

      if (next.step == AddUserStep.success &&
          prev?.step != AddUserStep.success) {
        _showSuccessSheet(context, next.successMessage ?? 'Employee registered.');
      }

      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        _showErrorDialog(context, next.errorMessage!);
      }
    });

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildAppBar(context, state),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const Gap(8),
                        _buildStepIndicator(state),
                        const Gap(24),
                        if (state.step == AddUserStep.capture ||
                            state.step == AddUserStep.form)
                          _buildCaptureSection(context, state),
                        if (state.step == AddUserStep.form) ...[
                          const Gap(24),
                          _buildForm(context, state),
                        ],
                        const Gap(40),
                      ]),
                    ),
                  ),
                ],
              ),
              if (state.isSubmitting || state.step == AddUserStep.processing)
                const LoadingOverlay(message: 'Registering employee...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AddUserState state) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      floating: true,
      leading: IconButton(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 14,
            color: AppColors.textPrimary,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Add Employee'),
      actions: [
        if (state.step == AddUserStep.form)
          TextButton.icon(
            onPressed: () => ref.read(addUserViewModelProvider.notifier).backToCapture(),
            icon: const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.accent),
            label: Text(
              'Recapture',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.accent,
                fontSize: 13,
              ),
            ),
          ),
        const Gap(8),
      ],
    );
  }

  Widget _buildStepIndicator(AddUserState state) {
    const steps = ['Capture', 'Details', 'Complete'];
    final currentIndex = switch (state.step) {
      AddUserStep.capture => 0,
      AddUserStep.form || AddUserStep.processing => 1,
      AddUserStep.success => 2,
    };

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIndex = i ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: stepIndex < currentIndex ? AppColors.accent : AppColors.border,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isDone = stepIndex < currentIndex;
        final isActive = stepIndex == currentIndex;
        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? AppColors.accent
                    : isActive
                        ? AppColors.surfaceCard
                        : AppColors.surface,
                border: Border.all(
                  color: isDone || isActive ? AppColors.accent : AppColors.border,
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, color: AppColors.primary, size: 14)
                    : Text(
                        '${stepIndex + 1}',
                        style: GoogleFonts.spaceGrotesk(
                          color: isActive ? AppColors.accent : AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const Gap(4),
            Text(
              steps[stepIndex],
              style: GoogleFonts.spaceGrotesk(
                color: isActive ? AppColors.accent : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCaptureSection(BuildContext context, AddUserState state) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Face Enrollment Samples',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Gap(6),
          Text(
            'Capture three live camera samples. These become the reference set for attendance verification.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Gap(20),
          ...List.generate(AddUserState.requiredAngleLabels.length, (index) {
            final angle = AddUserState.requiredAngleLabels[index];
            final image = state.capturedImages[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == AddUserState.requiredAngleLabels.length - 1 ? 0 : 14,
              ),
              child: _EnrollmentSampleCard(
                label: _labelForAngle(angle),
                image: image,
                onCapture: () => _captureSample(index),
              ),
            );
          }),
          const Gap(18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.25)),
            ),
            child: Text(
              'Use live camera only. Gallery enrollment is disabled to prevent stale or manipulated photos.',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.warning,
                fontSize: 12,
              ),
            ),
          ),
          const Gap(18),
          PrimaryButton(
            label: state.hasRequiredSamples ? 'Continue to Details' : 'Capture Required Samples',
            icon: state.hasRequiredSamples ? Icons.arrow_forward : Icons.camera_alt_outlined,
            onPressed: state.hasRequiredSamples
                ? () => ref.read(addUserViewModelProvider.notifier).goToForm()
                : null,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildForm(BuildContext context, AddUserState state) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Employee Details',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Gap(4),
          Text(
            'Complete the employee profile after the face samples are captured.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Gap(20),
          GlowCard(
            child: Column(
              children: [
                AppTextField(
                  label: 'Employee Code',
                  hint: 'e.g., EMP-001',
                  controller: _employeeCodeCtrl,
                  prefixIcon: Icons.badge_outlined,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const Gap(14),
                AppTextField(
                  label: 'Full Name',
                  hint: 'Enter full name',
                  controller: _nameCtrl,
                  prefixIcon: Icons.person_outline,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const Gap(14),
                AppTextField(
                  label: "Father's Name",
                  hint: "Enter father's name",
                  controller: _fatherNameCtrl,
                  prefixIcon: Icons.supervisor_account_outlined,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const Gap(14),
                AppTextField(
                  label: 'Attendance Code',
                  hint: 'Unique attendance identifier',
                  controller: _attendanceCodeCtrl,
                  prefixIcon: Icons.fingerprint,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
          const Gap(16),
          GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warehouse_outlined,
                      color: AppColors.accent,
                      size: 16,
                    ),
                    const Gap(8),
                    Text(
                      'Warehouse Assignment',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const Gap(14),
                if (state.isLoadingWarehouses)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else
                  DropdownButtonFormField(
                    initialValue: state.selectedWarehouse,
                    decoration: const InputDecoration(
                      labelText: 'Select Warehouse',
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ),
                    dropdownColor: AppColors.surfaceCard,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.accent,
                    ),
                    items: state.warehouses
                        .map(
                          (warehouse) => DropdownMenuItem(
                            value: warehouse,
                            child: Text(
                              warehouse.fullName,
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (warehouse) {
                      if (warehouse != null) {
                        ref.read(addUserViewModelProvider.notifier).selectWarehouse(warehouse);
                      }
                    },
                    validator: (value) => value == null ? 'Select a warehouse' : null,
                  ),
                if (state.selectedWarehouse != null) ...[
                  const Gap(14),
                  AppTextField(
                    label: 'Assigned Location',
                    controller: _locationCtrl,
                    prefixIcon: Icons.my_location_outlined,
                    readOnly: true,
                  ),
                ],
              ],
            ),
          ),
          const Gap(24),
          PrimaryButton(
            label: 'Register Employee',
            icon: Icons.how_to_reg_outlined,
            isLoading: state.isSubmitting,
            onPressed: _submit,
          ),
          const Gap(12),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.08, end: 0);
  }

  String _labelForAngle(String angle) {
    return switch (angle) {
      'front' => 'Front Face',
      'left' => 'Slight Left',
      'right' => 'Slight Right',
      _ => angle,
    };
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withOpacity(0.12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 34,
                ),
              ),
              const Gap(20),
              Text(
                'Registration Failed',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(10),
              Text(
                message,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Close',
                  icon: Icons.close,
                  color: AppColors.error,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSheet(BuildContext context, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 40,
              ),
            ).animate().scale(begin: const Offset(0.5, 0.5)).fadeIn(duration: 500.ms),
            const Gap(20),
            Text(
              'Registration Successful',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(8),
            Text(
              message,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(addUserViewModelProvider.notifier).reset();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Add Another'),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Done',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollmentSampleCard extends StatelessWidget {
  final String label;
  final File? image;
  final VoidCallback onCapture;

  const _EnrollmentSampleCard({
    required this.label,
    required this.image,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null;
    final preview = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.file(image!, fit: BoxFit.cover)
          : const Icon(
              Icons.face_retouching_natural_outlined,
              color: AppColors.accent,
              size: 28,
            ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(4),
        Text(
          hasImage
              ? 'Sample captured. Retake if the face is blurred or off-angle.'
              : 'Capture a clear live camera sample for this angle.',
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
    final actionButton = PrimaryButton(
      label: hasImage ? 'Retake' : 'Capture',
      width: 96,
      icon: hasImage ? Icons.refresh : Icons.camera_alt_outlined,
      onPressed: onCapture,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasImage ? AppColors.success.withOpacity(0.45) : AppColors.border,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useCompactLayout = constraints.maxWidth < 420;

          if (useCompactLayout) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    preview,
                    const Gap(14),
                    Expanded(child: details),
                  ],
                ),
                const Gap(12),
                PrimaryButton(
                  label: hasImage ? 'Retake' : 'Capture',
                  icon: hasImage ? Icons.refresh : Icons.camera_alt_outlined,
                  onPressed: onCapture,
                ),
              ],
            );
          }

          return Row(
            children: [
              preview,
              const Gap(14),
              Expanded(child: details),
              const Gap(10),
              actionButton,
            ],
          );
        },
      ),
    );
  }
}
