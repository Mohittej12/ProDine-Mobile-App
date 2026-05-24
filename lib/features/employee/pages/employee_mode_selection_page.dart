import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_colors.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/features/employee/data/employee_cart_store.dart';

class EmployeeModeSelectionPage extends StatefulWidget {
  const EmployeeModeSelectionPage({super.key});

  @override
  State<EmployeeModeSelectionPage> createState() =>
      _EmployeeModeSelectionPageState();
}

class _EmployeeModeSelectionPageState extends State<EmployeeModeSelectionPage>
    with TickerProviderStateMixin {
  int selectedIndex = 0;
  bool _isNavigating = false;

  late final AnimationController _entranceCtrl;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _welcomeFade;
  late final Animation<Offset> _welcomeSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _card1Fade;
  late final Animation<Offset> _card1Slide;
  late final Animation<double> _card2Fade;
  late final Animation<Offset> _card2Slide;
  late final Animation<double> _trustFade;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;

  late final AnimationController _card1ScaleCtrl;
  late final AnimationController _card2ScaleCtrl;

  static const double _maxMobileWidth = 430;
  static const Color _textDark = Color(0xFF171717);
  static const Color _textMuted = Color(0xFF706B67);

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    const curve = Curves.easeOutCubic;
    const slideUp = Offset(0, 0.6);

    _logoFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.45, curve: curve),
    );
    _logoSlide = Tween<Offset>(
      begin: slideUp,
      end: Offset.zero,
    ).animate(_logoFade);

    _welcomeFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.08, 0.50, curve: curve),
    );
    _welcomeSlide = Tween<Offset>(
      begin: slideUp,
      end: Offset.zero,
    ).animate(_welcomeFade);

    _titleFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.14, 0.55, curve: curve),
    );
    _titleSlide = Tween<Offset>(
      begin: slideUp,
      end: Offset.zero,
    ).animate(_titleFade);

    _subtitleFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.20, 0.60, curve: curve),
    );
    _subtitleSlide = Tween<Offset>(
      begin: slideUp,
      end: Offset.zero,
    ).animate(_subtitleFade);

    _card1Fade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.28, 0.68, curve: curve),
    );
    _card1Slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(_card1Fade);

    _card2Fade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.38, 0.78, curve: curve),
    );
    _card2Slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(_card2Fade);

    _trustFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.52, 0.88, curve: curve),
    );

    _buttonFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.60, 1.0, curve: curve),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(_buttonFade);

    _card1ScaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      lowerBound: 1.0,
      upperBound: 1.018,
      value: 1.018,
    );
    _card2ScaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      lowerBound: 1.0,
      upperBound: 1.018,
      value: 1.0,
    );

    // Start entrance AFTER route transition finishes (220ms CupertinoPageTransition)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Small delay to let route transition complete first
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _entranceCtrl.forward();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isNavigating = false;
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _card1ScaleCtrl.dispose();
    _card2ScaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, root) {
            final screenW = root.maxWidth;
            final screenH = root.maxHeight;

            final contentW = math.min(screenW, _maxMobileWidth);
            final narrow = contentW < 370;
            final compact = screenH < 720;
            final veryCompact = screenH < 620;

            final scale = (screenH / 820).clamp(0.62, 1.0);

            final horizontalPadding = narrow ? 16.0 : 22.0;

            final logoHeight = (52 * scale).clamp(34.0, 52.0);
            final titleSize = (35 * scale).clamp(24.0, 35.0);
            final welcomeSize = (16 * scale).clamp(12.0, 16.0);
            final subtitleSize = (15 * scale).clamp(11.5, 15.0);

            final cardHeight = (126 * scale).clamp(92.0, 126.0);
            final iconSize = (70 * scale).clamp(48.0, 70.0);
            final buttonHeight = (50 * scale).clamp(40.0, 50.0);
            final trustIconSize = (40 * scale).clamp(28.0, 40.0);

            final topGap = (32 * scale).clamp(20.0, 32.0);
            final logoToWelcomeGap = (28 * scale).clamp(12.0, 28.0);
            final welcomeToTitleGap = (12 * scale).clamp(6.0, 12.0);
            final titleToSubtitleGap = (14 * scale).clamp(8.0, 14.0);
            final subtitleToCardsGap = (40 * scale).clamp(24.0, 40.0);
            final cardGap = (18 * scale).clamp(12.0, 18.0);
            final bottomGap = (7 * scale).clamp(4.0, 7.0);

            return Center(
              child: SizedBox(
                width: contentW,
                height: screenH,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: veryCompact ? 48 : 66,
                      height: veryCompact
                          ? 52
                          : compact
                              ? 70
                              : 102,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: veryCompact ? 0.22 : 0.36,
                          child: CustomPaint(
                            painter: _PremiumDiningLineArtPainter(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: topGap),
                          SlideTransition(
                            position: _logoSlide,
                            child: FadeTransition(
                              opacity: _logoFade,
                              child: _Logo(height: logoHeight),
                            ),
                          ),
                          SizedBox(height: logoToWelcomeGap),
                          SlideTransition(
                            position: _welcomeSlide,
                            child: FadeTransition(
                              opacity: _welcomeFade,
                              child: Text(
                                'Welcome back! 👋',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: welcomeSize,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: welcomeToTitleGap),
                          SlideTransition(
                            position: _titleSlide,
                            child: FadeTransition(
                              opacity: _titleFade,
                              child: Text(
                                'How would you like\nto order today?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _textDark,
                                  fontSize: titleSize,
                                  height: 1.05,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.15,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: titleToSubtitleGap),
                          SlideTransition(
                            position: _subtitleSlide,
                            child: FadeTransition(
                              opacity: _subtitleFade,
                              child: Text(
                                'Choose your meal access mode to continue',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: subtitleSize,
                                  height: 1.2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: subtitleToCardsGap),
                          SlideTransition(
                            position: _card1Slide,
                            child: FadeTransition(
                              opacity: _card1Fade,
                              child: ScaleTransition(
                                scale: _card1ScaleCtrl,
                                child: _ModeCard(
                                  height: cardHeight,
                                  iconSize: iconSize,
                                  selected: selectedIndex == 0,
                                  recommended: true,
                                  title: 'Pre-Order & Pickup',
                                  highlight: 'Browse cafeteria & pickup orders',
                                  subtitle: veryCompact
                                      ? 'Order before and Pickup later'
                                      : 'Order before and Pickup later',
                                  icon: Icons.shopping_bag_outlined,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => selectedIndex = 0);
                                    _card1ScaleCtrl.forward();
                                    _card2ScaleCtrl.reverse();
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: cardGap),
                          SlideTransition(
                            position: _card2Slide,
                            child: FadeTransition(
                              opacity: _card2Fade,
                              child: ScaleTransition(
                                scale: _card2ScaleCtrl,
                                child: _ModeCard(
                                  height: cardHeight,
                                  iconSize: iconSize,
                                  selected: selectedIndex == 1,
                                  recommended: false,
                                  title: 'Ticketing',
                                  highlight: 'Breakfast & Dinner Access',
                                  subtitle: 'Company-supported meals',
                                  icon: Icons.local_activity_rounded,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => selectedIndex = 1);
                                    _card2ScaleCtrl.forward();
                                    _card1ScaleCtrl.reverse();
                                  },
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (!veryCompact) ...[
                            FadeTransition(
                              opacity: _trustFade,
                              child: _TrustRow(
                                iconSize: trustIconSize,
                                compact: compact,
                              ),
                            ),
                            SizedBox(height: bottomGap),
                          ],
                          SlideTransition(
                            position: _buttonSlide,
                            child: FadeTransition(
                              opacity: _buttonFade,
                              child: AnimatedScale(
                                scale: _isNavigating ? 0.96 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: buttonHeight,
                                  child: ElevatedButton(
                                    onPressed: _isNavigating ? null : _continue,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryRed,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: Text(
                                      'Continue with ${selectedIndex == 0 ? 'Pre-Order & Pickup' : 'Ticketing'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: (15 * scale).clamp(
                                          12.0,
                                          15.0,
                                        ),
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: bottomGap),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _continue() {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    HapticFeedback.lightImpact();

    final route =
        selectedIndex == 0 ? AppRoutes.employeeHome : AppRoutes.ticketingHome;

    EmployeeCartStore.instance.setTicketingMode(selectedIndex == 1);
    context.push(route);
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Text(
      'ProDine',
      style: TextStyle(
        color: AppColors.primaryRed,
        fontSize: height * 0.9,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.height,
    required this.iconSize,
    required this.selected,
    required this.recommended,
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final double height;
  final double iconSize;
  final bool selected;
  final bool recommended;
  final String title;
  final String highlight;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = height < 116;
    final tiny = height < 102;

    final badgeHeight = tiny ? 22.0 : 25.0;
    final badgeTopSpace = recommended ? badgeHeight + 8 : 0.0;

    final titleSize = tiny
        ? 16.5
        : compact
            ? 18.5
            : 21.0;

    final highlightSize = tiny
        ? 10.7
        : compact
            ? 12.0
            : 13.5;

    final subtitleSize = tiny
        ? 10.0
        : compact
            ? 11.2
            : 12.5;

    final arrowSize = tiny
        ? 34.0
        : compact
            ? 38.0
            : 44.0;

    final radius = compact ? 22.0 : 26.0;

    return SizedBox(
      height: height + badgeTopSpace,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (recommended)
            Positioned(
              top: 0,
              left: 22,
              child: Container(
                height: badgeHeight,
                padding: EdgeInsets.symmetric(horizontal: tiny ? 8 : 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.primaryRed.withOpacity(0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: tiny ? 11 : 13,
                      color: AppColors.primaryRed,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Recommended',
                      style: TextStyle(
                        color: AppColors.primaryRed,
                        fontSize: tiny ? 9.5 : 11.2,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: badgeTopSpace,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(radius),
                splashColor: AppColors.primaryRed.withOpacity(0.06),
                highlightColor: AppColors.primaryRed.withOpacity(0.03),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  height: height,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: tiny
                        ? 12
                        : compact
                            ? 14
                            : 17,
                    vertical: tiny
                        ? 10
                        : compact
                            ? 12
                            : 15,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFFFFBFB) : Colors.white,
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: selected
                          ? AppColors.primaryRed.withOpacity(0.38)
                          : const Color(0xFFE8E8E8),
                      width: selected ? 1.45 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: selected
                            ? AppColors.primaryRed.withOpacity(0.085)
                            : Colors.black.withOpacity(0.045),
                        blurRadius: selected ? 23 : 18,
                        offset: const Offset(0, 10),
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryRed
                              : const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(iconSize * 0.28),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryRed
                                : const Color(0xFFF0F0F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: selected
                                  ? AppColors.primaryRed.withOpacity(0.20)
                                  : Colors.black.withOpacity(0.025),
                              blurRadius: selected ? 15 : 11,
                              offset: const Offset(0, 7),
                              spreadRadius: -3,
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          size: iconSize * 0.45,
                          color:
                              selected ? Colors.white : const Color(0xFF2D2D2D),
                        ),
                      ),
                      SizedBox(
                        width: tiny
                            ? 10
                            : compact
                                ? 12
                                : 15,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF171717),
                                fontSize: titleSize,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.65,
                              ),
                            ),
                            SizedBox(height: tiny ? 3 : 5),
                            Text(
                              highlight,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.primaryRed,
                                fontSize: highlightSize,
                                height: 1.16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: tiny ? 2 : 4),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF707070),
                                fontSize: subtitleSize,
                                height: 1.16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: tiny ? 4 : 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        width: arrowSize,
                        height: arrowSize,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFFFECEC)
                              : const Color(0xFFF7F7F7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: tiny
                              ? 25
                              : compact
                                  ? 28
                                  : 32,
                          color: selected
                              ? AppColors.primaryRed
                              : const Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.iconSize, required this.compact});

  final double iconSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TrustItem(
            icon: Icons.verified_user_outlined,
            label: 'Secure\n& Safe',
            iconSize: iconSize,
            compact: compact,
          ),
        ),
        _divider(),
        Expanded(
          child: _TrustItem(
            icon: Icons.bolt_outlined,
            label: 'Fast\nCheckout',
            iconSize: iconSize,
            compact: compact,
          ),
        ),
        _divider(),
        Expanded(
          child: _TrustItem(
            icon: Icons.restaurant_menu_outlined,
            label: 'Best Food\nOptions',
            iconSize: iconSize,
            compact: compact,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: compact ? 24 : 34,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: const Color(0xFFE8E8E8),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.icon,
    required this.label,
    required this.iconSize,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final double iconSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF1F1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryRed, size: iconSize * 0.48),
        ),
        SizedBox(height: compact ? 3 : 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF151515),
            fontSize: compact ? 9.2 : 12.2,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _PremiumDiningLineArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.primaryRed.withOpacity(0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final floorY = h * 0.86;

    canvas.drawLine(Offset(0, floorY), Offset(w, floorY), p);

    _drawLeftCounter(canvas, p, w, h, floorY);
    _drawCafeTable(canvas, p, w, h, floorY);
    _drawRightPlant(canvas, p, w, h, floorY);
  }

  void _drawLeftCounter(
    Canvas canvas,
    Paint p,
    double w,
    double h,
    double floorY,
  ) {
    final counterW = w * 0.22;
    final counterH = h * 0.36;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, floorY - counterH, counterW, counterH),
        const Radius.circular(8),
      ),
      p,
    );

    canvas.drawLine(
      Offset(w * 0.035, floorY - counterH),
      Offset(w * 0.035, floorY - counterH - h * 0.24),
      p,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.035, floorY - counterH - h * 0.26),
        width: 28,
        height: 14,
      ),
      math.pi,
      math.pi,
      false,
      p,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.055, floorY - h * 0.16, w * 0.11, h * 0.07),
        const Radius.circular(10),
      ),
      p,
    );

    canvas.drawCircle(Offset(w * 0.18, floorY - h * 0.15), h * 0.045, p);
  }

  void _drawCafeTable(
    Canvas canvas,
    Paint p,
    double w,
    double h,
    double floorY,
  ) {
    final cx = w * 0.50;
    final tableY = floorY - h * 0.22;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, tableY),
          width: w * 0.30,
          height: h * 0.22,
        ),
        Radius.circular(h * 0.10),
      ),
      p,
    );

    canvas.drawLine(
      Offset(cx - w * 0.10, tableY + h * 0.08),
      Offset(cx - w * 0.16, floorY),
      p,
    );

    canvas.drawLine(
      Offset(cx + w * 0.10, tableY + h * 0.08),
      Offset(cx + w * 0.16, floorY),
      p,
    );

    _drawPerson(
      canvas,
      p,
      head: Offset(cx - w * 0.18, floorY - h * 0.43),
      facingRight: true,
      unit: h,
    );

    _drawPerson(
      canvas,
      p,
      head: Offset(cx, floorY - h * 0.52),
      facingRight: true,
      unit: h,
    );

    _drawPerson(
      canvas,
      p,
      head: Offset(cx + w * 0.18, floorY - h * 0.43),
      facingRight: false,
      unit: h,
    );
  }

  void _drawPerson(
    Canvas canvas,
    Paint p, {
    required Offset head,
    required bool facingRight,
    required double unit,
  }) {
    final r = unit * 0.075;
    final dir = facingRight ? 1.0 : -1.0;

    canvas.drawCircle(head, r, p);

    final neck = Offset(head.dx, head.dy + r);
    final waist = Offset(head.dx - dir * unit * 0.035, head.dy + unit * 0.31);

    canvas.drawLine(neck, waist, p);

    canvas.drawLine(
      Offset(neck.dx, neck.dy + unit * 0.09),
      Offset(neck.dx + dir * unit * 0.18, neck.dy + unit * 0.17),
      p,
    );

    canvas.drawLine(
      waist,
      Offset(waist.dx - unit * 0.10, waist.dy + unit * 0.15),
      p,
    );

    canvas.drawLine(
      waist,
      Offset(waist.dx + unit * 0.09, waist.dy + unit * 0.15),
      p,
    );
  }

  void _drawRightPlant(
    Canvas canvas,
    Paint p,
    double w,
    double h,
    double floorY,
  ) {
    final x = w * 0.91;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 14, floorY - h * 0.28, 28, h * 0.28),
        const Radius.circular(5),
      ),
      p,
    );

    canvas.drawLine(
      Offset(x, floorY - h * 0.28),
      Offset(x, floorY - h * 0.76),
      p,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x - w * 0.055, floorY - h * 0.58),
        width: w * 0.10,
        height: h * 0.16,
      ),
      p,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x + w * 0.055, floorY - h * 0.54),
        width: w * 0.10,
        height: h * 0.16,
      ),
      p,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x + w * 0.01, floorY - h * 0.76),
        width: w * 0.055,
        height: h * 0.28,
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
