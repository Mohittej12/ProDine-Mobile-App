import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_routes.dart';

class AppDrawer extends StatelessWidget {
  final String role;

  const AppDrawer({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final items =
        role == 'Vendor' ? _getVendorItems(context) : _getAdminItems(context);

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Text(
              '$role Dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  List<Widget> _getVendorItems(BuildContext context) {
    return [
      _drawerItem(context, 'Dashboard', AppRoutes.vendorDashboard),
      _drawerItem(context, 'Orders', AppRoutes.vendorOrders),
      _drawerItem(context, 'Food Items', AppRoutes.vendorFoodItems),
      _drawerItem(context, 'Food Portions', AppRoutes.vendorFoodPortions),
      _drawerItem(context, 'Reports', AppRoutes.vendorReports),
      _drawerItem(context, 'Ticket Data View', AppRoutes.vendorTicketData),
      _drawerItem(context, 'Terms & Disclaimer', AppRoutes.vendorTerms),
      const Divider(),
      ListTile(
        title: const Text('Sign Out'),
        onTap: () {
          // Placeholder
        },
      ),
    ];
  }

  List<Widget> _getAdminItems(BuildContext context) {
    return [
      _drawerItem(context, 'Dashboard', AppRoutes.adminDashboard),
      _drawerItem(context, 'Vendors', AppRoutes.adminVendors),
      _drawerItem(
          context, 'Vendor Performance', AppRoutes.adminVendorPerformance),
      _drawerItem(context, 'Menu Management', AppRoutes.adminMenuManagement),
      _drawerItem(context, 'Food Items', AppRoutes.adminFoodItems),
      _drawerItem(
          context, 'Upload Ticket Data', AppRoutes.adminUploadTicketData),
      _drawerItem(context, 'Reports', AppRoutes.adminReports),
      _drawerItem(context, 'Terms & Disclaimer', AppRoutes.adminTerms),
      const Divider(),
      ListTile(
        title: const Text('Sign Out'),
        onTap: () {
          // Placeholder
        },
      ),
    ];
  }

  Widget _drawerItem(BuildContext context, String title, String route) {
    return ListTile(
      title: Text(title),
      onTap: () {
        context.go(route);
      },
    );
  }
}
