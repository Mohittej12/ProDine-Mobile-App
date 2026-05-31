import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_dine/core/widgets/app_logo.dart';
import 'package:pro_dine/features/employee/data/employee_order_store.dart';
import 'package:pro_dine/features/employee/data/employee_profile_store.dart';

class EmployeeOrdersFragment extends StatefulWidget {
  const EmployeeOrdersFragment({super.key});

  @override
  State<EmployeeOrdersFragment> createState() => _EmployeeOrdersFragmentState();
}

class _EmployeeOrdersFragmentState extends State<EmployeeOrdersFragment>
    with TickerProviderStateMixin {
  static const Color _primaryRed = Color(0xFFFF1F1F);
  static const Color _darkText = Color(0xFF141827);
  static const Color _mutedText = Color(0xFF667085);
  static const Color _screenBg = Color(0xFFFFFCF8);
  static const Color _softBorder = Color(0xFFEDEDED);

  late final TabController _tabController;
  final ScrollController _activeScrollController = ScrollController();
  final ScrollController _historyScrollController = ScrollController();

  final EmployeeOrderStore _orderStore = EmployeeOrderStore.instance;

  bool _showTicketingOnly = false;
  bool _showDeliveredOnly = false;
  bool _headerScrolled = false;

  List<_OrderData> get _orders => _orderStore.orders.map(_orderToData).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_syncHeaderScrollState);
    _activeScrollController.addListener(_syncHeaderScrollState);
    _historyScrollController.addListener(_syncHeaderScrollState);
    _orderStore.addListener(_onOrdersUpdated);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.removeListener(_syncHeaderScrollState);
    _orderStore.removeListener(_onOrdersUpdated);
    _activeScrollController
      ..removeListener(_syncHeaderScrollState)
      ..dispose();
    _historyScrollController
      ..removeListener(_syncHeaderScrollState)
      ..dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _syncHeaderScrollState() {
    if (!mounted) return;

    final controller = _tabController.index == 0
        ? _activeScrollController
        : _historyScrollController;
    final nextScrolled = controller.hasClients && controller.offset > 8;

    if (nextScrolled != _headerScrolled) {
      setState(() => _headerScrolled = nextScrolled);
    }
  }

  void _onOrdersUpdated() {
    if (!mounted) return;
    setState(() {});
  }

  _OrderStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return _OrderStatus.delivered;
      case 'rejected':
        return _OrderStatus.rejected;
      case 'ordered':
      default:
        return _OrderStatus.ordered;
    }
  }

  String _formatOrderTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    final formattedHour = ((hour + 11) % 12) + 1;
    final period = isPm ? 'pm' : 'am';
    return '$formattedHour:$minute$period';
  }

  _OrderData _orderToData(EmployeeOrderEntry order) {
    return _OrderData(
      orderId: order.orderId,
      employeeId: order.employeeId,
      restaurant: order.shopName,
      status: _statusFromString(order.status),
      time: _formatOrderTime(order.createdAt),
      pickupSlot: order.pickupSlot,
      isTicketing: order.isTicketing,
      orderIntent: order.orderIntent,
      total: '₹${order.amount}',
      items: order.items
          .map(
            (item) => _OrderItemData(
              name: item.name,
              quantity: item.quantity,
              price: '₹${item.price * item.quantity}',
              imagePath: item.imagePath,
            ),
          )
          .toList(),
    );
  }

  List<_OrderData> get _activeOrders {
    return _orders.where((order) {
      final active = order.status == _OrderStatus.ordered;
      final ticketingOk = !_showTicketingOnly || order.isTicketing;
      final deliveredOk =
          !_showDeliveredOnly || order.status == _OrderStatus.delivered;
      return active && ticketingOk && deliveredOk;
    }).toList();
  }

  List<_OrderData> get _historyOrders {
    return _orders.where((order) {
      final history = order.status == _OrderStatus.delivered ||
          order.status == _OrderStatus.rejected;
      final ticketingOk = !_showTicketingOnly || order.isTicketing;
      final deliveredOk =
          !_showDeliveredOnly || order.status == _OrderStatus.delivered;
      return history && ticketingOk && deliveredOk;
    }).toList();
  }

  bool get _hasActiveFilters => _showTicketingOnly || _showDeliveredOnly;

  Future<void> _refreshOrders() async {
    HapticFeedback.lightImpact();
    await _loadOrders();
    if (!mounted) return;
    setState(() {});
    HapticFeedback.selectionClick();
  }

  Future<void> _loadOrders() async {
    final employeeId = EmployeeProfileStore.instance.value.employeeId;
    if (employeeId.isEmpty || employeeId == 'PD-2048') {
      return;
    }

    try {
      await _orderStore.loadOrdersForEmployee(employeeId);
    } catch (e) {
      debugPrint('Failed to load orders for $employeeId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _screenBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _OrdersLayout.fromWidth(constraints.maxWidth);
          final bottomSafe = MediaQuery.of(context).padding.bottom;

          return Column(
            children: [
              _FixedOrdersHeader(
                layout: layout,
                scrolled: _headerScrolled,
                hasActiveFilters: _hasActiveFilters,
                showTicketingOnly: _showTicketingOnly,
                showDeliveredOnly: _showDeliveredOnly,
                tabController: _tabController,
                onFilterTap: () => _openFilterSheet(context, layout),
                onTabTap: (_) {
                  setState(() {});
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _syncHeaderScrollState();
                  });
                },
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: layout.maxContentWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: layout.horizontalPadding,
                      ),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _OrdersList(
                            controller: _activeScrollController,
                            layout: layout,
                            bottomPadding:
                                layout.isDesktop ? 56 : 156 + bottomSafe,
                            onRefresh: _refreshOrders,
                            orders: _activeOrders,
                            emptyTitle: 'No active orders',
                            emptySubtitle:
                                'Your current food and ticketing orders will appear here.',
                          ),
                          _OrdersList(
                            controller: _historyScrollController,
                            layout: layout,
                            bottomPadding:
                                layout.isDesktop ? 56 : 156 + bottomSafe,
                            onRefresh: _refreshOrders,
                            orders: _historyOrders,
                            emptyTitle: 'No order history',
                            emptySubtitle:
                                'Delivered and rejected orders will appear here.',
                          ),
                        ],
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

  Future<void> _openFilterSheet(
    BuildContext context,
    _OrdersLayout layout,
  ) async {
    final result = await showModalBottomSheet<_OrderFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _OrderFilterSheet(
          layout: layout,
          showTicketingOnly: _showTicketingOnly,
          showDeliveredOnly: _showDeliveredOnly,
        );
      },
    );

    if (result == null) return;

    setState(() {
      _showTicketingOnly = result.showTicketingOnly;
      _showDeliveredOnly = result.showDeliveredOnly;
    });
  }
}

