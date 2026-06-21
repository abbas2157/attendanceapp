// lib/features/splash/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../home/presentation/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const HomeScreen(),
            transitionsBuilder: (_, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Face scan icon
              _buildFaceScanIcon(),
              const Gap(40),
              // App name
              Text(
                    'ATTEND',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: 8,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 700.ms)
                  .slideY(begin: 0.3, end: 0),
              const Gap(8),
              Text(
                'Face Recognition System',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  letterSpacing: 2.5,
                ),
              ).animate().fadeIn(delay: 900.ms, duration: 700.ms),
              const Gap(60),
              // Loading indicator
              SizedBox(
                width: 180,
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 2,
                ),
              ).animate().fadeIn(delay: 1200.ms, duration: 400.ms),
              const Gap(16),
              Text(
                'Initializing...',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ).animate().fadeIn(delay: 1400.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaceScanIcon() {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring pulse
          ...List.generate(3, (i) {
            return Container(
                  width: 160.0 - i * 20,
                  height: 160.0 - i * 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.15 - i * 0.04),
                      width: 1,
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.0, 1.0),
                  duration: Duration(milliseconds: 1600 + i * 200),
                  curve: Curves.easeOut,
                )
                .fadeOut(
                  begin: 0.8,
                  duration: Duration(milliseconds: 1600 + i * 200),
                );
          }),
          // Face icon container
          Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceCard,
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.face_retouching_natural_outlined,
                  color: AppColors.accent,
                  size: 48,
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.6, 0.6)),
          // Scan line
          AnimatedBuilder(
            animation: _scanController,
            builder: (_, _) {
              return Positioned(
                top: 32 + (_scanController.value * 96),
                left: 40,
                right: 40,
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.accent,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.7, 0.7));
  }
}
