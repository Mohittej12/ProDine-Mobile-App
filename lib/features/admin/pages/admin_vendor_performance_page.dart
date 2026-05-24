import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pro_dine/features/admin/widgets/admin_shell.dart';
import 'package:pro_dine/features/employee/data/employee_order_store.dart';
import 'package:pro_dine/utils/file_download.dart';

class AdminVendorPerformancePage extends StatefulWidget {
  const AdminVendorPerformancePage({super.key});

  @override
  State<AdminVendorPerformancePage> createState() =>
      _AdminVendorPerformancePageState();
}

class _AdminVendorPerformancePageState
    extends State<AdminVendorPerformancePage> {
  final EmployeeOrderStore _orderStore = EmployeeOrderStore.instance;
  final TextEditingController _searchController = TextEditingController();

  int _selectedRange = 0;
  String _selectedFilter = 'All';
  DateTimeRange? _customRange;

  final List<String> _ranges = const [
    'Today',
    'This Week',
    'This Month',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _orderStore.addListener(_refresh);
  }

  @override
  void dispose() {
    _orderStore.removeListener(_refresh);
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String _rangeLabel(int index) {
    if (index == 3 && _customRange != null) {
      return '${DateFormat('MMM d').format(_customRange!.start)} - ${DateFormat('MMM d').format(_customRange!.end)}';
    }
    return _ranges[index];
  }

  List<EmployeeOrderEntry> get _rangeOrders {
    final now = DateTime.now();
    late DateTime start;
    late DateTime end;

    if (_selectedRange == 0) {
      start = DateTime(now.year, now.month, now.day);
      end = start.add(const Duration(days: 1));
    } else if (_selectedRange == 1) {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(monday.year, monday.month, monday.day);
      end = start.add(const Duration(days: 7));
    } else if (_selectedRange == 2) {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 1);
    } else if (_customRange != null) {
      start = DateTime(
        _customRange!.start.year,
        _customRange!.start.month,
        _customRange!.start.day,
      );
      end = DateTime(
        _customRange!.end.year,
        _customRange!.end.month,
        _customRange!.end.day,
      ).add(const Duration(days: 1));
    } else {
      return _orderStore.orders;
    }

    return _orderStore.orders
        .where((order) =>
            !order.createdAt.isBefore(start) && order.createdAt.isBefore(end))
        .toList();
  }

  List<EmployeeOrderEntry> get _filteredOrders {
    final query = _searchController.text.trim().toLowerCase();
    return _rangeOrders.where((order) {
      final mode = order.isTicketing ? 'Ticketing' : 'Pre-Order';
      final matchesSearch = query.isEmpty ||
          order.orderId.toLowerCase().contains(query) ||
          order.employeeId.toLowerCase().contains(query) ||
          order.userName.toLowerCase().contains(query) ||
          order.shopName.toLowerCase().contains(query);
      final matchesFilter = switch (_selectedFilter) {
        'All' => true,
        'Delivered' => order.status.toLowerCase() == 'delivered',
        'Rejected' => order.status.toLowerCase() == 'rejected',
        'Ordered' => order.status.toLowerCase() == 'ordered',
        'Ticketing' => order.isTicketing,
        'Pre-Order' => mode == 'Pre-Order',
        _ => true,
      };
      return matchesSearch && matchesFilter;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int get _deliveredCount => _rangeOrders
      .where((order) => order.status.toLowerCase() == 'delivered')
      .length;

  int get _rejectedCount => _rangeOrders
      .where((order) => order.status.toLowerCase() == 'rejected')
      .length;

  int get _orderedCount => _rangeOrders
      .where((order) => order.status.toLowerCase() == 'ordered')
      .length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(onMenuTap: () => AdminShell.openDrawer(context)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 32),
            children: [
              _ControlPanel(
                searchController: _searchController,
                rangeLabel: _rangeLabel(_selectedRange),
                onSearchChanged: (_) => setState(() {}),
                onRangeTap: _pickRange,
                onExport: _exportReport,
              ),
              const SizedBox(height: 18),
              _SummaryStrip(
                total: _rangeOrders.length,
                delivered: _deliveredCount,
                rejected: _rejectedCount,
                ordered: _orderedCount,
              ),
              const SizedBox(height: 18),
              _FilterTabs(
                selectedFilter: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value),
              ),
              const SizedBox(height: 18),
              _OrdersTable(orders: _filteredOrders),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickRange() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_ranges.length, (index) {
              return ListTile(
                title: Text(_ranges[index]),
                onTap: () => Navigator.pop(context, index),
              );
            }),
          ),
        );
      },
    );
    if (selected == null) return;
    if (selected == 3) {
      if (!mounted) return;
      final picked = await showDateRangePicker(
        context: context,
        initialDateRange: _customRange,
        firstDate: DateTime(2023),
        lastDate: DateTime.now(),
      );
      if (picked == null) return;
      setState(() {
        _customRange = picked;
        _selectedRange = selected;
      });
      return;
    }
    setState(() => _selectedRange = selected);
  }

  Future<void> _exportReport() async {
    final orders = _filteredOrders;
    if (orders.isEmpty) {
      _showSnack('No orders in selected range');
      return;
    }

    final csv = StringBuffer()
      ..writeln(
        [
          'Order ID',
          'Employee ID',
          'Employee Name',
          'Cafeteria',
          'Mode',
          'Items',
          'Amount',
          'Status',
          'Created At',
        ].join(','),
      );

    for (final order in orders) {
      final mode = order.isTicketing ? 'Ticketing' : 'Pre-Order';
      final items = order.items
          .map((item) => '${item.name} x${item.quantity}')
          .join(' | ');
      final row = [
        order.orderId,
        order.employeeId,
        order.userName,
        order.shopName,
        mode,
        items,
        order.amount.toString(),
        order.status,
        DateFormat('yyyy-MM-dd HH:mm:ss').format(order.createdAt),
      ];
      csv.writeln(row.map(_csvCell).join(','));
    }

    try {
      final result = await downloadCsv(
        'admin_vendor_performance_${DateTime.now().millisecondsSinceEpoch}.csv',
        csv.toString(),
      );
      if (!mounted) return;
      if (kIsWeb) {
        _showSnack('Download started');
      } else {
        _showSnack(
            result == null ? 'Report generated' : 'Report saved to $result');
      }
    } catch (err) {
      if (mounted) _showSnack('Failed to export report: $err');
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
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFF1F0EE),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onMenuTap,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.menu_rounded, color: Color(0xFF151827)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vendor Performance',
                  style: TextStyle(
                    color: Color(0xFF151827),
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Live cafeteria intent and exportable order report',
                  style: TextStyle(
                    color: Color(0xFF77726E),
                    fontSize: 13,
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

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.searchController,
    required this.rangeLabel,
    required this.onSearchChanged,
    required this.onRangeTap,
    required this.onExport,
  });

  final TextEditingController searchController;
  final String rangeLabel;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRangeTap;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 420,
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search order ID, employee, or cafeteria',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFEAE8E4)),
              ),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onRangeTap,
          icon: const Icon(Icons.calendar_today_rounded),
          label: Text(rangeLabel),
        ),
        ElevatedButton.icon(
          onPressed: onExport,
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Export'),
        ),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.total,
    required this.delivered,
    required this.rejected,
    required this.ordered,
  });

  final int total;
  final int delivered;
  final int rejected;
  final int ordered;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SummaryCard(label: 'Total Orders', value: '$total'),
        _SummaryCard(label: 'Delivered', value: '$delivered'),
        _SummaryCard(label: 'Rejected', value: '$rejected'),
        _SummaryCard(label: 'Live Intent', value: '$ordered'),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF77726E))),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF151827),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.selectedFilter,
    required this.onChanged,
  });

  final String selectedFilter;
  final ValueChanged<String> onChanged;

  static const filters = [
    'All',
    'Ordered',
    'Delivered',
    'Rejected',
    'Ticketing',
    'Pre-Order',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((filter) {
        final active = filter == selectedFilter;
        return ChoiceChip(
          label: Text(filter),
          selected: active,
          onSelected: (_) => onChanged(filter),
          selectedColor: const Color(0xFFFF1F1F),
          labelStyle: TextStyle(
            color: active ? Colors.white : const Color(0xFF77726E),
            fontWeight: FontWeight.w800,
          ),
        );
      }).toList(),
    );
  }
}

class _OrdersTable extends StatelessWidget {
  const _OrdersTable({required this.orders});

  final List<EmployeeOrderEntry> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'No orders found',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      );
    }

    return Column(
      children: orders.map((order) => _OrderCard(order: order)).toList(),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final EmployeeOrderEntry order;

  @override
  Widget build(BuildContext context) {
    final mode = order.isTicketing ? 'Ticketing' : 'Pre-Order';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(order.orderId,
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
          Expanded(
            flex: 3,
            child: Text('${order.userName}\n${order.employeeId}'),
          ),
          Expanded(flex: 2, child: Text(order.shopName)),
          Expanded(flex: 2, child: Text(mode)),
          Expanded(flex: 2, child: Text('Rs ${order.amount}')),
          Expanded(
            flex: 2,
            child: Text(DateFormat('dd MMM, h:mm a').format(order.createdAt)),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Chip(label: Text(order.status)),
            ),
          ),
        ],
      ),
    );
  }
}