class _OrdersLayout {
  const _OrdersLayout({
    required this.isDesktop,
    required this.isTablet,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.topPadding,
    required this.scale,
    required this.sectionGap,
    required this.cardSpacing,
    required this.gridColumns,
  });

  final bool isDesktop;
  final bool isTablet;
  final double maxContentWidth;
  final double horizontalPadding;
  final double topPadding;
  final double scale;
  final double sectionGap;
  final double cardSpacing;
  final int gridColumns;

  static _OrdersLayout fromWidth(double width) {
    if (width >= 1180) {
      return const _OrdersLayout(
        isDesktop: true,
        isTablet: false,
        maxContentWidth: 1180,
        horizontalPadding: 48,
        topPadding: 26,
        scale: 1.08,
        sectionGap: 18,
        cardSpacing: 16,
        gridColumns: 2,
      );
    }

    if (width >= 760) {
      return const _OrdersLayout(
        isDesktop: false,
        isTablet: true,
        maxContentWidth: 760,
        horizontalPadding: 34,
        topPadding: 24,
        scale: 1.02,
        sectionGap: 16,
        cardSpacing: 15,
        gridColumns: 2,
      );
    }

    final veryNarrow = width < 345;
    final narrow = width < 370;

    final scale = veryNarrow
        ? 0.88
        : narrow
            ? 0.94
            : 1.0;

    return _OrdersLayout(
      isDesktop: false,
      isTablet: false,
      maxContentWidth: 430,
      horizontalPadding: narrow ? 16 : 20,
      topPadding: 17,
      scale: scale,
      sectionGap: 14,
      cardSpacing: 13,
      gridColumns: 1,
    );
  }
}

