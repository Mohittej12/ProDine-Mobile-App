import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_shell.dart';

class VendorDashboardPage extends StatefulWidget {
  const VendorDashboardPage({super.key});

  @override
  State<VendorDashboardPage> createState() => _VendorDashboardPageState();
}

class _VendorDashboardPageState extends State<VendorDashboardPage> {
  static const Color _primaryRed = Color(0xFFFF1F1F);
  static const Color _orange = Color(0xFFFF5A00);
  static const Color _green = Color(0xFF22C55E);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _darkText = Color(0xFF141827);
  static const Color _mutedText = Color(0xFF667085);
  static const Color _softBorder = Color(0xFFF0F0F0);

  final List<_VendorOrder> _orders = [
    const _VendorOrder(
      id: '#1023',
      customerName: 'Employee Order',
      items: 'Biryani x1, Idli x2',
      placedAgo: 'Placed 5 mins ago',
      amount: '₹260',
      prepMinutes: 14,
      status: _VendorOrderStatus.newOrder,
      type: _VendorOrderType.regular,
    ),
    const _VendorOrder(
      id: '#1024',
      customerName: 'Employee Order',
      items: 'Dosa x2, Coffee x1',
      placedAgo: 'Placed 12 mins ago',
      amount: '₹205',
      prepMinutes: 11,
      status: _VendorOrderStatus.newOrder,
      type: _VendorOrderType.regular,
    ),
    const _VendorOrder(
      id: '#1022',
      customerName: 'Ticketing',
      items: 'Breakfast x1',
      placedAgo: 'Placed 18 mins ago',
      amount: 'Company Supported',
      prepMinutes: 8,
      status: _VendorOrderStatus.newOrder,
      type: _VendorOrderType.ticketing,
    ),
  ];

  int get _todayOrders => _orders.length;

  int get _activeOrders => _orders
      .where((order) => order.status == _VendorOrderStatus.newOrder)
      .length;

  int get _deliveredOrders => _orders
      .where((order) => order.status == _VendorOrderStatus.delivered)
      .length;

  int get _rejectedOrders => _orders
      .where((order) => order.status == _VendorOrderStatus.rejected)
      .length;

  int get _todayRevenue {
    var total = 0;

    for (final order in _orders) {
      if (order.type == _VendorOrderType.ticketing) continue;

      final numeric = order.amount.replaceAll(RegExp(r'[^0-9]'), '');
      if (numeric.isEmpty) continue;
      total += int.tryParse(numeric) ?? 0;
    }

    return total;
  }

