import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/features/employee/data/employee_cart_store.dart';

Future<void> showEmployeeCartSwitcher(
  BuildContext context, {
  ValueChanged<String>? onViewMenu,
}) async {
  final groups = _CartRestaurantGroup.fromEntries(
    EmployeeCartStore.instance.items,
  );

  if (groups.isEmpty) {
    context.push(AppRoutes.employeeCart);
    return;
  }

  HapticFeedback.selectionClick();
  await _showEmployeeCartSwitcherDialog(context, onViewMenu: onViewMenu);
}

String employeeCartRouteForShop(String shopName) {
  return Uri(
    path: AppRoutes.employeeCart,
    queryParameters: {'shop': shopName},
  ).toString();
}

class EmployeeCartOverlay extends StatefulWidget {
  const EmployeeCartOverlay({
    super.key,
    required this.bottomOffset,
    this.horizontalPadding = 20,
    this.onViewMenu,
  });

  final double bottomOffset;
  final double horizontalPadding;
  final ValueChanged<String>? onViewMenu;

  @override
  State<EmployeeCartOverlay> createState() => _EmployeeCartOverlayState();
}

class _EmployeeCartOverlayState extends State<EmployeeCartOverlay> {
  static const Color _primary = Color(0xFFFF3154);
  static const Color _text = Color(0xFF101828);
  static const Color _muted = Color(0xFF667085);
  static const Color _line = Color(0xFFE9ECF2);

  String? _dismissedShop;
  int _lastItemCount = EmployeeCartStore.instance.itemCount;

  @override
  void initState() {
    super.initState();
    EmployeeCartStore.instance.addListener(_handleCartChanged);
  }

  @override
  void dispose() {
    EmployeeCartStore.instance.removeListener(_handleCartChanged);
    super.dispose();
  }

