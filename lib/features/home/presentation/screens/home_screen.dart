// lib/features/home/presentation/screens/home_screen.dart
import 'dart:async';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../../add_user/presentation/screens/add_user_screen.dart';
import '../../../attendance/presentation/screens/attendance_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final now = DateTime.now();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surfaceCard,
            onRefresh: () => ref.read(homeViewModelProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(16),
                  _buildHeader(context, now),
                  const Gap(24),
                  _buildLocationCard(context, state),
                  const Gap(16),
                  _buildWarehouseCard(context, state),
                  const Gap(32),
                  _buildActionButtons(context, ref, state),
                  const Gap(24),
                  _buildFooterInfo(context),
                  const Gap(24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DateTime now) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE').format(now),
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(duration: 500.ms),
              const Gap(4),
              Text(
                    DateFormat('MMM dd, yyyy').format(now),
                    style: Theme.of(context).textTheme.displayMedium,
                  )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 500.ms)
                  .slideX(begin: -0.1, end: 0),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const _LiveClock(),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
      ],
    );
  }

  Widget _buildLocationCard(BuildContext context, HomeState state) {
    return GlowCard(
      glowColor: state.isInPremises ? AppColors.success : AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.accent,
                  size: 18,
                ),
              ),
              const Gap(12),
              Text(
                'Your Location',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              if (state.isLoadingLocation)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                )
              else
                PulseDot(
                  color: state.position != null
                      ? AppColors.success
                      : AppColors.error,
                ),
            ],
          ),
          const Gap(16),
          if (state.isLoadingLocation)
            _shimmerRow()
          else if (state.position != null) ...[
            InfoRow(
              icon: Icons.pin_drop_outlined,
              label: 'Coords',
              value:
                  '${state.position!.latitude.toStringAsFixed(5)}, ${state.position!.longitude.toStringAsFixed(5)}',
            ),
            const Gap(8),
            InfoRow(
              icon: Icons.location_city_outlined,
              label: 'Address',
              value: state.address ?? 'Fetching...',
            ),
          ] else
            Text(
              state.errorMessage ?? 'Unable to get location',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.error,
                fontSize: 13,
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildWarehouseCard(BuildContext context, HomeState state) {
    final isInPremises = state.isInPremises;
    final color = isInPremises ? AppColors.success : AppColors.warning;

    return GlowCard(
      glowColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.warehouse_outlined, color: color, size: 18),
              ),
              const Gap(12),
              Text(
                'Premises Status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              StatusChip(
                label: isInPremises ? 'INSIDE' : 'OUTSIDE',
                color: color,
                icon: isInPremises
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
              ),
            ],
          ),
          const Gap(16),
          if (state.isLoadingWarehouses)
            _shimmerRow()
          else if (isInPremises) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const Gap(8),
                      Text(
                        'You are in the premises of',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Gap(6),
                  Text(
                    state.activeWarehouse!.fullName,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    'Code: ${state.activeWarehouse!.shortName}',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const Gap(10),
                  Expanded(
                    child: Text(
                      'You are not within any warehouse premises.\nAttendance marking is restricted.',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.warning,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    HomeState state,
  ) {
    final authState = ref.watch(authViewModelProvider);
    final isLoggedIn = authState.isLoggedIn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        const Gap(10),
        // ── Logged in user info + logout ─────────────────────────────────────
        if (isLoggedIn && authState.user != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  color: AppColors.accent,
                  size: 20,
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authState.user!.name,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        authState.user!.username,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.surfaceCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          'Logout',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to logout?',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'Logout',
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      ref.read(authViewModelProvider.notifier).logout();
                    }
                  },
                  icon: const Icon(
                    Icons.logout,
                    color: AppColors.error,
                    size: 16,
                  ),
                  label: Text(
                    'Logout',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),
          const Gap(10),
        ],
        Row(
          children: [
            // ── Add Employee — only when logged in ──────────────────────────
            if (isLoggedIn) ...[
              Expanded(
                child: _ActionCard(
                  icon: Icons.person_add_outlined,
                  label: 'Add\nEmployee',
                  color: AppColors.accent,
                  delay: 350,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddUserScreen()),
                  ),
                ),
              ),
              const Gap(14),
            ],

            // ── Mark Attendance — always visible ────────────────────────────
            Expanded(
              child: _ActionCard(
                icon: Icons.fingerprint,
                label: 'Mark\nAttendance',
                color: AppColors.success,
                delay: 450,
                isLoading: state.isCheckingAttendanceLocation,
                onTap: state.isCheckingAttendanceLocation
                    ? null
                    : () => _onMarkAttendanceTap(context, ref),
              ),
            ),

            // ── Login button — only when NOT logged in ──────────────────────
            if (!isLoggedIn) ...[
              const Gap(14),
              Expanded(
                child: _ActionCard(
                  icon: Icons.login_rounded,
                  label: 'Login',
                  color: AppColors.warning,
                  delay: 350,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Checks location first — navigates only on success, shows dialog on failure.
  Future<void> _onMarkAttendanceTap(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(homeViewModelProvider.notifier)
        .checkLocationForAttendance();

    if (!context.mounted) return;

    switch (result) {
      case AttendanceCheckSuccess(:final position, :final warehouse):
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AttendanceScreen(
              initialPosition: position,
              activeWarehouse: warehouse,
            ),
          ),
        );

      case AttendanceCheckFailure(:final error, :final message):
        _showLocationErrorDialog(context, ref, error, message);
    }
  }

  void _showLocationErrorDialog(
    BuildContext context,
    WidgetRef ref,
    AttendanceCheckError error,
    String message,
  ) {
    final isPermanent =
        error == AttendanceCheckError.permissionPermanentlyDenied;
    final isOutside = error == AttendanceCheckError.outsidePremises;

    // Icon and color per error type
    final (IconData icon, Color color) = switch (error) {
      AttendanceCheckError.outsidePremises => (
        Icons.location_searching,
        AppColors.warning,
      ),
      AttendanceCheckError.permissionDenied => (
        Icons.location_off_outlined,
        AppColors.error,
      ),
      AttendanceCheckError.permissionPermanentlyDenied => (
        Icons.lock_outline,
        AppColors.error,
      ),
      AttendanceCheckError.serviceDisabled => (
        Icons.gps_off,
        AppColors.warning,
      ),
      AttendanceCheckError.locationTimeout => (
        Icons.wifi_tethering_error,
        AppColors.warning,
      ),
      AttendanceCheckError.warehouseFetchFailed => (
        Icons.cloud_off_outlined,
        AppColors.error,
      ),
    };

    final title = switch (error) {
      AttendanceCheckError.outsidePremises => 'Not in Premises',
      AttendanceCheckError.permissionDenied => 'Location Required',
      AttendanceCheckError.permissionPermanentlyDenied => 'Permission Denied',
      AttendanceCheckError.serviceDisabled => 'GPS Disabled',
      AttendanceCheckError.locationTimeout => 'Location Unavailable',
      AttendanceCheckError.warehouseFetchFailed => 'Connection Error',
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const Gap(20),
              // Title
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(10),
              // Message
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
              // Buttons
              if (isPermanent) ...[
                // Two buttons: Open Settings + Cancel
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Open Settings',
                    icon: Icons.settings_outlined,
                    onPressed: () {
                      Navigator.pop(context);
                      Geolocator.openAppSettings();
                    },
                  ),
                ),
                const Gap(10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.spaceGrotesk(fontSize: 14),
                    ),
                  ),
                ),
              ] else if (isOutside) ...[
                // Two buttons: Try Again + Cancel
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Try Again',
                    icon: Icons.refresh,
                    color: color,
                    onPressed: () {
                      Navigator.pop(context);
                      _onMarkAttendanceTap(context, ref);
                    },
                  ),
                ),
                const Gap(10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.spaceGrotesk(fontSize: 14),
                    ),
                  ),
                ),
              ] else ...[
                // Single OK button for all other errors
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'OK',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shield_outlined,
            color: AppColors.textMuted,
            size: 16,
          ),
          const Gap(10),
          Expanded(
            child: Text(
              'Attendance is geo-fenced to authorized premises only. Pull down to refresh your location.',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textMuted,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 500.ms);
  }

  Widget _shimmerRow() {
    return Column(
      children: List.generate(
        2,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child:
              Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.border.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: 1500.ms,
                    color: AppColors.borderLight.withOpacity(0.3),
                  ),
        ),
      ),
    );
  }
}

// ─── Live Clock ───────────────────────────────────────────────────────────────
class _LiveClock extends StatefulWidget {
  const _LiveClock();
  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late String _time;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _time = DateFormat('HH:mm').format(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _time = DateFormat('HH:mm').format(DateTime.now()));
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _time,
      style: GoogleFonts.spaceGrotesk(
        color: AppColors.accent,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ─── Action Card ──────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int delay;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.delay,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.15), color.withOpacity(0.06)],
            ),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              splashColor: color.withOpacity(0.12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: isLoading
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: color,
                              ),
                            )
                          : Icon(icon, color: color, size: 22),
                    ),
                    const Spacer(),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const Gap(4),
                    isLoading
                        ? Text(
                            'Checking...',
                            style: GoogleFonts.spaceGrotesk(
                              color: color,
                              fontSize: 11,
                            ),
                          )
                        : Icon(Icons.arrow_forward, color: color, size: 14),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay),
          duration: 500.ms,
        )
        .slideY(begin: 0.15, end: 0);
  }
}
