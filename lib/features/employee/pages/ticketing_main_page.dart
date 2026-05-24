import 'package:flutter/material.dart';
import 'package:pro_dine/features/employee/pages/ticketing_home_page.dart';
import 'package:pro_dine/features/employee/pages/employee_orders_page.dart';
import 'package:pro_dine/features/employee/pages/employee_profile_page.dart';

class TicketingMainPage extends StatefulWidget {
  final int initialIndex;
  const TicketingMainPage({super.key, this.initialIndex = 0});

  @override
  State<TicketingMainPage> createState() => _TicketingMainPageState();
}

class _TicketingMainPageState extends State<TicketingMainPage>
    with TickerProviderStateMixin {
  late int _selectedIndex;

  // ── Entrance animations ──
  late final AnimationController _entranceCtrl;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _navFade;
  late final Animation<Offset> _navSlide;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    const curve = Curves.easeOutCubic;

    _contentFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.65, curve: curve),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_contentFade);

    _navFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.3, 1.0, curve: curve),
    );
    _navSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(_navFade);

    // Start entrance after first frame is laid out
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceCtrl.forward();
    });
  }

  final List<Widget> _fragments = [
    const TicketingHomeFragment(),
    const EmployeeOrdersFragment(),
    const EmployeeProfileFragment(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      resizeToAvoidBottomInset: false,
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
        child: SafeArea(
          child: Stack(
            children: [
              FadeTransition(
                opacity: _contentFade,
                child: _buildMeshBackground(),
              ),

              SlideTransition(
                position: _contentSlide,
                child: FadeTransition(
                  opacity: _contentFade,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final bool isIncoming =
                          child.key == ValueKey<int>(_selectedIndex);

                      if (isIncoming) {
                        return FadeTransition(
                          opacity: Tween<double>(
                            begin: 0.0,
                            end: 1.0,
                          ).animate(animation),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.02), // Subtle slide up
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      } else {
                        return FadeTransition(
                          opacity: Tween<double>(
                            begin: 0.0,
                            end: 1.0,
                          ).animate(animation),
                          child: child,
                        );
                      }
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_selectedIndex),
                      child: RepaintBoundary(child: _fragments[_selectedIndex]),
                    ),
                  ),
                ),
              ),

              // Fixed Bottom Navigation
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: _navSlide,
                  child: FadeTransition(
                    opacity: _navFade,
                    child: RepaintBoundary(child: _buildBottomNav()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeshBackground() {
    return Stack(
      children: [
        Positioned(
          top: -150,
          right: -150,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF4D4D).withOpacity(0.04),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            0,
            Icons.restaurant_menu_rounded,
            Icons.restaurant_menu_outlined,
            'Menu',
          ),
          _buildNavItem(
            1,
            Icons.receipt_long_rounded,
            Icons.receipt_long_outlined,
            'Orders',
          ),
          _buildNavItem(
            2,
            Icons.person_2_rounded,
            Icons.person_2_outlined,
            'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF4D4D).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? const Color(0xFFFF4D4D) : Colors.black38,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? const Color(0xFFFF4D4D) : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
