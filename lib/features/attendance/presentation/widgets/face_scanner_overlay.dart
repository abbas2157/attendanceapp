// lib/features/attendance/presentation/widgets/face_scanner_overlay.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';

class FaceScannerOverlay extends StatefulWidget {
  final bool isFaceDetected;
  final bool isProcessing;
  final String? warehouseName;

  const FaceScannerOverlay({
    super.key,
    required this.isFaceDetected,
    required this.isProcessing,
    this.warehouseName,
  });

  @override
  State<FaceScannerOverlay> createState() => _FaceScannerOverlayState();
}

class _FaceScannerOverlayState extends State<FaceScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ovalWidth = size.width * 0.72;
    final ovalHeight = size.height * 0.42;
    final color = widget.isProcessing
        ? AppColors.warning
        : widget.isFaceDetected
        ? AppColors.success
        : AppColors.accent;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark scrim with oval cutout
        CustomPaint(
          painter: _OvalCutoutPainter(
            ovalWidth: ovalWidth,
            ovalHeight: ovalHeight,
          ),
        ),

        // Animated scan line inside oval
        if (!widget.isProcessing)
          Center(
            child: ClipOval(
              child: SizedBox(
                width: ovalWidth,
                height: ovalHeight,
                child: AnimatedBuilder(
                  animation: _scanController,
                  builder: (_, _) => Stack(
                    children: [
                      Positioned(
                        top: _scanController.value * ovalHeight - 1,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                color.withOpacity(0.9),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Oval border with corner brackets
        Center(
              child: SizedBox(
                width: ovalWidth,
                height: ovalHeight,
                child: CustomPaint(painter: _OvalBorderPainter(color: color)),
              ),
            )
            .animate(target: widget.isFaceDetected ? 1 : 0)
            .custom(
              builder: (_, value, child) =>
                  Transform.scale(scale: 1.0 + value * 0.015, child: child),
            ),

        // Top info bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                if (widget.warehouseName != null)
                  StatusChip(
                    label: widget.warehouseName!,
                    color: AppColors.success,
                    icon: Icons.verified_outlined,
                  ),
                const Spacer(),
                PulseDot(
                  color: widget.isFaceDetected
                      ? AppColors.success
                      : AppColors.accent,
                ),
                const Gap(8),
                Text(
                  widget.isProcessing
                      ? 'Processing...'
                      : widget.isFaceDetected
                      ? 'Face Detected'
                      : 'Scanning...',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom instruction
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.75), Colors.transparent],
              ),
            ),
            child: Column(
              children: [
                // Status text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: widget.isProcessing
                      ? _StatusPill(
                          key: const ValueKey('processing'),
                          label: 'Verifying identity...',
                          color: AppColors.warning,
                          icon: Icons.hourglass_top_outlined,
                        )
                      : widget.isFaceDetected
                      ? _StatusPill(
                          key: const ValueKey('detected'),
                          label: 'Hold still — capturing',
                          color: AppColors.success,
                          icon: Icons.check_circle_outline,
                        )
                      : _StatusPill(
                          key: const ValueKey('scanning'),
                          label: 'Position face within the oval',
                          color: AppColors.accent,
                          icon: Icons.face_retouching_natural_outlined,
                        ),
                ),
                const Gap(16),
                Text(
                  'Make sure your face is well-lit\nand clearly visible',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusPill({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const Gap(8),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom Painters ──────────────────────────────────────────────────────────

class _OvalCutoutPainter extends CustomPainter {
  final double ovalWidth;
  final double ovalHeight;

  _OvalCutoutPainter({required this.ovalWidth, required this.ovalHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.58);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: ovalWidth,
      height: ovalHeight,
    );

    final path = Path()
      ..addRect(fullRect)
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OvalCutoutPainter old) =>
      old.ovalWidth != ovalWidth || old.ovalHeight != ovalHeight;
}

class _OvalBorderPainter extends CustomPainter {
  final Color color;

  _OvalBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawOval(rect, glowPaint);
    canvas.drawOval(rect, paint);

    // Corner accent marks
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width / 2;
    final ry = size.height / 2;
    const arcLen = 0.3;

    for (final angle in [0.0, pi / 2, pi, 3 * pi / 2]) {
      final startA = angle - arcLen / 2;
      final path = Path();
      final startX = cx + rx * cos(startA);
      final startY = cy + ry * sin(startA);
      path.moveTo(startX, startY);

      for (double t = startA; t <= startA + arcLen; t += 0.02) {
        path.lineTo(cx + rx * cos(t), cy + ry * sin(t));
      }
      canvas.drawPath(path, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(_OvalBorderPainter old) => old.color != color;
}
