import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/features/employee/data/employee_cart_store.dart';

class EmployeeCartPage extends StatefulWidget {
  const EmployeeCartPage({super.key, this.selectedShopName});

  final String? selectedShopName;

  @override
  State<EmployeeCartPage> createState() => _EmployeeCartPageState();
}

class _EmployeeCartPageState extends State<EmployeeCartPage> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  late final List<_CartItem> _items;

  @override
  void initState() {
    super.initState();
    _items = EmployeeCartStore.instance.items
        .where(
          (entry) =>
              widget.selectedShopName == null ||
              entry.shopName == widget.selectedShopName,
        )
        .map(_CartItem.fromEntry)
        .toList();
  }

  int get _subtotal {
    return _items.fold<int>(0, (sum, item) => sum + item.total);
  }

  int get _itemCount {
    return _items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  bool get _isEmpty => _items.isEmpty;

  int get _shopCount => _CartShopGroup.fromItems(_items).length;

  bool get _isPickupSelected {
    final groups = _CartShopGroup.fromItems(_items);
    for (final group in groups) {
      if (group.shopName == 'Meal Counter' &&
          EmployeeCartStore.instance.selectedPickupSlot(group.shopName) ==
              null) {
        return false;
      }
    }
    return true;
  }

  bool get _canCheckout => !_isEmpty && _shopCount <= 1 && _isPickupSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CartColors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _CartMetrics.fromWidth(
              constraints.maxWidth,
              constraints.maxHeight,
            );

            return Column(
              children: [
                _CartAppBar(
                  metrics: metrics,
                  onBack: () {
                    HapticFeedback.selectionClick();
                    if (context.canPop()) context.pop();
                  },
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: metrics.maxWidth),
                      child: metrics.isWide
                          ? _WideCartView(
                              metrics: metrics,
                              items: _items,
                              subtotal: _subtotal,
                              itemCount: _itemCount,
                              isEmpty: _isEmpty,
                              canCheckout: _canCheckout,
                              selectedPickupByShop:
                                  EmployeeCartStore.instance.pickupSelections,
                              onPickupChanged: _onPickupChanged,
                              onIncrease: _increaseQuantity,
                              onDecrease: _decreaseQuantity,
                              onRemove: _removeItem,
                              onCheckout: _goToCheckout,
                            )
                          : _PhoneCartView(
                              listKey: _listKey,
                              metrics: metrics,
                              items: _items,
                              subtotal: _subtotal,
                              itemCount: _itemCount,
                              isEmpty: _isEmpty,
                              canCheckout: _canCheckout,
                              selectedPickupByShop:
                                  EmployeeCartStore.instance.pickupSelections,
                              onPickupChanged: _onPickupChanged,
                              onIncrease: _increaseQuantity,
                              onDecrease: _decreaseQuantity,
                              onRemove: _removeItem,
                              onCheckout: _goToCheckout,
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _increaseQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    HapticFeedback.selectionClick();
    EmployeeCartStore.instance.increment(id);

    setState(() {
      final item = _items[index];
      _items[index] = item.copyWith(quantity: item.quantity + 1);
    });
  }

  void _decreaseQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final item = _items[index];

    HapticFeedback.selectionClick();

    if (item.quantity <= 1) {
      _removeItem(id);
      return;
    }

    EmployeeCartStore.instance.decrement(id);

    setState(() {
      _items[index] = item.copyWith(quantity: item.quantity - 1);
    });
  }

  void _removeItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final removed = _items[index];

    HapticFeedback.mediumImpact();
    EmployeeCartStore.instance.remove(id);

    setState(() {
      _items.removeAt(index);
    });

    final animatedList = _listKey.currentState;
    if (animatedList == null) return;

    animatedList.removeItem(index, (context, animation) {
      final metrics = _CartMetrics.fromWidth(
        MediaQuery.sizeOf(context).width,
        MediaQuery.sizeOf(context).height,
      );

      return _RemoveAnimation(
        animation: animation,
        child: _CartItemCard(
          metrics: metrics,
          item: removed,
          onIncrease: () {},
          onDecrease: () {},
          onRemove: () {},
          disabled: true,
        ),
      );
    }, duration: const Duration(milliseconds: 360));
  }

  void _onPickupChanged(String shopName, String? value) {
    EmployeeCartStore.instance.setPickupSlot(shopName, value);
    setState(() {});
  }

  void _goToCheckout() {
    if (_isEmpty) return;

    if (!_canCheckout) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: _CartColors.text,
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: Text(
              !_isPickupSelected
                  ? 'Select pickup time for Meal Counter before checkout.'
                  : 'Choose one restaurant cart to continue.',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        );
      return;
    }

    HapticFeedback.lightImpact();
    context.push(AppRoutes.employeeCheckout);
  }
}