class _FixedOrdersHeader extends StatelessWidget {
  const _FixedOrdersHeader({
    required this.layout,
    required this.scrolled,
    required this.hasActiveFilters,
    required this.showTicketingOnly,
    required this.showDeliveredOnly,
    required this.tabController,
    required this.onFilterTap,
    required this.onTabTap,
  });

  final _OrdersLayout layout;
  final bool scrolled;
  final bool hasActiveFilters;
  final bool showTicketingOnly;
  final bool showDeliveredOnly;
  final TabController tabController;
  final VoidCallback onFilterTap;
  final ValueChanged<int> onTabTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(
        layout.horizontalPadding,
        layout.topPadding,
        layout.horizontalPadding,
        hasActiveFilters ? 10 * scale : 11 * scale,
      ),
      decoration: BoxDecoration(
        color: _EmployeeOrdersFragmentState._screenBg.withOpacity(
          scrolled ? 0.995 : 1,
        ),
        boxShadow: scrolled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.065),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: -11,
                ),
              ]
            : null,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(
                layout: layout,
                hasActiveFilters: hasActiveFilters,
                onFilterTap: onFilterTap,
              ),
              SizedBox(height: 10 * scale),
              _SegmentedTabs(
                controller: tabController,
                layout: layout,
                onTap: onTabTap,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: hasActiveFilters
                    ? Padding(
                        key: const ValueKey('active-order-filters'),
                        padding: EdgeInsets.only(top: 8 * scale),
                        child: _ActiveFilterChips(
                          showTicketingOnly: showTicketingOnly,
                          showDeliveredOnly: showDeliveredOnly,
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-order-filters')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.layout,
    required this.hasActiveFilters,
    required this.onFilterTap,
  });

  final _OrdersLayout layout;
  final bool hasActiveFilters;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;
    final buttonSize = layout.isDesktop ? 44.0 : 39.0 * scale;
    final brandScale = layout.isDesktop || layout.isTablet ? 1.0 : scale;

    return SizedBox(
      height: layout.isDesktop ? 48 : 44 * brandScale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppLogo(
              height: layout.isDesktop ? 21 : 17.5 * brandScale,
              isBrand: true,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: layout.isDesktop ? 64 : 54 * brandScale,
            ),
            child: Text(
              'My Orders',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _EmployeeOrdersFragmentState._darkText,
                fontSize: layout.isDesktop ? 25 : 18 * scale,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                onTap: onFilterTap,
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFE9ECF1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: hasActiveFilters
                            ? _EmployeeOrdersFragmentState._primaryRed
                            : _EmployeeOrdersFragmentState._darkText,
                        size: layout.isDesktop ? 22 : 19.5 * scale,
                      ),
                      if (hasActiveFilters)
                        Positioned(
                          top: 9,
                          right: 9,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: _EmployeeOrdersFragmentState._primaryRed,
                              shape: BoxShape.circle,
                            ),
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

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.controller,
    required this.layout,
    required this.onTap,
  });

  final TabController controller;
  final _OrdersLayout layout;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      height: layout.isDesktop ? 48 : 43 * scale,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EBEF)),
      ),
      child: TabBar(
        controller: controller,
        onTap: onTap,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: -5,
            ),
          ],
        ),
        labelColor: _EmployeeOrdersFragmentState._primaryRed,
        unselectedLabelColor: _EmployeeOrdersFragmentState._mutedText,
        labelStyle: TextStyle(
          fontSize: layout.isDesktop ? 14.2 : 12.8 * scale,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: layout.isDesktop ? 14.2 : 12.8 * scale,
          fontWeight: FontWeight.w700,
        ),
        tabs: const [
          Tab(text: 'Active Orders'),
          Tab(text: 'History'),
        ],
      ),
    );
  }
}

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({
    required this.showTicketingOnly,
    required this.showDeliveredOnly,
  });

  final bool showTicketingOnly;
  final bool showDeliveredOnly;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (showTicketingOnly) const _FilterChipView(label: 'Ticketing only'),
        if (showDeliveredOnly) const _FilterChipView(label: 'Delivered only'),
      ],
    );
  }
}

