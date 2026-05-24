import 'package:flutter/material.dart';
import 'package:pro_dine/features/employee/data/employee_order_store.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_page_header.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_shell.dart';

class VendorFoodPortionsPage extends StatefulWidget {
  const VendorFoodPortionsPage({super.key});

  @override
  State<VendorFoodPortionsPage> createState() => _VendorFoodPortionsPageState();
}

class _VendorFoodPortionsPageState extends State<VendorFoodPortionsPage> {
  static const Color _primaryRed = Color(0xFFFF1F1F);
  static const Color _screenBg = Color(0xFFFFFCF8);
  static const Color _surface = Colors.white;
  static const Color _darkText = Color(0xFF141827);
  static const Color _mutedText = Color(0xFF667085);
  static const Color _softBorder = Color(0xFFE9EDF3);
  static const Color _green = Color(0xFF16A34A);
  static const Color _blue = Color(0xFF2563EB);

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

  List<_PortionRow> get _portionRows {
    final rowsByKey = <String, _PortionAccumulator>{};

    for (final order in _orderStore.orders) {
      if (order.status.toLowerCase() != 'ordered') continue;

      for (final item in order.items) {
        final meal = _mealLabel(order, item);
        final intent = _intentLabel(order);
        final key = '${order.shopName}|$intent|$meal|${item.name}';

        rowsByKey.putIfAbsent(
          key,
          () => _PortionAccumulator(
            vendor: order.shopName,
            intent: intent,
            meal: meal,
            itemName: item.name,
          ),
        )
          ..count += item.quantity
          ..orderIds.add(order.orderId);
      }
    }

    final rows = rowsByKey.values
        .map(
          (row) => _PortionRow(
            vendor: row.vendor,
            intent: row.intent,
            meal: row.meal,
            itemName: row.itemName,
            count: row.count,
            orderCount: row.orderIds.length,
          ),
        )
        .toList();

    rows.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return a.itemName.compareTo(b.itemName);
    });

    return rows;
  }

  int get _totalPendingPortions =>
      _portionRows.fold<int>(0, (sum, row) => sum + row.count);

  int get _pendingOrders => _orderStore.orders
      .where((order) => order.status.toLowerCase() == 'ordered')
      .length;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _screenBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _PortionsLayout.fromWidth(constraints.maxWidth);
          final rows = _portionRows;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VendorPageHeader(
                title: 'Food Portions',
                maxContentWidth: layout.maxContentWidth,
                horizontalPadding: layout.horizontalPadding,
                isDesktop: layout.isDesktop,
                scale: layout.scale,
                onMenuTap: () => VendorShell.openDrawer(context),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: layout.maxContentWidth,
                    ),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            layout.horizontalPadding,
                            16,
                            layout.horizontalPadding,
                            32 + MediaQuery.of(context).padding.bottom,
                          ),
                          sliver: SliverList.list(
                            children: [
                              _LiveSummary(
                                layout: layout,
                                pendingOrders: _pendingOrders,
                                pendingPortions: _totalPendingPortions,
                                itemTypes: rows.length,
                              ),
                              SizedBox(height: 18 * layout.scale),
                              if (rows.isEmpty)
                                const _EmptyPortionsState()
                              else
                                ...List.generate(rows.length, (index) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: 12 * layout.scale,
                                    ),
                                    child: _PortionCard(
                                      row: rows[index],
                                      rank: index + 1,
                                      maxCount: rows.first.count,
                                      layout: layout,
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],
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

  String _intentLabel(EmployeeOrderEntry order) {
    final intent = order.orderIntent.trim();
    if (intent.isNotEmpty) return intent;
    return order.isTicketing ? 'Ticketing' : 'Pre-Order';
  }

  String _mealLabel(EmployeeOrderEntry order, EmployeeOrderItem item) {
    if (item.meal.trim().isNotEmpty) return item.meal.trim();
    if (order.pickupSlot.trim().isNotEmpty) return order.pickupSlot.trim();
    return order.isTicketing ? item.name : 'General';
  }
}

class _PortionsLayout {
  const _PortionsLayout({
    required this.isDesktop,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.scale,
  });

  final bool isDesktop;
  final double maxContentWidth;
  final double horizontalPadding;
  final double scale;

  static _PortionsLayout fromWidth(double width) {
    if (width >= 1100) {
      return const _PortionsLayout(
        isDesktop: true,
        maxContentWidth: 1180,
        horizontalPadding: 42,
        scale: 1,
      );
    }

    if (width >= 760) {
      return const _PortionsLayout(
        isDesktop: false,
        maxContentWidth: 760,
        horizontalPadding: 32,
        scale: 1,
      );
    }

    return _PortionsLayout(
      isDesktop: false,
      maxContentWidth: 430,
      horizontalPadding: width < 370 ? 16 : 20,
      scale: width < 370 ? 0.92 : 1,
    );
  }
}

class _LiveSummary extends StatelessWidget {
  const _LiveSummary({
    required this.layout,
    required this.pendingOrders,
    required this.pendingPortions,
    required this.itemTypes,
  });

  final _PortionsLayout layout;
  final int pendingOrders;
  final int pendingPortions;
  final int itemTypes;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        color: _VendorFoodPortionsPageState._surface,
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(color: _VendorFoodPortionsPageState._softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42 * scale,
                height: 42 * scale,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEFEF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.room_service_rounded,
                  color: _VendorFoodPortionsPageState._primaryRed,
                  size: 22 * scale,
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live order intent',
                      style: TextStyle(
                        color: _VendorFoodPortionsPageState._darkText,
                        fontSize: layout.isDesktop ? 22 : 19 * scale,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      'Highest requested menu items appear first.',
                      style: TextStyle(
                        color: _VendorFoodPortionsPageState._mutedText,
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * scale),
          Wrap(
            spacing: 10 * scale,
            runSpacing: 10 * scale,
            children: [
              _SummaryPill(label: 'Pending orders', value: pendingOrders),
              _SummaryPill(label: 'Portions needed', value: pendingPortions),
              _SummaryPill(label: 'Menu items', value: itemTypes),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: _VendorFoodPortionsPageState._darkText,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PortionCard extends StatelessWidget {
  const _PortionCard({
    required this.row,
    required this.rank,
    required this.maxCount,
    required this.layout,
  });

  final _PortionRow row;
  final int rank;
  final int maxCount;
  final _PortionsLayout layout;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;
    final ratio = maxCount <= 0 ? 0.0 : row.count / maxCount;

    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: _VendorFoodPortionsPageState._surface,
        borderRadius: BorderRadius.circular(22 * scale),
        border: Border.all(color: _VendorFoodPortionsPageState._softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34 * scale,
                height: 34 * scale,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFEF),
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: _VendorFoodPortionsPageState._primaryRed,
                    fontSize: 12.5 * scale,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _VendorFoodPortionsPageState._darkText,
                        fontSize: layout.isDesktop ? 18 : 16 * scale,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Wrap(
                      spacing: 7 * scale,
                      runSpacing: 7 * scale,
                      children: [
                        _MetaChip(
                          icon: Icons.storefront_rounded,
                          label: row.vendor,
                          color: _VendorFoodPortionsPageState._blue,
                        ),
                        _MetaChip(
                          icon: Icons.confirmation_number_rounded,
                          label: row.intent,
                          color: _VendorFoodPortionsPageState._primaryRed,
                        ),
                        _MetaChip(
                          icon: Icons.schedule_rounded,
                          label: row.meal,
                          color: _VendorFoodPortionsPageState._green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10 * scale),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${row.count}',
                    style: TextStyle(
                      color: _VendorFoodPortionsPageState._darkText,
                      fontSize: layout.isDesktop ? 30 : 26 * scale,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5 * scale),
                  Text(
                    row.count == 1 ? 'portion' : 'portions',
                    style: TextStyle(
                      color: _VendorFoodPortionsPageState._mutedText,
                      fontSize: 11.5 * scale,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 14 * scale),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7 * scale,
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF0F2F5),
              valueColor: const AlwaysStoppedAnimation<Color>(
                _VendorFoodPortionsPageState._primaryRed,
              ),
            ),
          ),
          SizedBox(height: 10 * scale),
          Text(
            '${row.orderCount} active ${row.orderCount == 1 ? 'order' : 'orders'}',
            style: TextStyle(
              color: _VendorFoodPortionsPageState._mutedText,
              fontSize: 12 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPortionsState extends StatelessWidget {
  const _EmptyPortionsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
      decoration: BoxDecoration(
        color: _VendorFoodPortionsPageState._surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _VendorFoodPortionsPageState._softBorder),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: _VendorFoodPortionsPageState._primaryRed,
            size: 38,
          ),
          SizedBox(height: 12),
          Text(
            'No portions pending',
            style: TextStyle(
              color: _VendorFoodPortionsPageState._darkText,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'New employee orders will appear here immediately.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _VendorFoodPortionsPageState._mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortionAccumulator {
  _PortionAccumulator({
    required this.vendor,
    required this.intent,
    required this.meal,
    required this.itemName,
  });

  final String vendor;
  final String intent;
  final String meal;
  final String itemName;
  int count = 0;
  final Set<String> orderIds = {};
}

class _PortionRow {
  const _PortionRow({
    required this.vendor,
    required this.intent,
    required this.meal,
    required this.itemName,
    required this.count,
    required this.orderCount,
  });

  final String vendor;
  final String intent;
  final String meal;
  final String itemName;
  final int count;
  final int orderCount;
}
