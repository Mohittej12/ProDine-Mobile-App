import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/core/widgets/app_logo.dart';

class VendorSidebar extends StatelessWidget {
  final String currentRoute;
  const VendorSidebar({super.key, required this.currentRoute});

  static const Color _text = Color(0xFF151827);
  static const Color _muted = Color(0xFF77726E);
  static const Color _softMuted = Color(0xFFA09B96);
  static const Color _surface = Colors.white;
  static const Color _canvasBg = Color(0xFFFAF9F7);
  static const Color _border = Color(0xFFECEAE6);
  static const Color _red = Color(0xFFFF1F1F);
  static const Color _redSoft = Color(0xFFFFF1F0);
  static const Color _activeNavBg = Color(0xFFF5F4F2);

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Drawer(
      width: 280,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // ─── Branding ───
          Padding(
            padding: EdgeInsets.fromLTRB(22, topSafe + 20, 22, 0),
            child: Row(
              children: [
                const AppLogo(
                  height: 14,
                  isBrand: true,
                ),
                const SizedBox(width: 10),
                Container(
                  height: 16,
                  width: 1,
                  color: _border,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Vendor',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ─── Profile Card ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _canvasBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF5C5C), Color(0xFFFF1F1F)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'K',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          height: 1,
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
                          'Kitchen Vendor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _text,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            height: 1.1,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '+91 8888888888',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _softMuted,
                            fontSize: 12,
                            height: 1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: _muted,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ─── Scrollable Navigation ───
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSectionLabel('MAIN'),
                _buildNavTile(
                  context,
                  icon: Icons.grid_view_rounded,
                  label: 'Dashboard',
                  route: AppRoutes.vendorDashboard,
                ),
                _buildNavTile(
                  context,
                  icon: Icons.shopping_bag_rounded,
                  label: 'Orders',
                  route: AppRoutes.vendorOrders,
                ),
                _buildNavTile(
                  context,
                  icon: Icons.restaurant_menu_rounded,
                  label: 'Food Items',
                  route: AppRoutes.vendorFoodItems,
                ),
                _buildNavTile(
                  context,
                  icon: Icons.room_service_rounded,
                  label: 'Food Portions',
                  route: AppRoutes.vendorFoodPortions,
                ),
                const SizedBox(height: 6),
                _buildSectionLabel('ANALYTICS'),
                _buildNavTile(
                  context,
                  icon: Icons.bar_chart_rounded,
                  label: 'Reports',
                  route: AppRoutes.vendorReports,
                ),
                _buildNavTile(
                  context,
                  icon: Icons.receipt_long_rounded,
                  label: 'Ticket Data',
                  route: AppRoutes.vendorTicketData,
                ),
                const SizedBox(height: 6),
                _buildSectionLabel('LEGAL'),
                _buildNavTile(
                  context,
                  icon: Icons.description_outlined,
                  label: 'Terms & Disclaimer',
                  route: AppRoutes.vendorTerms,
                ),
              ],
            ),
          ),

          // ─── Pinned Sign Out ───
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 14 + bottomSafe),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: _border, width: 1),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.go(AppRoutes.login);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _redSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _red.withOpacity(0.12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: _red,
                        size: 19,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          color: _red,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          height: 1,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: _softMuted,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isActive = currentRoute == route;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            if (!isActive) context.go(route);
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? _activeNavBg : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isActive ? _red : const Color(0xFFF0EFED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? Colors.white : _muted,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? _text : _muted,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 14,
                      height: 1,
                      letterSpacing: -0.15,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _red,
                      shape: BoxShape.circle,
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
