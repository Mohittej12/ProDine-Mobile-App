import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_colors.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
// AppLogo removed on splash — show text-only ProDine branding

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _contentController;
  late final AnimationController _dotsController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  bool _showSplashContent = false;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );

    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_contentFade);

    _introController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Fire-and-forget — precache in background, don't block navigation
    _precacheAssets();

    // Stage 1: show app logo immediately
    await Future.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;
    setState(() => _showSplashContent = true);
    _contentController.forward();

    // Stage 2: keep splash visible before route transition
    await Future.delayed(const Duration(milliseconds: 980));

    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  void _precacheAssets() {
    // Non-blocking — images load in background, ready by the time user needs them
    try {
      precacheImage(
        const AssetImage('assets/images/auth_login_header.png'),
        context,
      );
      precacheImage(const AssetImage('assets/images/app_logo.png'), context);
    } catch (_) {}
  }

  @override
  void dispose() {
    _introController.dispose();
    _contentController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortestSide = size.shortestSide;

    final bool isCompactMobile = shortestSide < 380;
    final bool isTabletOrDesktop = size.width >= 700;

    final double logoHeight = isTabletOrDesktop
        ? 150
        : isCompactMobile
            ? 92
            : 112;

    final double maxContentWidth = isTabletOrDesktop ? 520 : 360;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ProDine',
                            style: TextStyle(
                              color: AppColors.primaryRed,
                              fontSize: logoHeight * 0.55,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: !_showSplashContent
                                ? const SizedBox(
                                    height: 1,
                                    key: ValueKey('empty'),
                                  )
                                : SlideTransition(
                                    key: const ValueKey('content'),
                                    position: _contentSlide,
                                    child: FadeTransition(
                                      opacity: _contentFade,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            height: isCompactMobile ? 26 : 32,
                                          ),
                                          Text(
                                            'Smart Cafeteria Experience',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: const Color(0xFF344054),
                                              fontSize:
                                                  isTabletOrDesktop ? 16 : 14,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0,
                                            ),
                                          ),
                                          SizedBox(
                                            height: isCompactMobile ? 14 : 18,
                                          ),
                                          _ThreeDotLoader(
                                            controller: _dotsController,
                                            dotSize: isTabletOrDesktop ? 10 : 8,
                                            spacing: isTabletOrDesktop ? 9 : 7,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreeDotLoader extends StatelessWidget {
  const _ThreeDotLoader({
    required this.controller,
    required this.dotSize,
    required this.spacing,
  });

  final AnimationController controller;
  final double dotSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final double progress = (controller.value + (index * 0.22)) % 1.0;
            final double opacity = _dotOpacity(progress);
            final double scale = _dotScale(progress);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double _dotOpacity(double value) {
    if (value < 0.5) {
      return 0.35 + (value * 1.3);
    }
    return 1.0 - ((value - 0.5) * 1.1);
  }

  double _dotScale(double value) {
    if (value < 0.5) {
      return 0.82 + (value * 0.42);
    }
    return 1.03 - ((value - 0.5) * 0.32);
  }
}
