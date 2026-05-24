import 'package:flutter/material.dart';
import 'package:pro_dine/features/admin/widgets/admin_shell.dart';
import 'package:pro_dine/features/vendor/pages/vendor_add_food_page.dart';
import 'package:pro_dine/features/vendor/pages/vendor_edit_food_page.dart';

class AdminFoodItemsPage extends StatefulWidget {
  const AdminFoodItemsPage({super.key});

  @override
  State<AdminFoodItemsPage> createState() => _AdminFoodItemsPageState();
}

class _AdminFoodItemsPageState extends State<AdminFoodItemsPage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';

  final List<_FoodItem> _items = [
    _FoodItem(
      id: 'FD-001',
      name: 'Chicken Biryani',
      description: 'Aromatic basmati rice with tender chicken and spices',
      price: 180,
      category: 'Lunch',
      imagePath: 'assets/images/auth_login_header.png',
      isAvailable: true,
    ),
    _FoodItem(
      id: 'FD-002',
      name: 'Veg Sandwich',
      description: 'Fresh vegetables with mayo and cheese',
      price: 60,
      category: 'Snacks',
      imagePath: 'assets/images/auth_login_header.png',
      isAvailable: true,
    ),
    _FoodItem(
      id: 'FD-003',
      name: 'Margherita Pizza',
      description: 'Classic pizza with tomato sauce and mozzarella',
      price: 220,
      category: 'Lunch',
      imagePath: 'assets/images/auth_login_header.png',
      isAvailable: false,
    ),
    _FoodItem(
      id: 'FD-004',
      name: 'Cold Coffee',
      description: 'Refreshing iced coffee with whipped cream',
      price: 80,
      category: 'Beverages',
      imagePath: 'assets/images/auth_login_header.png',
      isAvailable: true,
    ),
    _FoodItem(
      id: 'FD-005',
      name: 'Masala Dosa',
      description: 'Crispy dosa with potato filling and chutney',
      price: 120,
      category: 'Breakfast',
      imagePath: 'assets/images/auth_login_header.png',
      isAvailable: true,
    ),
  ];

  List<_FoodItem> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();

    return _items.where((item) {
      final matchesSearch =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);

      final matchesFilter =
          _selectedFilter == 'All' ||
          (_selectedFilter == 'Available' && item.isAvailable) ||
          (_selectedFilter == 'Out of Stock' && !item.isAvailable) ||
          item.category == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get _availableCount => _items.where((item) => item.isAvailable).length;

  int get _outOfStockCount => _items.where((item) => !item.isAvailable).length;

  int get _totalValue {
    return _items.fold<int>(0, (sum, item) => sum + item.price);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleAvailability(String id, bool value) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index == -1) return;
      _items[index] = _items[index].copyWith(isAvailable: value);
    });
  }

  void _deleteItem(_FoodItem item) {
    setState(() {
      _items.removeWhere((food) => food.id == item.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openFilterSheet(_FoodLayout layout) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _FilterBottomSheet(
          selectedFilter: _selectedFilter,
          onChanged: (value) {
            setState(() => _selectedFilter = value);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _openDeleteConfirmation(_FoodItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _DeleteConfirmationSheet(
          item: item,
          onDelete: () {
            Navigator.pop(context);
            _deleteItem(item);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FoodTheme.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = _FoodLayout.fromWidth(constraints.maxWidth);

            return Column(
              children: [
                _Header(
                  layout: layout,
                  onMenuTap: () => AdminShell.openDrawer(context),
                  onAddTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => SizedBox(
                        height: MediaQuery.of(context).size.height * 0.94,
                        child: const ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: VendorAddFoodPage(),
                        ),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          layout.pagePadding,
                          layout.contentTopPadding,
                          layout.pagePadding,
                          36,
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
                                  _SearchAndFilter(
                                    layout: layout,
                                    controller: _searchController,
                                    selectedFilter: _selectedFilter,
                                    onChanged: (_) => setState(() {}),
                                    onFilterTap: () => _openFilterSheet(layout),
                                  ),
                                  SizedBox(height: layout.sectionGap),
                                  _SummaryStrip(
                                    layout: layout,
                                    total: _items.length,
                                    available: _availableCount,
                                    outOfStock: _outOfStockCount,
                                    totalValue: _totalValue,
                                  ),
                                  SizedBox(height: layout.sectionGap),
                                  _FilterChips(
                                    layout: layout,
                                    selectedFilter: _selectedFilter,
                                    onChanged: (value) {
                                      setState(() => _selectedFilter = value);
                                    },
                                  ),
                                  SizedBox(height: layout.sectionGap),
                                  _FoodContent(
                                    layout: layout,
                                    items: _visibleItems,
                                    onToggle: _toggleAvailability,
                                    onEdit: (_) {
                                      showModalBottomSheet<void>(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) => SizedBox(
                                          height:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.94,
                                          child: const ClipRRect(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(24),
                                            ),
                                            child: VendorEditFoodPage(),
                                          ),
                                        ),
                                      );
                                    },
                                    onDelete: _openDeleteConfirmation,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FoodTheme {
  const _FoodTheme._();

  static const Color canvas = Color(0xFFF7F7F5);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFFBFBFA);
  static const Color border = Color(0xFFEAE8E4);

  static const Color red = Color(0xFFFF1F1F);
  static const Color redDark = Color(0xFFE01818);
  static const Color redSoft = Color(0xFFFFEEEE);

  static const Color green = Color(0xFF138A45);
  static const Color greenSoft = Color(0xFFEAF8EF);

  static const Color amber = Color(0xFFFF8A1E);
  static const Color amberSoft = Color(0xFFFFF3E8);

  static const Color text = Color(0xFF151827);
  static const Color muted = Color(0xFF77726E);
  static const Color softText = Color(0xFF9B9690);
}

class _FoodLayout {
  const _FoodLayout({
    required this.isDesktop,
    required this.isTablet,
    required this.maxContentWidth,
    required this.pagePadding,
    required this.contentTopPadding,
    required this.topBarHeight,
    required this.sectionGap,
    required this.cardRadius,
    required this.cardPadding,
    required this.scale,
  });

  final bool isDesktop;
  final bool isTablet;
  final double maxContentWidth;
  final double pagePadding;
  final double contentTopPadding;
  final double topBarHeight;
  final double sectionGap;
  final double cardRadius;
  final double cardPadding;
  final double scale;

  static _FoodLayout fromWidth(double width) {
    if (width >= 1180) {
      return const _FoodLayout(
        isDesktop: true,
        isTablet: false,
        maxContentWidth: 1240,
        pagePadding: 36,
        contentTopPadding: 28,
        topBarHeight: 86,
        sectionGap: 18,
        cardRadius: 22,
        cardPadding: 18,
        scale: 1,
      );
    }

    if (width >= 760) {
      return const _FoodLayout(
        isDesktop: false,
        isTablet: true,
        maxContentWidth: 760,
        pagePadding: 28,
        contentTopPadding: 24,
        topBarHeight: 86,
        sectionGap: 18,
        cardRadius: 22,
        cardPadding: 18,
        scale: 1,
      );
    }

    final scale = (width / 390).clamp(0.86, 1.0).toDouble();

    return _FoodLayout(
      isDesktop: false,
      isTablet: false,
      maxContentWidth: 430,
      pagePadding: width < 360 ? 14 : 16,
      contentTopPadding: 18,
      topBarHeight: 78 * scale,
      sectionGap: 14,
      cardRadius: 20,
      cardPadding: width < 360 ? 13 : 14,
      scale: scale,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.layout,
    required this.onMenuTap,
    required this.onAddTap,
  });

  final _FoodLayout layout;
  final VoidCallback onMenuTap;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: layout.topBarHeight,
      decoration: const BoxDecoration(
        color: _FoodTheme.surface,
        border: Border(bottom: BorderSide(color: _FoodTheme.border, width: 1)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: layout.pagePadding),
            child: Row(
              children: [
                Material(
                  color: const Color(0xFFF1F0EE),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: onMenuTap,
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: layout.isDesktop ? 48 : 44 * layout.scale,
                      height: layout.isDesktop ? 48 : 44 * layout.scale,
                      child: Icon(
                        Icons.menu_rounded,
                        color: _FoodTheme.text,
                        size: layout.isDesktop ? 28 : 25 * layout.scale,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14 * layout.scale),
                Expanded(
                  child: Text(
                    'Food Items',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _FoodTheme.text,
                      fontSize: layout.isDesktop ? 25 : 23 * layout.scale,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),
                ),
                Material(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: onAddTap,
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: layout.isDesktop ? 48 : 44 * layout.scale,
                      height: layout.isDesktop ? 48 : 44 * layout.scale,
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: layout.isDesktop ? 28 : 25 * layout.scale,
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

class _SearchAndFilter extends StatefulWidget {
  const _SearchAndFilter({
    required this.layout,
    required this.controller,
    required this.selectedFilter,
    required this.onChanged,
    required this.onFilterTap,
  });

  final _FoodLayout layout;
  final TextEditingController controller;
  final String selectedFilter;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  @override
  State<_SearchAndFilter> createState() => _SearchAndFilterState();
}

class _SearchAndFilterState extends State<_SearchAndFilter> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.layout.isDesktop ? 54 : 58 * widget.layout.scale,
      decoration: BoxDecoration(
        color: _FoodTheme.surface,
        borderRadius: BorderRadius.circular(widget.layout.isDesktop ? 18 : 20),
        border: Border.all(
          color: _isFocused ? _FoodTheme.red : _FoodTheme.border,
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 16 * widget.layout.scale),
          Icon(
            Icons.search_rounded,
            color: _isFocused ? _FoodTheme.red : _FoodTheme.muted,
            size: widget.layout.isDesktop ? 25 : 25 * widget.layout.scale,
          ),
          SizedBox(width: 10 * widget.layout.scale),
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: widget.controller,
              onChanged: widget.onChanged,
              cursorColor: _FoodTheme.red,
              style: TextStyle(
                color: _FoodTheme.text,
                fontSize: widget.layout.isDesktop
                    ? 14
                    : 14 * widget.layout.scale,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Search for items...',
                hintStyle: TextStyle(
                  color: const Color(0xFF9CA3AF),
                  fontSize: widget.layout.isDesktop
                      ? 14
                      : 14 * widget.layout.scale,
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            IconButton(
              onPressed: () {
                widget.controller.clear();
                widget.onChanged('');
                FocusScope.of(context).unfocus();
              },
              icon: const Icon(
                Icons.close_rounded,
                color: _FoodTheme.muted,
                size: 20,
              ),
            ),
          Material(
            color: widget.selectedFilter == 'All'
                ? Colors.transparent
                : _FoodTheme.redSoft,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: widget.onFilterTap,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: widget.layout.isDesktop ? 48 : 46 * widget.layout.scale,
                height: widget.layout.isDesktop ? 48 : 46 * widget.layout.scale,
                child: Icon(
                  Icons.tune_rounded,
                  color: widget.selectedFilter == 'All'
                      ? const Color(0xFF9CA3AF)
                      : _FoodTheme.red,
                  size: widget.layout.isDesktop ? 24 : 23 * widget.layout.scale,
                ),
              ),
            ),
          ),
          SizedBox(width: 6 * widget.layout.scale),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.layout,
    required this.total,
    required this.available,
    required this.outOfStock,
    required this.totalValue,
  });

  final _FoodLayout layout;
  final int total;
  final int available;
  final int outOfStock;
  final int totalValue;

  @override
  Widget build(BuildContext context) {
    final data = [
      _SummaryData(
        label: 'Total Items',
        value: total.toString(),
        icon: Icons.restaurant_menu_rounded,
        fg: _FoodTheme.text,
        bg: const Color(0xFFF1F0EE),
      ),
      _SummaryData(
        label: 'Available',
        value: available.toString(),
        icon: Icons.check_rounded,
        fg: _FoodTheme.green,
        bg: _FoodTheme.greenSoft,
      ),
      _SummaryData(
        label: 'Out of Stock',
        value: outOfStock.toString(),
        icon: Icons.close_rounded,
        fg: _FoodTheme.redDark,
        bg: _FoodTheme.redSoft,
      ),
      _SummaryData(
        label: 'Menu Value',
        value: _formatCurrencyShort(totalValue),
        icon: Icons.currency_rupee_rounded,
        fg: _FoodTheme.amber,
        bg: _FoodTheme.amberSoft,
      ),
    ];

    if (layout.isDesktop || layout.isTablet) {
      return Row(
        children: data.map((item) {
          final isLast = data.last == item;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 12),
              child: _SummaryTile(layout: layout, data: item),
            ),
          );
        }).toList(),
      );
    }

    return GridView.builder(
      itemCount: data.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.55,
      ),
      itemBuilder: (_, index) {
        return _SummaryTile(layout: layout, data: data[index]);
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.layout, required this.data});

  final _FoodLayout layout;
  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(13 * layout.scale),
      decoration: BoxDecoration(
        color: _FoodTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _FoodTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34 * layout.scale,
            height: 34 * layout.scale,
            decoration: BoxDecoration(
              color: data.bg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(data.icon, color: data.fg, size: 18 * layout.scale),
          ),
          SizedBox(width: 10 * layout.scale),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _FoodTheme.text,
                    fontSize: layout.isDesktop ? 18 : 16 * layout.scale,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5 * layout.scale),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _FoodTheme.muted,
                    fontSize: layout.isDesktop ? 12 : 11.5 * layout.scale,
                    height: 1,
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
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.layout,
    required this.selectedFilter,
    required this.onChanged,
  });

  final _FoodLayout layout;
  final String selectedFilter;
  final ValueChanged<String> onChanged;

  static const List<String> filters = [
    'All',
    'Available',
    'Out of Stock',
    'Breakfast',
    'Lunch',
    'Snacks',
    'Beverages',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40 * layout.scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 8 * layout.scale),
        itemBuilder: (_, index) {
          final filter = filters[index];
          final active = selectedFilter == filter;

          return Material(
            color: active ? _FoodTheme.red : _FoodTheme.surface,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () => onChanged(filter),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14 * layout.scale,
                  vertical: 9 * layout.scale,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: active ? _FoodTheme.red : _FoodTheme.border,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: active ? Colors.white : _FoodTheme.muted,
                    fontSize: 12.5 * layout.scale,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FoodContent extends StatelessWidget {
  const _FoodContent({
    required this.layout,
    required this.items,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final _FoodLayout layout;
  final List<_FoodItem> items;
  final void Function(String id, bool value) onToggle;
  final ValueChanged<_FoodItem> onEdit;
  final ValueChanged<_FoodItem> onDelete;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(layout: layout);
    }

    if (layout.isDesktop) {
      return _FoodDesktopTable(
        items: items,
        onToggle: onToggle,
        onEdit: onEdit,
        onDelete: onDelete,
      );
    }

    if (layout.isTablet) {
      return GridView.builder(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.95,
        ),
        itemBuilder: (_, index) {
          final item = items[index];
          return _FoodCard(
            layout: layout,
            item: item,
            onToggle: (value) => onToggle(item.id, value),
            onEdit: () => onEdit(item),
            onDelete: () => onDelete(item),
          );
        },
      );
    }

    return Column(
      children: items.map((item) {
        return Padding(
          padding: EdgeInsets.only(bottom: 14 * layout.scale),
          child: _FoodCard(
            layout: layout,
            item: item,
            onToggle: (value) => onToggle(item.id, value),
            onEdit: () => onEdit(item),
            onDelete: () => onDelete(item),
          ),
        );
      }).toList(),
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({
    required this.layout,
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final _FoodLayout layout;
  final _FoodItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final imageSize = layout.isTablet ? 76.0 : 74.0 * layout.scale;

    return Opacity(
      opacity: item.isAvailable ? 1 : 0.72,
      child: Container(
        padding: EdgeInsets.all(layout.cardPadding),
        decoration: BoxDecoration(
          color: _FoodTheme.surface,
          borderRadius: BorderRadius.circular(layout.cardRadius),
          border: Border.all(color: _FoodTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            _FoodImage(
              imagePath: item.imagePath,
              size: imageSize,
              isAvailable: item.isAvailable,
            ),
            SizedBox(width: 13 * layout.scale),
            Expanded(
              child: _FoodDetails(layout: layout, item: item),
            ),
            SizedBox(width: 10 * layout.scale),
            _FoodActions(
              layout: layout,
              isAvailable: item.isAvailable,
              onToggle: onToggle,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodImage extends StatelessWidget {
  const _FoodImage({
    required this.imagePath,
    required this.size,
    required this.isAvailable,
  });

  final String imagePath;
  final double size;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.asset(
            imagePath,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                width: size,
                height: size,
                color: const Color(0xFFF1F0EE),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: _FoodTheme.softText,
                ),
              );
            },
          ),
        ),
        if (!isAvailable)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.42),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Text(
                'OUT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FoodDetails extends StatelessWidget {
  const _FoodDetails({required this.layout, required this.item});

  final _FoodLayout layout;
  final _FoodItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _FoodTheme.text,
            fontSize: layout.isDesktop ? 16 : 15.5 * layout.scale,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 5 * layout.scale),
        Text(
          item.description,
          maxLines: layout.isTablet ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _FoodTheme.muted,
            fontSize: layout.isDesktop ? 12.5 : 12.2 * layout.scale,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 9 * layout.scale),
        Wrap(
          spacing: 8 * layout.scale,
          runSpacing: 6 * layout.scale,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '₹${item.price}',
              style: TextStyle(
                color: _FoodTheme.text,
                fontSize: layout.isDesktop ? 16 : 15.5 * layout.scale,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            _StatusPill(isAvailable: item.isAvailable, scale: layout.scale),
            _CategoryPill(label: item.category, scale: layout.scale),
          ],
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isAvailable, required this.scale});

  final bool isAvailable;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 5 * scale,
      ),
      decoration: BoxDecoration(
        color: isAvailable ? _FoodTheme.greenSoft : _FoodTheme.redSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAvailable ? 'Available' : 'Out of Stock',
        style: TextStyle(
          color: isAvailable ? _FoodTheme.green : _FoodTheme.redDark,
          fontSize: 11.5 * scale,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9 * scale, vertical: 5 * scale),
      decoration: BoxDecoration(
        color: _FoodTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _FoodTheme.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _FoodTheme.muted,
          fontSize: 11 * scale,
          height: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FoodActions extends StatelessWidget {
  const _FoodActions({
    required this.layout,
    required this.isAvailable,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final _FoodLayout layout;
  final bool isAvailable;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final buttonSize = layout.isDesktop ? 38.0 : 36.0 * layout.scale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AvailabilitySwitch(
          value: isAvailable,
          onChanged: onToggle,
          scale: layout.scale,
        ),
        SizedBox(height: 8 * layout.scale),
        _IconSquareButton(
          size: buttonSize,
          icon: Icons.edit_rounded,
          iconColor: const Color(0xFF4B5563),
          bgColor: const Color(0xFFF1F2F4),
          onTap: onEdit,
        ),
        SizedBox(height: 8 * layout.scale),
        _IconSquareButton(
          size: buttonSize,
          icon: Icons.delete_rounded,
          iconColor: _FoodTheme.red,
          bgColor: _FoodTheme.redSoft,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _AvailabilitySwitch extends StatelessWidget {
  const _AvailabilitySwitch({
    required this.value,
    required this.onChanged,
    required this.scale,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42 * scale,
      height: 26 * scale,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFF22C55E),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFFE5E7EB),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _IconSquareButton extends StatelessWidget {
  const _IconSquareButton({
    required this.size,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  final double size;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: iconColor, size: size * 0.52),
        ),
      ),
    );
  }
}

class _FoodDesktopTable extends StatelessWidget {
  const _FoodDesktopTable({
    required this.items,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final List<_FoodItem> items;
  final void Function(String id, bool value) onToggle;
  final ValueChanged<_FoodItem> onEdit;
  final ValueChanged<_FoodItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _FoodTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _FoodTheme.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: _FoodTheme.surfaceAlt,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(bottom: BorderSide(color: _FoodTheme.border)),
            ),
            child: const Row(
              children: [
                _TableHeader('Item', flex: 5),
                _TableHeader('Category', flex: 2),
                _TableHeader('Price', flex: 2),
                _TableHeader('Status', flex: 2),
                _TableHeader('Actions', flex: 3, alignRight: true),
              ],
            ),
          ),
          ...items.map((item) {
            return _FoodTableRow(
              item: item,
              onToggle: (value) => onToggle(item.id, value),
              onEdit: () => onEdit(item),
              onDelete: () => onDelete(item),
            );
          }),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.label, {required this.flex, this.alignRight = false});

  final String label;
  final int flex;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          color: _FoodTheme.muted,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FoodTableRow extends StatelessWidget {
  const _FoodTableRow({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final _FoodItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _FoodTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                _FoodImage(
                  imagePath: item.imagePath,
                  size: 52,
                  isAvailable: item.isAvailable,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FoodDetails(
                    layout: const _FoodLayout(
                      isDesktop: true,
                      isTablet: false,
                      maxContentWidth: 1240,
                      pagePadding: 36,
                      contentTopPadding: 28,
                      topBarHeight: 86,
                      sectionGap: 18,
                      cardRadius: 22,
                      cardPadding: 18,
                      scale: 1,
                    ),
                    item: item,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.category,
              style: const TextStyle(
                color: _FoodTheme.muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹${item.price}',
              style: const TextStyle(
                color: _FoodTheme.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusPill(isAvailable: item.isAvailable, scale: 1),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _AvailabilitySwitch(
                  value: item.isAvailable,
                  onChanged: onToggle,
                  scale: 1,
                ),
                const SizedBox(width: 10),
                _IconSquareButton(
                  size: 36,
                  icon: Icons.edit_rounded,
                  iconColor: const Color(0xFF4B5563),
                  bgColor: const Color(0xFFF1F2F4),
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                _IconSquareButton(
                  size: 36,
                  icon: Icons.delete_rounded,
                  iconColor: _FoodTheme.red,
                  bgColor: _FoodTheme.redSoft,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends StatelessWidget {
  const _FilterBottomSheet({
    required this.selectedFilter,
    required this.onChanged,
  });

  final String selectedFilter;
  final ValueChanged<String> onChanged;

  static const List<String> filters = [
    'All',
    'Available',
    'Out of Stock',
    'Breakfast',
    'Lunch',
    'Snacks',
    'Beverages',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: const BoxDecoration(
        color: _FoodTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: _FoodTheme.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Filter food items',
                style: TextStyle(
                  color: _FoodTheme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...filters.map((filter) {
              final active = filter == selectedFilter;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => onChanged(filter),
                title: Text(
                  filter,
                  style: TextStyle(
                    color: active ? _FoodTheme.red : _FoodTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                trailing: active
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: _FoodTheme.red,
                      )
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DeleteConfirmationSheet extends StatelessWidget {
  const _DeleteConfirmationSheet({required this.item, required this.onDelete});

  final _FoodItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: _FoodTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: _FoodTheme.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const Icon(
              Icons.delete_outline_rounded,
              color: _FoodTheme.red,
              size: 38,
            ),
            const SizedBox(height: 12),
            const Text(
              'Delete food item?',
              style: TextStyle(
                color: _FoodTheme.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'This will remove ${item.name} from the menu list.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _FoodTheme.muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _FoodTheme.text,
                      side: const BorderSide(color: _FoodTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _FoodTheme.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.layout});

  final _FoodLayout layout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 24 * layout.scale,
        vertical: 42 * layout.scale,
      ),
      decoration: BoxDecoration(
        color: _FoodTheme.surface,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        border: Border.all(color: _FoodTheme.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            color: _FoodTheme.softText,
            size: 46 * layout.scale,
          ),
          SizedBox(height: 14 * layout.scale),
          Text(
            'No food items found',
            style: TextStyle(
              color: _FoodTheme.text,
              fontSize: 18 * layout.scale,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7 * layout.scale),
          Text(
            'Try changing your search or selected filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _FoodTheme.muted,
              fontSize: 13 * layout.scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodItem {
  const _FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imagePath,
    required this.isAvailable,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final String category;
  final String imagePath;
  final bool isAvailable;

  _FoodItem copyWith({
    String? id,
    String? name,
    String? description,
    int? price,
    String? category,
    String? imagePath,
    bool? isAvailable,
  }) {
    return _FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class _SummaryData {
  const _SummaryData({
    required this.label,
    required this.value,
    required this.icon,
    required this.fg,
    required this.bg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color fg;
  final Color bg;
}

String _formatCurrencyShort(int value) {
  if (value >= 100000) {
    final lakhs = value / 100000;
    return '₹${lakhs.toStringAsFixed(lakhs >= 10 ? 0 : 1)}L';
  }

  if (value >= 1000) {
    final thousands = value / 1000;
    return '₹${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}K';
  }

  return '₹$value';
}