  int get _todayAvgPrepTime {
    final todays = _orders.where((o) => true).toList();
    if (todays.isEmpty) return 0;
    final sum = todays.fold<int>(0, (p, e) => p + (e.prepMinutes ?? 0));
    return (sum / todays.length).round();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _VendorDashboardLayout.fromWidth(constraints.maxWidth);

        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DashboardHeader(
                          layout: layout,
                          onMenuTap: _openDrawerOrSnack,
                        ),
                        SizedBox(height: layout.sectionGap),
                        if (layout.isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 11,
                                child: _HeroRevenueCard(
                                  layout: layout,
                                  todayOrders: _todayOrders,
                                  revenue: _todayRevenue,
                                  activeOrders: _activeOrders,
                                  avgPrepMinutes: _todayAvgPrepTime,
                                ),
                              ),
                              SizedBox(width: layout.gridGap),
                              Expanded(
                                flex: 10,
                                child: _MetricGrid(
                                  layout: layout,
                                  activeOrders: _activeOrders,
                                  deliveredOrders: _deliveredOrders,
                                  rejectedOrders: _rejectedOrders,
                                  revenue: _todayRevenue,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _HeroRevenueCard(
                            layout: layout,
                            todayOrders: _todayOrders,
                            revenue: _todayRevenue,
                            activeOrders: _activeOrders,
                            avgPrepMinutes: _todayAvgPrepTime,
                          ),
                          SizedBox(height: layout.cardGap),
                          _MetricGrid(
                            layout: layout,
                            activeOrders: _activeOrders,
                            deliveredOrders: _deliveredOrders,
                            rejectedOrders: _rejectedOrders,
                            revenue: _todayRevenue,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openDrawerOrSnack() {
    if (VendorShell.openDrawer(context)) {
      return;
    }

    _showSnack('Vendor menu');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _darkText,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
  }
}

class _VendorDashboardLayout {
  const _VendorDashboardLayout({
    required this.isDesktop,
    required this.isTablet,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.scale,
    required this.sectionGap,
    required this.cardGap,
    required this.gridGap,
    required this.metricColumns,
    required this.orderColumns,
  });

  final bool isDesktop;
  final bool isTablet;
  final double maxContentWidth;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double scale;
  final double sectionGap;
  final double cardGap;
  final double gridGap;
  final int metricColumns;
  final int orderColumns;

  static _VendorDashboardLayout fromWidth(double width) {
    if (width >= 1180) {
      return const _VendorDashboardLayout(
        isDesktop: true,
        isTablet: false,
        maxContentWidth: 1180,
        horizontalPadding: 48,
        topPadding: 30,
        bottomPadding: 56,
        scale: 1.08,
        sectionGap: 30,
        cardGap: 20,
        gridGap: 22,
        metricColumns: 2,
        orderColumns: 2,
      );
    }

    if (width >= 760) {
      return const _VendorDashboardLayout(
        isDesktop: false,
        isTablet: true,
        maxContentWidth: 760,
        horizontalPadding: 36,
        topPadding: 28,
        bottomPadding: 56,
        scale: 1.02,
        sectionGap: 28,
        cardGap: 18,
        gridGap: 20,
        metricColumns: 2,
        orderColumns: 2,
      );
    }

    return _VendorDashboardLayout(
      isDesktop: false,
      isTablet: false,
      maxContentWidth: 430,
      horizontalPadding: width < 370 ? 14 : 16,
      topPadding: 18,
      bottomPadding: 132,
      scale: width < 370 ? 0.92 : 1,
      sectionGap: 24,
      cardGap: 16,
      gridGap: width < 370 ? 12 : 14,
      metricColumns: 2,
      orderColumns: 1,
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.layout, required this.onMenuTap});

  final _VendorDashboardLayout layout;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return SizedBox(
      height: layout.isDesktop ? 58 : 52 * scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onMenuTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: layout.isDesktop ? 48 : 44 * scale,
                  height: layout.isDesktop ? 48 : 44 * scale,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F2F4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.045),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    color: _VendorDashboardPageState._darkText,
                    size: layout.isDesktop ? 28 : 26 * scale,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Dashboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _VendorDashboardPageState._darkText,
                    fontSize: layout.isDesktop ? 31 : 23 * scale,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                if (layout.isDesktop) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Live vendor operations',
                    style: TextStyle(
                      color: _VendorDashboardPageState._mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 8 * scale,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEFFFF4),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _VendorDashboardPageState._green.withOpacity(0.18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7 * scale,
                    height: 7 * scale,
                    decoration: const BoxDecoration(
                      color: _VendorDashboardPageState._green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 7 * scale),
                  Text(
                    'Live',
                    style: TextStyle(
                      color: _VendorDashboardPageState._green,
                      fontSize: 12 * scale,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroRevenueCard extends StatelessWidget {
  const _HeroRevenueCard({
    required this.layout,
    required this.todayOrders,
    required this.revenue,
    required this.activeOrders,
    required this.avgPrepMinutes,
  });

  final _VendorDashboardLayout layout;
  final int todayOrders;
  final int revenue;
  final int activeOrders;
  final int avgPrepMinutes;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(layout.isDesktop ? 30 : 24 * scale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _VendorDashboardPageState._primaryRed,
            _VendorDashboardPageState._orange,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30 * scale),
        boxShadow: [
          BoxShadow(
            color: _VendorDashboardPageState._primaryRed.withOpacity(0.24),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -45,
            child: Container(
              width: 150 * scale,
              height: 150 * scale,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: -54,
            child: Container(
              width: 120 * scale,
              height: 120 * scale,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48 * scale,
                    height: 48 * scale,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16 * scale),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 25 * scale,
                    ),
                  ),
                  SizedBox(width: 14 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Orders",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: layout.isDesktop ? 19 : 17 * scale,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        Text(
                          activeOrders == 0
                              ? 'No pending orders'
                              : '$activeOrders orders need action',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 13 * scale,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 28 * scale),
              Text(
                '$todayOrders',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: layout.isDesktop ? 74 : 62 * scale,
                  height: 0.9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2.4,
                ),
              ),
              SizedBox(height: 10 * scale),
              Text(
                'Total orders received today',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.76),
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 24 * scale),
              Container(height: 1, color: Colors.white.withOpacity(0.22)),
              SizedBox(height: 20 * scale),
              Row(
                children: [
                  Expanded(
                    child: _HeroStat(
                      label: 'Revenue',
                      value: '₹$revenue',
                      scale: scale,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 34 * scale,
                    color: Colors.white.withOpacity(0.18),
                  ),
                  Expanded(
                    child: _HeroStat(
                      label: 'Avg. Prep',
                      value: '${avgPrepMinutes}m',
                      scale: scale,
                      alignRight: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.scale,
    this.alignRight = false,
  });

  final String label;
  final String value;
  final double scale;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.72),
            fontSize: 12.5 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6 * scale),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22 * scale,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.45,
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.layout,
    required this.activeOrders,
    required this.deliveredOrders,
    required this.rejectedOrders,
    required this.revenue,
  });

  final _VendorDashboardLayout layout;
  final int activeOrders;
  final int deliveredOrders;
  final int rejectedOrders;
  final int revenue;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        title: 'Active',
        value: '$activeOrders',
        subtitle: 'Needs action',
        icon: Icons.bolt_rounded,
        color: _VendorDashboardPageState._primaryRed,
        bgColor: const Color(0xFFFFEFEF),
      ),
      _MetricData(
        title: 'Delivered',
        value: '$deliveredOrders',
        subtitle: 'Completed',
        icon: Icons.check_circle_rounded,
        color: _VendorDashboardPageState._green,
        bgColor: const Color(0xFFEFFFF4),
      ),
      _MetricData(
        title: 'Rejected',
        value: '$rejectedOrders',
        subtitle: 'Cancelled',
        icon: Icons.cancel_rounded,
        color: const Color(0xFFEF4444),
        bgColor: const Color(0xFFFFEFEF),
      ),
      _MetricData(
        title: 'Revenue',
        value: '₹$revenue',
        subtitle: 'Today',
        icon: Icons.payments_rounded,
        color: _VendorDashboardPageState._orange,
        bgColor: const Color(0xFFFFF3E8),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.min(layout.metricColumns, metrics.length);
        final spacing = layout.gridGap;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics.map((metric) {
            return SizedBox(
              width: width,
              child: _MetricCard(layout: layout, metric: metric),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.layout, required this.metric});

  final _VendorDashboardLayout layout;
  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      padding: EdgeInsets.all(17 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22 * scale),
        border: Border.all(color: _VendorDashboardPageState._softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42 * scale,
            height: 42 * scale,
            decoration: BoxDecoration(
              color: metric.bgColor,
              borderRadius: BorderRadius.circular(14 * scale),
            ),
            child: Icon(metric.icon, color: metric.color, size: 22 * scale),
          ),
          SizedBox(height: 15 * scale),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _VendorDashboardPageState._darkText,
              fontSize: layout.isDesktop ? 25 : 22 * scale,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            metric.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _VendorDashboardPageState._darkText,
              fontSize: 14 * scale,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5 * scale),
          Text(
            metric.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _VendorDashboardPageState._mutedText,
              fontSize: 12 * scale,
              height: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.layout,
    required this.title,
    required this.actionText,
    required this.onActionTap,
  });

  final _VendorDashboardLayout layout;
  final String title;
  final String actionText;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _VendorDashboardPageState._darkText,
              fontSize: layout.isDesktop ? 28 : 23 * scale,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
        ),
        Material(
          color: const Color(0xFFFFEFEF),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: onActionTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 13 * scale,
                vertical: 9 * scale,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionText,
                    style: TextStyle(
                      color: _VendorDashboardPageState._primaryRed,
                      fontSize: 13.5 * scale,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 3 * scale),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _VendorDashboardPageState._primaryRed,
                    size: 20 * scale,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveOrdersPanel extends StatelessWidget {
  const _ActiveOrdersPanel({
    required this.layout,
    required this.orders,
    required this.onDelivered,
    required this.onRejected,
  });

  final _VendorDashboardLayout layout;
  final List<_VendorOrder> orders;
  final ValueChanged<String> onDelivered;
  final ValueChanged<String> onRejected;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const _EmptyOrdersState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.min(layout.orderColumns, orders.length);
        final spacing = layout.gridGap;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: orders.map((order) {
            return SizedBox(
              width: width,
              child: _VendorOrderCard(
                layout: layout,
                order: order,
                onDelivered: () => onDelivered(order.id),
                onRejected: () => onRejected(order.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _VendorOrderCard extends StatelessWidget {
  const _VendorOrderCard({
    required this.layout,
    required this.order,
    required this.onDelivered,
    required this.onRejected,
  });

  final _VendorDashboardLayout layout;
  final _VendorOrder order;
  final VoidCallback onDelivered;
  final VoidCallback onRejected;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(color: _VendorDashboardPageState._softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46 * scale,
                height: 46 * scale,
                decoration: BoxDecoration(
                  color: order.type == _VendorOrderType.ticketing
                      ? const Color(0xFFFFEFEF)
                      : const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(15 * scale),
                ),
                child: Icon(
                  order.type == _VendorOrderType.ticketing
                      ? Icons.confirmation_number_rounded
                      : Icons.shopping_bag_rounded,
                  color: order.type == _VendorOrderType.ticketing
                      ? _VendorDashboardPageState._primaryRed
                      : _VendorDashboardPageState._blue,
                  size: 23 * scale,
                ),
              ),
              SizedBox(width: 13 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8 * scale,
                      runSpacing: 6 * scale,
                      children: [
                        Text(
                          'Order ${order.id}',
                          style: TextStyle(
                            color: _VendorDashboardPageState._darkText,
                            fontSize: layout.isDesktop ? 17 : 15.5 * scale,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.25,
                          ),
                        ),
                        _StatusBadge(
                          text: 'New',
                          bgColor: const Color(0xFFEAF2FF),
                          textColor: _VendorDashboardPageState._blue,
                          scale: scale,
                        ),
                        if (order.type == _VendorOrderType.ticketing)
                          _StatusBadge(
                            text: 'Ticketing',
                            bgColor: const Color(0xFFFFEFEF),
                            textColor: _VendorDashboardPageState._primaryRed,
                            scale: scale,
                          ),
                      ],
                    ),
                    SizedBox(height: 8 * scale),
                    Text(
                      order.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _VendorDashboardPageState._mutedText,
                        fontSize: 12.5 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * scale),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(18 * scale),
              border: Border.all(color: const Color(0xFFF2F2F2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.items,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _VendorDashboardPageState._darkText,
                    fontSize: layout.isDesktop ? 15 : 14 * scale,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 9 * scale),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: _VendorDashboardPageState._mutedText,
                      size: 15 * scale,
                    ),
                    SizedBox(width: 6 * scale),
                    Expanded(
                      child: Text(
                        order.placedAgo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _VendorDashboardPageState._mutedText,
                          fontSize: 12.5 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      order.amount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: order.type == _VendorOrderType.ticketing
                            ? _VendorDashboardPageState._primaryRed
                            : _VendorDashboardPageState._darkText,
                        fontSize: 12.5 * scale,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16 * scale),
          Row(
            children: [
              Expanded(
                child: _OrderActionButton(
                  label: 'Delivered',
                  icon: Icons.check_rounded,
                  color: _VendorDashboardPageState._green,
                  onTap: onDelivered,
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: _OrderActionButton(
                  label: 'Reject',
                  icon: Icons.close_rounded,
                  color: _VendorDashboardPageState._primaryRed,
                  onTap: onRejected,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.bgColor,
    required this.textColor,
    required this.scale,
  });

  final String text;
  final Color bgColor;
  final Color textColor;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 5 * scale,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11 * scale,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OrderActionButton extends StatelessWidget {
  const _OrderActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _VendorDashboardPageState._softBorder),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            color: _VendorDashboardPageState._primaryRed,
            size: 38,
          ),
          SizedBox(height: 12),
          Text(
            'No active orders',
            style: TextStyle(
              color: _VendorDashboardPageState._darkText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'New employee orders will appear here instantly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _VendorDashboardPageState._mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
}

enum _VendorOrderStatus { newOrder, delivered, rejected }

enum _VendorOrderType { regular, ticketing }

class _VendorOrder {
  const _VendorOrder({
    required this.id,
    required this.customerName,
    required this.items,
    required this.placedAgo,
    required this.amount,
    required this.status,
    required this.type,
    required this.prepMinutes,
  });

  final String id;
  final String customerName;
  final String items;
  final String placedAgo;
  final String amount;
  final _VendorOrderStatus status;
  final _VendorOrderType type;
  final int prepMinutes;

  _VendorOrder copyWith({
    String? id,
    String? customerName,
    String? items,
    String? placedAgo,
    String? amount,
    _VendorOrderStatus? status,
    _VendorOrderType? type,
    int? prepMinutes,
  }) {
    return _VendorOrder(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      placedAgo: placedAgo ?? this.placedAgo,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      type: type ?? this.type,
      prepMinutes: prepMinutes ?? this.prepMinutes,
    );
  }
}