  void _handleCartChanged() {
    if (!mounted) return;

    final groups = _CartRestaurantGroup.fromEntries(
      EmployeeCartStore.instance.items,
    );
    final nextItemCount = EmployeeCartStore.instance.itemCount;
    if (nextItemCount > _lastItemCount) _dismissedShop = null;
    _lastItemCount = nextItemCount;

    if (_dismissedShop != null &&
        !groups.any((group) => group.shopName == _dismissedShop)) {
      _dismissedShop = null;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final groups = _CartRestaurantGroup.fromEntries(
      EmployeeCartStore.instance.items,
    );
    final visibleGroups = groups
        .where((group) => group.shopName != _dismissedShop)
        .toList();
    final primaryGroup = visibleGroups.isNotEmpty ? visibleGroups.first : null;
    final isVisible = primaryGroup != null;

    return Positioned(
      left: widget.horizontalPadding,
      right: widget.horizontalPadding,
      bottom: widget.bottomOffset,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: IgnorePointer(
            ignoring: !isVisible,
            child: AnimatedSlide(
              offset: isVisible ? Offset.zero : const Offset(0, 0.32),
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: isVisible ? 1 : 0,
                duration: const Duration(milliseconds: 170),
                curve: Curves.easeOutCubic,
                child: primaryGroup == null
                    ? const SizedBox.shrink()
                    : _CollapsedCartCard(
                        group: primaryGroup,
                        moreCount: groups.length - 1,
                        onMoreTap: () => _showCartSwitcher(context, groups),
                        onViewCart: () => context.push(
                          employeeCartRouteForShop(primaryGroup.shopName),
                        ),
                        onViewMenu: () =>
                            widget.onViewMenu?.call(primaryGroup.shopName),
                        onRemove: () {
                          HapticFeedback.mediumImpact();
                          EmployeeCartStore.instance.removeShop(
                            primaryGroup.shopName,
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCartSwitcher(
    BuildContext context,
    List<_CartRestaurantGroup> groups,
  ) async {
    if (groups.length <= 1) return;

    HapticFeedback.selectionClick();
    await _showEmployeeCartSwitcherDialog(
      context,
      onViewMenu: widget.onViewMenu,
    );
  }
}

Future<void> _showEmployeeCartSwitcherDialog(
  BuildContext context, {
  ValueChanged<String>? onViewMenu,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close carts',
    barrierColor: Colors.black.withOpacity(0.52),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (dialogContext, _1, _2) {
      return _CartSwitcherSheet(
        onViewCart: (shopName) {
          Navigator.pop(dialogContext);
          context.push(employeeCartRouteForShop(shopName));
        },
        onViewMenu: (shopName) {
          Navigator.pop(dialogContext);
          onViewMenu?.call(shopName);
        },
        onRemoveShop: (shopName) {
          EmployeeCartStore.instance.removeShop(shopName);
          final nextGroups = _CartRestaurantGroup.fromEntries(
            EmployeeCartStore.instance.items,
          );
          if (nextGroups.isEmpty && dialogContext.mounted) {
            Navigator.pop(dialogContext);
          }
        },
        onClearAll: () {
          EmployeeCartStore.instance.clear();
          Navigator.pop(dialogContext);
        },
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final isWide = MediaQuery.sizeOf(context).width >= 700;

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: isWide ? const Offset(0, 0.025) : const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _CollapsedCartCard extends StatefulWidget {
  const _CollapsedCartCard({
    required this.group,
    required this.moreCount,
    required this.onMoreTap,
    required this.onViewCart,
    required this.onViewMenu,
    required this.onRemove,
  });

  final _CartRestaurantGroup group;
  final int moreCount;
  final VoidCallback onMoreTap;
  final VoidCallback onViewCart;
  final VoidCallback onViewMenu;
  final VoidCallback onRemove;

  @override
  State<_CollapsedCartCard> createState() => _CollapsedCartCardState();
}

class _CollapsedCartCardState extends State<_CollapsedCartCard> {
  bool _removeRevealed = false;

  @override
  void didUpdateWidget(covariant _CollapsedCartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.shopName != widget.group.shopName) {
      _removeRevealed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildCard(context, constraints.maxWidth);
      },
    );
  }

  Widget _buildCard(BuildContext context, double maxWidth) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;
    final scale = (width / 390).clamp(0.86, 1.0).toDouble();
    final cardHeight = compact ? 60 * scale : 72.0;
    final thumbSize = compact ? 38 * scale : 50.0;
    final revealOffset = math.min(maxWidth * 0.25, compact ? 88.0 : 104.0);
    final removeWidth = revealOffset + (compact ? 17.0 : 20.0);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Positioned.fill(
          top: widget.moreCount > 0 ? 15 : 0,
          child: Align(
            alignment: Alignment.centerRight,
            child: AnimatedOpacity(
              opacity: _removeRevealed ? 1 : 0,
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOutCubic,
              child: _RemoveRevealAction(
                width: removeWidth,
                height: cardHeight,
                compact: compact,
                scale: scale,
                onTap: widget.onRemove,
              ),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 230),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
            _removeRevealed ? -revealOffset : 0,
            0,
            0,
          ),
          child: Container(
            height: cardHeight,
            margin: EdgeInsets.only(top: widget.moreCount > 0 ? 15 : 0),
            padding: EdgeInsets.fromLTRB(
              compact ? 7 * scale : 11,
              compact ? 7 * scale : 9,
              compact ? 7 * scale : 10,
              compact ? 7 * scale : 9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(compact ? 16 * scale : 19),
              border: Border.all(color: _EmployeeCartOverlayState._line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.13),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                _RestaurantThumb(
                  imagePath: widget.group.imagePath,
                  size: thumbSize,
                ),
                SizedBox(width: compact ? 7 * scale : 12),
                Expanded(
                  child: _RestaurantCartText(
                    group: widget.group,
                    compact: compact,
                    onTap: widget.onViewMenu,
                  ),
                ),
                SizedBox(width: compact ? 5 * scale : 10),
                _ViewCartButton(
                  compact: compact,
                  scale: scale,
                  onTap: widget.onViewCart,
                ),
                SizedBox(width: compact ? 5 * scale : 8),
                _CloseCircle(
                  compact: compact,
                  scale: scale,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _removeRevealed = !_removeRevealed);
                  },
                ),
              ],
            ),
          ),
        ),
        if (widget.moreCount > 0)
          Positioned(
            top: 0,
            child: _MoreChip(count: widget.moreCount, onTap: widget.onMoreTap),
          ),
      ],
    );
  }
}

class _RemoveRevealAction extends StatelessWidget {
  const _RemoveRevealAction({
    required this.width,
    required this.height,
    required this.compact,
    required this.scale,
    required this.onTap,
  });

  final double width;
  final double height;
  final bool compact;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFDDDD),
      borderRadius: BorderRadius.circular(compact ? 14 * scale : 18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 14 * scale : 18),
        child: SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: EdgeInsets.only(left: compact ? 22 * scale : 28),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'Remove',
                maxLines: 1,
                style: TextStyle(
                  color: _EmployeeCartOverlayState._primary,
                  fontSize: compact ? 13 * scale : 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartSwitcherSheet extends StatelessWidget {
  const _CartSwitcherSheet({
    required this.onViewCart,
    required this.onViewMenu,
    required this.onRemoveShop,
    required this.onClearAll,
  });

  final ValueChanged<String> onViewCart;
  final ValueChanged<String> onViewMenu;
  final ValueChanged<String> onRemoveShop;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: EmployeeCartStore.instance,
      builder: (context, _) {
        final currentGroups = _CartRestaurantGroup.fromEntries(
          EmployeeCartStore.instance.items,
        );
        if (currentGroups.isEmpty) return const SizedBox.shrink();

        return _CartSwitcherSheetContent(
          groups: currentGroups,
          onViewCart: onViewCart,
          onViewMenu: onViewMenu,
          onRemoveShop: onRemoveShop,
          onClearAll: onClearAll,
        );
      },
    );
  }
}

class _CartSwitcherSheetContent extends StatelessWidget {
  const _CartSwitcherSheetContent({
    required this.groups,
    required this.onViewCart,
    required this.onViewMenu,
    required this.onRemoveShop,
    required this.onClearAll,
  });

  final List<_CartRestaurantGroup> groups;
  final ValueChanged<String> onViewCart;
  final ValueChanged<String> onViewMenu;
  final ValueChanged<String> onRemoveShop;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 700;
    final panelMaxHeight = isWide ? size.height - 136 : size.height * 0.50;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: isWide
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 620,
                      maxHeight: panelMaxHeight,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SheetCloseButton(
                          size: 56,
                          iconSize: 31,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 14),
                        Flexible(
                          child: _CartSwitcherPanel(
                            groups: groups,
                            bottomPadding: 22,
                            isWide: true,
                            onViewCart: onViewCart,
                            onViewMenu: onViewMenu,
                            onRemoveShop: onRemoveShop,
                            onClearAll: onClearAll,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SheetCloseButton(
                      size: 50,
                      iconSize: 28,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: panelMaxHeight),
                      child: _CartSwitcherPanel(
                        groups: groups,
                        bottomPadding: 16 + bottomSafe,
                        isWide: false,
                        onViewCart: onViewCart,
                        onViewMenu: onViewMenu,
                        onRemoveShop: onRemoveShop,
                        onClearAll: onClearAll,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CartSwitcherPanel extends StatelessWidget {
  const _CartSwitcherPanel({
    required this.groups,
    required this.bottomPadding,
    required this.isWide,
    required this.onViewCart,
    required this.onViewMenu,
    required this.onRemoveShop,
    required this.onClearAll,
  });

  final List<_CartRestaurantGroup> groups;
  final double bottomPadding;
  final bool isWide;
  final ValueChanged<String> onViewCart;
  final ValueChanged<String> onViewMenu;
  final ValueChanged<String> onRemoveShop;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, isWide ? 22 : 17, 20, bottomPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(24),
          bottom: Radius.circular(isWide ? 28 : 0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your Carts (${groups.length})',
                  style: TextStyle(
                    color: _EmployeeCartOverlayState._text,
                    fontSize: isWide ? 23 : 21,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              TextButton(
                onPressed: onClearAll,
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: _EmployeeCartOverlayState._muted,
                    fontSize: isWide ? 14 : 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isWide ? 16 : 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: groups.length,
              separatorBuilder: (_1, _2) => SizedBox(height: isWide ? 12 : 10),
              itemBuilder: (context, index) {
                final group = groups[index];
                return _SwitcherRestaurantCard(
                  group: group,
                  isWide: isWide,
                  onViewCart: () => onViewCart(group.shopName),
                  onViewMenu: () => onViewMenu(group.shopName),
                  onRemove: () => onRemoveShop(group.shopName),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitcherRestaurantCard extends StatelessWidget {
  const _SwitcherRestaurantCard({
    required this.group,
    required this.isWide,
    required this.onViewCart,
    required this.onViewMenu,
    required this.onRemove,
  });

  final _CartRestaurantGroup group;
  final bool isWide;
  final VoidCallback onViewCart;
  final VoidCallback onViewMenu;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;
    final scale = (width / 390).clamp(0.86, 1.0).toDouble();
    final cardHeight = isWide ? 68.0 : (compact ? 54 * scale : 58.0);

    return Container(
      height: cardHeight,
      padding: EdgeInsets.fromLTRB(
        isWide ? 11 : 7 * scale,
        isWide ? 8 : 6 * scale,
        isWide ? 9 : 7 * scale,
        isWide ? 8 : 6 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWide ? 16 : 14),
        border: Border.all(color: _EmployeeCartOverlayState._line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _RestaurantThumb(
            imagePath: group.imagePath,
            size: isWide ? 48 : (compact ? 34 * scale : 36),
          ),
          SizedBox(width: isWide ? 11 : 7 * scale),
          Expanded(
            child: _RestaurantCartText(
              group: group,
              compact: compact || isWide,
              onTap: onViewMenu,
            ),
          ),
          SizedBox(width: isWide ? 9 : 5 * scale),
          _ViewCartButton(
            compact: compact || isWide,
            scale: isWide ? 1 : scale,
            onTap: onViewCart,
          ),
          SizedBox(width: isWide ? 7 : 4 * scale),
          _CloseCircle(
            compact: compact || isWide,
            scale: isWide ? 1 : scale,
            onTap: onRemove,
          ),
        ],
      ),
    );
  }
}

class _RestaurantCartText extends StatelessWidget {
  const _RestaurantCartText({
    required this.group,
    required this.compact,
    required this.onTap,
  });

  final _CartRestaurantGroup group;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 390)
        .clamp(0.86, 1.0)
        .toDouble();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.shopName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _EmployeeCartOverlayState._text,
                fontSize: compact ? 12.8 * scale : 17,
                height: 1.05,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: compact ? 3 * scale : 5),
            Row(
              children: [
                Flexible(
                  child: Text(
                    '${group.itemLabel} | View Menu',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _EmployeeCartOverlayState._text,
                      fontSize: compact ? 11.4 * scale : 14,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                SizedBox(width: 4 * scale),
                Icon(
                  Icons.play_arrow_rounded,
                  color: _EmployeeCartOverlayState._primary,
                  size: compact ? 14 * scale : 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantThumb extends StatelessWidget {
  const _RestaurantThumb({required this.imagePath, required this.size});

  final String imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_1, _2, _3) => Container(
            color: const Color(0xFFFFEEF2),
            child: const Icon(
              Icons.restaurant_rounded,
              color: _EmployeeCartOverlayState._primary,
              size: 23,
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewCartButton extends StatelessWidget {
  const _ViewCartButton({
    required this.compact,
    required this.scale,
    required this.onTap,
  });

  final bool compact;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 32 * scale : 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _EmployeeCartOverlayState._primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: compact ? 11 * scale : 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 11 * scale : 14),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
        ),
        child: Text(
          'View Cart',
          maxLines: 1,
          style: TextStyle(
            fontSize: compact ? 11.8 * scale : 16,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _CloseCircle extends StatelessWidget {
  const _CloseCircle({
    required this.compact,
    required this.scale,
    required this.onTap,
  });

  final bool compact;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 28.0 * scale : 38.0;

    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFF4F5FA),
          foregroundColor: _EmployeeCartOverlayState._muted,
          shape: const CircleBorder(),
        ),
        icon: Icon(Icons.close_rounded, size: compact ? 15 * scale : 19),
      ),
    );
  }
}

class _MoreChip extends StatelessWidget {
  const _MoreChip({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = (width / 390).clamp(0.86, 1.0).toDouble();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 13 * scale,
            vertical: 5 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _EmployeeCartOverlayState._line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+$count more',
                style: TextStyle(
                  color: _EmployeeCartOverlayState._primary,
                  fontSize: 14.5 * scale,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(width: 4 * scale),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: _EmployeeCartOverlayState._primary,
                size: 17 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({
    required this.onTap,
    required this.size,
    required this.iconSize,
  });

  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1F1F1F),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(Icons.close_rounded, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}

class _CartRestaurantGroup {
  const _CartRestaurantGroup({
    required this.shopName,
    required this.itemCount,
    required this.imagePath,
  });

  final String shopName;
  final int itemCount;
  final String imagePath;

  String get itemLabel => itemCount == 1 ? '1 item' : '$itemCount items';

  static List<_CartRestaurantGroup> fromEntries(
    List<EmployeeCartEntry> entries,
  ) {
    final orderedShops = <String>[];
    final quantities = <String, int>{};
    final images = <String, String>{};

    for (final entry in entries.reversed) {
      if (!quantities.containsKey(entry.shopName)) {
        orderedShops.add(entry.shopName);
        quantities[entry.shopName] = 0;
        images[entry.shopName] = entry.imagePath;
      }
      quantities[entry.shopName] = quantities[entry.shopName]! + entry.quantity;
    }

    return [
      for (final shopName in orderedShops)
        _CartRestaurantGroup(
          shopName: shopName,
          itemCount: quantities[shopName]!,
          imagePath: images[shopName] ?? EmployeeCartStore.defaultFoodImage,
        ),
    ];
  }
}
