import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/core/widgets/app_logo.dart';

class AdminSidebar extends StatelessWidget {
  final String currentRoute;
  final bool isDrawer;

  const AdminSidebar({
    super.key,
    required this.currentRoute,
    this.isDrawer = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isDrawer) {
      return Drawer(
        width: 300,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: AdminSidebarContent(currentRoute: currentRoute, isDrawer: true),
      );
    }

    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: AdminSidebarContent(currentRoute: currentRoute, isDrawer: false),
    );
  }
}

class AdminSidebarContent extends StatelessWidget {
  final String currentRoute;
  final bool isDrawer;

  const AdminSidebarContent({
    super.key,
    required this.currentRoute,
    required this.isDrawer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildProfileCard(),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(context, Icons.grid_view_rounded, 'Dashboard',
                    AppRoutes.adminDashboard),
                _buildNavItem(context, Icons.restaurant_menu_rounded,
                    'Menu Management', AppRoutes.adminMenuManagement),
                _buildNavItem(context, Icons.assignment_rounded,
                    'Terms and Disclaimer', AppRoutes.adminTerms),
                _buildNavItem(context, Icons.inventory_2_rounded, 'Vendors',
                    AppRoutes.adminVendors),
                _buildNavItem(context, Icons.leaderboard_rounded,
                    'Vendor Performance', AppRoutes.adminVendorPerformance),
                _buildNavItem(context, Icons.list_alt_rounded, 'Food Items',
                    AppRoutes.adminFoodItems),
                _buildNavItem(context, Icons.upload_file_rounded,
                    'Upload Ticket ID Data', AppRoutes.adminUploadTicketData),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildSignOut(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AppLogo(
            height: 18,
            isBrand: true,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(
                color: Color(0xFF1A1A3F),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFEF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'A',
                style: TextStyle(
                  color: Color(0xFFFF1F1F),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin',
                  style: TextStyle(
                    color: Color(0xFF1A1A3F),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '+91 8888888888',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black26,
                    fontSize: 10,
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

  Widget _buildNavItem(
      BuildContext context, IconData icon, String label, String route) {
    final bool isActive = currentRoute == route;
    const Color primaryRed = Color(0xFFFF1F1F);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isDrawer) {
              Scaffold.of(context).closeDrawer();
            }
            context.go(route);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isActive ? primaryRed : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: primaryRed.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : Colors.black38,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black45,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 13,
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

  Widget _buildSignOut(BuildContext context) {
    const Color primaryRed = Color(0xFFFF1F1F);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: InkWell(
        onTap: () {
          if (isDrawer) {
            Scaffold.of(context).closeDrawer();
          }
          context.go(AppRoutes.login);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: const Row(
            children: [
              Icon(Icons.logout_rounded, color: primaryRed, size: 20),
              const SizedBox(width: 12),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: primaryRed,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
