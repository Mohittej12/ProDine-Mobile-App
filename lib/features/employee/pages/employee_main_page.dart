import 'package:flutter/material.dart';
import 'package:pro_dine/features/employee/pages/employee_home_page.dart';
import 'package:pro_dine/features/employee/pages/employee_menu_page.dart';
import 'package:pro_dine/features/employee/pages/employee_orders_page.dart';
import 'package:pro_dine/features/employee/pages/employee_profile_page.dart';
import 'package:pro_dine/features/employee/widgets/employee_cart_overlay.dart';

class EmployeeMainPage extends StatefulWidget {
  final int initialIndex;
  const EmployeeMainPage({super.key, this.initialIndex = 0});

  @override
  State<EmployeeMainPage> createState() => _EmployeeMainPageState();
}

class _EmployeeMainPageState extends State<EmployeeMainPage>
    with TickerProviderStateMixin {
  static const Duration _tabTransitionDuration = Duration(milliseconds: 190);
  static const Curve _tabTransitionCurve = Curves.easeOutCubic;

  late int _selectedIndex;
  int _previousIndex = 0;
  String? _menuRestaurantName;
  String? _menuMealName;
  int _menuSelectionVersion = 0;
  late final List<bool> _activatedTabs;

  late final AnimationController _tabTransitionController = AnimationController(
    vsync: this,
    duration: _tabTransitionDuration,
  )..value = 1;
  late final Animation<double> _tabTransition = CurvedAnimation(
    parent: _tabTransitionController,
    curve: _tabTransitionCurve,
  );

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
    _previousIndex = widget.initialIndex;
    _activatedTabs = List.generate(4, (index) => index == widget.initialIndex);

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

  @override
  void didUpdateWidget(covariant EmployeeMainPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _selectTab(widget.initialIndex);
    }
  }

  @override
  void dispose() {
    _tabTransitionController.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _selectTab(index);
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
      _activatedTabs[index] = true;
    });
    _tabTransitionController.forward(from: 0);
  }

  void _openMenu(String? restaurantName, {String? mealName}) {
    setState(() {
      _previousIndex = _selectedIndex;
      _menuRestaurantName = restaurantName;
      _menuMealName = mealName;
      _menuSelectionVersion++;
      _selectedIndex = 1;
      _activatedTabs[1] = true;
    });
    _tabTransitionController.forward(from: 0);
  }

  List<Widget> _buildFragments() {
    return [
      EmployeeHomeFragment(onOpenMenu: _openMenu),
      EmployeeMenuFragment(
        initialRestaurantName: _menuRestaurantName,
        initialMealName: _menuMealName,
        selectionVersion: _menuSelectionVersion,
      ),
      const EmployeeOrdersFragment(),
      const EmployeeProfileFragment(),
    ];
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
                  child: _buildTabStack(),
                ),
              ),

              EmployeeCartOverlay(
                bottomOffset: MediaQuery.sizeOf(context).width < 370
                    ? 116
                    : 124,
                horizontalPadding: MediaQuery.sizeOf(context).width >= 760
                    ? 34
                    : 14,
                onViewMenu: (restaurantName) => _openMenu(restaurantName),
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

  Widget _buildTabStack() {
    // GPU-composited transitions — no saveLayer, no per-frame rebuilds
    return FadeTransition(
      opacity: Tween<double>(begin: 0.92, end: 1.0).animate(_tabTransition),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(
            0.03 * (_selectedIndex >= _previousIndex ? 1.0 : -1.0),
            0,
          ),
          end: Offset.zero,
        ).animate(_tabTransition),
        child: IndexedStack(
          index: _selectedIndex,
          sizing: StackFit.expand,
          children: _buildFragments()
              .asMap()
              .map((i, fragment) => MapEntry(
                    i,
                    _activatedTabs[i]
                        ? RepaintBoundary(child: fragment)
                        : const SizedBox.shrink(),
                  ))
              .values
              .toList(),
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
          _buildNavItem(0, Icons.home_filled, Icons.home_outlined, 'Home'),
          _buildNavItem(
            1,
            Icons.restaurant_menu_rounded,
            Icons.restaurant_menu_outlined,
            'Menu',
          ),
          _buildNavItem(
            2,
            Icons.receipt_long_rounded,
            Icons.receipt_long_outlined,
            'Orders',
          ),
          _buildNavItem(
            3,
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
