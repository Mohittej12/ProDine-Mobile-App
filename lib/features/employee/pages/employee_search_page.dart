part of 'employee_home_page.dart';

class _HomeSearchPage extends StatefulWidget {
  const _HomeSearchPage({
    required this.category,
    required this.dietFilter,
    required this.maxAmount,
  });

  final String category;
  final _DietFilter dietFilter;
  final int maxAmount;

  @override
  State<_HomeSearchPage> createState() => _HomeSearchPageState();
}

class _HomeSearchPageState extends State<_HomeSearchPage>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _cartIconKey = GlobalKey();

  late String _category = widget.category;
  late _DietFilter _dietFilter = widget.dietFilter;
  late int _maxAmount = widget.maxAmount;
  String _query = '';
  int _cartCount = EmployeeCartStore.instance.itemCount;

  // ── Cart bounce ──
  late final AnimationController _cartBounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _cartBounceAnim = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.28, end: 0.92), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.04), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 20),
  ]).animate(
    CurvedAnimation(
      parent: _cartBounceController,
      curve: Curves.easeOutCubic,
    ),
  );

  // ── Entrance orchestration ──
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    reverseDuration: const Duration(milliseconds: 180),
  );

  late final Animation<double> _backButtonAnim = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0.0, 0.50, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _actionsAnim = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0.08, 0.55, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _chipsAnim = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0.18, 0.65, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _gridAnim = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0.22, 1.0, curve: Curves.easeOutCubic),
  );
  late final Animation<Offset> _gridSlideAnim = Tween<Offset>(
    begin: const Offset(0, 0.035),
    end: Offset.zero,
  ).animate(_gridAnim);

  bool get _hasActiveFilters =>
      _category != 'All' || _dietFilter != _DietFilter.all || _maxAmount != 250;

  List<_SearchFoodItem> get _results {
    final q = _query.trim().toLowerCase();

    return _searchFoodItems.where((item) {
      final matchesSearch = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q) ||
          item.restaurant.toLowerCase().contains(q) ||
          item.meal.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q);
      final matchesCategory = _category == 'All' ||
          item.meal == _category ||
          item.category == _category;
      final matchesDiet = _dietFilter == _DietFilter.all ||
          (_dietFilter == _DietFilter.veg && item.isVeg) ||
          (_dietFilter == _DietFilter.nonVeg && !item.isVeg);
      final matchesAmount = _amountFromPrice(item.price) <= _maxAmount;

      return matchesSearch &&
          matchesCategory &&
          matchesDiet &&
          matchesAmount;
    }).toList();
  }

  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _entranceController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _cartBounceController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _openFilters(_HomeLayout layout) async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
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

  Future<void> _close() async {
    if (_isClosing) return;
    _isClosing = true;

    await _entranceController.reverse();
    if (!mounted) return;

    Navigator.pop(
      context,
      _FilterResult(
        category: _category,
        dietFilter: _dietFilter,
        maxAmount: _maxAmount,
      ),
    );
  }

  void _addToCart(_SearchFoodItem item, Offset sourceOffset) {
    if (!item.isAvailable) return;

    EmployeeCartStore.instance.addItem(
      id: _cartIdFor(item),
      name: item.name,
      shopName: item.restaurant,
      meal: item.meal,
      price: _priceToInt(item.price),
      imagePath: item.imagePath,
    );

    _flyToCart(sourceOffset, item.imagePath);
  }

  Future<void> _openCart() async {
    await showEmployeeCartSwitcher(
      context,
      onViewMenu: (restaurantName) {
        Navigator.pop(
          context,
          _FilterResult(
            category: _category,
            dietFilter: _dietFilter,
            maxAmount: _maxAmount,
          ),
        );
      },
    );
  }

  String _cartIdFor(_SearchFoodItem item) {
    final restaurant = item.restaurant.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '-',
        );
    final meal = item.meal.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final name = item.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return '$restaurant-$meal-$name';
  }

  int _priceToInt(String price) {
    final digits = RegExp(r'\d+').allMatches(price).map((m) => m.group(0)!);
    return int.tryParse(digits.join()) ?? 0;
  }

  void _flyToCart(Offset sourceOffset, String imagePath) {
    final cartBox =
        _cartIconKey.currentContext?.findRenderObject() as RenderBox?;

    if (cartBox == null || !cartBox.attached) {
      _cartBounceController.forward(from: 0);
      setState(() => _cartCount = EmployeeCartStore.instance.itemCount);
      return;
    }

    final cartPos = cartBox.localToGlobal(
      Offset(cartBox.size.width / 2, cartBox.size.height / 2),
    );

    final overlay = Overlay.of(context);
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );

    final curvedAnim = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) {
        return AnimatedBuilder(
          animation: curvedAnim,
          builder: (context, child) {
            final t = curvedAnim.value;

            final dx = sourceOffset.dx + (cartPos.dx - sourceOffset.dx) * t;
            final arcHeight = -118.0 * (1 - math.pow(2 * t - 1, 2));
            final dy = sourceOffset.dy +
                (cartPos.dy - sourceOffset.dy) * t +
                arcHeight;

            final scale = 1.0 - (t * 0.66);
            final opacity = (1.0 - math.pow(t, 2.35)).clamp(0.0, 1.0);

            return Positioned(
              left: dx - 22 * scale,
              top: dy - 22 * scale,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _EmployeeHomeFragmentState._primaryRed
                              .withOpacity(0.34),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_1, _2, _3) => const Icon(
                          Icons.restaurant_rounded,
                          color: _EmployeeHomeFragmentState._primaryRed,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(entry);
    controller.forward().then((_) {
      entry.remove();
      controller.dispose();
      if (!mounted) return;
      _cartBounceController.forward(from: 0);
      setState(() => _cartCount = EmployeeCartStore.instance.itemCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: _EmployeeHomeFragmentState._screenBg,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = _HomeLayout.fromWidth(constraints.maxWidth);
              final bottomSafe = MediaQuery.paddingOf(context).bottom;

              return Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          layout.horizontalPadding,
                          layout.topPadding,
                          layout.horizontalPadding,
                          12 * layout.scale,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: layout.maxContentWidth,
                            ),
                            child: Column(
                              children: [
                                _SearchPageBar(
                                  layout: layout,
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  query: _query,
                                  hasActiveFilters: _hasActiveFilters,
                                  onBack: _close,
                                  onChanged: (value) {
                                    setState(() => _query = value);
                                  },
                                  onClear: () {
                                    _controller.clear();
                                    setState(() => _query = '');
                                  },
                                  onFilterTap: () => _openFilters(layout),
                                  onCartTap: _openCart,
                                  cartIconKey: _cartIconKey,
                                  cartCount: _cartCount,
                                  cartBounceAnim: _cartBounceAnim,
                                  backButtonAnim: _backButtonAnim,
                                  actionsAnim: _actionsAnim,
                                ),
                                if (_hasActiveFilters) ...[
                                  SizedBox(height: 10 * layout.scale),
                                  FadeTransition(
                                    opacity: _chipsAnim,
                                    child: _SearchFilterChips(
                                      category: _category,
                                      dietFilter: _dietFilter,
                                      maxAmount: _maxAmount,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SlideTransition(
                          position: _gridSlideAnim,
                          child: FadeTransition(
                            opacity: _gridAnim,
                            child: CustomScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              slivers: [
                                SliverPadding(
                                  padding: EdgeInsets.fromLTRB(
                                    layout.horizontalPadding,
                                    0,
                                    layout.horizontalPadding,
                                    110 + bottomSafe,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: layout.maxContentWidth,
                                        ),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          switchInCurve: Curves.easeOutCubic,
                                          switchOutCurve: Curves.easeInCubic,
                                          child: _results.isEmpty
                                              ? _SearchEmptyState(
                                                  query: _query,
                                                )
                                              : _SearchFoodGrid(
                                                  key: ValueKey(
                                                    '$_query-$_category-$_dietFilter-$_maxAmount',
                                                  ),
                                                  layout: layout,
                                                  items: _results,
                                                  onAddToCart: _addToCart,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  EmployeeCartOverlay(
                    bottomOffset: bottomSafe + 18,
                    horizontalPadding: layout.horizontalPadding,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SearchPageBar extends StatelessWidget {
  const _SearchPageBar({
    required this.layout,
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.hasActiveFilters,
    required this.onBack,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
    required this.onCartTap,
    required this.cartIconKey,
    required this.cartCount,
    required this.cartBounceAnim,
    required this.backButtonAnim,
    required this.actionsAnim,
  });

  final _HomeLayout layout;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final bool hasActiveFilters;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;
  final VoidCallback onCartTap;
  final GlobalKey cartIconKey;
  final int cartCount;
  final Animation<double> cartBounceAnim;
  final Animation<double> backButtonAnim;
  final Animation<double> actionsAnim;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;
    final height = layout.isDesktop ? 52.0 : 48 * scale;

    return Row(
      children: [
        // Back button — fades in
        FadeTransition(
          opacity: backButtonAnim,
          child: _SearchHeaderIcon(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
            scale: scale,
          ),
        ),
        SizedBox(width: 8 * scale),
        // Search bar — appears instantly (no animation)
        Expanded(
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14 * scale),
              border: Border.all(color: const Color(0xFFD9D7E8), width: 1.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(width: 13 * scale),
                Icon(
                  Icons.search_rounded,
                  color: const Color(0xFFB7B4CF),
                  size: 21 * scale,
                ),
                SizedBox(width: 9 * scale),
                Expanded(
                  child: TextField(
                    focusNode: focusNode,
                    controller: controller,
                    onChanged: onChanged,
                    onTapOutside: (_) => focusNode.unfocus(),
                    textInputAction: TextInputAction.search,
                    cursorColor: query.isEmpty
                        ? Colors.transparent
                        : _EmployeeHomeFragmentState._primaryRed,
                    cursorWidth: query.isEmpty ? 0 : 1.7,
                    showCursor: query.isNotEmpty,
                    scrollPadding: EdgeInsets.zero,
                    style: TextStyle(
                      color: _EmployeeHomeFragmentState._textDark,
                      fontSize: 14 * scale,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      hintText: 'Search food items',
                      hintStyle: TextStyle(
                        color: Color(0xFF98A2B3),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (query.isNotEmpty)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onClear,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF98A2B3),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(width: 8 * scale),
        // Filter + Cart — fade in
        FadeTransition(
          opacity: actionsAnim,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _SearchHeaderIcon(
                    icon: Icons.tune_rounded,
                    onTap: onFilterTap,
                    scale: scale,
                    active: hasActiveFilters,
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 7.5,
                        height: 7.5,
                        decoration: const BoxDecoration(
                          color: _EmployeeHomeFragmentState._primaryRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 4 * scale),
              ScaleTransition(
                scale: cartBounceAnim,
                child: _SearchHeaderIcon(
                  key: cartIconKey,
                  icon: Icons.shopping_bag_outlined,
                  onTap: onCartTap,
                  scale: scale,
                  badgeLabel: cartCount > 9 ? '9+' : '$cartCount',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchHeaderIcon extends StatelessWidget {
  const _SearchHeaderIcon({
    super.key,
    required this.icon,
    required this.onTap,
    required this.scale,
    this.active = false,
    this.badgeLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double scale;
  final bool active;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final size = 36 * scale;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkResponse(
        onTap: onTap,
        radius: 22 * scale,
        containedInkWell: false,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: active
                    ? _EmployeeHomeFragmentState._primaryRed
                    : _EmployeeHomeFragmentState._textDark,
                size:
                    icon == Icons.arrow_back_rounded ? 23 * scale : 24 * scale,
              ),
              if (badgeLabel != null)
                Positioned(
                  top: 3 * scale,
                  right: 1 * scale,
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: 16 * scale,
                      minHeight: 16 * scale,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 4 * scale),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _EmployeeHomeFragmentState._primaryRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeLabel!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5 * scale,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchFilterChips extends StatelessWidget {
  const _SearchFilterChips({
    required this.category,
    required this.dietFilter,
    required this.maxAmount,
  });

  final String category;
  final _DietFilter dietFilter;
  final int maxAmount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (category != 'All') _ActiveChip(label: category),
        if (dietFilter != _DietFilter.all)
          _ActiveChip(label: dietFilter == _DietFilter.veg ? 'Veg' : 'Non-Veg'),
        if (maxAmount != 250) _ActiveChip(label: 'Up to Rs $maxAmount'),
      ],
    );
  }
}

class _SearchFoodGrid extends StatelessWidget {
  const _SearchFoodGrid({
    super.key,
    required this.layout,
    required this.items,
    required this.onAddToCart,
  });

  final _HomeLayout layout;
  final List<_SearchFoodItem> items;
  final void Function(_SearchFoodItem item, Offset sourceOffset) onAddToCart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = layout.isDesktop
            ? 4
            : layout.isTablet
                ? 3
                : 2;
        final spacing = layout.isDesktop ? 20.0 : 14.0 * layout.scale;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final imageHeight = (itemWidth * 0.64).clamp(102.0, 150.0);
        final itemHeight = imageHeight + (itemWidth < 150 ? 90 : 96);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < items.length; index++)
              TweenAnimationBuilder<double>(
                key: ValueKey(items[index].name),
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 180 + index * 22),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  width: itemWidth,
                  height: itemHeight,
                  child: _SearchFoodCard(
                    item: items[index],
                    layout: layout,
                    imageHeight: imageHeight,
                    itemWidth: itemWidth,
                    onAddToCart: onAddToCart,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SearchFoodCard extends StatefulWidget {
  const _SearchFoodCard({
    required this.item,
    required this.layout,
    required this.imageHeight,
    required this.itemWidth,
    required this.onAddToCart,
  });

  final _SearchFoodItem item;
  final _HomeLayout layout;
  final double imageHeight;
  final double itemWidth;
  final void Function(_SearchFoodItem item, Offset sourceOffset) onAddToCart;

  @override
  State<_SearchFoodCard> createState() => _SearchFoodCardState();
}

class _SearchFoodCardState extends State<_SearchFoodCard> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final favoriteId = _favoriteIdFor(item);
    final scale = widget.layout.scale;
    final radius = widget.layout.isDesktop || widget.layout.isTablet
        ? 22.0
        : widget.itemWidth < 150
            ? 19.0
            : 21.0;

    return Opacity(
      opacity: item.isAvailable ? 1 : 0.62,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: const Color(0xFFEDEFF3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.055),
              blurRadius: 18,
              offset: const Offset(0, 9),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: widget.imageHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    item.imagePath,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFFFF2EC),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.restaurant_rounded,
                          color: _EmployeeHomeFragmentState._primaryRed,
                          size: 32,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 8 * scale,
                    left: 8 * scale,
                    child: _SearchDietBadge(isVeg: item.isVeg, scale: scale),
                  ),
                  Positioned(
                    top: 8 * scale,
                    right: 8 * scale,
                    child: ValueListenableBuilder<List<EmployeeFavoriteItem>>(
                      valueListenable: EmployeeFavoritesStore.instance,
                      builder: (context, favorites, _) {
                        final favorite = favorites.any(
                          (item) => item.id == favoriteId,
                        );

                        return _SearchCircleIconButton(
                          scale: scale,
                          icon: favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: favorite
                              ? _EmployeeHomeFragmentState._primaryRed
                              : _EmployeeHomeFragmentState._textDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            EmployeeFavoritesStore.instance.toggle(
                              EmployeeFavoriteItem(
                                id: favoriteId,
                                name: item.name,
                                price: item.price,
                                description: item.description,
                                restaurant: item.restaurant,
                                meal: item.meal,
                                category: item.category,
                                rating: '4.6',
                                isVeg: item.isVeg,
                                isAvailable: item.isAvailable,
                                imagePath: item.imagePath,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 8 * scale,
                    right: 8 * scale,
                    child: _SearchAddButton(
                      enabled: item.isAvailable,
                      onAdd: (offset) => widget.onAddToCart(item, offset),
                    ),
                  ),
                  if (!item.isAvailable)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.22),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Unavailable',
                            style: TextStyle(
                              color: _EmployeeHomeFragmentState._textDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  11.5 * scale,
                  9 * scale,
                  11.5 * scale,
                  8.5 * scale,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _EmployeeHomeFragmentState._textDark,
                        fontSize: widget.layout.isDesktop ? 16 : 14.2 * scale,
                        height: 1.04,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4.5 * scale),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _EmployeeHomeFragmentState._textMuted,
                        fontSize: widget.layout.isDesktop ? 12 : 10.9 * scale,
                        height: 1.12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _EmployeeHomeFragmentState._primaryRed,
                        fontSize: widget.layout.isDesktop ? 16 : 14.8 * scale,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _favoriteIdFor(_SearchFoodItem item) {
    return '${item.restaurant}-${item.meal}-${item.name}'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  }
}

class _SearchDietBadge extends StatelessWidget {
  const _SearchDietBadge({required this.isVeg, required this.scale});

  final bool isVeg;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 7.5 * scale,
        vertical: 5 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: isVeg ? const Color(0xFF12B76A) : const Color(0xFFFF7A00),
            size: 7.4 * scale,
          ),
          SizedBox(width: 5 * scale),
          Text(
            isVeg ? 'Veg' : 'Non-Veg',
            style: TextStyle(
              color: _EmployeeHomeFragmentState._textDark,
              fontSize: 9.4 * scale,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchCircleIconButton extends StatelessWidget {
  const _SearchCircleIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.scale,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final size = 34 * scale;

    return Material(
      color: Colors.white.withOpacity(0.96),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 18.5 * scale, color: color),
        ),
      ),
    );
  }
}

class _SearchAddButton extends StatefulWidget {
  const _SearchAddButton({required this.enabled, required this.onAdd});

  final bool enabled;
  final ValueChanged<Offset> onAdd;

  @override
  State<_SearchAddButton> createState() => _SearchAddButtonState();
}

class _SearchAddButtonState extends State<_SearchAddButton>
    with TickerProviderStateMixin {
  final GlobalKey _buttonKey = GlobalKey();
  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  late final Animation<double> _scaleAnimation = Tween<double>(
    begin: 1.0,
    end: 0.88,
  ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeInOut));

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        key: _buttonKey,
        color: widget.enabled
            ? _EmployeeHomeFragmentState._primaryRed
            : Colors.grey,
        shape: const CircleBorder(),
        elevation: 7,
        shadowColor: _EmployeeHomeFragmentState._primaryRed.withValues(
          alpha: 0.28,
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.enabled
              ? () async {
                  HapticFeedback.lightImpact();

                  await _pressController.forward();
                  await _pressController.reverse();

                  final box = _buttonKey.currentContext?.findRenderObject()
                      as RenderBox?;
                  if (box == null || !box.attached) return;

                  final center = box.localToGlobal(
                    Offset(box.size.width / 2, box.size.height / 2),
                  );

                  widget.onAdd(center);
                }
              : null,
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(Icons.add_rounded, color: Colors.white, size: 25),
          ),
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: _EmployeeHomeFragmentState._primaryRed,
            size: 36,
          ),
          const SizedBox(height: 10),
          const Text(
            'No items found',
            style: TextStyle(
              color: _EmployeeHomeFragmentState._textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            query.isEmpty
                ? 'Start typing to search available food items.'
                : 'Try another item, meal type, or filter.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _EmployeeHomeFragmentState._textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