class _CartColors {
  static const Color primary = Color(0xFFFF1717);
  static const Color background = Color(0xFFF7F7F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF111827);
  static const Color muted = Color(0xFF667085);
  static const Color line = Color(0xFFE8EAEE);
  static const Color pill = Color(0xFFF5F6F8);
  static const Color dangerSoft = Color(0xFFFFEEEE);
}

class _CartMetrics {
  const _CartMetrics({
    required this.isWide,
    required this.isTablet,
    required this.scale,
    required this.maxWidth,
    required this.pagePadding,
    required this.headerHeight,
    required this.cardRadius,
    required this.cardPadding,
    required this.imageSize,
    required this.bottomBarHeight,
  });

  final bool isWide;
  final bool isTablet;
  final double scale;
  final double maxWidth;
  final double pagePadding;
  final double headerHeight;
  final double cardRadius;
  final double cardPadding;
  final double imageSize;
  final double bottomBarHeight;

  static _CartMetrics fromWidth(double width, double height) {
    if (width >= 1000) {
      return const _CartMetrics(
        isWide: true,
        isTablet: false,
        scale: 1,
        maxWidth: 1120,
        pagePadding: 32,
        headerHeight: 76,
        cardRadius: 24,
        cardPadding: 22,
        imageSize: 72,
        bottomBarHeight: 0,
      );
    }

    if (width >= 700) {
      return const _CartMetrics(
        isWide: false,
        isTablet: true,
        scale: 1,
        maxWidth: 680,
        pagePadding: 24,
        headerHeight: 70,
        cardRadius: 24,
        cardPadding: 20,
        imageSize: 68,
        bottomBarHeight: 96,
      );
    }

    final scale = (width / 390).clamp(0.88, 1.0).toDouble();
    final compact = width < 360 || height < 700;

    return _CartMetrics(
      isWide: false,
      isTablet: false,
      scale: scale,
      maxWidth: 460,
      pagePadding: compact ? 13 : 16,
      headerHeight: compact ? 58 : 64,
      cardRadius: 22,
      cardPadding: compact ? 13 : 15,
      imageSize: compact ? 54 : 58,
      bottomBarHeight: compact ? 84 : 94,
    );
  }
}

class _CartAppBar extends StatelessWidget {
  const _CartAppBar({required this.metrics, required this.onBack});

