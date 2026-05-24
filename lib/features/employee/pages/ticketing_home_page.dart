import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/core/widgets/app_logo.dart';

class TicketingHomeFragment extends StatefulWidget {
  const TicketingHomeFragment({super.key});

  @override
  State<TicketingHomeFragment> createState() => _TicketingHomeFragmentState();
}

class _TicketingHomeFragmentState extends State<TicketingHomeFragment> {
  static const Color _primaryRed = Color(0xFFFF1F1F);
  static const Color _textDark = Color(0xFF141827);
  static const Color _textMuted = Color(0xFF667085);
  static const Color _screenBg = Color(0xFFFFFCF8);
  static const Color _cardBg = Colors.white;
  static const Color _borderSoft = Color(0xFFE9ECEF);
  static const Color _green = Color(0xFF159947);
  static const Color _greenSoft = Color(0xFFEAF8EF);

  static const String _breakfastImage = 'assets/images/auth_login_header.png';
  static const String _lunchImage = 'assets/images/auth_login_header.png';
  static const String _dinnerImage = 'assets/images/auth_login_header.png';

  int _selectedMealIndex = 0;

  final List<_TicketingMealData> _meals = const [
    _TicketingMealData(
      type: 'Breakfast',
      title: 'Breakfast Meal',
      vendor: 'Meal Counter',
      imagePath: _breakfastImage,
    ),
    _TicketingMealData(
      type: 'Lunch',
      title: 'Lunch Meal',
      vendor: 'Meal Counter',
      imagePath: _lunchImage,
    ),
    _TicketingMealData(
      type: 'Dinner',
      title: 'Dinner Meal',
      vendor: 'Meal Counter',
      imagePath: _dinnerImage,
    ),
  ];

  _TicketingMealData get _selectedMeal => _meals[_selectedMealIndex];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _screenBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _TicketingLayout.fromSize(
            constraints.maxWidth,
            constraints.maxHeight,
          );

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  layout.horizontalPadding,
                  layout.topPadding,
                  layout.horizontalPadding,
                  layout.bottomPadding,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: layout.maxContentWidth,
                      ),
                      child: layout.isDesktop
                          ? _DesktopTicketingBody(
                              layout: layout,
                              selectedMealIndex: _selectedMealIndex,
                              selectedMeal: _selectedMeal,
                              onMealChanged: _onMealChanged,
                            )
                          : _MobileTicketingBody(
                              layout: layout,
                              selectedMealIndex: _selectedMealIndex,
                              selectedMeal: _selectedMeal,
                              onMealChanged: _onMealChanged,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onMealChanged(int index) async {
    if (_selectedMealIndex == index) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Only one ticketing meal allowed'),
          content: Text(
            'Ticketing can be raised for only one meal at a time. Change your selection to ${_meals[index].title}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep current'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryRed,
              ),
              child: const Text('Change'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() => _selectedMealIndex = index);
    }
  }
}

class _MobileTicketingBody extends StatelessWidget {
  const _MobileTicketingBody({
    required this.layout,
    required this.selectedMealIndex,
    required this.selectedMeal,
    required this.onMealChanged,
  });

  final _TicketingLayout layout;
  final int selectedMealIndex;
  final _TicketingMealData selectedMeal;
  final ValueChanged<int> onMealChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TicketingHeader(layout: layout),
        SizedBox(height: layout.sectionGap),
        _MealModeTabs(
          layout: layout,
          selectedMealIndex: selectedMealIndex,
          onMealChanged: onMealChanged,
        ),
        SizedBox(height: layout.sectionGap * 0.72),
        _AvailableHeader(layout: layout),
        SizedBox(height: layout.smallGap),
        _TicketingMealCard(layout: layout, meal: selectedMeal),
      ],
    );
  }
}

class _DesktopTicketingBody extends StatelessWidget {
  const _DesktopTicketingBody({
    required this.layout,
    required this.selectedMealIndex,
    required this.selectedMeal,
    required this.onMealChanged,
  });

