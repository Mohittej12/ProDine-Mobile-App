import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pro_dine/features/employee/data/employee_order_store.dart';
import 'package:pro_dine/utils/file_download.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EmployeeUsagePage extends StatefulWidget {
  const EmployeeUsagePage({super.key});

  @override
  State<EmployeeUsagePage> createState() => _EmployeeUsagePageState();
}

class _EmployeeUsagePageState extends State<EmployeeUsagePage> {
  int _selectedFilterIndex = 0;
  DateTimeRange? _selectedDateRange;

  final List<String> _filters = const [
    'Today',
    'This Week',
    'This Month',
    'Custom',
  ];

  String _getFilterLabel(int index) {
    if (index == 3 && _selectedDateRange != null) {
      final start = DateFormat('MMM d').format(_selectedDateRange!.start);
      final end = DateFormat('MMM d').format(_selectedDateRange!.end);
      return '$start - $end';
    }
    return _filters[index];
  }

  Future<void> _selectCustomRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _UsageTheme.primaryRed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _UsageTheme.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _UsageTheme.primaryRed,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedFilterIndex = 3;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    EmployeeOrderStore.instance.addListener(_onOrdersChanged);
  }

  @override
  void dispose() {
    EmployeeOrderStore.instance.removeListener(_onOrdersChanged);
    super.dispose();
  }

  void _onOrdersChanged() => setState(() {});

  List<EmployeeOrderEntry> get _allEntries =>
      EmployeeOrderStore.instance.orders;

  List<EmployeeOrderEntry> get _filteredEntries {
    final now = DateTime.now();

    DateTime start;
    DateTime end;

    if (_selectedFilterIndex == 0) {
      // Today
      start = DateTime(now.year, now.month, now.day);
      end = start
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1));
    } else if (_selectedFilterIndex == 1) {
      // This week (Monday - Sunday)
      final monday = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(monday.year, monday.month, monday.day);
      end = start
          .add(const Duration(days: 7))
          .subtract(const Duration(seconds: 1));
    } else if (_selectedFilterIndex == 2) {
      // This month
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 1)
          .subtract(const Duration(seconds: 1));
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
      ).add(const Duration(hours: 23, minutes: 59, seconds: 59));
    } else {
      // fallback: all
      return _allEntries;
    }

    return _allEntries.where((e) {
      final t = e.createdAt;
      return t.isAfter(start.subtract(const Duration(seconds: 1))) &&
          t.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  int get _totalOrders => _filteredEntries.length;

  int get _totalSpent => _filteredEntries.fold<int>(0, (s, e) => s + e.amount);

  List<_UsageOrder> get _usageOrders {
    return _filteredEntries.map((e) {
      final date = DateFormat('dd MMM yyyy').format(e.createdAt);
      final time = DateFormat('h:mm a').format(e.createdAt);

      final items = e.items
          .map((it) => _UsageItem(
                name: it.name,
                qty: it.quantity,
                unitPrice: it.price,
                lineTotal: it.price * it.quantity,
                isCovered: false,
              ))
          .toList();

      final subtotal = items.fold<int>(0, (s, it) => s + it.lineTotal);

      return _UsageOrder(
        status: _OrderStatus.delivered,
        date: date,
        time: time,
        orderId: e.orderId,
        restaurant: e.shopName,
        items: items,
        subtotal: subtotal,
        total: e.amount,
        sponsoredAmount: 0,
        isSponsored: false,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _UsageTheme.screenBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = _UsageLayout.fromWidth(constraints.maxWidth);

            return Column(
              children: [
                _UsageHeader(
                  layout: layout,
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    }
                  },
                ),
                _FilterBar(
                  layout: layout,
                  filters:
                      List.generate(_filters.length, (i) => _getFilterLabel(i)),
                  selectedIndex: _selectedFilterIndex,
                  onSelected: (index) {
                    if (index == 3) {
                      _selectCustomRange();
                    } else {
                      setState(() => _selectedFilterIndex = index);
                    }
                  },
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: layout.maxContentWidth,
                      ),
                      child: layout.isDesktop
                          ? _DesktopUsageBody(
                              layout: layout,
                              totalOrders: _totalOrders,
                              totalSpent: _totalSpent,
                              orders: _usageOrders,
                              selectedFilter:
                                  _getFilterLabel(_selectedFilterIndex),
                              onDownload: _downloadReport,
                            )
                          : _MobileUsageBody(
                              layout: layout,
                              totalOrders: _totalOrders,
                              totalSpent: _totalSpent,
                              orders: _usageOrders,
                              selectedFilter:
                                  _getFilterLabel(_selectedFilterIndex),
                              onDownload: _downloadReport,
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

  Future<void> _downloadReport() async {
    final entries = _filteredEntries;
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No orders in selected range'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final header = [
      'Order ID',
      'Employee ID',
      'Employee Name',
      'Cafeteria',
      'Items',
      'Amount',
      'Mode',
      'Pickup Time',
      'Status',
      'Created At',
    ];

    final rows = <List<String>>[];
    for (final e in entries) {
      final itemsLabel =
          e.items.map((it) => '${it.name} x${it.quantity}').join(' | ');
      final mode = e.isTicketing ? 'Ticketing' : 'Pre-Order';
      final pickup = e.isTicketing ? '' : (e.pickupSlot);
      rows.add([
        e.orderId,
        e.employeeId,
        e.userName,
        e.shopName,
        itemsLabel,
        e.amount.toString(),
        mode,
        pickup,
        e.status,
        DateFormat('yyyy-MM-dd HH:mm:ss').format(e.createdAt),
      ]);
    }

    final csvBuffer = StringBuffer();
    csvBuffer.writeln(header.join(','));
    for (final row in rows) {
      // simple CSV escaping for commas and quotes
      final escaped = row.map((cell) {
        final cellStr = cell.replaceAll('"', '""');
        if (cellStr.contains(',') ||
            cellStr.contains('"') ||
            cellStr.contains('\n')) {
          return '"$cellStr"';
        }
        return cellStr;
      }).join(',');
      csvBuffer.writeln(escaped);
    }

    try {
      final fileName =
          'employee_usage_${DateTime.now().millisecondsSinceEpoch}.csv';
      final result = await downloadCsv(fileName, csvBuffer.toString());

      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download started'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved to $result'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report generated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate report: $err'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _UsageTheme {
  const _UsageTheme._();

  static const Color primaryRed = Color(0xFFFF1F1F);
  static const Color textDark = Color(0xFF141827);
  static const Color textMuted = Color(0xFF667085);
  static const Color screenBg = Color(0xFFF6F7F9);
  static const Color cardBorder = Color(0xFFE6E8EC);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color chipBg = Color(0xFFF0F1F4);
  static const Color iconSoftBg = Color(0xFFFFEFEF);
  static const Color success = Color(0xFF108A43);
  static const Color successBg = Color(0xFFEAF9F0);
  static const Color sponsoredBg = Color(0xFFFFEEF1);
  static const Color greenMoney = Color(0xFF10A84F);
}

class _UsageLayout {
  const _UsageLayout({
    required this.isDesktop,
    required this.isTablet,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.topPadding,
    required this.scale,
    required this.cardRadius,
    required this.cardPadding,
    required this.sectionGap,
  });

  final bool isDesktop;
  final bool isTablet;
  final double maxContentWidth;
  final double horizontalPadding;
  final double topPadding;
  final double scale;
  final double cardRadius;
  final double cardPadding;
  final double sectionGap;

  static _UsageLayout fromWidth(double width) {
    if (width >= 1100) {
      return const _UsageLayout(
        isDesktop: true,
        isTablet: false,
        maxContentWidth: 1120,
        horizontalPadding: 42,
        topPadding: 30,
        scale: 1,
        cardRadius: 22,
        cardPadding: 24,
        sectionGap: 24,
      );
    }

    if (width >= 760) {
      return const _UsageLayout(
        isDesktop: false,
        isTablet: true,
        maxContentWidth: 720,
        horizontalPadding: 32,
        topPadding: 26,
        scale: 1,
        cardRadius: 22,
        cardPadding: 22,
        sectionGap: 20,
      );
    }

    final scale = (width / 390).clamp(0.88, 1.0).toDouble();

    return _UsageLayout(
      isDesktop: false,
      isTablet: false,
      maxContentWidth: 430,
      horizontalPadding: width < 360 ? 14 : 16,
      topPadding: 20,
      scale: scale,
      cardRadius: 12,
      cardPadding: width < 360 ? 16 : 20,
      sectionGap: 14,
    );
  }
}

class _UsageHeader extends StatelessWidget {
  const _UsageHeader({
    required this.layout,
    required this.onBack,
  });

  final _UsageLayout layout;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final height = layout.isDesktop ? 92.0 : 78.0 * layout.scale;

    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _UsageTheme.cardBorder,
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: layout.horizontalPadding),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: onBack,
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: layout.isDesktop ? 46 : 40 * layout.scale,
                        height: layout.isDesktop ? 46 : 40 * layout.scale,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: _UsageTheme.textDark,
                          size: layout.isDesktop ? 28 : 25 * layout.scale,
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'My Usage',
                      style: TextStyle(
                        color: _UsageTheme.textDark,
                        fontSize: layout.isDesktop ? 24 : 19 * layout.scale,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.35,
                      ),
                    ),
                    SizedBox(height: 7 * layout.scale),
                    Text(
                      'Track your orders and spending',
                      style: TextStyle(
                        color: _UsageTheme.textMuted,
                        fontSize: layout.isDesktop ? 13 : 12 * layout.scale,
                        height: 1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.layout,
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  final _UsageLayout layout;
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
          bottom: BorderSide(
            color: _UsageTheme.cardBorder,
            width: 1,
          ),
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
              final active = selectedIndex == index;

              return _FilterPill(
                label: filters[index],
                active: active,
                layout: layout,
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
    required this.label,
    required this.active,
    required this.layout,
    required this.onTap,
  });

  final String label;
  final bool active;
  final _UsageLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final minWidth = layout.isDesktop ? 118.0 : 96.0 * layout.scale;

    return Material(
      color: active ? _UsageTheme.primaryRed : _UsageTheme.chipBg,
      borderRadius: BorderRadius.circular(999),
      elevation: active ? 3 : 0,
      shadowColor: _UsageTheme.primaryRed.withOpacity(0.22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: layout.isDesktop ? 42 : 42 * layout.scale,
          constraints: BoxConstraints(minWidth: minWidth),
          padding: EdgeInsets.symmetric(horizontal: 18 * layout.scale),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? Colors.white : _UsageTheme.textDark,
              fontSize: layout.isDesktop ? 14 : 14 * layout.scale,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileUsageBody extends StatelessWidget {
  const _MobileUsageBody({
    required this.layout,
    required this.totalOrders,
    required this.totalSpent,
    required this.orders,
    required this.selectedFilter,
    required this.onDownload,
  });

  final _UsageLayout layout;
  final int totalOrders;
  final int totalSpent;
  final List<_UsageOrder> orders;
  final String selectedFilter;
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
        18 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        _SummaryGrid(
          layout: layout,
          totalOrders: totalOrders,
          totalSpent: totalSpent,
        ),
        SizedBox(height: 24 * layout.scale),
        _SectionTitle(
          layout: layout,
          title: "Today's Breakdown",
          subtitle: selectedFilter,
        ),
        SizedBox(height: 14 * layout.scale),
        ...orders.map(
          (order) => Padding(
            padding: EdgeInsets.only(bottom: 12 * layout.scale),
            child: _UsageOrderCard(layout: layout, order: order),
          ),
        ),
        SizedBox(height: 8 * layout.scale),
        _DownloadButton(layout: layout, onTap: onDownload),
      ],
    );
  }
}

class _DesktopUsageBody extends StatelessWidget {
  const _DesktopUsageBody({
    required this.layout,
    required this.totalOrders,
    required this.totalSpent,
    required this.orders,
    required this.selectedFilter,
    required this.onDownload,
  });

  final _UsageLayout layout;
  final int totalOrders;
  final int totalSpent;
  final List<_UsageOrder> orders;
  final String selectedFilter;
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
                  title: "Today's Breakdown",
                  subtitle: selectedFilter,
                ),
                const SizedBox(height: 16),
                ...orders.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _UsageOrderCard(layout: layout, order: order),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 8,
            child: Column(
              children: [
                _SummaryGrid(
                  layout: layout,
                  totalOrders: totalOrders,
                  totalSpent: totalSpent,
                ),
                const SizedBox(height: 14),
                _DownloadButton(layout: layout, onTap: onDownload),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.layout,
    required this.totalOrders,
    required this.totalSpent,
  });

  final _UsageLayout layout;
  final int totalOrders;
  final int totalSpent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            layout: layout,
            icon: Icons.receipt_long_rounded,
            value: totalOrders.toString(),
            label: 'Total Orders',
          ),
        ),
        SizedBox(width: 12 * layout.scale),
        Expanded(
          child: _SummaryCard(
            layout: layout,
            icon: Icons.currency_rupee_rounded,
            value: totalSpent.toString(),
            label: 'Total Spent',
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.layout,
    required this.icon,
    required this.value,
    required this.label,
  });

  final _UsageLayout layout;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final height = layout.isDesktop ? 132.0 : 126.0 * layout.scale;

    return Container(
      height: height,
      padding: EdgeInsets.all(layout.isDesktop ? 18 : 16 * layout.scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        border: Border.all(
          color: _UsageTheme.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: layout.isDesktop ? 42 : 40 * layout.scale,
            height: layout.isDesktop ? 42 : 40 * layout.scale,
            decoration: const BoxDecoration(
              color: _UsageTheme.iconSoftBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: _UsageTheme.primaryRed,
              size: layout.isDesktop ? 21 : 20 * layout.scale,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _UsageTheme.textDark,
              fontSize: layout.isDesktop ? 28 : 28 * layout.scale,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          SizedBox(height: 6 * layout.scale),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _UsageTheme.textMuted,
              fontSize: layout.isDesktop ? 13 : 13 * layout.scale,
              height: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.layout,
    required this.title,
    required this.subtitle,
  });

  final _UsageLayout layout;
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
              color: _UsageTheme.textDark,
              fontSize: layout.isDesktop ? 20 : 18 * layout.scale,
              height: 1.1,
              fontWeight: FontWeight.w900,
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
            border: Border.all(color: _UsageTheme.cardBorder),
          ),
          child: Text(
            subtitle,
            style: TextStyle(
              color: _UsageTheme.textMuted,
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

class _UsageOrderCard extends StatelessWidget {
  const _UsageOrderCard({
    required this.layout,
    required this.order,
  });

  final _UsageLayout layout;
  final _UsageOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(layout.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        border: Border.all(
          color: _UsageTheme.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _OrderBadgesRow(layout: layout, order: order),
          SizedBox(height: 16 * layout.scale),
          _OrderHeaderDetails(layout: layout, order: order),
          SizedBox(height: 14 * layout.scale),
          const _ThinDivider(),
          SizedBox(height: 14 * layout.scale),
          ...order.items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 12 * layout.scale),
              child: _UsageItemRow(layout: layout, item: item),
            ),
          ),
          const _ThinDivider(),
          SizedBox(height: 14 * layout.scale),
          _AmountLine(
            layout: layout,
            label: 'Subtotal',
            value: '₹${order.subtotal}',
            labelColor: _UsageTheme.textMuted,
            valueColor: order.isSponsored
                ? _UsageTheme.textMuted.withOpacity(0.65)
                : _UsageTheme.textDark,
            valueDecoration:
                order.isSponsored ? TextDecoration.lineThrough : null,
            isStrong: false,
          ),
          if (order.isSponsored) ...[
            SizedBox(height: 10 * layout.scale),
            _AmountLine(
              layout: layout,
              label: 'Company Sponsored',
              value: '-₹${order.sponsoredAmount}',
              labelColor: _UsageTheme.greenMoney,
              valueColor: _UsageTheme.greenMoney,
              isStrong: false,
            ),
          ],
          SizedBox(height: 10 * layout.scale),
          _AmountLine(
            layout: layout,
            label: 'Total',
            value: '₹${order.total}',
            labelColor: _UsageTheme.textDark,
            valueColor: order.total == 0
                ? _UsageTheme.greenMoney
                : _UsageTheme.primaryRed,
            isStrong: true,
          ),
        ],
      ),
    );
  }
}

class _OrderBadgesRow extends StatelessWidget {
  const _OrderBadgesRow({
    required this.layout,
    required this.order,
  });

  final _UsageLayout layout;
  final _UsageOrder order;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatusBadge(layout: layout, status: order.status),
        const Spacer(),
        if (order.isSponsored) _SponsoredBadge(layout: layout),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.layout,
    required this.status,
  });

  final _UsageLayout layout;
  final _OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final isDelivered = status == _OrderStatus.delivered;

    return Container(
      height: 30 * layout.scale,
      padding: EdgeInsets.symmetric(horizontal: 11 * layout.scale),
      decoration: BoxDecoration(
        color: isDelivered ? _UsageTheme.successBg : _UsageTheme.sponsoredBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDelivered ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isDelivered ? _UsageTheme.success : _UsageTheme.primaryRed,
            size: 15 * layout.scale,
          ),
          SizedBox(width: 6 * layout.scale),
          Text(
            isDelivered ? 'Delivered' : 'Rejected',
            style: TextStyle(
              color: isDelivered ? _UsageTheme.success : _UsageTheme.primaryRed,
              fontSize: 12.5 * layout.scale,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SponsoredBadge extends StatelessWidget {
  const _SponsoredBadge({required this.layout});

  final _UsageLayout layout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30 * layout.scale,
      padding: EdgeInsets.symmetric(horizontal: 11 * layout.scale),
      decoration: BoxDecoration(
        color: _UsageTheme.sponsoredBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.business_rounded,
            color: _UsageTheme.primaryRed,
            size: 14 * layout.scale,
          ),
          SizedBox(width: 6 * layout.scale),
          Text(
            'Company Sponsored',
            style: TextStyle(
              color: _UsageTheme.primaryRed,
              fontSize: 12 * layout.scale,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderHeaderDetails extends StatelessWidget {
  const _OrderHeaderDetails({
    required this.layout,
    required this.order,
  });

  final _UsageLayout layout;
  final _UsageOrder order;

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
                order.date,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _UsageTheme.textDark,
                  fontSize: layout.isDesktop ? 17 : 16 * layout.scale,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 7 * layout.scale),
              Text(
                order.time,
                style: TextStyle(
                  color: _UsageTheme.textMuted,
                  fontSize: layout.isDesktop ? 13 : 13 * layout.scale,
                  height: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 11 * layout.scale),
              Text(
                'Order ID: ${order.orderId}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _UsageTheme.textMuted,
                  fontSize: layout.isDesktop ? 12.5 : 12.5 * layout.scale,
                  height: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 10 * layout.scale),
              Text(
                order.restaurant,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _UsageTheme.textDark,
                  fontSize: layout.isDesktop ? 15.5 : 15 * layout.scale,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.15,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 14 * layout.scale),
        Text(
          '₹${order.total}',
          style: TextStyle(
            color: order.total == 0
                ? _UsageTheme.greenMoney
                : _UsageTheme.textDark,
            fontSize: layout.isDesktop ? 18 : 18 * layout.scale,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.25,
          ),
        ),
      ],
    );
  }
}

class _UsageItemRow extends StatelessWidget {
  const _UsageItemRow({
    required this.layout,
    required this.item,
  });

  final _UsageLayout layout;
  final _UsageItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: '${item.name} x${item.qty}',
              style: TextStyle(
                color: _UsageTheme.textMuted,
                fontSize: layout.isDesktop ? 14 : 14 * layout.scale,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
              children: [
                if (!item.isCovered)
                  TextSpan(
                    text: '  ₹${item.unitPrice} each',
                    style: TextStyle(
                      color: _UsageTheme.textMuted.withOpacity(0.82),
                      fontSize: layout.isDesktop ? 12.5 : 12.5 * layout.scale,
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
          item.isCovered ? 'Covered' : '₹${item.lineTotal}',
          style: TextStyle(
            color:
                item.isCovered ? _UsageTheme.greenMoney : _UsageTheme.textDark,
            fontSize: layout.isDesktop ? 14 : 14 * layout.scale,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({
    required this.layout,
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
    required this.isStrong,
    this.valueDecoration,
  });

  final _UsageLayout layout;
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final bool isStrong;
  final TextDecoration? valueDecoration;

  @override
  Widget build(BuildContext context) {
    final fontSize = isStrong ? 15.5 : 14.0;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: layout.isDesktop ? fontSize : fontSize * layout.scale,
              height: 1.1,
              fontWeight: isStrong ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: layout.isDesktop
                ? (isStrong ? 17 : 14)
                : (isStrong ? 17 : 14) * layout.scale,
            height: 1,
            fontWeight: FontWeight.w900,
            decoration: valueDecoration,
            decorationThickness: 2,
          ),
        ),
      ],
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({
    required this.layout,
    required this.onTap,
  });

  final _UsageLayout layout;
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
          backgroundColor: _UsageTheme.primaryRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            Colors.white.withOpacity(0.10),
          ),
        ),
      ),
    );
  }
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: _UsageTheme.divider,
    );
  }
}

enum _OrderStatus {
  delivered,
}

class _UsageOrder {
  const _UsageOrder({
    required this.status,
    required this.date,
    required this.time,
    required this.orderId,
    required this.restaurant,
    required this.items,
    required this.subtotal,
    required this.total,
    this.sponsoredAmount = 0,
    this.isSponsored = false,
  });

  final _OrderStatus status;
  final String date;
  final String time;
  final String orderId;
  final String restaurant;
  final List<_UsageItem> items;
  final int subtotal;
  final int total;
  final int sponsoredAmount;
  final bool isSponsored;
}

class _UsageItem {
  const _UsageItem({
    required this.name,
    required this.qty,
    this.unitPrice = 0,
    this.lineTotal = 0,
    this.isCovered = false,
  });

  final String name;
  final int qty;
  final int unitPrice;
  final int lineTotal;
  final bool isCovered;
}
