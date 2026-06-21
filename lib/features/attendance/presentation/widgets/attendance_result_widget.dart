// lib/features/attendance/presentation/widgets/attendance_result_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/models/attendance_model.dart';

class AttendanceResultWidget extends StatelessWidget {
  final AttendanceResponse response;
  final VoidCallback onScanAgain;
  final VoidCallback onDone;

  const AttendanceResultWidget({
    super.key,
    required this.response,
    required this.onScanAgain,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final action = response.parsedAction;
    final isSuccess = action == AttendanceAction.checkIn ||
        action == AttendanceAction.checkOut;
    final isCooldown = action == AttendanceAction.cooldown;
    final isAlreadyDone = action == AttendanceAction.alreadyDone;
    final isAmbiguous = action == AttendanceAction.ambiguousFace;

    final Color primaryColor;
    final IconData icon;
    final String title;

    if (action == AttendanceAction.checkIn) {
      primaryColor = AppColors.success;
      icon = Icons.login_outlined;
      title = 'Checked In';
    } else if (action == AttendanceAction.checkOut) {
      primaryColor = AppColors.accentDim;
      icon = Icons.logout_outlined;
      title = 'Checked Out';
    } else if (isCooldown) {
      primaryColor = AppColors.warning;
      icon = Icons.timer_outlined;
      title = 'Please Wait';
    } else if (isAlreadyDone) {
      primaryColor = AppColors.accent;
      icon = Icons.event_available_outlined;
      title = 'Already Recorded';
    } else if (isAmbiguous) {
      primaryColor = AppColors.warning;
      icon = Icons.help_outline;
      title = 'Ambiguous Match';
    } else {
      primaryColor = AppColors.error;
      icon = Icons.error_outline;
      title = 'Recognition Failed';
    }

    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon
              _buildResultIcon(primaryColor, icon, isSuccess),
              const Gap(28),

              // Title
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  letterSpacing: -0.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.2, end: 0),

              const Gap(12),

              // Message
              Text(
                response.message,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 400.ms),

              const Gap(28),

              // Detail cards
              if (isSuccess || isAlreadyDone)
                _buildDetailCard(context, response, action, primaryColor),

              if (!isSuccess && !isAlreadyDone)
                _buildSimpleInfo(response, primaryColor),

              const Gap(32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onScanAgain,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Scan Again'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Done',
                      color: primaryColor,
                      onPressed: onDone,
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 600.ms)
                  .slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultIcon(Color color, IconData icon, bool isSuccess) {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow rings
          ...List.generate(3, (i) {
            return Container(
              width: 130.0 - i * 22,
              height: 130.0 - i * 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.15 - i * 0.04),
                  width: 1,
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.0, 1.0),
                  duration: Duration(milliseconds: 1400 + i * 200),
                )
                .fadeOut(duration: Duration(milliseconds: 1400 + i * 200));
          }),
          // Main circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 40),
          )
              .animate()
              .scale(
                begin: const Offset(0.3, 0.3),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    AttendanceResponse response,
    AttendanceAction action,
    Color color,
  ) {
    return GlowCard(
      glowColor: color,
      child: Column(
        children: [
          if (response.employee != null)
            InfoRow(
              icon: Icons.person_outline,
              label: 'Employee',
              value: response.employee!,
              valueColor: AppColors.textPrimary,
            ),
          if (response.time != null) ...[
            const Gap(10),
            InfoRow(
              icon: action == AttendanceAction.checkIn
                  ? Icons.login_outlined
                  : Icons.logout_outlined,
              label: action == AttendanceAction.checkIn
                  ? 'Check-In Time'
                  : 'Check-Out Time',
              value: response.time!,
              valueColor: color,
            ),
          ],
          if (response.hoursWorked != null) ...[
            const Gap(10),
            InfoRow(
              icon: Icons.access_time_outlined,
              label: 'Hours Worked',
              value: response.hoursWorked!,
              valueColor: AppColors.accent,
            ),
          ],
          if (action == AttendanceAction.alreadyDone) ...[
            if (response.checkIn != null) ...[
              const Gap(10),
              InfoRow(
                icon: Icons.login_outlined,
                label: 'Check In',
                value: response.checkIn!,
              ),
            ],
            if (response.checkOut != null) ...[
              const Gap(10),
              InfoRow(
                icon: Icons.logout_outlined,
                label: 'Check Out',
                value: response.checkOut!,
              ),
            ],
          ],
          if (response.confidence != null) ...[
            const Gap(10),
            Row(
              children: [
                const Icon(Icons.analytics_outlined,
                    color: AppColors.accent, size: 16),
                const Gap(10),
                Text(
                  'Confidence: ',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${response.confidence!.toStringAsFixed(1)}%',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          if (response.matchMargin != null) ...[
            const Gap(10),
            InfoRow(
              icon: Icons.compare_arrows_outlined,
              label: 'Match Margin',
              value: '${response.matchMargin!.toStringAsFixed(2)}',
              valueColor: AppColors.warning,
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 450.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildSimpleInfo(AttendanceResponse response, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 18),
          const Gap(10),
          Expanded(
            child: Text(
              response.message,
              style: GoogleFonts.spaceGrotesk(
                color: color,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms);
  }
}