  final _TicketingLayout layout;
  final int selectedMealIndex;
  final _TicketingMealData selectedMeal;
  final ValueChanged<int> onMealChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TicketingHeader(layout: layout),
        SizedBox(height: layout.sectionGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MealModeTabs(
                    layout: layout,
                    selectedMealIndex: selectedMealIndex,
                    onMealChanged: onMealChanged,
                  ),
                  SizedBox(height: layout.sectionGap),
                  _AvailableHeader(layout: layout),
                  SizedBox(height: layout.smallGap),
                  _DesktopInfoPanel(layout: layout, meal: selectedMeal),
                  SizedBox(height: layout.smallGap),
                  _DesktopRulesPanel(layout: layout),
                ],
              ),
            ),
            SizedBox(width: layout.gridSpacing),
            Expanded(
              flex: 10,
              child: _TicketingMealCard(layout: layout, meal: selectedMeal),
            ),
          ],
        ),
      ],
    );
  }
}

class _TicketingHeader extends StatelessWidget {
  const _TicketingHeader({required this.layout});

  final _TicketingLayout layout;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppLogo(height: layout.logoHeight, isBrand: true),
            const Spacer(),
            Material(
              color: const Color(0xFFFFE7DE),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () => context.push(AppRoutes.employeeProfile),
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  width: layout.profileButtonSize,
                  height: layout.profileButtonSize,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: _TicketingHomeFragmentState._textDark,
                    size: layout.profileIconSize,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: layout.headerTextGap),
        Text(
          'Hi,',
          style: TextStyle(
            fontSize: layout.titleSize,
            height: 1.02,
            fontWeight: FontWeight.w900,
            color: _TicketingHomeFragmentState._textDark,
            letterSpacing: layout.isDesktop ? -1.25 : -1.05,
          ),
        ),
        SizedBox(height: 8 * scale),
        Text(
          'Meal Counter',
          style: TextStyle(
            fontSize: layout.subtitleSize,
            height: 1.02,
            fontWeight: FontWeight.w900,
            color: _TicketingHomeFragmentState._primaryRed,
            letterSpacing: -0.45,
          ),
        ),
        SizedBox(height: 7 * scale),
        Text(
          "Select today's company-supported meal",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: layout.subtitleSize,
            height: 1.18,
            fontWeight: FontWeight.w700,
            color: _TicketingHomeFragmentState._textDark,
            letterSpacing: -0.25,
          ),
        ),
      ],
    );
  }
}

class _MealModeTabs extends StatelessWidget {
  const _MealModeTabs({
    required this.layout,
    required this.selectedMealIndex,
    required this.onMealChanged,
  });

