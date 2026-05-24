import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pro_dine/features/employee/data/employee_order_store.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_page_header.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_shell.dart';
import 'package:pro_dine/utils/file_download.dart';

class VendorReportsPage extends StatefulWidget {
  const VendorReportsPage({super.key});

  @override
  State<VendorReportsPage> createState() => _VendorReportsPageState();
}

class _VendorReportsPageState extends State<VendorReportsPage> {
  final EmployeeOrderStore _orderStore = EmployeeOrderStore.instance;

  int _selectedFilter = 0;
  bool _showAllOrders = false;
  DateTimeRange? _selectedDateRange;

  final List<String> _filters = const [
    'Today',
    'This Week',
    'This Month',
    'Custom',
  ];

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

  String _filterLabel(int index) {
    if (index == 3 && _selectedDateRange != null) {
      final start = DateFormat('MMM d').format(_selectedDateRange!.start);
      final end = DateFormat('MMM d').format(_selectedDateRange!.end);
      return '$start - $end';
    }
    return _filters[index];
  }

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _ReportsTheme.primaryRed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _ReportsTheme.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _ReportsTheme.primaryRed,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _selectedDateRange = picked;
      _selectedFilter = 3;
      _showAllOrders = false;
    });
  }

  List<EmployeeOrderEntry> get _filteredOrders {
    final now = DateTime.now();
    late DateTime start;
    late DateTime end;

    if (_selectedFilter == 0) {
      start = DateTime(now.year, now.month, now.day);
      end = start.add(const Duration(days: 1));
    } else if (_selectedFilter == 1) {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(monday.year, monday.month, monday.day);
      end = start.add(const Duration(days: 7));
    } else if (_selectedFilter == 2) {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 1);
    } else if (_selectedDateRange != null) {
      start = DateTime(
        _selectedDateRange!.start.year,
        _selectedDateRange!.start.month,
        _selectedDateRange!.start.day,
      );
      end = DateTime(
        _selectedDateRange!.end.year,
        _selectedDateRange!.end.month,
        _selectedDateRange!.end.day,
      ).add(const Duration(days: 1));
    } else {
      return _orderStore.orders;
    }

    return _orderStore.orders.where((order) {
      final created = order.createdAt;
      return !created.isBefore(start) && created.isBefore(end);
    }).toList();
  }

  List<_ReportOrder> get _reportOrders {
    final orders = _filteredOrders.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return orders.map(_toReportOrder).toList();
  }

  List<_RevenuePoint> get _revenue {
    final grouped = <DateTime, int>{};
    for (final order in _filteredOrders) {
      final day = DateTime(
        order.createdAt.year,
        order.createdAt.month,
        order.createdAt.day,
      );
      grouped[day] = (grouped[day] ?? 0) + order.amount;
    }

    final days = grouped.keys.toList()..sort();
    return days
        .map(
          (day) => _RevenuePoint(
            day: DateFormat('EEE').format(day),
            value: grouped[day] ?? 0,
          ),
        )
        .toList();
  }

  List<_MetricData> get _metrics {
    final orders = _filteredOrders;
    final revenue = orders.fold<int>(0, (sum, order) => sum + order.amount);
    final average = orders.isEmpty ? 0 : revenue ~/ orders.length;

    return [
      _MetricData(
        label: 'Revenue',
        value: 'Rs $revenue',
        icon: Icons.currency_rupee_rounded,
        tone: _ReportsTheme.primaryRed,
      ),
      _MetricData(
        label: 'Orders',
        value: '${orders.length}',
        icon: Icons.receipt_long_rounded,
        tone: const Color(0xFF4B5563),
      ),
      _MetricData(
        label: 'Avg Order',
        value: 'Rs $average',
        icon: Icons.bar_chart_rounded,
        tone: const Color(0xFF4B5563),
      ),
    ];
  }

  List<_ReportOrder> get _visibleOrders {
    final orders = _reportOrders;
    if (_showAllOrders || orders.length <= 3) return orders;
    return orders.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _ReportsLayout.fromWidth(constraints.maxWidth);
        final filterLabels =
            List.generate(_filters.length, (index) => _filterLabel(index));
        final allOrders = _reportOrders;

        return Column(
          children: [
            VendorPageHeader(
              title: 'Reports',
              maxContentWidth: layout.maxContentWidth,
              horizontalPadding: layout.horizontalPadding,
              isDesktop: layout.isDesktop,
              scale: layout.scale,
              onMenuTap: () => VendorShell.openDrawer(context),
            ),
            _ReportsFilterBar(
              layout: layout,
              filters: filterLabels,
              selectedIndex: _selectedFilter,
              onSelected: (index) {
                if (index == 3) {
                  _selectCustomRange();
                  return;
                }
                setState(() {
                  _selectedFilter = index;
                  _showAllOrders = false;
                });
              },
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
                  child: layout.isDesktop
                      ? _DesktopReportsBody(
                          layout: layout,
                          metrics: _metrics,
                          revenue: _revenue,
                          orders: _visibleOrders,
                          totalOrderCount: allOrders.length,
                          selectedFilter: _filterLabel(_selectedFilter),
                          showViewAll: !_showAllOrders && allOrders.length > 3,
                          onViewAll: () =>
                              setState(() => _showAllOrders = true),
                          onDownload: _downloadReport,
                        )
                      : _MobileReportsBody(
                          layout: layout,
                          metrics: _metrics,
                          revenue: _revenue,
                          orders: _visibleOrders,
                          totalOrderCount: allOrders.length,
                          selectedFilter: _filterLabel(_selectedFilter),
                          showViewAll: !_showAllOrders && allOrders.length > 3,
                          onViewAll: () =>
                              setState(() => _showAllOrders = true),
                          onDownload: _downloadReport,
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  _ReportOrder _toReportOrder(EmployeeOrderEntry order) {
    final status = switch (order.status.toLowerCase()) {
      'delivered' => _OrderStatus.delivered,
      'rejected' => _OrderStatus.rejected,
      _ => _OrderStatus.ordered,
    };

    return _ReportOrder(
      id: order.orderId,
      date: DateFormat('dd MMM yyyy').format(order.createdAt),
      day: DateFormat('EEEE').format(order.createdAt),
      time: DateFormat('h:mm a').format(order.createdAt),
      vendor: order.shopName,
      employee: order.userName,
      intent: order.orderIntent,
      status: status,
      total: order.amount,
      items: order.items
          .map(
            (item) => _ReportOrderItem(
              name: item.name,
              quantity: item.quantity,
              note: item.price == 0 ? 'covered' : 'Rs ${item.price} each',
              amount: item.price * item.quantity,
            ),
          )
          .toList(),
    );
  }

  Future<void> _downloadReport() async {
    final orders = _filteredOrders;
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No orders in selected range'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final csv = StringBuffer()
      ..writeln(
        [
          'Order ID',
          'Date',
          'Day',
          'Time',
          'Employee ID',
          'Employee Name',
          'Vendor',
          'Intent',
          'Items',
          'Amount',
          'Status',
        ].join(','),
      );

    for (final order in orders) {
      final items = order.items
          .map((item) => '${item.name} x${item.quantity}')
          .join(' | ');
      final cells = [
        order.orderId,
        DateFormat('yyyy-MM-dd').format(order.createdAt),
        DateFormat('EEEE').format(order.createdAt),
        DateFormat('h:mm a').format(order.createdAt),
        order.employeeId,
        order.userName,
        order.shopName,
        order.orderIntent,
        items,
        order.amount.toString(),
        order.status,
      ];
      csv.writeln(cells.map(_csvCell).join(','));
    }

    try {
      final fileName =
          'vendor_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final result = await downloadCsv(fileName, csv.toString());

      if (!mounted) return;

      if (kIsWeb) {
        _showSnack('Download started');
      } else if (result != null) {
        _showSnack('Report saved to $result');
      } else {
        _showSnack('Report generated');
      }
    } catch (err) {
      if (!mounted) return;
      _showSnack('Failed to generate report: $err');
    }
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n')) {
      return '"$escaped"';
    }
    return escaped;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _ReportsTheme {
  const _ReportsTheme._();

  static const Color primaryRed = Color(0xFFFF1F1F);
  static const Color textDark = Color(0xFF141827);
  static const Color textMuted = Color(0xFF667085);
  static const Color cardBorder = Color(0xFFE6E8EC);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color softRed = Color(0xFFFFEFEF);
  static const Color success = Color(0xFF108A43);
  static const Color successBg = Color(0xFFEAF9F0);
  static const Color warning = Color(0xFFE98300);
  static const Color warningBg = Color(0xFFFFF4E5);
  static const Color rejectedBg = Color(0xFFFFEEF1);
}

class _ReportsLayout {
  const _ReportsLayout({
    required this.isDesktop,
    required this.isTablet,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.topPadding,
    required this.scale,
    required this.cardRadius,
    required this.cardPadding,
  });

  final bool isDesktop;
  final bool isTablet;
  final double maxContentWidth;
  final double horizontalPadding;
  final double topPadding;
  final double scale;
  final double cardRadius;
  final double cardPadding;

  static _ReportsLayout fromWidth(double width) {
    if (width >= 1100) {
      return const _ReportsLayout(
        isDesktop: true,
        isTablet: false,
        maxContentWidth: 1180,
        horizontalPadding: 42,
        topPadding: 30,
        scale: 1,
        cardRadius: 22,
        cardPadding: 24,
      );
    }

    if (width >= 760) {
      return const _ReportsLayout(
        isDesktop: false,
        isTablet: true,
        maxContentWidth: 760,
        horizontalPadding: 32,
        topPadding: 24,
        scale: 1,
        cardRadius: 22,
        cardPadding: 22,
      );
    }

    final scale = (width / 390).clamp(0.88, 1.0).toDouble();

    return _ReportsLayout(
      isDesktop: false,
      isTablet: false,
      maxContentWidth: 430,
      horizontalPadding: width < 360 ? 14 : 16,
      topPadding: 20,
      scale: scale,
      cardRadius: 12,
      cardPadding: width < 360 ? 16 : 18,
    );
  }
}

class _ReportsFilterBar extends StatelessWidget {
  const _ReportsFilterBar({
    required this.layout,
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  final _ReportsLayout layout;
  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: layout.isDesktop ? 68 : 66 * layout.scale,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _ReportsTheme.cardBorder, width: 1),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: layout.horizontalPadding,
              vertical: 11 * layout.scale,
            ),
            itemCount: filters.length,
            separatorBuilder: (_, __) => SizedBox(width: 10 * layout.scale),
            itemBuilder: (context, index) {
              return _FilterPill(
                layout: layout,
                label: filters[index],
                active: selectedIndex == index,
                onTap: () => onSelected(index),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.layout,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final _ReportsLayout layout;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? _ReportsTheme.primaryRed : Colors.white,
      borderRadius: BorderRadius.circular(999),
      elevation: active ? 3 : 0,
      shadowColor: _ReportsTheme.primaryRed.withValues(alpha: 0.22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: layout.isDesktop ? 42 : 42 * layout.scale,
          constraints: BoxConstraints(
            minWidth: layout.isDesktop ? 116 : 92 * layout.scale,
          ),
          padding: EdgeInsets.symmetric(horizontal: 18 * layout.scale),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  active ? _ReportsTheme.primaryRed : _ReportsTheme.cardBorder,
              width: 1,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? Colors.white : _ReportsTheme.textDark,
              fontSize: layout.isDesktop ? 14 : 13.5 * layout.scale,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileReportsBody extends StatelessWidget {
  const _MobileReportsBody({
    required this.layout,
    required this.metrics,
    required this.revenue,
    required this.orders,
    required this.totalOrderCount,
    required this.selectedFilter,
    required this.showViewAll,
    required this.onViewAll,
    required this.onDownload,
  });

  final _ReportsLayout layout;
  final List<_MetricData> metrics;
  final List<_RevenuePoint> revenue;
  final List<_ReportOrder> orders;
  final int totalOrderCount;
  final String selectedFilter;
  final bool showViewAll;
  final VoidCallback onViewAll;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        layout.horizontalPadding,
        20 * layout.scale,
        layout.horizontalPadding,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        _MetricsGrid(layout: layout, metrics: metrics),
        SizedBox(height: 16 * layout.scale),
        _RevenueCard(layout: layout, points: revenue),
        SizedBox(height: 22 * layout.scale),
        _SectionTitle(
          layout: layout,
          title: 'Order Breakdown',
          subtitle: selectedFilter,
        ),
        SizedBox(height: 12 * layout.scale),
        _OrdersList(layout: layout, orders: orders),
        if (showViewAll) ...[
          SizedBox(height: 4 * layout.scale),
          _ViewAllButton(
            layout: layout,
            remainingCount: totalOrderCount - orders.length,
            onTap: onViewAll,
          ),
        ],
        SizedBox(height: 16 * layout.scale),
        _DownloadButton(layout: layout, onTap: onDownload),
      ],
    );
  }
}

class _DesktopReportsBody extends StatelessWidget {
  const _DesktopReportsBody({
    required this.layout,
    required this.metrics,
    required this.revenue,
    required this.orders,
    required this.totalOrderCount,
    required this.selectedFilter,
    required this.showViewAll,
    required this.onViewAll,
    required this.onDownload,
  });

  final _ReportsLayout layout;
  final List<_MetricData> metrics;
  final List<_RevenuePoint> revenue;
  final List<_ReportOrder> orders;
  final int totalOrderCount;
  final String selectedFilter;
  final bool showViewAll;
  final VoidCallback onViewAll;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        layout.horizontalPadding,
        layout.topPadding,
        layout.horizontalPadding,
        30,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 12,
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                _SectionTitle(
                  layout: layout,
                  title: 'Order Breakdown',
                  subtitle: selectedFilter,
                ),
                const SizedBox(height: 16),
                _OrdersList(layout: layout, orders: orders),
                if (showViewAll) ...[
                  const SizedBox(height: 4),
                  _ViewAllButton(
                    layout: layout,
                    remainingCount: totalOrderCount - orders.length,
                    onTap: onViewAll,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 8,
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                _MetricsGrid(layout: layout, metrics: metrics),
                const SizedBox(height: 16),
                _RevenueCard(layout: layout, points: revenue),
                const SizedBox(height: 16),
                _DownloadButton(layout: layout, onTap: onDownload),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.layout, required this.orders});

  final _ReportsLayout layout;
  final List<_ReportOrder> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const _EmptyReportState();
    }

    return Column(
      children: [
        ...orders.map(
          (order) => Padding(
            padding: EdgeInsets.only(bottom: 12 * layout.scale),
            child: _OrderCard(layout: layout, order: order),
          ),
        ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.layout, required this.metrics});

  final _ReportsLayout layout;
  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < metrics.length; i++) ...[
          Expanded(
            child: _MetricCard(layout: layout, data: metrics[i]),
          ),
          if (i != metrics.length - 1) SizedBox(width: 10 * layout.scale),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.layout, required this.data});

  final _ReportsLayout layout;
  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: layout.isDesktop ? 112 : 102 * layout.scale,
      padding: EdgeInsets.all(layout.isDesktop ? 16 : 14 * layout.scale),
      decoration: _cardDecoration(layout),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: layout.isDesktop ? 28 : 26 * layout.scale,
            height: layout.isDesktop ? 28 : 26 * layout.scale,
            decoration: BoxDecoration(
              color: data.tone.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              color: data.tone,
              size: layout.isDesktop ? 15 : 14 * layout.scale,
            ),
          ),
          const Spacer(),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _ReportsTheme.textDark,
              fontSize: layout.isDesktop ? 22 : 20 * layout.scale,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: -0.35,
            ),
          ),
          SizedBox(height: 6 * layout.scale),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _ReportsTheme.textMuted,
              fontSize: layout.isDesktop ? 12 : 11.5 * layout.scale,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.layout, required this.points});

  final _ReportsLayout layout;
  final List<_RevenuePoint> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(layout.cardPadding),
      decoration: _cardDecoration(layout),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue by Day',
            style: TextStyle(
              color: _ReportsTheme.textDark,
              fontSize: layout.isDesktop ? 18 : 16 * layout.scale,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 18 * layout.scale),
          SizedBox(
            height: layout.isDesktop ? 220 : 190 * layout.scale,
            width: double.infinity,
            child: CustomPaint(
              painter: _RevenueChartPainter(points: points),
              child: points.isEmpty
                  ? const Center(
                      child: Text(
                        'No revenue in this range',
                        style: TextStyle(
                          color: _ReportsTheme.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueChartPainter extends CustomPainter {
  _RevenueChartPainter({required this.points});

  final List<_RevenuePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;

    const left = 38.0;
    const right = 8.0;
    const top = 10.0;
    const bottom = 26.0;

    final chartW = size.width - left - right;
    final chartH = size.height - top - bottom;
    final maxValue = points.map((e) => e.value).reduce(math.max).toDouble();

    final gridPaint = Paint()
      ..color = _ReportsTheme.divider
      ..strokeWidth = 1;

    final barPaint = Paint()
      ..color = _ReportsTheme.primaryRed
      ..style = PaintingStyle.fill;

    final fadedBarPaint = Paint()
      ..color = _ReportsTheme.primaryRed.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;

    final labelPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i <= 3; i++) {
      final y = top + chartH - (chartH / 3 * i);
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );

      final valueLabel = i == 0 ? '0' : '${i}k';
      labelPainter.text = TextSpan(
        text: valueLabel,
        style: const TextStyle(
          color: _ReportsTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(0, y - 6));
    }

    final gap = chartW / points.length;
    final barWidth = math.min(24.0, gap * 0.52);

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final normalized = maxValue == 0 ? 0 : point.value / maxValue;
      final barH = chartH * normalized;
      final x = left + gap * i + (gap - barWidth) / 2;
      final y = top + chartH - barH;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barH),
        const Radius.circular(7),
      );

      canvas.drawRRect(rect, i == points.length - 1 ? barPaint : fadedBarPaint);

      labelPainter.text = TextSpan(
        text: '${(point.value / 1000).toStringAsFixed(1)}k',
        style: const TextStyle(
          color: _ReportsTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - labelPainter.width / 2, y - 16),
      );

      labelPainter.text = TextSpan(
        text: point.day,
        style: const TextStyle(
          color: _ReportsTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - labelPainter.width / 2, top + chartH + 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.layout,
    required this.title,
    required this.subtitle,
  });

  final _ReportsLayout layout;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: _ReportsTheme.textDark,
              fontSize: layout.isDesktop ? 20 : 17 * layout.scale,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -0.25,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10 * layout.scale,
            vertical: 6 * layout.scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _ReportsTheme.cardBorder),
          ),
          child: Text(
            subtitle,
            style: TextStyle(
              color: _ReportsTheme.textMuted,
              fontSize: 12 * layout.scale,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.layout, required this.order});

  final _ReportsLayout layout;
  final _ReportOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(layout.cardPadding),
      decoration: _cardDecoration(layout),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order.day}, ${order.date}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ReportsTheme.textDark,
                    fontSize: layout.isDesktop ? 16.5 : 15.5 * layout.scale,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.15,
                  ),
                ),
              ),
              SizedBox(width: 10 * layout.scale),
              _StatusBadge(layout: layout, status: order.status),
            ],
          ),
          SizedBox(height: 9 * layout.scale),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                color: _ReportsTheme.textMuted.withValues(alpha: 0.72),
                size: 15 * layout.scale,
              ),
              SizedBox(width: 6 * layout.scale),
              Text(
                order.time,
                style: TextStyle(
                  color: _ReportsTheme.textMuted,
                  fontSize: layout.isDesktop ? 12.5 : 12.5 * layout.scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 10 * layout.scale),
              Expanded(
                child: Text(
                  'Order #${order.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ReportsTheme.textMuted,
                    fontSize: layout.isDesktop ? 12.5 : 12.5 * layout.scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * layout.scale),
          Row(
            children: [
              Expanded(
                child: Text(
                  order.vendor,
                  style: TextStyle(
                    color: _ReportsTheme.textDark,
                    fontSize: layout.isDesktop ? 14.5 : 14 * layout.scale,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _IntentBadge(layout: layout, label: order.intent),
            ],
          ),
          SizedBox(height: 7 * layout.scale),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              order.employee,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _ReportsTheme.textMuted,
                fontSize: layout.isDesktop ? 12.5 : 12.5 * layout.scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 16 * layout.scale),
          ...order.items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 13 * layout.scale),
              child: _OrderItemRow(layout: layout, item: item),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _ReportsTheme.divider),
          SizedBox(height: 14 * layout.scale),
          Row(
            children: [
              Text(
                'Total',
                style: TextStyle(
                  color: _ReportsTheme.textDark,
                  fontSize: layout.isDesktop ? 15 : 14.5 * layout.scale,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                'Rs ${order.total}',
                style: TextStyle(
                  color: order.total == 0
                      ? _ReportsTheme.textDark
                      : _ReportsTheme.primaryRed,
                  fontSize: layout.isDesktop ? 18 : 17 * layout.scale,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
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
  const _StatusBadge({required this.layout, required this.status});

  final _ReportsLayout layout;
  final _OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, icon) = switch (status) {
      _OrderStatus.delivered => (
          'Delivered',
          _ReportsTheme.successBg,
          _ReportsTheme.success,
          Icons.check_circle_rounded,
        ),
      _OrderStatus.rejected => (
          'Rejected',
          _ReportsTheme.rejectedBg,
          _ReportsTheme.primaryRed,
          Icons.cancel_rounded,
        ),
      _OrderStatus.ordered => (
          'Ordered',
          _ReportsTheme.warningBg,
          _ReportsTheme.warning,
          Icons.pending_rounded,
        ),
    };

    return Container(
      height: 28 * layout.scale,
      padding: EdgeInsets.symmetric(horizontal: 10 * layout.scale),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 14 * layout.scale),
          SizedBox(width: 5 * layout.scale),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: layout.isDesktop ? 11.5 : 11.5 * layout.scale,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntentBadge extends StatelessWidget {
  const _IntentBadge({required this.layout, required this.label});

  final _ReportsLayout layout;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * layout.scale,
        vertical: 7 * layout.scale,
      ),
      decoration: BoxDecoration(
        color: _ReportsTheme.softRed,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _ReportsTheme.primaryRed,
          fontSize: 11.5 * layout.scale,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.layout, required this.item});

  final _ReportsLayout layout;
  final _ReportOrderItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: item.name,
              style: TextStyle(
                color: _ReportsTheme.textMuted,
                fontSize: layout.isDesktop ? 13.5 : 13 * layout.scale,
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(
                  text: '   x${item.quantity} - ${item.note}',
                  style: TextStyle(
                    color: _ReportsTheme.textMuted.withValues(alpha: 0.78),
                    fontSize: layout.isDesktop ? 12 : 12 * layout.scale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 12 * layout.scale),
        Text(
          item.amount == 0 ? 'Covered' : 'Rs ${item.amount}',
          style: TextStyle(
            color: item.amount == 0
                ? _ReportsTheme.success
                : _ReportsTheme.textDark,
            fontSize: layout.isDesktop ? 14 : 13.5 * layout.scale,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton({
    required this.layout,
    required this.remainingCount,
    required this.onTap,
  });

  final _ReportsLayout layout;
  final int remainingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: layout.isDesktop ? 50 : 48 * layout.scale,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _ReportsTheme.textDark,
          side: const BorderSide(color: _ReportsTheme.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(layout.cardRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
        child: Text(
          remainingCount > 0 ? 'View All ($remainingCount more)' : 'View All',
        ),
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({
    required this.layout,
    required this.onTap,
  });

  final _ReportsLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: layout.isDesktop ? 58 : 56 * layout.scale,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          Icons.file_download_rounded,
          color: Colors.white,
          size: layout.isDesktop ? 21 : 21 * layout.scale,
        ),
        label: Text(
          'Download Report',
          style: TextStyle(
            color: Colors.white,
            fontSize: layout.isDesktop ? 16 : 16 * layout.scale,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _ReportsTheme.primaryRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: 0.10),
          ),
        ),
      ),
    );
  }
}

class _EmptyReportState extends StatelessWidget {
  const _EmptyReportState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ReportsTheme.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: _ReportsTheme.primaryRed,
            size: 38,
          ),
          SizedBox(height: 12),
          Text(
            'No orders in this range',
            style: TextStyle(
              color: _ReportsTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try a different report range.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ReportsTheme.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration(_ReportsLayout layout) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(layout.cardRadius),
    border: Border.all(color: _ReportsTheme.cardBorder, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.035),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tone;
}

class _RevenuePoint {
  const _RevenuePoint({required this.day, required this.value});

  final String day;
  final int value;
}

enum _OrderStatus { ordered, delivered, rejected }

class _ReportOrder {
  const _ReportOrder({
    required this.id,
    required this.date,
    required this.day,
    required this.time,
    required this.vendor,
    required this.employee,
    required this.intent,
    required this.status,
    required this.total,
    required this.items,
  });

  final String id;
  final String date;
  final String day;
  final String time;
  final String vendor;
  final String employee;
  final String intent;
  final _OrderStatus status;
  final int total;
  final List<_ReportOrderItem> items;
}

class _ReportOrderItem {
  const _ReportOrderItem({
    required this.name,
    required this.quantity,
    required this.note,
    required this.amount,
  });

  final String name;
  final int quantity;
  final String note;
  final int amount;
}
