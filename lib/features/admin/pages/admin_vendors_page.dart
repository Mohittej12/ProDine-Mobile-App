import 'package:flutter/material.dart';
import 'package:pro_dine/features/admin/widgets/admin_shell.dart';
import 'package:pro_dine/features/employee/data/employee_order_store.dart';

class AdminVendorsPage extends StatefulWidget {
  const AdminVendorsPage({super.key});

  @override
  State<AdminVendorsPage> createState() => _AdminVendorsPageState();
}

class _AdminVendorsPageState extends State<AdminVendorsPage> {
  final EmployeeOrderStore _orderStore = EmployeeOrderStore.instance;
  final TextEditingController _searchController = TextEditingController();
  final List<_CafeteriaAccount> _cafeterias = [
    const _CafeteriaAccount(name: 'Meal Counter', phone: '+91 8888888888'),
    const _CafeteriaAccount(name: 'Tuck Shop', phone: '+91 8888888888'),
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

  List<_CafeteriaAccount> get _visibleCafeterias {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _cafeterias;
    return _cafeterias
        .where((item) =>
            item.name.toLowerCase().contains(query) ||
            item.phone.toLowerCase().contains(query))
        .toList();
  }

  _VendorStats _statsFor(String cafeteria) {
    final orders = _orderStore.orders
        .where((order) => order.shopName == cafeteria)
        .toList();
    final revenue = orders.fold<int>(0, (sum, order) => sum + order.amount);
    final ticketing = orders.where((order) => order.isTicketing).length;
    final preOrder = orders.where((order) => !order.isTicketing).length;
    final active =
        orders.where((order) => order.status.toLowerCase() == 'ordered').length;
    return _VendorStats(
      totalOrders: orders.length,
      revenue: revenue,
      ticketing: ticketing,
      preOrder: preOrder,
      active: active,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildFilters(),
        Expanded(
          child: Stack(
            children: [
              ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                itemBuilder: (context, index) {
                  final cafeteria = _visibleCafeterias[index];
                  return _VendorCard(
                    cafeteria: cafeteria,
                    stats: _statsFor(cafeteria.name),
                    onReset: () => _confirmReset(cafeteria),
                    onDelete: () => _confirmDelete(cafeteria),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemCount: _visibleCafeterias.length,
              ),
              Positioned(
                right: 24,
                bottom: 24,
                child: FloatingActionButton(
                  onPressed: _showAddCafeteriaDialog,
                  backgroundColor: const Color(0xFFFF1F1F),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => AdminShell.openDrawer(context),
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.menu_rounded,
                  color: Color(0xFF1A1A3F),
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vendors',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A3F),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Live cafeteria access and order intent',
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search cafeterias...',
            hintStyle: TextStyle(
              color: Colors.black26,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            border: InputBorder.none,
            icon: Icon(Icons.search_rounded, color: Colors.black26),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(_CafeteriaAccount cafeteria) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset credentials?'),
        content: Text(
          'This option will reset ${cafeteria.name} cafeteria information and data all to start stage. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed == true) _showSnack('${cafeteria.name} reset started');
  }

  Future<void> _confirmDelete(_CafeteriaAccount cafeteria) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete cafeteria operation?'),
        content: Text(
          'If you click delete, ${cafeteria.name} cafeteria operation will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Come back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF1F1F),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _cafeterias.remove(cafeteria));
      _showSnack('${cafeteria.name} deleted');
    }
  }

  Future<void> _showAddCafeteriaDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<_CafeteriaAccount>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create cafeteria'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(controller: nameController, label: 'Cafeteria name'),
              _DialogField(controller: phoneController, label: 'Phone number'),
              _DialogField(
                controller: passwordController,
                label: 'Password',
                obscureText: true,
              ),
              _DialogField(
                controller: confirmController,
                label: 'Confirm password',
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isEmpty ||
                  phone.isEmpty ||
                  passwordController.text.isEmpty ||
                  passwordController.text != confirmController.text) {
                return;
              }
              Navigator.pop(
                context,
                _CafeteriaAccount(name: name, phone: phone),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();

    if (result == null) return;
    setState(() => _cafeterias.add(result));
    _showSnack('${result.name} created');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}

class _VendorCard extends StatelessWidget {
  const _VendorCard({
    required this.cafeteria,
    required this.stats,
    required this.onReset,
    required this.onDelete,
  });

  final _CafeteriaAccount cafeteria;
  final _VendorStats stats;
  final VoidCallback onReset;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFBFB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: Color(0xFF1A1A3F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cafeteria.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Color(0xFF1A1A3F),
                      ),
                    ),
                    Text(
                      cafeteria.phone,
                      style: const TextStyle(
                        color: Colors.black26,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon:
                    const Icon(Icons.more_vert_rounded, color: Colors.black26),
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                stats.active == 0 ? 'Active' : 'Live intent: ${stats.active}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _StatBox(label: 'Total Orders', value: '${stats.totalOrders}'),
              const SizedBox(width: 16),
              _StatBox(label: 'Revenue', value: 'Rs ${stats.revenue}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatBox(label: 'Ticketing', value: '${stats.ticketing}'),
              const SizedBox(width: 16),
              _StatBox(label: 'Pre-Order', value: '${stats.preOrder}'),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onReset,
              child: const Text(
                'Reset Credentials',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFBFB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black26,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A3F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _CafeteriaAccount {
  const _CafeteriaAccount({required this.name, required this.phone});

  final String name;
  final String phone;
}

class _VendorStats {
  const _VendorStats({
    required this.totalOrders,
    required this.revenue,
    required this.ticketing,
    required this.preOrder,
    required this.active,
  });

  final int totalOrders;
  final int revenue;
  final int ticketing;
  final int preOrder;
  final int active;
}