  final _TicketingLayout layout;
  final int selectedMealIndex;
  final ValueChanged<int> onMealChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: layout.segmentHeight,
      padding: EdgeInsets.all(layout.segmentPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _MealTabButton(
              label: 'Breakfast',
              selected: selectedMealIndex == 0,
              layout: layout,
              onTap: () => onMealChanged(0),
            ),
          ),
          SizedBox(width: layout.segmentInnerGap),
          Expanded(
            child: _MealTabButton(
              label: 'Lunch',
              selected: selectedMealIndex == 1,
              layout: layout,
              onTap: () => onMealChanged(1),
            ),
          ),
          SizedBox(width: layout.segmentInnerGap),
          Expanded(
            child: _MealTabButton(
              label: 'Dinner',
              selected: selectedMealIndex == 2,
              layout: layout,
              onTap: () => onMealChanged(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealTabButton extends StatelessWidget {
  const _MealTabButton({
    required this.label,
    required this.selected,
    required this.layout,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _TicketingLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected
            ? _TicketingHomeFragmentState._primaryRed
            : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: _TicketingHomeFragmentState._primaryRed.withValues(
                    alpha: 0.20,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                  spreadRadius: -3,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : _TicketingHomeFragmentState._textMuted,
                fontSize: layout.tabTextSize,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailableHeader extends StatelessWidget {
  const _AvailableHeader({required this.layout});

  final _TicketingLayout layout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Available Today',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: layout.availableTitleSize,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: _TicketingHomeFragmentState._textDark,
              letterSpacing: -0.55,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: layout.scale * 11,
            vertical: layout.scale * 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5F7),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '1 item',
            style: TextStyle(
              fontSize: layout.itemCountSize,
              fontWeight: FontWeight.w800,
              color: _TicketingHomeFragmentState._textMuted,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _TicketingMealCard extends StatelessWidget {
  const _TicketingMealCard({required this.layout, required this.meal});

  final _TicketingLayout layout;
  final _TicketingMealData meal;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _TicketingHomeFragmentState._cardBg,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        border: Border.all(color: const Color(0xFFF0F1F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.068),
            blurRadius: layout.isDesktop ? 30 : 24,
            offset: Offset(0, layout.isDesktop ? 16 : 12),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: layout.mealImageHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _SafeAssetImage(imagePath: meal.imagePath, fit: BoxFit.cover),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.02),
                          Colors.black.withOpacity(0.20),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14 * scale,
                  bottom: 13 * scale,
                  child: _ImageBadge(
                    layout: layout,
                    text: meal.type,
                    icon: switch (meal.type) {
                      'Breakfast' => Icons.wb_sunny_outlined,
                      'Lunch' => Icons.wb_sunny_rounded,
                      _ => Icons.nights_stay_outlined,
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              layout.cardPadding,
              layout.cardPadding * 0.88,
              layout.cardPadding,
              layout.cardPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MealTitleBlock(meal: meal, layout: layout),
                SizedBox(height: layout.buttonTopGap),
                _ContinueButton(layout: layout, meal: meal),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  const _ImageBadge({
    required this.layout,
    required this.text,
    required this.icon,
  });

  final _TicketingLayout layout;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 11 * scale,
        vertical: 7 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 7),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _TicketingHomeFragmentState._primaryRed,
            size: layout.badgeIconSize,
          ),
          SizedBox(width: 6 * scale),
          Text(
            text,
            style: TextStyle(
              color: _TicketingHomeFragmentState._textDark,
              fontSize: layout.badgeTextSize,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealTitleBlock extends StatelessWidget {
  const _MealTitleBlock({required this.meal, required this.layout});

  final _TicketingMealData meal;
  final _TicketingLayout layout;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meal.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _TicketingHomeFragmentState._textDark,
                  fontSize: layout.mealTitleSize,
                  height: 1.06,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.45,
                ),
              ),
              SizedBox(height: 7 * layout.scale),
              Text(
                meal.vendor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _TicketingHomeFragmentState._textMuted,
                  fontSize: layout.mealVendorSize,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10 * layout.scale),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10 * layout.scale,
            vertical: 7 * layout.scale,
          ),
          decoration: BoxDecoration(
            color: _TicketingHomeFragmentState._greenSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Active',
            style: TextStyle(
              color: _TicketingHomeFragmentState._green,
              fontSize: layout.statusSize,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.layout,
    required this.meal,
  });

  final _TicketingLayout layout;
  final _TicketingMealData meal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: layout.buttonHeight,
      child: ElevatedButton(
        onPressed: () {
          context.push(
            AppRoutes.employeeMealAuthorization,
            extra: meal.type,
          );
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _TicketingHomeFragmentState._primaryRed,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'Continue to Authorization',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: layout.buttonTextSize,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            SizedBox(width: 8 * layout.scale),
            Icon(
              Icons.arrow_forward_rounded,
              size: layout.buttonIconSize,
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopInfoPanel extends StatelessWidget {
  const _DesktopInfoPanel({required this.layout, required this.meal});

  final _TicketingLayout layout;
  final _TicketingMealData meal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _TicketingHomeFragmentState._borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ticketing Access',
            style: TextStyle(
              color: _TicketingHomeFragmentState._textDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${meal.type} is company-supported. Employees can continue directly to authorization without payment.',
            style: const TextStyle(
              color: _TicketingHomeFragmentState._textMuted,
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _DesktopMiniStat(label: 'Meal Type', value: meal.type),
              const SizedBox(width: 12),
              const _DesktopMiniStat(label: 'Limit', value: '1 / User'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesktopRulesPanel extends StatelessWidget {
  const _DesktopRulesPanel({required this.layout});

  final _TicketingLayout layout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE2D8)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _TicketingHomeFragmentState._primaryRed,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ticketing mode is limited to the available company-supported meal option. Regular cart ordering is not shown in this flow.',
              style: TextStyle(
                color: _TicketingHomeFragmentState._textMuted,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopMiniStat extends StatelessWidget {
  const _DesktopMiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAF7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFE3DB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _TicketingHomeFragmentState._textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: _TicketingHomeFragmentState._textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafeAssetImage extends StatelessWidget {
  const _SafeAssetImage({required this.imagePath, required this.fit});

  final String imagePath;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.high,
      errorBuilder: (_1, _2, _3) {
        return Container(
          color: const Color(0xFFFFF2EC),
          alignment: Alignment.center,
          child: const Icon(
            Icons.restaurant_rounded,
            color: _TicketingHomeFragmentState._primaryRed,
            size: 42,
          ),
        );
      },
    );
  }
}

class _TicketingLayout {
  const _TicketingLayout({
    required this.isDesktop,
    required this.isTablet,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.scale,
    required this.sectionGap,
    required this.smallGap,
    required this.gridSpacing,
    required this.logoHeight,
    required this.headerTextGap,
    required this.titleSize,
    required this.subtitleSize,
    required this.segmentHeight,
    required this.segmentPadding,
    required this.segmentInnerGap,
    required this.tabTextSize,
    required this.availableTitleSize,
    required this.itemCountSize,
    required this.mealImageHeight,
    required this.cardRadius,
    required this.cardPadding,
    required this.mealTitleSize,
    required this.mealVendorSize,
    required this.statusSize,
    required this.buttonHeight,
    required this.buttonTopGap,
    required this.buttonTextSize,
    required this.buttonIconSize,
    required this.profileButtonSize,
    required this.profileIconSize,
    required this.badgeIconSize,
    required this.badgeTextSize,
  });

  final bool isDesktop;
  final bool isTablet;

  final double maxContentWidth;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double scale;
  final double sectionGap;
  final double smallGap;
  final double gridSpacing;

  final double logoHeight;
  final double headerTextGap;
  final double titleSize;
  final double subtitleSize;

  final double segmentHeight;
  final double segmentPadding;
  final double segmentInnerGap;
  final double tabTextSize;

  final double availableTitleSize;
  final double itemCountSize;

  final double mealImageHeight;
  final double cardRadius;
  final double cardPadding;

  final double mealTitleSize;
  final double mealVendorSize;
  final double statusSize;

  final double buttonHeight;
  final double buttonTopGap;
  final double buttonTextSize;
  final double buttonIconSize;

  final double profileButtonSize;
  final double profileIconSize;

  final double badgeIconSize;
  final double badgeTextSize;

  static _TicketingLayout fromSize(double width, double height) {
    if (width >= 1180) {
      return const _TicketingLayout(
        isDesktop: true,
        isTablet: false,
        maxContentWidth: 1160,
        horizontalPadding: 44,
        topPadding: 32,
        bottomPadding: 44,
        scale: 1.0,
        sectionGap: 30,
        smallGap: 16,
        gridSpacing: 28,
        logoHeight: 25,
        headerTextGap: 22,
        titleSize: 44,
        subtitleSize: 23,
        segmentHeight: 58,
        segmentPadding: 5,
        segmentInnerGap: 4,
        tabTextSize: 16,
        availableTitleSize: 26,
        itemCountSize: 13,
        mealImageHeight: 248,
        cardRadius: 28,
        cardPadding: 22,
        mealTitleSize: 27,
        mealVendorSize: 16,
        statusSize: 12,
        buttonHeight: 56,
        buttonTopGap: 20,
        buttonTextSize: 16,
        buttonIconSize: 22,
        profileButtonSize: 48,
        profileIconSize: 27,
        badgeIconSize: 16,
        badgeTextSize: 13,
      );
    }

    if (width >= 760) {
      return const _TicketingLayout(
        isDesktop: false,
        isTablet: true,
        maxContentWidth: 620,
        horizontalPadding: 34,
        topPadding: 28,
        bottomPadding: 42,
        scale: 1.0,
        sectionGap: 28,
        smallGap: 15,
        gridSpacing: 22,
        logoHeight: 23,
        headerTextGap: 20,
        titleSize: 38,
        subtitleSize: 21,
        segmentHeight: 58,
        segmentPadding: 5,
        segmentInnerGap: 4,
        tabTextSize: 16,
        availableTitleSize: 24,
        itemCountSize: 13,
        mealImageHeight: 230,
        cardRadius: 28,
        cardPadding: 21,
        mealTitleSize: 25,
        mealVendorSize: 16,
        statusSize: 11.5,
        buttonHeight: 55,
        buttonTopGap: 20,
        buttonTextSize: 15.5,
        buttonIconSize: 21,
        profileButtonSize: 46,
        profileIconSize: 26,
        badgeIconSize: 15,
        badgeTextSize: 12.5,
      );
    }

    final bool narrow = width < 370;
    final bool veryNarrow = width < 345;
    final bool short = height < 720;
    final bool veryShort = height < 650;

    final double baseScale = veryNarrow
        ? 0.88
        : narrow
            ? 0.93
            : 1.0;

    final double heightScale = veryShort
        ? 0.88
        : short
            ? 0.94
            : 1.0;

    final double scale = math.min(baseScale, heightScale);

    return _TicketingLayout(
      isDesktop: false,
      isTablet: false,
      maxContentWidth: 430,
      horizontalPadding: narrow ? 16 : 20,
      topPadding: veryShort
          ? 14
          : short
              ? 16
              : 20,
      bottomPadding: veryShort ? 22 : 30,
      scale: scale,
      sectionGap: veryShort
          ? 20
          : short
              ? 23
              : 28,
      smallGap: veryShort
          ? 10
          : short
              ? 12
              : 14,
      gridSpacing: 18,
      logoHeight: 20 * scale,
      headerTextGap: veryShort ? 14 : 18 * scale,
      titleSize: (34 * scale).clamp(28.0, 34.0),
      subtitleSize: (19 * scale).clamp(16.0, 19.0),
      segmentHeight: veryShort ? 48 : 54 * scale,
      segmentPadding: 4,
      segmentInnerGap: 4,
      tabTextSize: (15.5 * scale).clamp(13.2, 15.5),
      availableTitleSize: (22 * scale).clamp(18.5, 22.0),
      itemCountSize: (12.5 * scale).clamp(11.0, 12.5),
      mealImageHeight: veryShort
          ? 156
          : short
              ? 178
              : 202,
      cardRadius: (26 * scale).clamp(22.0, 26.0),
      cardPadding: (18 * scale).clamp(15.0, 18.0),
      mealTitleSize: (22 * scale).clamp(18.5, 22.0),
      mealVendorSize: (15.5 * scale).clamp(13.2, 15.5),
      statusSize: (11 * scale).clamp(9.8, 11.0),
      buttonHeight: (53 * scale).clamp(46.0, 53.0),
      buttonTopGap: veryShort ? 14 : 18 * scale,
      buttonTextSize: (15.5 * scale).clamp(13.2, 15.5),
      buttonIconSize: (21 * scale).clamp(18.0, 21.0),
      profileButtonSize: (42 * scale).clamp(36.0, 42.0),
      profileIconSize: (25 * scale).clamp(21.0, 25.0),
      badgeIconSize: (14 * scale).clamp(12.0, 14.0),
      badgeTextSize: (12 * scale).clamp(10.5, 12.0),
    );
  }
}

class _TicketingMealData {
  const _TicketingMealData({
    required this.type,
    required this.title,
    required this.vendor,
    required this.imagePath,
  });

  final String type;
  final String title;
  final String vendor;
  final String imagePath;
}
