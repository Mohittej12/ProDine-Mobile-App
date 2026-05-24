import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_dine/core/widgets/app_logo.dart';
import 'package:pro_dine/features/employee/data/employee_cart_store.dart';
import 'package:pro_dine/features/employee/data/employee_favorites_store.dart';
import 'package:pro_dine/features/employee/widgets/employee_cart_overlay.dart';

part 'employee_search_page.dart';

enum _DietFilter { all, veg, nonVeg }

typedef EmployeeOpenMenuCallback = void Function(String? restaurantName,
    {String? mealName});

class EmployeeHomeFragment extends StatefulWidget {
  const EmployeeHomeFragment({super.key, this.onOpenMenu});

  final EmployeeOpenMenuCallback? onOpenMenu;

  @override
  State<EmployeeHomeFragment> createState() => _EmployeeHomeFragmentState();
}

class _EmployeeHomeFragmentState extends State<EmployeeHomeFragment> {
  static const Color _primaryRed = Color(0xFFFF1F1F);
  static const Color _textDark = Color(0xFF141827);
  static const Color _textMuted = Color(0xFF667085);
  static const Color _screenBg = Color(0xFFFFFCF8);
  static const Color _cardBg = Colors.white;

  static const String _mainFoodImage = 'assets/images/auth_login_header.png';
  static const String _secondCafeImage =
      'assets/images/auth_dining_detailed_line_art_png_1778509028286.png';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _query = '';
  String _category = 'All';
  _DietFilter _dietFilter = _DietFilter.all;
  int _maxAmount = 250;
  bool _showStickySearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Show sticky header when original search bar scrolls out of view
    final shouldShow = _scrollController.offset > 180;
    if (shouldShow != _showStickySearch) {
      setState(() => _showStickySearch = shouldShow);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  List<_CafeteriaData> get _filteredCafeterias {
    final q = _query.trim().toLowerCase();

    return _cafeterias.where((item) {
      final matchesSearch = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.tags.any((tag) => tag.toLowerCase().contains(q));

      final matchesCategory =
          _category == 'All' || item.tags.contains(_category);

      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<_DishData> get _filteredDishes {
    final q = _query.trim().toLowerCase();

    return _dishes.where((dish) {
      final matchesSearch = q.isEmpty ||
          dish.name.toLowerCase().contains(q) ||
          dish.description.toLowerCase().contains(q) ||
          dish.restaurant.toLowerCase().contains(q) ||
          dish.category.toLowerCase().contains(q);

      final matchesCategory = _category == 'All' || dish.category == _category;

      final matchesDiet = _dietFilter == _DietFilter.all ||
          (_dietFilter == _DietFilter.veg && dish.isVeg) ||
          (_dietFilter == _DietFilter.nonVeg && !dish.isVeg);

      final matchesAmount = _amountFromPrice(dish.price) <= _maxAmount;

      return matchesSearch && matchesCategory && matchesDiet && matchesAmount;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _screenBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final layout = _HomeLayout.fromWidth(width);

          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      layout.horizontalPadding,
                      layout.topPadding,
                      layout.horizontalPadding,
                      132,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: layout.maxContentWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Header(layout: layout),
                              SizedBox(height: layout.sectionGap * 0.75),
                              _SearchAndFilters(
                                layout: layout,
                                controller: _searchController,
                                query: _query,
                                category: _category,
                                dietFilter: _dietFilter,
                                maxAmount: _maxAmount,
                                onOpenSearch: () => _openSearchPage(context),
                                onClearSearch: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                onOpenFilters: () =>
                                    _openFilters(context, layout),
                              ),
                              SizedBox(height: layout.sectionGap),
                              _SectionHeader(
                                title: "Featured Cafeteria's",
                                layout: layout,
                              ),
                              SizedBox(height: layout.smallGap),
                              _CafeteriaSection(
                                layout: layout,
                                cafeterias: _filteredCafeterias,
                                onOpenMenu: widget.onOpenMenu,
                              ),
                              SizedBox(height: layout.sectionGap),
                              _SectionHeader(
                                title: 'Popular Dishes',
                                layout: layout,
                              ),
                              SizedBox(height: layout.smallGap),
                              _PopularDishSection(
                                layout: layout,
                                dishes: _filteredDishes,
                                onOpenMenu: widget.onOpenMenu,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Sticky search header ──
              _StickySearchHeader(
                visible: _showStickySearch,
                layout: layout,
                onTap: () => _openSearchPage(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openFilters(BuildContext context, _HomeLayout layout) async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FilterSheet(
          category: _category,
          dietFilter: _dietFilter,
          maxAmount: _maxAmount,
          layout: layout,
        );
      },
    );

    if (result == null) return;

    setState(() {
      _category = result.category;
      _dietFilter = result.dietFilter;
      _maxAmount = result.maxAmount;
    });
  }

  Future<void> _openSearchPage(BuildContext context) async {
    final result = await Navigator.of(context).push<_FilterResult>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _HomeSearchPage(
            category: _category,
            dietFilter: _dietFilter,
            maxAmount: _maxAmount,
          );
        },
        transitionsBuilder: _searchPageTransition,
      ),
    );

    if (result == null) return;
    setState(() {
      _category = result.category;
      _dietFilter = result.dietFilter;
      _maxAmount = result.maxAmount;
    });
  }

  Widget _searchPageTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: false,
      child: child,
    );
  }
}

class _HomeLayout {
  const _HomeLayout({
    required this.isDesktop,
    required this.isTablet,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.topPadding,
    required this.scale,
    required this.sectionGap,
    required this.smallGap,
    required this.cafeteriaCardHeight,
    required this.cafeteriaCardWidth,
    required this.heroImageHeight,
    required this.gridColumns,
    required this.gridSpacing,
  });

  final bool isDesktop;
  final bool isTablet;
  final double maxContentWidth;
  final double horizontalPadding;
  final double topPadding;
  final double scale;
  final double sectionGap;
  final double smallGap;
  final double cafeteriaCardHeight;
  final double cafeteriaCardWidth;
  final double heroImageHeight;
  final int gridColumns;
  final double gridSpacing;

  static _HomeLayout fromWidth(double width) {
    if (width >= 1180) {
      return const _HomeLayout(
        isDesktop: true,
        isTablet: false,
        maxContentWidth: 1180,
        horizontalPadding: 48,
        topPadding: 34,
        scale: 1.08,
        sectionGap: 36,
        smallGap: 18,
        cafeteriaCardHeight: 230,
        cafeteriaCardWidth: 390,
        heroImageHeight: 260,
        gridColumns: 4,
        gridSpacing: 22,
      );
    }

    if (width >= 760) {
      return const _HomeLayout(
        isDesktop: false,
        isTablet: true,
        maxContentWidth: 720,
        horizontalPadding: 36,
        topPadding: 30,
        scale: 1.02,
        sectionGap: 34,
        smallGap: 18,
        cafeteriaCardHeight: 218,
        cafeteriaCardWidth: 340,
        heroImageHeight: 240,
        gridColumns: 3,
        gridSpacing: 20,
      );
    }

    return _HomeLayout(
      isDesktop: false,
      isTablet: false,
      maxContentWidth: 430,
      horizontalPadding: width < 370 ? 16 : 20,
      topPadding: 20,
      scale: width < 370 ? 0.94 : 1.0,
      sectionGap: 32,
      smallGap: 16,
      cafeteriaCardHeight: 190,
      cafeteriaCardWidth: 300,
      heroImageHeight: 220,
      gridColumns: 2,
      gridSpacing: 18,
    );
  }
}

// ── Sticky search header that appears when scrolling down ──
class _StickySearchHeader extends StatelessWidget {
  const _StickySearchHeader({
    required this.visible,
    required this.layout,
    required this.onTap,
  });

  final bool visible;
  final _HomeLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        offset: Offset(0, visible ? 0 : -1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: visible ? 1.0 : 0.0,
          child: Container(
            decoration: BoxDecoration(
              color: _EmployeeHomeFragmentState._screenBg.withValues(
                alpha: 0.92,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                layout.horizontalPadding,
                8 * scale,
                layout.horizontalPadding,
                10 * scale,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
                  child: GestureDetector(
                    onTap: onTap,
                    child: Container(
                      height: layout.isDesktop ? 52 : 48 * scale,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16 * scale),
                        border: Border.all(color: const Color(0xFFECEDF0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 14 * scale),
                          Icon(
                            Icons.search_rounded,
                            color: const Color(0xFF98A2B3),
                            size: 22 * scale,
                          ),
                          SizedBox(width: 10 * scale),
                          Expanded(
                            child: Text(
                              'Search cafeterias, dishes...',
                              style: TextStyle(
                                color: const Color(0xFF98A2B3),
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 22,
                            color: const Color(0xFFE9EAEC),
                          ),
                          SizedBox(width: 4 * scale),
                          Icon(
                            Icons.tune_rounded,
                            color: const Color(0xFF98A2B3),
                            size: 21 * scale,
                          ),
                          SizedBox(width: 12 * scale),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatefulWidget {
  const _Header({required this.layout});

  final _HomeLayout layout;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> with TickerProviderStateMixin {
  late final AnimationController _shineController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    // Start the shine loop: animate → pause 1.5s → repeat
    _startShineLoop();
  }

  void _startShineLoop() async {
    // Initial delay before first shine
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    while (mounted) {
      await _shineController.forward(from: 0);
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    final scale = layout.scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppLogo(height: layout.isDesktop ? 24 : 20 * scale, isBrand: true),
        SizedBox(height: layout.isDesktop ? 22 : 16 * scale),
        Row(
          children: [
            Text(
              'Hi,',
              style: TextStyle(
                fontSize: layout.isDesktop ? 46 : 34 * scale,
                height: 1.02,
                fontWeight: FontWeight.w900,
                color: _EmployeeHomeFragmentState._textDark,
                letterSpacing: -1.4,
              ),
            ),
          ],
        ),
        SizedBox(height: 8 * scale),
        Text.rich(
          TextSpan(
            text: 'What are you ',
            style: TextStyle(
              fontSize: layout.isDesktop ? 26 : 20 * scale,
              height: 1.18,
              fontWeight: FontWeight.w800,
              color: _EmployeeHomeFragmentState._textDark,
              letterSpacing: -0.3,
            ),
            children: const [
              TextSpan(
                text: 'craving today?',
                style: TextStyle(color: _EmployeeHomeFragmentState._primaryRed),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _SearchAndFilters extends StatefulWidget {
  const _SearchAndFilters({
    required this.layout,
    required this.controller,
    required this.query,
    required this.category,
    required this.dietFilter,
    required this.maxAmount,
    required this.onOpenSearch,
    required this.onClearSearch,
    required this.onOpenFilters,
  });

  final _HomeLayout layout;
  final TextEditingController controller;
  final String query;
  final String category;
  final _DietFilter dietFilter;
  final int maxAmount;
  final VoidCallback onOpenSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenFilters;

  @override
  State<_SearchAndFilters> createState() => _SearchAndFiltersState();
}

class _SearchAndFiltersState extends State<_SearchAndFilters> {
  bool get _hasActiveFilters =>
      widget.category != 'All' ||
      widget.dietFilter != _DietFilter.all ||
      widget.maxAmount != 250;

  @override
  Widget build(BuildContext context) {
    final scale = widget.layout.scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22 * scale),
          child: Container(
            height: widget.layout.isDesktop ? 66 : 62 * scale,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22 * scale),
              border: Border.all(color: const Color(0xFFF1F2F4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.045),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(width: 16 * scale),
                Icon(
                  Icons.search_rounded,
                  color: const Color(0xFF98A2B3),
                  size: widget.layout.isDesktop ? 32 : 29 * scale,
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    readOnly: true,
                    enableInteractiveSelection: false,
                    onTap: widget.onOpenSearch,
                    textInputAction: TextInputAction.search,
                    cursorColor: _EmployeeHomeFragmentState._primaryRed,
                    scrollPadding: EdgeInsets.zero,
                    style: TextStyle(
                      color: _EmployeeHomeFragmentState._textDark,
                      fontSize: widget.layout.isDesktop ? 17 : 15.5 * scale,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintText: 'Search cafeterias, dishes...',
                      hintStyle: TextStyle(
                        color: const Color(0xFF98A2B3),
                        fontSize: widget.layout.isDesktop ? 17 : 15.5 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (widget.query.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: widget.onClearSearch,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF98A2B3),
                    ),
                  ),
                Container(width: 1, height: 28, color: const Color(0xFFE9EAEC)),
                SizedBox(width: 6 * scale),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'Filter',
                      onPressed: widget.onOpenFilters,
                      icon: Icon(
                        Icons.tune_rounded,
                        color: _hasActiveFilters
                            ? _EmployeeHomeFragmentState._primaryRed
                            : const Color(0xFF98A2B3),
                        size: widget.layout.isDesktop ? 28 : 25 * scale,
                      ),
                    ),
                    if (_hasActiveFilters)
                      Positioned(
                        top: 9,
                        right: 9,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _EmployeeHomeFragmentState._primaryRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 8 * scale),
              ],
            ),
          ),
        ),
        if (_hasActiveFilters) ...[
          SizedBox(height: 12 * scale),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.category != 'All') _ActiveChip(label: widget.category),
              if (widget.dietFilter != _DietFilter.all)
                _ActiveChip(
                  label:
                      widget.dietFilter == _DietFilter.veg ? 'Veg' : 'Non-Veg',
                ),
              if (widget.maxAmount != 250)
                _ActiveChip(label: 'Up to Rs ${widget.maxAmount}'),
            ],
          ),
        ],
      ],
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.category,
    required this.dietFilter,
    required this.maxAmount,
    required this.layout,
  });

  final String category;
  final _DietFilter dietFilter;
  final int maxAmount;
  final _HomeLayout layout;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _category = widget.category;
  late _DietFilter _dietFilter = widget.dietFilter;
  late int _maxAmount = widget.maxAmount;

  @override
  Widget build(BuildContext context) {
    final isDesktop = widget.layout.isDesktop || widget.layout.isTablet;

    return Align(
      alignment: isDesktop ? Alignment.centerRight : Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 420 : double.infinity,
        ),
        child: Container(
          margin: EdgeInsets.only(
            right: isDesktop ? 28 : 0,
            bottom: isDesktop ? 28 : 0,
            top: isDesktop ? 28 : 0,
          ),
          padding: EdgeInsets.fromLTRB(
            22,
            14,
            22,
            22 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(28),
              bottom: Radius.circular(isDesktop ? 28 : 0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Filter Food',
                        style: TextStyle(
                          color: _EmployeeHomeFragmentState._textDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _category = 'All';
                          _dietFilter = _DietFilter.all;
                          _maxAmount = 250;
                        });
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          color: _EmployeeHomeFragmentState._primaryRed,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _FilterTitle('Category'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _categories.map((category) {
                    return _ChoicePill(
                      label: category,
                      selected: _category == category,
                      onTap: () => setState(() => _category = category),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),
                const _FilterTitle('Diet'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ChoicePill(
                      label: 'All',
                      selected: _dietFilter == _DietFilter.all,
                      onTap: () =>
                          setState(() => _dietFilter = _DietFilter.all),
                    ),
                    _ChoicePill(
                      label: 'Veg',
                      selected: _dietFilter == _DietFilter.veg,
                      onTap: () =>
                          setState(() => _dietFilter = _DietFilter.veg),
                    ),
                    _ChoicePill(
                      label: 'Non-Veg',
                      selected: _dietFilter == _DietFilter.nonVeg,
                      onTap: () =>
                          setState(() => _dietFilter = _DietFilter.nonVeg),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(child: _FilterTitle('Amount Range')),
                    Text(
                      'Up to Rs $_maxAmount',
                      style: const TextStyle(
                        color: _EmployeeHomeFragmentState._primaryRed,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _maxAmount.toDouble(),
                  min: 25,
                  max: 250,
                  divisions: 9,
                  activeColor: _EmployeeHomeFragmentState._primaryRed,
                  inactiveColor: const Color(0xFFFFDADA),
                  onChanged: (value) {
                    setState(() => _maxAmount = value.round());
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _FilterResult(
                          category: _category,
                          dietFilter: _dietFilter,
                          maxAmount: _maxAmount,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _EmployeeHomeFragmentState._primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
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
}

class _FilterTitle extends StatelessWidget {
  const _FilterTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _EmployeeHomeFragmentState._textDark,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFFFEAEA),
      backgroundColor: const Color(0xFFF8F8F8),
      side: BorderSide(
        color: selected
            ? _EmployeeHomeFragmentState._primaryRed.withOpacity(0.35)
            : const Color(0xFFE7E7E7),
      ),
      labelStyle: TextStyle(
        color: selected
            ? _EmployeeHomeFragmentState._primaryRed
            : _EmployeeHomeFragmentState._textDark,
        fontWeight: FontWeight.w900,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _EmployeeHomeFragmentState._primaryRed,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.layout});

  final String title;
  final _HomeLayout layout;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: layout.isDesktop ? 28 : 22 * scale,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: _EmployeeHomeFragmentState._textDark,
              letterSpacing: -0.65,
            ),
          ),
        ),
      ],
    );
  }
}

class _CafeteriaSection extends StatelessWidget {
  const _CafeteriaSection({
    required this.layout,
    required this.cafeterias,
    required this.onOpenMenu,
  });

  final _HomeLayout layout;
  final List<_CafeteriaData> cafeterias;
  final EmployeeOpenMenuCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    if (cafeterias.isEmpty) {
      return const _EmptyState(message: 'No cafeterias found');
    }

    if (layout.isDesktop) {
      return Row(
        children: cafeterias.take(3).map((item) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: item == cafeterias.take(3).last ? 0 : layout.gridSpacing,
              ),
              child: _CafeteriaCard(
                name: item.name,
                imagePath: item.imagePath,
                tags: item.tags,
                height: layout.cafeteriaCardHeight,
                layout: layout,
                onTap: () => onOpenMenu?.call(null),
              ),
            ),
          );
        }).toList(),
      );
    }

    return SizedBox(
      height: layout.cafeteriaCardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: cafeterias.length,
        separatorBuilder: (context, index) =>
            SizedBox(width: 16 * layout.scale),
        itemBuilder: (context, index) {
          final item = cafeterias[index];

          return SizedBox(
            width: layout.cafeteriaCardWidth,
            child: _CafeteriaCard(
              name: item.name,
              imagePath: item.imagePath,
              tags: item.tags,
              height: layout.cafeteriaCardHeight,
              layout: layout,
              onTap: () => onOpenMenu?.call(null),
            ),
          );
        },
      ),
    );
  }
}

class _CafeteriaCard extends StatelessWidget {
  const _CafeteriaCard({
    required this.name,
    required this.imagePath,
    required this.tags,
    required this.height,
    required this.layout,
    required this.onTap,
  });

  final String name;
  final String imagePath;
  final List<String> tags;
  final double height;
  final _HomeLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26 * scale),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26 * scale),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26 * scale),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _SafeAssetImage(imagePath: imagePath, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.10),
                        Colors.black.withOpacity(0.20),
                        Colors.black.withOpacity(0.62),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 7 * scale,
                        runSpacing: 6 * scale,
                        children: tags.map((tag) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10 * scale,
                              vertical: 5 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.96),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 9 * scale,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Spacer(),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: layout.isDesktop ? 25 : 21 * scale,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.45),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _PopularDishSection extends StatelessWidget {
  const _PopularDishSection({
    required this.layout,
    required this.dishes,
    required this.onOpenMenu,
  });

  final _HomeLayout layout;
  final List<_DishData> dishes;
  final EmployeeOpenMenuCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    if (dishes.isEmpty) {
      return const _EmptyState(message: 'No dishes match your filters');
    }

    final hero = dishes.first;
    final grid = dishes.skip(1).toList();

    if (layout.isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 11,
            child: _HeroDishCard(
              layout: layout,
              dish: hero,
              onTap: () => onOpenMenu?.call(
                hero.restaurant,
                mealName: _menuMealForDishCategory(hero.category),
              ),
            ),
          ),
          SizedBox(width: layout.gridSpacing),
          Expanded(
            flex: 13,
            child: _DishGrid(
              layout: layout,
              dishes: grid,
              onOpenMenu: onOpenMenu,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _HeroDishCard(
          layout: layout,
          dish: hero,
          onTap: () => onOpenMenu?.call(
            hero.restaurant,
            mealName: _menuMealForDishCategory(hero.category),
          ),
        ),
        SizedBox(height: 22 * layout.scale),
        _DishGrid(layout: layout, dishes: grid, onOpenMenu: onOpenMenu),
      ],
    );
  }
}

class _HeroDishCard extends StatelessWidget {
  const _HeroDishCard({
    required this.layout,
    required this.dish,
    required this.onTap,
  });

  final _HomeLayout layout;
  final _DishData dish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28 * scale),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28 * scale),
        child: Ink(
          decoration: BoxDecoration(
            color: _EmployeeHomeFragmentState._cardBg,
            borderRadius: BorderRadius.circular(28 * scale),
            border: Border.all(color: const Color(0xFFF0F2F5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.045),
                blurRadius: 24,
                offset: const Offset(0, 12),
                spreadRadius: -10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28 * scale),
            child: Column(
              children: [
                SizedBox(
                  height: layout.heroImageHeight,
                  width: double.infinity,
                  child: _DishImageFrame(
                    imagePath: dish.imagePath,
                    restaurant: dish.restaurant,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28 * scale),
                    ),
                    scale: scale,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20 * scale,
                    18 * scale,
                    18 * scale,
                    18 * scale,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _DishTitleBlock(
                              name: dish.name,
                              description: dish.description,
                              nameSize: layout.isDesktop ? 22 : 19 * scale,
                              descriptionSize:
                                  layout.isDesktop ? 14.5 : 12.8 * scale,
                            ),
                          ),
                          SizedBox(width: 12 * scale),
                          _PricePill(price: dish.price, scale: scale),
                        ],
                      ),
                    ],
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

class _DishGrid extends StatelessWidget {
  const _DishGrid({
    required this.layout,
    required this.dishes,
    required this.onOpenMenu,
  });

  final _HomeLayout layout;
  final List<_DishData> dishes;
  final EmployeeOpenMenuCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    if (dishes.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = layout.gridSpacing;
        final columns = math.min(layout.gridColumns, dishes.length);
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final itemHeight =
            layout.isDesktop ? itemWidth * 1.22 : itemWidth * 1.43;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: dishes.map((dish) {
            return SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: _SmallDishCard(
                dish: dish,
                layout: layout,
                onTap: () => onOpenMenu?.call(
                  dish.restaurant,
                  mealName: _menuMealForDishCategory(dish.category),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SmallDishCard extends StatelessWidget {
  const _SmallDishCard({
    required this.dish,
    required this.layout,
    required this.onTap,
  });

  final _DishData dish;
  final _HomeLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22 * scale),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22 * scale),
        child: Ink(
          decoration: BoxDecoration(
            color: _EmployeeHomeFragmentState._cardBg,
            borderRadius: BorderRadius.circular(22 * scale),
            border: Border.all(color: const Color(0xFFF0F2F5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 9),
                spreadRadius: -8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22 * scale),
            child: Column(
              children: [
                Expanded(
                  flex: layout.isDesktop ? 54 : 58,
                  child: SizedBox(
                    width: double.infinity,
                    child: _DishImageFrame(
                      imagePath: dish.imagePath,
                      restaurant: dish.restaurant,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(22 * scale),
                      ),
                      scale: scale,
                    ),
                  ),
                ),
                Expanded(
                  flex: layout.isDesktop ? 46 : 42,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      14 * scale,
                      12 * scale,
                      14 * scale,
                      12 * scale,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DishTitleBlock(
                          name: dish.name,
                          description: dish.description,
                          nameSize: layout.isDesktop ? 16.5 : 15.5 * scale,
                          descriptionSize:
                              layout.isDesktop ? 12.2 : 11.2 * scale,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                dish.price,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _EmployeeHomeFragmentState._primaryRed,
                                  fontSize:
                                      layout.isDesktop ? 16.5 : 15.5 * scale,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}

class _DishTitleBlock extends StatelessWidget {
  const _DishTitleBlock({
    required this.name,
    required this.description,
    required this.nameSize,
    required this.descriptionSize,
  });

  final String name;
  final String description;
  final double nameSize;
  final double descriptionSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _EmployeeHomeFragmentState._textDark,
            fontSize: nameSize,
            height: 1.15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.35,
          ),
        ),
        SizedBox(height: 5 * (nameSize / 16)),
        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _EmployeeHomeFragmentState._textMuted,
            fontSize: descriptionSize,
            height: 1.22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DishImageFrame extends StatelessWidget {
  const _DishImageFrame({
    required this.imagePath,
    required this.restaurant,
    required this.borderRadius,
    required this.scale,
  });

  final String imagePath;
  final String restaurant;
  final BorderRadius borderRadius;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _SafeAssetImage(imagePath: imagePath, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.24),
                  Colors.white.withOpacity(0.02),
                  Colors.black.withOpacity(0.12),
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 12 * scale,
            left: 12 * scale,
            child: _RestaurantBadge(label: restaurant, scale: scale),
          ),
        ],
      ),
    );
  }
}

class _RestaurantBadge extends StatefulWidget {
  const _RestaurantBadge({required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  State<_RestaurantBadge> createState() => _RestaurantBadgeState();
}

class _RestaurantBadgeState extends State<_RestaurantBadge>
    with TickerProviderStateMixin {
  late final AnimationController _shineController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  late final Animation<double> _shineAnimation = CurvedAnimation(
    parent: _shineController,
    curve: Curves.easeInOutCubic,
  );

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: AnimatedBuilder(
        animation: _shineAnimation,
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10 * widget.scale,
              vertical: 6 * widget.scale,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.68)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                  spreadRadius: -6,
                ),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment(-1.5 + 3.0 * _shineAnimation.value, -1),
                end: Alignment(-0.9 + 3.0 * _shineAnimation.value, 1),
                colors: [
                  Colors.white.withOpacity(0),
                  Colors.white.withOpacity(0.42),
                  Colors.white.withOpacity(0),
                ],
                stops: const [0.36, 0.5, 0.64],
              ),
            ),
            child: child,
          );
        },
        child: Text(
          widget.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _EmployeeHomeFragmentState._textDark,
            fontSize: 10.5 * widget.scale,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.price, required this.scale});

  final String price;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 13 * scale,
        vertical: 8 * scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFDDD2)),
      ),
      child: Text(
        price,
        style: TextStyle(
          color: _EmployeeHomeFragmentState._primaryRed,
          fontSize: 15.5 * scale,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.15,
        ),
      ),
    );
  }
}

