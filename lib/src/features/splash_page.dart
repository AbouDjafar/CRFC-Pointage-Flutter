import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_controller.dart';
import '../core/design_system.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _timer = Timer(const Duration(milliseconds: 2400), _navigateNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _navigateNext() {
    if (!mounted) {
      return;
    }
    final loggedIn = ref.read(appControllerProvider).value?.currentUser != null;
    context.go(loggedIn ? '/dashboard' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CrfcColors.splashTop, CrfcColors.splashBottom],
          ),
        ),
        child: Stack(
          children: [
            for (final circle in const [
              (
                size: 600.0,
                alignment: Alignment.bottomRight,
                offset: Offset(200, 200),
              ),
              (
                size: 400.0,
                alignment: Alignment.bottomRight,
                offset: Offset(100, 100),
              ),
              (
                size: 200.0,
                alignment: Alignment.bottomRight,
                offset: Offset.zero,
              ),
              (
                size: 500.0,
                alignment: Alignment.topLeft,
                offset: Offset(-200, -200),
              ),
            ])
              Align(
                alignment: circle.alignment,
                child: Transform.translate(
                  offset: circle.offset,
                  child: Container(
                    width: circle.size,
                    height: circle.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) => Transform.rotate(
                          angle: _controller.value * math.pi * 2,
                          child: child,
                        ),
                        child: Container(
                          width: 164,
                          height: 164,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.transparent,
                              width: 2,
                            ),
                            gradient: const SweepGradient(
                              colors: [
                                CrfcColors.splashOrange,
                                Colors.transparent,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 140,
                        height: 140,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55000000),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: SvgPicture.asset('crfc_logo.svg'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'CRFC',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 10,
                    ),
                  ),
                  Container(
                    width: 160,
                    height: 2,
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          CrfcColors.splashOrange,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Text(
                    'POINTAGE',
                    style: GoogleFonts.lato(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 7,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 58,
              child: Column(
                children: [
                  SizedBox(
                    width: 160,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 2200),
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 2,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFFFBBF24),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'CHARGEMENT...',
                    style: GoogleFonts.lato(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