class _FilterChipView extends StatelessWidget {
  const _FilterChipView({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _EmployeeOrdersFragmentState._primaryRed,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({
    required this.controller,
    required this.layout,
    required this.bottomPadding,
    required this.onRefresh,
    required this.orders,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final ScrollController controller;
  final _OrdersLayout layout;
  final double bottomPadding;
  final RefreshCallback onRefresh;
  final List<_OrderData> orders;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _OrdersRefreshShell(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          controller: controller,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            children: [
              _RefreshHint(layout: layout),
              const SizedBox(height: 8),
              SizedBox(
                height: 420,
                child: _EmptyOrdersState(
                  title: emptyTitle,
                  subtitle: emptySubtitle,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (layout.isDesktop || layout.isTablet) {
      return _OrdersRefreshShell(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          controller: controller,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            children: [
              _RefreshHint(layout: layout),
              SizedBox(height: 8 * layout.scale),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = math.min(layout.gridColumns, orders.length);
                  final spacing = layout.cardSpacing;
                  final itemWidth =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                          columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: orders.map((order) {
                      return SizedBox(
                        width: itemWidth,
                        child: _OrderCard(layout: layout, order: order),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return _OrdersRefreshShell(
      onRefresh: onRefresh,
      child: ListView.separated(
        controller: controller,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.only(bottom: bottomPadding),
        itemCount: orders.length + 1,
        separatorBuilder: (_, index) {
          return SizedBox(
            height: index == 0 ? 8 * layout.scale : layout.cardSpacing,
          );
        },
        itemBuilder: (context, index) {
          if (index == 0) return _RefreshHint(layout: layout);
          return _OrderCard(layout: layout, order: orders[index - 1]);
        },
      ),
    );
  }
}

class _OrdersRefreshShell extends StatelessWidget {
  const _OrdersRefreshShell({required this.onRefresh, required this.child});

  final RefreshCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _EmployeeOrdersFragmentState._primaryRed,
      backgroundColor: Colors.white,
      displacement: 34,
      edgeOffset: 0,
      strokeWidth: 2.5,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: child,
    );
  }
}

class _RefreshHint extends StatelessWidget {
  const _RefreshHint({required this.layout});

  final _OrdersLayout layout;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return SizedBox(
      height: layout.isDesktop ? 28 : 26 * scale,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10 * scale,
            vertical: 5 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFEDEFF3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 15 * scale,
                color: _EmployeeOrdersFragmentState._mutedText,
              ),
              SizedBox(width: 3 * scale),
              Text(
                'Pull down to refresh',
                style: TextStyle(
                  color: _EmployeeOrdersFragmentState._mutedText,
                  fontSize: 10.8 * scale,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.layout, required this.order});

  final _OrdersLayout layout;
  final _OrderData order;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;
    final statusStyle = _statusStyle(order.status);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.038),
            blurRadius: 18,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
        border: Border.all(color: const Color(0xFFEDEFF3), width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16 * scale,
              15 * scale,
              16 * scale,
              9 * scale,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.restaurant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _EmployeeOrdersFragmentState._darkText,
                          fontSize: layout.isDesktop ? 17.5 : 15.6 * scale,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(width: 10 * scale),
                    _StatusPill(
                      text: statusStyle.label,
                      textColor: statusStyle.textColor,
                      bgColor: statusStyle.bgColor,
                      scale: scale,
                    ),
                  ],
                ),
                SizedBox(height: 11 * scale),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${order.orderId} · ${order.employeeId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _EmployeeOrdersFragmentState._mutedText,
                          fontSize: 12.3 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (order.orderIntent.isNotEmpty) ...[
                  SizedBox(height: 6 * scale),
                  Text(
                    order.orderIntent,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _EmployeeOrdersFragmentState._mutedText,
                      fontSize: 11.5 * scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                SizedBox(height: 10 * scale),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 15 * scale,
                      color: _EmployeeOrdersFragmentState._mutedText,
                    ),
                    SizedBox(width: 6 * scale),
                    Text(
                      order.time,
                      style: TextStyle(
                        color: _EmployeeOrdersFragmentState._mutedText,
                        fontSize: 12.5 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (order.pickupSlot.isNotEmpty) ...[
                      SizedBox(width: 10 * scale),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 9 * scale,
                          vertical: 4 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F6F8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          order.pickupSlot,
                          style: TextStyle(
                            color: _EmployeeOrdersFragmentState._mutedText,
                            fontSize: 11.5 * scale,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),

                    // IMPORTANT:
                    // Ticketing tag appears only for Ticketing orders.
                    if (order.isTicketing) _TicketingTag(scale: scale),
                  ],
                ),
                SizedBox(height: 11 * scale),
                ...order.items.map(
                  (item) => Padding(
                    padding: EdgeInsets.only(bottom: 10 * scale),
                    child: _OrderItemRow(
                      item: item,
                      showPrice: !order.isTicketing,
                      scale: scale,
                      desktop: layout.isDesktop,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!order.isTicketing)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * scale,
                vertical: 12 * scale,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFFCFCFC),
                border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      color: _EmployeeOrdersFragmentState._darkText,
                      fontSize: 13.5 * scale,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    order.total,
                    style: TextStyle(
                      color: _EmployeeOrdersFragmentState._primaryRed,
                      fontSize: 14.5 * scale,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  _StatusVisual _statusStyle(_OrderStatus status) {
    switch (status) {
      case _OrderStatus.ordered:
        return const _StatusVisual(
          label: 'Ordered',
          textColor: Color(0xFF2563EB),
          bgColor: Color(0xFFEAF2FF),
        );
      case _OrderStatus.delivered:
        return const _StatusVisual(
          label: 'Delivered',
          textColor: Color(0xFF12A150),
          bgColor: Color(0xFFE8FFE8),
        );
      case _OrderStatus.rejected:
        return const _StatusVisual(
          label: 'Rejected',
          textColor: Color(0xFFE53935),
          bgColor: Color(0xFFFFEAEA),
        );
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.text,
    required this.textColor,
    required this.bgColor,
    required this.scale,
  });

  final String text;
  final Color textColor;
  final Color bgColor;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 82 * scale),
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 5.5 * scale,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: textColor.withOpacity(0.16)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11 * scale,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TicketingTag extends StatelessWidget {
  const _TicketingTag({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 112 * scale),
      padding: EdgeInsets.symmetric(
        horizontal: 11 * scale,
        vertical: 5.5 * scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        'Ticketing',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: const Color(0xFF6D6A66),
          fontSize: 11 * scale,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.item,
    required this.showPrice,
    required this.scale,
    required this.desktop,
  });

  final _OrderItemData item;
  final bool showPrice;
  final double scale;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final imageSize = desktop ? 44.0 : 36.0 * scale;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9 * scale),
          child: Image.asset(
            item.imagePath,
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) {
              return Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2EC),
                  borderRadius: BorderRadius.circular(9 * scale),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.restaurant_rounded,
                  color: _EmployeeOrdersFragmentState._primaryRed,
                  size: 18 * scale,
                ),
              );
            },
          ),
        ),
        SizedBox(width: 12 * scale),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: item.name,
              style: TextStyle(
                color: _EmployeeOrdersFragmentState._darkText,
                fontSize: desktop ? 15.5 : 14.5 * scale,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.15,
              ),
              children: [
                TextSpan(
                  text: 'x${item.quantity}',
                  style: TextStyle(
                    color: _EmployeeOrdersFragmentState._mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showPrice) ...[
          SizedBox(width: 10 * scale),
          Text(
            item.price,
            style: TextStyle(
              color: _EmployeeOrdersFragmentState._darkText,
              fontSize: desktop ? 15.5 : 14.5 * scale,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

class _OrderFilterSheet extends StatefulWidget {
  const _OrderFilterSheet({
    required this.layout,
    required this.showTicketingOnly,
    required this.showDeliveredOnly,
  });

  final _OrdersLayout layout;
  final bool showTicketingOnly;
  final bool showDeliveredOnly;

  @override
  State<_OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends State<_OrderFilterSheet> {
  late bool _showTicketingOnly = widget.showTicketingOnly;
  late bool _showDeliveredOnly = widget.showDeliveredOnly;

  @override
  Widget build(BuildContext context) {
    final sideSheet = widget.layout.isDesktop || widget.layout.isTablet;

    return Align(
      alignment: sideSheet ? Alignment.centerRight : Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: sideSheet ? 420 : double.infinity,
        ),
        child: Container(
          margin: EdgeInsets.only(
            right: sideSheet ? 28 : 0,
            top: sideSheet ? 28 : 0,
            bottom: sideSheet ? 28 : 0,
          ),
          padding: EdgeInsets.fromLTRB(
            22,
            14,
            22,
            22 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(28),
              bottom: Radius.circular(sideSheet ? 28 : 0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Filter Orders',
                        style: TextStyle(
                          color: _EmployeeOrdersFragmentState._darkText,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showTicketingOnly = false;
                          _showDeliveredOnly = false;
                        });
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          color: _EmployeeOrdersFragmentState._primaryRed,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SwitchTile(
                  title: 'Ticketing orders only',
                  subtitle: 'Show ticketing / company-supported meals',
                  value: _showTicketingOnly,
                  onChanged: (value) {
                    setState(() => _showTicketingOnly = value);
                  },
                ),
                const SizedBox(height: 10),
                _SwitchTile(
                  title: 'Delivered only',
                  subtitle: 'Show completed orders',
                  value: _showDeliveredOnly,
                  onChanged: (value) {
                    setState(() => _showDeliveredOnly = value);
                  },
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _OrderFilterResult(
                          showTicketingOnly: _showTicketingOnly,
                          showDeliveredOnly: _showDeliveredOnly,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _EmployeeOrdersFragmentState._primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _EmployeeOrdersFragmentState._softBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _EmployeeOrdersFragmentState._darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _EmployeeOrdersFragmentState._mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: _EmployeeOrdersFragmentState._primaryRed,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 38),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _EmployeeOrdersFragmentState._softBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              color: _EmployeeOrdersFragmentState._primaryRed,
              size: 38,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: _EmployeeOrdersFragmentState._darkText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _EmployeeOrdersFragmentState._mutedText,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderFilterResult {
  const _OrderFilterResult({
    required this.showTicketingOnly,
    required this.showDeliveredOnly,
  });

  final bool showTicketingOnly;
  final bool showDeliveredOnly;
}

class _StatusVisual {
  const _StatusVisual({
    required this.label,
    required this.textColor,
    required this.bgColor,
  });

  final String label;
  final Color textColor;
  final Color bgColor;
}

enum _OrderStatus { ordered, delivered, rejected }

class _OrderData {
  const _OrderData({
    required this.orderId,
    required this.employeeId,
    required this.restaurant,
    required this.status,
    required this.time,
    required this.pickupSlot,
    required this.isTicketing,
    required this.orderIntent,
    required this.items,
    required this.total,
  });

  final String orderId;
  final String employeeId;
  final String restaurant;
  final _OrderStatus status;
  final String time;
  final String pickupSlot;
  final bool isTicketing;
  final String orderIntent;
  final List<_OrderItemData> items;
  final String total;
}

class _OrderItemData {
  const _OrderItemData({
    required this.name,
    required this.quantity,
    required this.price,
    required this.imagePath,
  });

  final String name;
  final int quantity;
  final String price;
  final String imagePath;
}