class _SafeAssetImage extends StatelessWidget {
  const _SafeAssetImage({required this.imagePath, required this.fit});

  final String imagePath;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFFFF2EC),
          alignment: Alignment.center,
          child: const Icon(
            Icons.restaurant_rounded,
            color: _EmployeeHomeFragmentState._primaryRed,
            size: 34,
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _EmployeeHomeFragmentState._textMuted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FilterResult {
  const _FilterResult({
    required this.category,
    required this.dietFilter,
    required this.maxAmount,
  });

  final String category;
  final _DietFilter dietFilter;
  final int maxAmount;
}

class _CafeteriaData {
  const _CafeteriaData({
    required this.name,
    required this.imagePath,
    required this.tags,
  });

  final String name;
  final String imagePath;
  final List<String> tags;
}

class _DishData {
  const _DishData({
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    required this.category,
    required this.restaurant,
    required this.prepMinutes,
    required this.isVeg,
  });

  final String name;
  final String description;
  final String price;
  final String imagePath;
  final String category;
  final String restaurant;
  final int prepMinutes;
  final bool isVeg;
}

class _SearchFoodItem {
  const _SearchFoodItem({
    required this.name,
    required this.price,
    required this.description,
    required this.restaurant,
    required this.meal,
    required this.category,
    required this.prepMinutes,
    required this.isVeg,
    required this.isAvailable,
    required this.imagePath,
  });

  final String name;
  final String price;
  final String description;
  final String restaurant;
  final String meal;
  final String category;
  final int prepMinutes;
  final bool isVeg;
  final bool isAvailable;
  final String imagePath;
}

const List<String> _categories = [
  'All',
  'Breakfast',
  'Lunch',
  'Dinner',
  'Snacks',
];

String _menuMealForDishCategory(String category) {
  return switch (category) {
    'Breakfast' || 'Lunch' || 'Dinner' || 'Juices' || 'Beverages' => category,
    _ => 'Lunch',
  };
}

int _amountFromPrice(String price) {
  final digits = RegExp(r'\d+').allMatches(price).map((m) => m.group(0)!);
  return int.tryParse(digits.join()) ?? 0;
}

const List<_CafeteriaData> _cafeterias = [
  _CafeteriaData(
    name: 'Meal Counter',
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
    tags: ['Breakfast', 'Lunch', 'Dinner'],
  ),
  _CafeteriaData(
    name: 'Tuck Shop',
    imagePath: _EmployeeHomeFragmentState._secondCafeImage,
    tags: ['Juices', 'Beverages'],
  ),
];

const List<_SearchFoodItem> _searchFoodItems = [
  _SearchFoodItem(
    name: 'Idli',
    price: 'Rs 60',
    description: 'Soft steamed rice cakes',
    restaurant: 'Meal Counter',
    meal: 'Breakfast',
    category: 'Breakfast',
    prepMinutes: 10,
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Upma',
    price: 'Rs 55',
    description: 'Warm savory semolina breakfast',
    restaurant: 'Meal Counter',
    meal: 'Breakfast',
    category: 'Breakfast',
    prepMinutes: 12,
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Dosa',
    price: 'Rs 80',
    description: 'Crispy dosa with chutney',
    restaurant: 'Meal Counter',
    meal: 'Breakfast',
    category: 'Breakfast',
    prepMinutes: 15,
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Poori',
    price: 'Rs 70',
    description: 'Fluffy poori with curry',
    restaurant: 'Meal Counter',
    meal: 'Breakfast',
    category: 'Breakfast',
    prepMinutes: 16,
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Pongal',
    price: 'Rs 65',
    description: 'Ghee pongal with chutney',
    restaurant: 'Meal Counter',
    meal: 'Breakfast',
    category: 'Breakfast',
    prepMinutes: 14,
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Vada',
    price: 'Rs 45',
    description: 'Crispy lentil vada',
    restaurant: 'Meal Counter',
    meal: 'Breakfast',
    category: 'Breakfast',
    prepMinutes: 10,
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Veg Meals',
    price: 'Rs 140',
    description: 'Rice, curry, dal and sides',
    restaurant: 'Meal Counter',
    meal: 'Lunch',
    category: 'Lunch',
    prepMinutes: 18,
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Chicken Biryani',
    price: 'Rs 220',
    description: 'Spiced rice with chicken',
    restaurant: 'Meal Counter',
    meal: 'Lunch',
    category: 'Lunch',
    prepMinutes: 25,
    isVeg: false,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Curd Rice',
    price: 'Rs 90',
    description: 'Comfort curd rice bowl',
    restaurant: 'Meal Counter',
    meal: 'Lunch',
    category: 'Lunch',
    prepMinutes: 12,
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Paneer Rice',
    price: 'Rs 165',
    description: 'Paneer curry rice bowl',
    restaurant: 'Meal Counter',
    meal: 'Lunch',
    category: 'Lunch',
    prepMinutes: 20,
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Chapati Curry',
    price: 'Rs 110',
    description: 'Chapati with fresh curry',
    restaurant: 'Meal Counter',
    meal: 'Dinner',
    category: 'Dinner',
    prepMinutes: 18,
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Fried Rice',
    price: 'Rs 160',
    description: 'Hot wok-style fried rice',
    restaurant: 'Meal Counter',
    meal: 'Dinner',
    category: 'Dinner',
    prepMinutes: 22,
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Veg Puff',
    price: 'Rs 35',
    description: 'Crispy bakery puff',
    restaurant: 'Tuck Shop',
    meal: 'Breakfast',
    category: 'Snacks',
    prepMinutes: 8,
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Coffee',
    price: 'Rs 45',
    description: 'Fresh brewed coffee',
    restaurant: 'Tuck Shop',
    meal: 'Breakfast',
    category: 'Snacks',
    prepMinutes: 5,
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Tea',
    price: 'Rs 25',
    description: 'Hot cafeteria tea',
    restaurant: 'Tuck Shop',
    meal: 'Breakfast',
    category: 'Snacks',
    prepMinutes: 5,
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Sandwich',
    price: 'Rs 75',
    description: 'Fresh grilled sandwich',
    restaurant: 'Tuck Shop',
    meal: 'Lunch',
    category: 'Snacks',
    prepMinutes: 12,
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Burger',
    price: 'Rs 120',
    description: 'Loaded cafeteria burger',
    restaurant: 'Tuck Shop',
    meal: 'Lunch',
    category: 'Lunch',
    prepMinutes: 18,
    isVeg: false,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'French Fries',
    price: 'Rs 85',
    description: 'Crispy salted fries',
    restaurant: 'Tuck Shop',
    meal: 'Lunch',
    category: 'Snacks',
    prepMinutes: 10,
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Noodles',
    price: 'Rs 130',
    description: 'Hot spicy noodles',
    restaurant: 'Tuck Shop',
    meal: 'Dinner',
    category: 'Dinner',
    prepMinutes: 24,
    isVeg: true,
    isAvailable: false,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
  _SearchFoodItem(
    name: 'Veg Roll',
    price: 'Rs 95',
    description: 'Fresh loaded veg roll',
    restaurant: 'Tuck Shop',
    meal: 'Dinner',
    category: 'Snacks',
    prepMinutes: 15,
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
  ),
];

const List<_DishData> _dishes = [
  _DishData(
    name: 'Paneer Wrap',
    description: 'Soft roti wrap with paneer, salad, and mild house sauce.',
    price: 'Rs 120',
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
    category: 'Lunch',
    restaurant: 'Tuck Shop',
    prepMinutes: 20,
    isVeg: true,
  ),
  _DishData(
    name: 'Veg Puff',
    description: 'Flaky baked puff filled with lightly spiced vegetables.',
    price: 'Rs 45',
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
    category: 'Snacks',
    restaurant: 'Tuck Shop',
    prepMinutes: 18,
    isVeg: true,
  ),
  _DishData(
    name: 'South Indian Thali',
    description: 'Balanced lunch plate with rice, sambar, poriyal, and curd.',
    price: 'Rs 110',
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
    category: 'Lunch',
    restaurant: 'Meal Counter',
    prepMinutes: 25,
    isVeg: true,
  ),
  _DishData(
    name: 'Chapati Kurma',
    description: 'Warm chapatis served with homestyle vegetable kurma.',
    price: 'Rs 90',
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
    category: 'Dinner',
    restaurant: 'Meal Counter',
    prepMinutes: 24,
    isVeg: true,
  ),
  _DishData(
    name: 'Idli Sambar',
    description: 'Steamed idlis with sambar and coconut chutney.',
    price: 'Rs 60',
    imagePath: _EmployeeHomeFragmentState._mainFoodImage,
    category: 'Breakfast',
    restaurant: 'Meal Counter',
    prepMinutes: 15,
    isVeg: true,
  ),
];
