import 'package:flutter/material.dart';
import 'package:pro_dine/features/employee/data/employee_order_store.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_page_header.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_shell.dart';

class VendorOrdersPage extends StatefulWidget {
  const VendorOrdersPage({super.key});

  @override
  State<VendorOrdersPage> createState() => _VendorOrdersPageState();
}

class _VendorOrdersPageState extends State<VendorOrdersPage>
    with TickerProviderStateMixin {
  final EmployeeOrderStore _orderStore = EmployeeOrderStore.instance;
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  int _selectedTab = 0;
  String _searchQuery = '';

  List<EmployeeOrderEntry> get _activeOrders {
    final orders = _orderStore.orders
        .where((order) => order.status.toLowerCase() == 'ordered')
        .toList();

    if (_searchQuery.isEmpty) return orders;

    final query = _searchQuery.toLowerCase();
    return orders
        .where((order) => order.orderId.toLowerCase().contains(query))
        .toList();
  }

  List<EmployeeOrderEntry> get _historyOrders =>
      _orderStore.orders.where((order) {
        final status = order.status.toLowerCase();
        return status == 'delivered' || status == 'rejected';
      }).toList();

  @override
  void initState() {
    super.initState();
    _orderStore.addListener(_onOrdersUpdated);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _orderStore.removeListener(_onOrdersUpdated);
    _searchController.dispose();
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  void _onOrdersUpdated() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleTabChanged() {
    if (!mounted || _selectedTab == _tabController.index) return;
    setState(() => _selectedTab = _tabController.index);
  }

  void _selectTab(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildSearchBar(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(isActive: true),
              _buildOrdersList(isActive: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1100;
        final scale = (width / 390).clamp(0.88, 1.0).toDouble();

        return VendorPageHeader(
          title: 'Orders',
          maxContentWidth: isDesktop ? 1180 : (width >= 760 ? 760 : 430),
          horizontalPadding: isDesktop ? 42 : (width >= 760 ? 32 : 16),
          isDesktop: isDesktop,
          scale: scale,
          onMenuTap: () => VendorShell.openDrawer(context),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width >= 760 ? 32.0 : 16.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            width >= 760 ? 16 : 12,
            horizontalPadding,
            width >= 760 ? 12 : 8,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: width >= 760 ? 420 : double.infinity,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: 'Search by order ID',
                  hintStyle: const TextStyle(
                    color: Color(0xFF98A2B3),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 14, right: 10),
                    child: Icon(
                      Icons.search_rounded,
                      color: Color(0xFF98A2B3),
                      size: 20,
                    ),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.close_rounded,
                              color: Color(0xFF98A2B3),
                              size: 18,
                            ),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF6F6F8),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE1E5EC),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE1E5EC),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF141827),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width >= 760 ? 32.0 : 16.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            width >= 760 ? 18 : 14,
            horizontalPadding,
            width >= 760 ? 8 : 6,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: width >= 760 ? 420 : double.infinity,
              ),
              child: _OrdersSegmentedSwitch(
                selectedIndex: _selectedTab,
                onSelected: _selectTab,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrdersList({required bool isActive}) {
    final orders = isActive ? _activeOrders : _historyOrders;
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Text(
            isActive
                ? 'No active orders are available yet.'
                : 'No delivered or rejected orders yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 36),
      separatorBuilder: (_, __) => const SizedBox(height: 22),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildDetailedOrderCard(order, isActive);
      },
    );
  }

  Widget _buildDetailedOrderCard(EmployeeOrderEntry order, bool isActive) {
    final status = order.status.toLowerCase();
    final statusLabel = isActive
        ? 'Active'
        : status == 'rejected'
            ? 'Rejected'
            : 'Delivered';
    final statusColor = isActive
        ? const Color(0xFFFFF3E0)
        : status == 'rejected'
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFEAF7EF);
    final statusTextColor = isActive
        ? const Color(0xFFFF8A00)
        : status == 'rejected'
            ? const Color(0xFFB71C1C)
            : const Color(0xFF16833A);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.orderId,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF1A1A3F),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.employeeId,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order.orderIntent,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatOrderDateTime(order.createdAt),
            style: const TextStyle(
              color: Colors.black26,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            order.userName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF1A1A3F),
            ),
          ),
          const SizedBox(height: 6),
          if (order.pickupSlot.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Pickup ${order.pickupSlot.toLowerCase()}',
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 22),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.name} x${item.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    '₹${item.price * item.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF1A1A3F),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: Colors.black26,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              Text(
                '₹${order.amount}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Color(0xFF1A1A3F),
                ),
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    'Mark Delivered',
                    const Color(0xFF237A35),
                    () => _handleMarkDelivered(order),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildActionBtn(
                    'Reject Order',
                    const Color(0xFFFF3B30),
                    () => _handleReject(order),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBtn(
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  String _formatOrderDateTime(DateTime dateTime) {
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = dateTime.day;
    final month = monthNames[dateTime.month - 1];
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    final formattedHour = ((hour + 11) % 12) + 1;
    final period = isPm ? 'pm' : 'am';
    return '$day $month · $formattedHour:$minute$period';
  }

  void _handleMarkDelivered(EmployeeOrderEntry order) {
    final shouldReject = _isPastPickup(order.pickupSlot);
    _orderStore.updateOrderStatus(
      order.orderId,
      shouldReject ? 'rejected' : 'delivered',
    );
  }

  void _handleReject(EmployeeOrderEntry order) {
    _orderStore.updateOrderStatus(order.orderId, 'rejected');
  }

  bool _isPastPickup(String pickupSlot) {
    if (pickupSlot.trim().isEmpty) return false;

    final normalized = pickupSlot
        .replaceAll(' ', '')
        .replaceAll('AM', 'am')
        .replaceAll('PM', 'pm')
        .replaceAll('Am', 'am')
        .replaceAll('Pm', 'pm')
        .toLowerCase();
    final match = RegExp(r'^(\d{1,2}):(\d{2})(am|pm)\$').firstMatch(normalized);
    if (match == null) return false;

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!;
    final parsedHour = period == 'pm' && hour != 12
        ? hour + 12
        : period == 'am' && hour == 12
            ? 0
            : hour;

    final now = DateTime.now();
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
      parsedHour,
      minute,
    );

    return now.isAfter(cutoff);
  }
}

class _OrdersSegmentedSwitch extends StatelessWidget {
  const _OrdersSegmentedSwitch({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEFF3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E5EC)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final thumbWidth = constraints.maxWidth / 2;

          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: selectedIndex == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: thumbWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                        spreadRadius: -7,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _OrdersSegmentButton(
                    label: 'Active',
                    selected: selectedIndex == 0,
                    onTap: () => onSelected(0),
                  ),
                  _OrdersSegmentButton(
                    label: 'Delivered',
                    selected: selectedIndex == 1,
                    onTap: () => onSelected(1),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrdersSegmentButton extends StatelessWidget {
  const _OrdersSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF141827) : const Color(0xFF667085);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