  final _CartMetrics metrics;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: metrics.headerHeight,
      color: _CartColors.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: metrics.maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: metrics.pagePadding),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: onBack,
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 42 * metrics.scale,
                        height: 42 * metrics.scale,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 25 * metrics.scale,
                          color: _CartColors.text,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  'My Cart',
                  style: TextStyle(
                    color: _CartColors.text,
                    fontSize: metrics.isWide ? 24 : 21 * metrics.scale,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneCartView extends StatelessWidget {
  const _PhoneCartView({
    required this.listKey,
    required this.metrics,
    required this.items,
    required this.subtotal,
    required this.itemCount,
    required this.isEmpty,
    required this.canCheckout,
    required this.selectedPickupByShop,
    required this.onPickupChanged,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onCheckout,
  });

  final GlobalKey<AnimatedListState> listKey;
  final _CartMetrics metrics;
  final List<_CartItem> items;
  final int subtotal;
  final int itemCount;
  final bool isEmpty;
  final bool canCheckout;
  final Map<String, String?> selectedPickupByShop;
  final void Function(String shopName, String? value) onPickupChanged;
  final ValueChanged<String> onIncrease;
  final ValueChanged<String> onDecrease;
  final ValueChanged<String> onRemove;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            metrics.pagePadding,
            14,
            metrics.pagePadding,
            metrics.bottomBarHeight + bottomSafe + 20,
          ),
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: isEmpty
                  ? const _EmptyCart(key: ValueKey('empty-cart'))
                  : Column(
                      key: const ValueKey('cart-content'),
                      children: [
                        _CartItemsPanel(
                          listKey: null,
                          metrics: metrics,
                          items: items,
                          selectedPickupByShop: selectedPickupByShop,
                          onPickupChanged: onPickupChanged,
                          onIncrease: onIncrease,
                          onDecrease: onDecrease,
                          onRemove: onRemove,
                        ),
                        const SizedBox(height: 12),
                        _BillSummaryPanel(
                          metrics: metrics,
                          subtotal: subtotal,
                          itemCount: itemCount,
                          canCheckout: canCheckout,
                          showCheckoutButton: false,
                          onCheckout: onCheckout,
                        ),
                      ],
                    ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _CheckoutBottomBar(
            metrics: metrics,
            subtotal: subtotal,
            itemCount: itemCount,
            isEmpty: isEmpty,
            canCheckout: canCheckout,
            bottomSafe: bottomSafe,
            onCheckout: onCheckout,
          ),
        ),
      ],
    );
  }
}

class _WideCartView extends StatelessWidget {
  const _WideCartView({
    required this.metrics,
    required this.items,
    required this.subtotal,
    required this.itemCount,
    required this.isEmpty,
    required this.canCheckout,
    required this.selectedPickupByShop,
    required this.onPickupChanged,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onCheckout,
  });

