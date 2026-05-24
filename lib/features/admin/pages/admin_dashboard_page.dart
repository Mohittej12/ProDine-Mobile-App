import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pro_dine/features/employee/data/employee_order_store.dart';
import 'package:pro_dine/features/admin/widgets/admin_shell.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final EmployeeOrderStore _orderStore = EmployeeOrderStore.instance;

  @override
  void initState() {
    super.initState();
    _orderStore.addListener(_handleOrdersChanged);
  }

  @override
  void dispose() {
    _orderStore.removeListener(_handleOrdersChanged);
    super.dispose();
  }

  void _handleOrdersChanged() {
    if (mounted) setState(() {});
  }

  List<EmployeeOrderEntry> get _orders => _orderStore.orders;

  List<EmployeeOrderEntry> get _todayOrders {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _orders
        .where((order) =>
            !order.createdAt.isBefore(start) && order.createdAt.isBefore(end))
        .toList();
  }

  List<_KpiData> get _kpis {
    final orders = _todayOrders;
    final total = orders.length;
    final delivered = orders
        .where((order) => order.status.toLowerCase() == 'delivered')
        .length;
    final rejected = orders
        .where((order) => order.status.toLowerCase() == 'rejected')
        .length;
    final revenue = orders.fold<int>(0, (sum, order) => sum + order.amount);
    final completion = total == 0 ? 0 : ((delivered / total) * 100).round();
    final rejection = total == 0 ? 0 : ((rejected / total) * 100).round();

    return [
      _KpiData(
        title: 'Orders',
        value: '$total',
        caption: 'Today from employee orders',
        icon: Icons.shopping_bag_rounded,
        type: _KpiType.orders,
      ),
      _KpiData(
        title: 'Delivered',
        value: '$delivered',
        caption: '$completion% completion rate',
        icon: Icons.done_rounded,
        type: _KpiType.good,
      ),
      _KpiData(
        title: 'Rejected',
        value: '$rejected',
        caption: '$rejection% rejection rate',
        icon: Icons.close_rounded,
        type: _KpiType.risk,
      ),
      _KpiData(
        title: 'Revenue',
        value: _formatMoney(revenue),
        caption: 'Today collected amount',
        icon: Icons.currency_rupee_rounded,
        type: _KpiType.money,
      ),
    ];
  }

  List<_BarData> get _weeklyBars {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return List.generate(7, (index) {
      final day = today.subtract(Duration(days: 6 - index));
      final nextDay = day.add(const Duration(days: 1));
      final count = _orders
          .where((order) =>
              !order.createdAt.isBefore(day) &&
              order.createdAt.isBefore(nextDay))
          .length;
      return _BarData(DateFormat('EEE').format(day), count);
    });
  }

  List<_VendorData> get _vendors {
    const vendorNames = ['Meal Counter', 'Tuck Shop'];

    return vendorNames.map((name) {
      final orders = _todayOrders.where((order) => order.shopName == name);
      final orderList = orders.toList();
      final total = orderList.length;
      final delivered = orderList
          .where((order) => order.status.toLowerCase() == 'delivered')
          .length;
      final rejected = orderList
          .where((order) => order.status.toLowerCase() == 'rejected')
          .length;
      final active = orderList
          .where((order) => order.status.toLowerCase() == 'ordered')
          .length;
      final revenue =
          orderList.fold<int>(0, (sum, order) => sum + order.amount);
      final deliveredRate =
          total == 0 ? 0 : ((delivered / total) * 100).round();
      final rejectedRate = total == 0 ? 0 : ((rejected / total) * 100).round();

      return _VendorData(
        name: name,
        orders: '$total',
        revenue: _formatMoney(revenue),
        delivered: '$deliveredRate%',
        rejected: '$rejectedRate%',
        queue: '$active active',
        eta: active == 0 ? 'No queue' : 'Live intent',
      );
    }).toList();
  }

  String get _mobileSummaryTitle {
    if (_todayOrders.isEmpty) return 'No employee orders yet today';
    return 'Today has ${_todayOrders.length} employee orders';
  }

  String get _mobileSummarySubtitle {
    final active = _todayOrders
        .where((order) => order.status.toLowerCase() == 'ordered')
        .length;
    final delivered = _todayOrders
        .where((order) => order.status.toLowerCase() == 'delivered')
        .length;
    final revenue =
        _todayOrders.fold<int>(0, (sum, order) => sum + order.amount);
    return '$active active - $delivered delivered - ${_formatMoney(revenue)} revenue';
  }

  String _formatMoney(int amount) {
    if (amount >= 100000) {
      return 'Rs ${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return 'Rs ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'Rs $amount';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _AdminLayout.fromWidth(constraints.maxWidth);

        return Column(
          children: [
            _TopBar(
              layout: layout,
              onMenuTap: () => AdminShell.openDrawer(context),
            ),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      layout.pagePadding,
                      layout.contentTopPadding,
                      layout.pagePadding,
                      34,
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
                              if (!layout.isDesktop) ...[
                                _MobileAdminSummary(
                                  layout: layout,
                                  title: _mobileSummaryTitle,
                                  subtitle: _mobileSummarySubtitle,
                                ),
                                SizedBox(height: layout.sectionGap),
                              ],
                              _KpiSection(layout: layout, data: _kpis),
                              SizedBox(height: layout.sectionGap),
                              if (layout.isDesktop)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 13,
                                      child: _WeeklyOrdersPanel(
                                        layout: layout,
                                        bars: _weeklyBars,
                                      ),
                                    ),
                                    SizedBox(width: layout.sectionGap),
                                    Expanded(
                                      flex: 9,
                                      child: _LiveOperationsPanel(
                                        layout: layout,
                                        vendors: _vendors,
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                _WeeklyOrdersPanel(
                                  layout: layout,
                                  bars: _weeklyBars,
                                ),
                                SizedBox(height: layout.sectionGap),
                                _LiveOperationsPanel(
                                  layout: layout,
                                  vendors: _vendors,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminTheme {
  const _AdminTheme._();

  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFFBFBFA);
  static const Color border = Color(0xFFEAE8E4);

  static const Color red = Color(0xFFFF1F1F);
  static const Color redDark = Color(0xFFE01818);
  static const Color redSoft = Color(0xFFFFEEEE);

  static const Color green = Color(0xFF138A45);
  static const Color greenSoft = Color(0xFFEAF8EF);

  static const Color orange = Color(0xFFFF7A1A);

  static const Color text = Color(0xFF151827);
  static const Color muted = Color(0xFF77726E);
  static const Color softText = Color(0xFF9B9690);
}

class _AdminLayout {
  const _AdminLayout({
    required this.isDesktop,
    required this.isTablet,
    required this.maxContentWidth,
    required this.pagePadding,
    required this.contentTopPadding,
    required this.topBarHeight,
    required this.sectionGap,
    required this.cardRadius,
    required this.cardPadding,
    required this.scale,
  });

  final bool isDesktop;
  final bool isTablet;
  final double maxContentWidth;
  final double pagePadding;
  final double contentTopPadding;
  final double topBarHeight;
  final double sectionGap;
  final double cardRadius;
  final double cardPadding;
  final double scale;

  static _AdminLayout fromWidth(double width) {
    if (width >= 1180) {
      return const _AdminLayout(
        isDesktop: true,
        isTablet: false,
        maxContentWidth: 1240,
        pagePadding: 36,
        contentTopPadding: 28,
        topBarHeight: 86,
        sectionGap: 22,
        cardRadius: 24,
        cardPadding: 22,
        scale: 1,
      );
    }

    if (width >= 760) {
      return const _AdminLayout(
        isDesktop: false,
        isTablet: true,
        maxContentWidth: 760,
        pagePadding: 28,
        contentTopPadding: 24,
        topBarHeight: 92,
        sectionGap: 20,
        cardRadius: 22,
        cardPadding: 20,
        scale: 1,
      );
    }

    final scale = (width / 390).clamp(0.88, 1.0).toDouble();

    return _AdminLayout(
      isDesktop: false,
      isTablet: false,
      maxContentWidth: 430,
      pagePadding: width < 360 ? 14 : 16,
      contentTopPadding: 18,
      topBarHeight: 82 * scale,
      sectionGap: 18,
      cardRadius: 20,
      cardPadding: width < 360 ? 15 : 16,
      scale: scale,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.layout, required this.onMenuTap});

  final _AdminLayout layout;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: layout.topBarHeight,
      decoration: const BoxDecoration(
        color: _AdminTheme.surface,
        border: Border(bottom: BorderSide(color: _AdminTheme.border, width: 1)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: layout.pagePadding),
            child: Row(
              children: [
                if (!layout.isDesktop)
                  _IconSquareButton(
                    icon: Icons.menu_rounded,
                    onTap: onMenuTap,
                    size: 48 * layout.scale,
                  ),
                if (!layout.isDesktop) SizedBox(width: 14 * layout.scale),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _AdminTheme.text,
                          fontSize: layout.isDesktop ? 25 : 25 * layout.scale,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                      SizedBox(height: 5 * layout.scale),
                      Text(
                        'Monitor cafeteria orders, vendors, and revenue in real time',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _AdminTheme.muted,
                          fontSize:
                              layout.isDesktop ? 13.5 : 13.5 * layout.scale,
                          height: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (layout.isDesktop) ...[
                  _TopBarChip(
                    icon: Icons.calendar_today_rounded,
                    label: 'Today',
                    color: _AdminTheme.text,
                    background: const Color(0xFFF3F2F0),
                  ),
                  const SizedBox(width: 10),
                  _TopBarChip(
                    icon: Icons.sync_rounded,
                    label: 'Live',
                    color: _AdminTheme.green,
                    background: _AdminTheme.greenSoft,
                  ),
                  const SizedBox(width: 10),
                  _ExportButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconSquareButton extends StatelessWidget {
  const _IconSquareButton({
    required this.icon,
    required this.onTap,
    required this.size,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F0EE),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: _AdminTheme.text, size: size * 0.56),
        ),
      ),
    );
  }
}

class _TopBarChip extends StatelessWidget {
  const _TopBarChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _AdminTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _AdminTheme.red,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(999),
        child: const SizedBox(
          height: 40,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.file_download_outlined,
                  size: 17,
                  color: Colors.white,
                ),
                SizedBox(width: 7),
                Text(
                  'Export',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
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

class _MobileAdminSummary extends StatelessWidget {
  const _MobileAdminSummary({
    required this.layout,
    required this.title,
    required this.subtitle,
  });

  final _AdminLayout layout;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16 * layout.scale),
      decoration: BoxDecoration(
        color: _AdminTheme.text,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42 * layout.scale,
            height: 42 * layout.scale,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.insights_rounded,
              color: Colors.white,
              size: 23 * layout.scale,
            ),
          ),
          SizedBox(width: 13 * layout.scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5 * layout.scale,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                  ),
                ),
                SizedBox(height: 5 * layout.scale),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 12.5 * layout.scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiSection extends StatelessWidget {
  const _KpiSection({required this.layout, required this.data});

  final _AdminLayout layout;
  final List<_KpiData> data;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = layout.isDesktop ? 4 : 2;
    final aspectRatio = layout.isDesktop
        ? 1.95
        : layout.isTablet
            ? 1.75
            : 1.35;

    return GridView.builder(
      itemCount: data.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: layout.isDesktop ? 14 : 12,
        mainAxisSpacing: layout.isDesktop ? 14 : 12,
        childAspectRatio: aspectRatio,
      ),
      itemBuilder: (context, index) {
        return _KpiCard(layout: layout, data: data[index]);
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.layout, required this.data});

  final _AdminLayout layout;
  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    final colors = _KpiColors.fromType(data.type);

    return _Panel(
      radius: layout.cardRadius,
      padding: EdgeInsets.all(layout.isDesktop ? 18 : 15 * layout.scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: layout.isDesktop ? 42 : 40 * layout.scale,
                height: layout.isDesktop ? 42 : 40 * layout.scale,
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  data.icon,
                  color: colors.fg,
                  size: layout.isDesktop ? 21 : 20 * layout.scale,
                ),
              ),
              SizedBox(width: 10 * layout.scale),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _AdminTheme.muted,
                    fontSize: layout.isDesktop ? 13 : 12.5 * layout.scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _AdminTheme.text,
              fontSize: layout.isDesktop ? 30 : 27 * layout.scale,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(height: 7 * layout.scale),
          Text(
            data.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.caption,
              fontSize: layout.isDesktop ? 12.5 : 11.5 * layout.scale,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyOrdersPanel extends StatelessWidget {
  const _WeeklyOrdersPanel({required this.layout, required this.bars});

  final _AdminLayout layout;
  final List<_BarData> bars;

  @override
  Widget build(BuildContext context) {
    final chartHeight = layout.isDesktop ? 300.0 : 245.0 * layout.scale;

    return _Panel(
      radius: layout.cardRadius + 2,
      padding: EdgeInsets.all(layout.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: 'Weekly Orders',
            subtitle: 'Last 7 days performance',
            layout: layout,
            trailing: _TrendBadge(layout: layout),
          ),
          SizedBox(height: layout.isDesktop ? 28 : 24 * layout.scale),
          SizedBox(
            height: chartHeight,
            child: _OrdersChart(bars: bars, layout: layout),
          ),
        ],
      ),
    );
  }
}

class _OrdersChart extends StatelessWidget {
  const _OrdersChart({required this.bars, required this.layout});

  final List<_BarData> bars;
  final _AdminLayout layout;

  @override
  Widget build(BuildContext context) {
    final maxValue =
        math.max(1, bars.map((e) => e.value).fold<int>(0, math.max)).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final barMaxHeight = constraints.maxHeight * 0.58;

        return Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _ChartGridPainter())),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars.map((bar) {
                final height = barMaxHeight * (bar.value / maxValue);
                return Expanded(
                  child: _ModernBar(data: bar, height: height, layout: layout),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _ModernBar extends StatelessWidget {
  const _ModernBar({
    required this.data,
    required this.height,
    required this.layout,
  });

  final _BarData data;
  final double height;
  final _AdminLayout layout;

  @override
  Widget build(BuildContext context) {
    final barWidth = layout.isDesktop ? 34.0 : 30.0 * layout.scale;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8 * layout.scale,
            vertical: 5 * layout.scale,
          ),
          decoration: BoxDecoration(
            color: _AdminTheme.text,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            data.value.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: layout.isDesktop ? 11.5 : 10.5 * layout.scale,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(height: 9 * layout.scale),
        Container(
          width: barWidth,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_AdminTheme.red, _AdminTheme.orange],
            ),
            boxShadow: [
              BoxShadow(
                color: _AdminTheme.red.withOpacity(0.16),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
        ),
        SizedBox(height: 13 * layout.scale),
        Text(
          data.day,
          style: TextStyle(
            color: _AdminTheme.softText,
            fontSize: layout.isDesktop ? 13 : 12.5 * layout.scale,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ChartGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _AdminTheme.border.withOpacity(0.55)
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LiveOperationsPanel extends StatelessWidget {
  const _LiveOperationsPanel({required this.layout, required this.vendors});

  final _AdminLayout layout;
  final List<_VendorData> vendors;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      radius: layout.cardRadius + 2,
      padding: EdgeInsets.all(layout.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: 'Cafeteria Snapshot',
            subtitle: 'Live vendor performance',
            layout: layout,
            trailing: layout.isDesktop ? _MiniLiveDot(layout: layout) : null,
          ),
          SizedBox(height: 18 * layout.scale),
          ...List.generate(vendors.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == vendors.length - 1 ? 0 : 14 * layout.scale,
              ),
              child: _VendorCard(vendor: vendors[index], layout: layout),
            );
          }),
        ],
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  const _VendorCard({required this.vendor, required this.layout});

  final _VendorData vendor;
  final _AdminLayout layout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(layout.isDesktop ? 17 : 16 * layout.scale),
      decoration: BoxDecoration(
        color: _AdminTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AdminTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: layout.isDesktop ? 42 : 40 * layout.scale,
                height: layout.isDesktop ? 42 : 40 * layout.scale,
                decoration: BoxDecoration(
                  color: _AdminTheme.redSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: _AdminTheme.red,
                  size: layout.isDesktop ? 21 : 20 * layout.scale,
                ),
              ),
              SizedBox(width: 11 * layout.scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _AdminTheme.text,
                        fontSize: layout.isDesktop ? 16.5 : 16 * layout.scale,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4 * layout.scale),
                    Text(
                      '${vendor.queue} · ${vendor.eta}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _AdminTheme.muted,
                        fontSize: layout.isDesktop ? 12 : 11.5 * layout.scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: 'LIVE', layout: layout),
            ],
          ),
          SizedBox(height: 15 * layout.scale),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            childAspectRatio: layout.isDesktop ? 2.35 : 2.25,
            children: [
              _VendorStat(
                label: 'Orders',
                value: vendor.orders,
                layout: layout,
              ),
              _VendorStat(
                label: 'Revenue',
                value: vendor.revenue,
                layout: layout,
              ),
              _VendorStat(
                label: 'Delivered',
                value: vendor.delivered,
                valueColor: _AdminTheme.green,
                layout: layout,
              ),
              _VendorStat(
                label: 'Rejected',
                value: vendor.rejected,
                valueColor: _AdminTheme.redDark,
                layout: layout,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VendorStat extends StatelessWidget {
  const _VendorStat({
    required this.label,
    required this.value,
    required this.layout,
    this.valueColor,
  });

  final String label;
  final String value;
  final _AdminLayout layout;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * layout.scale,
        vertical: 10 * layout.scale,
      ),
      decoration: BoxDecoration(
        color: _AdminTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AdminTheme.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _AdminTheme.muted,
              fontSize: layout.isDesktop ? 11.5 : 11 * layout.scale,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6 * layout.scale),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? _AdminTheme.text,
              fontSize: layout.isDesktop ? 17 : 16 * layout.scale,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.subtitle,
    required this.layout,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final _AdminLayout layout;
  final Widget? trailing;

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
                title,
                style: TextStyle(
                  color: _AdminTheme.text,
                  fontSize: layout.isDesktop ? 20 : 19 * layout.scale,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6 * layout.scale),
              Text(
                subtitle,
                style: TextStyle(
                  color: _AdminTheme.muted,
                  fontSize: layout.isDesktop ? 13 : 12.5 * layout.scale,
                  height: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: 12 * layout.scale),
          trailing!,
        ],
      ],
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.layout});

  final _AdminLayout layout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 11 * layout.scale,
        vertical: 8 * layout.scale,
      ),
      decoration: BoxDecoration(
        color: _AdminTheme.greenSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up_rounded,
            size: 16 * layout.scale,
            color: _AdminTheme.green,
          ),
          SizedBox(width: 6 * layout.scale),
          Text(
            'Trending up',
            style: TextStyle(
              color: _AdminTheme.green,
              fontSize: 12.5 * layout.scale,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLiveDot extends StatelessWidget {
  const _MiniLiveDot({required this.layout});

  final _AdminLayout layout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: _AdminTheme.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        const Text(
          'Live',
          style: TextStyle(
            color: _AdminTheme.green,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.layout});

  final String label;
  final _AdminLayout layout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 9 * layout.scale,
        vertical: 6 * layout.scale,
      ),
      decoration: BoxDecoration(
        color: _AdminTheme.greenSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _AdminTheme.green,
          fontSize: 10.5 * layout.scale,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    required this.radius,
    required this.padding,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _AdminTheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _AdminTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _KpiData {
  const _KpiData({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.type,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final _KpiType type;
}

enum _KpiType { orders, good, risk, money }

class _KpiColors {
  const _KpiColors({required this.bg, required this.fg, required this.caption});

  final Color bg;
  final Color fg;
  final Color caption;

  static _KpiColors fromType(_KpiType type) {
    switch (type) {
      case _KpiType.orders:
        return const _KpiColors(
          bg: _AdminTheme.redSoft,
          fg: _AdminTheme.red,
          caption: _AdminTheme.green,
        );
      case _KpiType.good:
        return const _KpiColors(
          bg: _AdminTheme.greenSoft,
          fg: _AdminTheme.green,
          caption: _AdminTheme.green,
        );
      case _KpiType.risk:
        return const _KpiColors(
          bg: _AdminTheme.redSoft,
          fg: _AdminTheme.redDark,
          caption: _AdminTheme.redDark,
        );
      case _KpiType.money:
        return const _KpiColors(
          bg: _AdminTheme.greenSoft,
          fg: _AdminTheme.green,
          caption: _AdminTheme.green,
        );
    }
  }
}

class _BarData {
  const _BarData(this.day, this.value);

  final String day;
  final int value;
}

class _VendorData {
  const _VendorData({
    required this.name,
    required this.orders,
    required this.revenue,
    required this.delivered,
    required this.rejected,
    required this.queue,
    required this.eta,
  });

  final String name;
  final String orders;
  final String revenue;
  final String delivered;
  final String rejected;
  final String queue;
  final String eta;
}