  final _CartMetrics metrics;
  final List<_CartItem> items;
  final int subtotal;
  final int itemCount;
  final bool isEmpty;
  final bool canCheckout;
  final Map<String, String?> selectedPickupByShop;
  final void Function(String shopName, String? value) onPickupChanged;
  final ValueChanged<String> onIncrease;
  final ValueChanged<String> onDecrease;
  final ValueChanged<String> onRemove;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(metrics.pagePadding),
        child: const _EmptyCart(),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(metrics.pagePadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 13,
            child: _CartItemsPanel(
              listKey: null,
              metrics: metrics,
              items: items,
              selectedPickupByShop: selectedPickupByShop,
              onPickupChanged: onPickupChanged,
              onIncrease: onIncrease,
              onDecrease: onDecrease,
              onRemove: onRemove,
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            flex: 8,
            child: _BillSummaryPanel(
              metrics: metrics,
              subtotal: subtotal,
              itemCount: itemCount,
              canCheckout: canCheckout,
              showCheckoutButton: true,
              onCheckout: onCheckout,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemsPanel extends StatelessWidget {
  const _CartItemsPanel({
    required this.listKey,
    required this.metrics,
    required this.items,
    required this.selectedPickupByShop,
    required this.onPickupChanged,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final GlobalKey<AnimatedListState>? listKey;
  final _CartMetrics metrics;
  final List<_CartItem> items;
  final Map<String, String?> selectedPickupByShop;
  final void Function(String shopName, String? value) onPickupChanged;
  final ValueChanged<String> onIncrease;
  final ValueChanged<String> onDecrease;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final groups = _CartShopGroup.fromItems(items);

    return _Panel(
      metrics: metrics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: 'Cart Items',
            subtitle:
                '${groups.length} restaurant${groups.length == 1 ? '' : 's'} selected',
            metrics: metrics,
          ),
          SizedBox(height: 12 * metrics.scale),
          if (listKey == null)
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  for (int i = 0; i < groups.length; i++) ...[
                    _CartShopSection(
                      metrics: metrics,
                      group: groups[i],
                      selectedPickup: selectedPickupByShop[groups[i].shopName],
                      onPickupChanged: onPickupChanged,
                      onIncrease: onIncrease,
                      onDecrease: onDecrease,
                      onRemove: onRemove,
                    ),
                    if (i != groups.length - 1) const SizedBox(height: 14),
                  ],
                ],
              ),
            )
          else
            AnimatedList(
              key: listKey,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              initialItemCount: items.length,
              itemBuilder: (context, index, animation) {
                if (index >= items.length) return const SizedBox.shrink();

                final item = items[index];

                return _InsertAnimation(
                  animation: animation,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: index == items.length - 1 ? 0 : 10,
                    ),
                    child: _CartItemCard(
                      metrics: metrics,
                      item: item,
                      onIncrease: () => onIncrease(item.id),
                      onDecrease: () => onDecrease(item.id),
                      onRemove: () => onRemove(item.id),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CartShopSection extends StatelessWidget {
  const _CartShopSection({
    required this.metrics,
    required this.group,
    required this.selectedPickup,
    required this.onPickupChanged,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final _CartMetrics metrics;
  final _CartShopGroup group;
  final String? selectedPickup;
  final void Function(String shopName, String? value) onPickupChanged;
  final ValueChanged<String> onIncrease;
  final ValueChanged<String> onDecrease;
  final ValueChanged<String> onRemove;

  List<String> _timeSlotsForMeal(String meal) {
    List<String> slots = [];

    TimeOfDay start;
    TimeOfDay end;

    switch (meal.toLowerCase()) {
      case 'breakfast':
        start = const TimeOfDay(hour: 8, minute: 0);
        end = const TimeOfDay(hour: 10, minute: 0);
        break;
      case 'lunch':
        start = const TimeOfDay(hour: 12, minute: 0);
        end = const TimeOfDay(hour: 14, minute: 0);
        break;
      case 'dinner':
        start = const TimeOfDay(hour: 19, minute: 0);
        end = const TimeOfDay(hour: 22, minute: 30);
        break;
      default:
        return ['ASAP'];
    }

    final minutesStart = start.hour * 60 + start.minute;
    final minutesEnd = end.hour * 60 + end.minute;

    for (var t = minutesStart; t <= minutesEnd; t += 30) {
      final h = (t ~/ 60) % 24;
      final m = t % 60;
      final period = h < 12 ? 'AM' : 'PM';
      final displayH = h == 0 ? 12 : (h <= 12 ? h : h - 12);
      final displayM = m.toString().padLeft(2, '0');
      // remove leading zero from minutes when possible (e.g., 8:00 AM)
      final minutesText = displayM == '00' ? '00' : displayM;
      slots.add('$displayH:$minutesText $period');
    }

    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final metrics = this.metrics;
    final group = this.group;
    final compact = MediaQuery.sizeOf(context).width < 380;

    final meal = group.items.isNotEmpty ? group.items.first.meal : '';
    final slots = _timeSlotsForMeal(meal);
    final showPickup = group.shopName == 'Meal Counter' && slots.isNotEmpty;
    final showError = showPickup && selectedPickup == null;

    return Container(
      padding: EdgeInsets.all(compact ? 8 * metrics.scale : 10 * metrics.scale),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFE),
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: _CartColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: compact ? 28 * metrics.scale : 32 * metrics.scale,
                height: compact ? 28 * metrics.scale : 32 * metrics.scale,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEEEE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: _CartColors.primary,
                  size: compact ? 15 * metrics.scale : 17 * metrics.scale,
                ),
              ),
              SizedBox(width: compact ? 8 * metrics.scale : 10 * metrics.scale),
              Expanded(
                child: Text(
                  group.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _CartColors.text,
                    fontSize: metrics.isWide
                        ? 16
                        : compact
                            ? 14.2 * metrics.scale
                            : 15.2 * metrics.scale,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Text(
                '${group.itemCount} item${group.itemCount == 1 ? '' : 's'}',
                style: TextStyle(
                  color: _CartColors.primary,
                  fontSize: metrics.isWide
                      ? 13
                      : compact
                          ? 11.5 * metrics.scale
                          : 12.2 * metrics.scale,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 * metrics.scale : 10 * metrics.scale),
          if (showPickup) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select pickup time',
                style: TextStyle(
                  color: _CartColors.muted,
                  fontSize: 12 * metrics.scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * metrics.scale,
                      vertical: 10 * metrics.scale,
                    ),
                    decoration: BoxDecoration(
                      color: _CartColors.pill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: showError
                            ? Colors.redAccent.withOpacity(0.35)
                            : _CartColors.line,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 18 * metrics.scale,
                          color: _CartColors.primary,
                        ),
                        SizedBox(width: 10 * metrics.scale),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedPickup,
                              isExpanded: true,
                              hint: const Text('Select time slot'),
                              items: slots
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  onPickupChanged(group.shopName, v),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (showError) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pickup time is required for Meal Counter.',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11 * metrics.scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            SizedBox(height: 12 * metrics.scale),
          ],
          for (int i = 0; i < group.items.length; i++) ...[
            _CartItemCard(
              metrics: metrics,
              item: group.items[i],
              onIncrease: () => onIncrease(group.items[i].id),
              onDecrease: () => onDecrease(group.items[i].id),
              onRemove: () => onRemove(group.items[i].id),
            ),
            if (i != group.items.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.metrics,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    this.disabled = false,
  });

  final _CartMetrics metrics;
  final _CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTiny = width < 360;
    final compact = width < 390;
    final imageSize = compact
        ? (metrics.imageSize * 0.86).clamp(44.0, 52.0)
        : metrics.imageSize;

    return Opacity(
      opacity: disabled ? 0.65 : 1,
      child: Container(
        padding: EdgeInsets.all(isTiny ? 8 : 10),
        decoration: BoxDecoration(
          color: _CartColors.surface,
          borderRadius: BorderRadius.circular(compact ? 15 : 18),
          border: Border.all(color: _CartColors.line, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _FoodImage(imagePath: item.imagePath, size: imageSize),
            SizedBox(width: compact ? 9 * metrics.scale : 12 * metrics.scale),
            Expanded(
              child: _ItemInfo(metrics: metrics, item: item, height: imageSize),
            ),
            SizedBox(width: compact ? 6 * metrics.scale : 8 * metrics.scale),
            _ItemActions(
              metrics: metrics,
              quantity: item.quantity,
              compact: compact,
              height: imageSize,
              disabled: disabled,
              onIncrease: onIncrease,
              onDecrease: onDecrease,
              onRemove: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemInfo extends StatelessWidget {
  const _ItemInfo({
    required this.metrics,
    required this.item,
    required this.height,
  });

  final _CartMetrics metrics;
  final _CartItem item;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _CartColors.text,
              fontSize: metrics.isWide ? 16 : 14.5 * metrics.scale,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
          SizedBox(height: 3 * metrics.scale),
          Text(
            item.shopName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _CartColors.muted,
              fontSize: metrics.isWide ? 12.5 : 11.2 * metrics.scale,
              height: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            child: Text(
              '₹${item.total}',
              key: ValueKey<int>(item.total),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _CartColors.primary,
                fontSize: metrics.isWide ? 18.5 : 17.5 * metrics.scale,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemActions extends StatelessWidget {
  const _ItemActions({
    required this.metrics,
    required this.quantity,
    required this.compact,
    required this.height,
    required this.disabled,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final _CartMetrics metrics;
  final int quantity;
  final bool compact;
  final double height;
  final bool disabled;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final width = metrics.isWide
        ? 126.0
        : compact
            ? math.max(82.0, 90 * metrics.scale)
            : math.max(96.0, 104 * metrics.scale);

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _RemoveTextButton(disabled: disabled, onTap: onRemove),
          const Spacer(),
          _QuantityPill(
            width: width,
            compact: compact,
            quantity: quantity,
            disabled: disabled,
            onIncrease: onIncrease,
            onDecrease: onDecrease,
          ),
        ],
      ),
    );
  }
}

class _FoodImage extends StatelessWidget {
  const _FoodImage({required this.imagePath, required this.size});

  final String imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_1, _2, _3) {
            return Container(
              color: const Color(0xFFFFF1EC),
              alignment: Alignment.center,
              child: Icon(
                Icons.restaurant_rounded,
                color: _CartColors.primary,
                size: size * 0.34,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RemoveTextButton extends StatefulWidget {
  const _RemoveTextButton({required this.disabled, required this.onTap});

  final bool disabled;
  final VoidCallback onTap;

  @override
  State<_RemoveTextButton> createState() => _RemoveTextButtonState();
}

class _RemoveTextButtonState extends State<_RemoveTextButton>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _busy = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );

    _scale = Tween<double>(
      begin: 1,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (widget.disabled || _busy) return;

    _busy = true;
    await _controller.forward();
    await _controller.reverse();

    if (!mounted) return;
    widget.onTap();

    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: _CartColors.dangerSoft,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: widget.disabled ? null : _tap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            child: Text(
              'Remove',
              maxLines: 1,
              style: TextStyle(
                color: _CartColors.primary,
                fontSize: 11.5,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuantityPill extends StatelessWidget {
  const _QuantityPill({
    required this.width,
    required this.compact,
    required this.quantity,
    required this.disabled,
    required this.onIncrease,
    required this.onDecrease,
  });

  final double width;
  final bool compact;
  final int quantity;
  final bool disabled;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
        width: width,
        height: compact ? 30 : 34,
        decoration: BoxDecoration(
          color: _CartColors.pill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _CartColors.line, width: 0.8),
        ),
        child: Row(
          children: [
            _QtyButton(
              icon: Icons.remove_rounded,
              disabled: disabled,
              onTap: onDecrease,
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: SizedBox(
                key: ValueKey<int>(quantity),
                width: compact ? 24 : 30,
                child: Text(
                  quantity.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _CartColors.text,
                    fontSize: compact ? 14 : 15.5,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            _QtyButton(
              icon: Icons.add_rounded,
              disabled: disabled,
              onTap: onIncrease,
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatefulWidget {
  const _QtyButton({
    required this.icon,
    required this.disabled,
    required this.onTap,
  });

  final IconData icon;
  final bool disabled;
  final VoidCallback onTap;

  @override
  State<_QtyButton> createState() => _QtyButtonState();
}

class _QtyButtonState extends State<_QtyButton>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );

    _scale = Tween<double>(
      begin: 1,
      end: 0.86,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (widget.disabled) return;

    await _controller.forward();
    await _controller.reverse();

    if (!mounted) return;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: widget.disabled ? null : _tap,
          borderRadius: BorderRadius.circular(999),
          child: ScaleTransition(
            scale: _scale,
            child: Icon(
              widget.icon,
              color: _CartColors.text,
              size: compact ? 17 : 19,
            ),
          ),
        ),
      ),
    );
  }
}

class _BillSummaryPanel extends StatelessWidget {
  const _BillSummaryPanel({
    required this.metrics,
    required this.subtotal,
    required this.itemCount,
    required this.canCheckout,
    required this.showCheckoutButton,
    required this.onCheckout,
  });

  final _CartMetrics metrics;
  final int subtotal;
  final int itemCount;
  final bool canCheckout;
  final bool showCheckoutButton;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      metrics: metrics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: 'Bill Summary',
            subtitle: 'Inclusive of all selected items',
            metrics: metrics,
          ),
          SizedBox(height: 18 * metrics.scale),
          _BillLine(
            label: 'Item total',
            value: '₹$subtotal',
            muted: true,
            metrics: metrics,
          ),
          SizedBox(height: 18 * metrics.scale),
          const Divider(height: 1, color: _CartColors.line),
          SizedBox(height: 15 * metrics.scale),
          _BillLine(
            label: 'To Pay',
            value: '₹$subtotal',
            muted: false,
            metrics: metrics,
          ),
          if (!canCheckout && subtotal > 0) ...[
            const SizedBox(height: 14),
            _SingleRestaurantWarning(metrics: metrics),
          ],
          if (showCheckoutButton) ...[
            const SizedBox(height: 18),
            _CheckoutHint(itemCount: itemCount),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: _PrimaryButton(
                enabled: subtotal > 0 && canCheckout,
                text: 'Proceed to Pay',
                onTap: onCheckout,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BillLine extends StatelessWidget {
  const _BillLine({
    required this.label,
    required this.value,
    required this.muted,
    required this.metrics,
  });

  final String label;
  final String value;
  final bool muted;
  final _CartMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final isTotal = !muted;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? _CartColors.text : _CartColors.muted,
              fontSize: isTotal ? 17 * metrics.scale : 14.2 * metrics.scale,
              height: 1.1,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            value,
            key: ValueKey<String>(value),
            style: TextStyle(
              color: isTotal ? _CartColors.primary : _CartColors.text,
              fontSize: isTotal ? 23 * metrics.scale : 14.2 * metrics.scale,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _SingleRestaurantWarning extends StatelessWidget {
  const _SingleRestaurantWarning({required this.metrics});

  final _CartMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12 * metrics.scale,
        vertical: 10 * metrics.scale,
      ),
      decoration: BoxDecoration(
        color: _CartColors.dangerSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD7D7)),
      ),
      child: Text(
        'Checkout supports one restaurant at a time.',
        style: TextStyle(
          color: _CartColors.primary,
          fontSize: metrics.isWide ? 12.5 : 12 * metrics.scale,
          height: 1.2,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.metrics, required this.child});

  final _CartMetrics metrics;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(metrics.cardPadding),
      decoration: BoxDecoration(
        color: _CartColors.surface,
        borderRadius: BorderRadius.circular(metrics.cardRadius),
        border: Border.all(color: _CartColors.line, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.subtitle,
    required this.metrics,
  });

  final String title;
  final String subtitle;
  final _CartMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _CartColors.text,
                  fontSize: metrics.isWide ? 18.5 : 17 * metrics.scale,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.35,
                ),
              ),
              SizedBox(height: 5 * metrics.scale),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _CartColors.muted,
                  fontSize: metrics.isWide ? 12.5 : 12 * metrics.scale,
                  height: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckoutBottomBar extends StatelessWidget {
  const _CheckoutBottomBar({
    required this.metrics,
    required this.subtotal,
    required this.itemCount,
    required this.isEmpty,
    required this.canCheckout,
    required this.bottomSafe,
    required this.onCheckout,
  });

  final _CartMetrics metrics;
  final int subtotal;
  final int itemCount;
  final bool isEmpty;
  final bool canCheckout;
  final double bottomSafe;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: isEmpty,
      child: AnimatedOpacity(
        opacity: isEmpty ? 0.45 : 1,
        duration: const Duration(milliseconds: 180),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            metrics.pagePadding,
            10,
            metrics.pagePadding,
            math.max(10, bottomSafe + 8),
          ),
          decoration: BoxDecoration(
            color: _CartColors.surface,
            border: const Border(
              top: BorderSide(color: _CartColors.line, width: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 28,
                offset: const Offset(0, -12),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Column(
                    key: ValueKey<String>(
                      'bar-$itemCount-$subtotal-$canCheckout',
                    ),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        canCheckout
                            ? '$itemCount item${itemCount == 1 ? '' : 's'}'
                            : 'One restaurant only',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _CartColors.muted,
                          fontSize: 12 * metrics.scale,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6 * metrics.scale),
                      Text(
                        '₹$subtotal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _CartColors.text,
                          fontSize: 23 * metrics.scale,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 14 * metrics.scale),
              SizedBox(
                width: math.min(
                  190 * metrics.scale,
                  MediaQuery.sizeOf(context).width * 0.50,
                ),
                height: 52 * metrics.scale,
                child: _PrimaryButton(
                  enabled: !isEmpty && canCheckout,
                  text: 'Proceed to Pay',
                  onTap: onCheckout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.enabled,
    required this.text,
    required this.onTap,
  });

  final bool enabled;
  final String text;
  final VoidCallback onTap;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _scale = Tween<double>(
      begin: 1,
      end: 0.975,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (!widget.enabled) return;

    await _controller.forward();
    await _controller.reverse();

    if (!mounted) return;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: widget.enabled
              ? [
                  BoxShadow(
                    color: _CartColors.primary.withOpacity(0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: widget.enabled ? _tap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _CartColors.primary,
            disabledBackgroundColor: const Color(0xFFFFB7B7),
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.text,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckoutHint extends StatelessWidget {
  const _CheckoutHint({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _CartColors.primary.withOpacity(0.10),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            color: _CartColors.primary,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '$itemCount item${itemCount == 1 ? '' : 's'} ready for checkout',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _CartColors.text,
                fontSize: 12.8,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsertAnimation extends StatelessWidget {
  const _InsertAnimation({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    return SizeTransition(
      sizeFactor: curved,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
    );
  }
}

class _RemoveAnimation extends StatelessWidget {
  const _RemoveAnimation({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0, 0.65, curve: Curves.easeOut),
      ),
    );

    final slide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.05, 0),
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    final size = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.20, 1, curve: Curves.easeInOutCubic),
      ),
    );

    return SizeTransition(
      sizeFactor: size,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 46),
      decoration: BoxDecoration(
        color: _CartColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _CartColors.line, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            color: _CartColors.primary,
            size: 48,
          ),
          SizedBox(height: 15),
          Text(
            'Your cart is empty',
            style: TextStyle(
              color: _CartColors.text,
              fontSize: 19,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add your favourite food items to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _CartColors.muted,
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItem {
  const _CartItem({
    required this.id,
    required this.name,
    required this.shopName,
    required this.meal,
    required this.price,
    required this.quantity,
    required this.imagePath,
  });

  final String id;
  final String name;
  final String shopName;
  final String meal;
  final int price;
  final int quantity;
  final String imagePath;

  factory _CartItem.fromEntry(EmployeeCartEntry entry) {
    return _CartItem(
      id: entry.id,
      name: entry.name,
      shopName: entry.shopName,
      meal: entry.meal,
      price: entry.price,
      quantity: entry.quantity,
      imagePath: entry.imagePath,
    );
  }

  int get total => price * quantity;

  _CartItem copyWith({
    String? id,
    String? name,
    String? shopName,
    String? meal,
    int? price,
    int? quantity,
    String? imagePath,
  }) {
    return _CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      shopName: shopName ?? this.shopName,
      meal: meal ?? this.meal,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class _CartShopGroup {
  const _CartShopGroup({required this.shopName, required this.items});

  final String shopName;
  final List<_CartItem> items;

  int get itemCount {
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  static List<_CartShopGroup> fromItems(List<_CartItem> items) {
    final orderedShops = <String>[];
    final grouped = <String, List<_CartItem>>{};

    for (final item in items) {
      grouped.putIfAbsent(item.shopName, () {
        orderedShops.add(item.shopName);
        return <_CartItem>[];
      }).add(item);
    }

    return [
      for (final shopName in orderedShops)
        _CartShopGroup(shopName: shopName, items: grouped[shopName]!),
    ];
  }
}
