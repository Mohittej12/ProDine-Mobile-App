import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pro_dine/features/vendor/pages/vendor_add_food_page.dart';
import 'package:pro_dine/features/vendor/pages/vendor_edit_food_page.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_page_header.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_shell.dart';

class VendorFoodItemsPage extends StatefulWidget {
  const VendorFoodItemsPage({super.key});

  @override
  State<VendorFoodItemsPage> createState() => _VendorFoodItemsPageState();
}

class _VendorFoodItemsPageState extends State<VendorFoodItemsPage> {
  // Premium SaaS Color Palette
  static const Color _primaryRed = Color(0xFFE11D48); // Rose 600
  static const Color _bgCanvas = Color(0xFFF8FAFC); // Slate 50
  static const Color _surface = Colors.white;
  static const Color _textMain = Color(0xFF0F172A); // Slate 900
  static const Color _textMuted = Color(0xFF64748B); // Slate 500
  static const Color _borderSoft = Color(0xFFE2E8F0); // Slate 200
  static const Color _success = Color(0xFF10B981); // Emerald 500
  static const Color _warning = Color(0xFFF59E0B); // Amber 500

  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  bool _availableOnly = false;
  bool _outOfStockOnly = false;

  final List<_FoodItem> _items = [
    const _FoodItem(
      id: '1',
      name: 'Chicken Biryani',
      description: 'Aromatic basmati rice with tender chicken and spices',
      price: 180,
      category: 'Lunch',
      isAvailable: true,
      isVeg: false,
    ),
    const _FoodItem(
      id: '2',
      name: 'Veg Sandwich',
      description: 'Fresh vegetables with mayo and cheese',
      price: 60,
      category: 'Snacks',
      isAvailable: true,
      isVeg: true,
    ),
    const _FoodItem(
      id: '3',
      name: 'Margherita Pizza',
      description: 'Classic pizza with tomato sauce and mozzarella',
      price: 220,
      category: 'Fast Food',
      isAvailable: false,
      isVeg: true,
    ),
    const _FoodItem(
      id: '4',
      name: 'Cold Coffee',
      description: 'Refreshing iced coffee with whipped cream',
      price: 80,
      category: 'Beverages',
      isAvailable: true,
      isVeg: true,
    ),
    const _FoodItem(
      id: '5',
      name: 'Masala Dosa',
      description: 'Crispy dosa with potato filling and chutney',
      price: 120,
      category: 'Breakfast',
      isAvailable: true,
      isVeg: true,
    ),
  ];

  List<_FoodItem> get _filteredItems {
    final search = _query.trim().toLowerCase();

    return _items.where((item) {
      final matchesSearch =
          search.isEmpty ||
          item.name.toLowerCase().contains(search) ||
          item.description.toLowerCase().contains(search) ||
          item.category.toLowerCase().contains(search);

      final matchesAvailability =
          (!_availableOnly || item.isAvailable) &&
          (!_outOfStockOnly || !item.isAvailable);

      return matchesSearch && matchesAvailability;
    }).toList();
  }

  int get _availableCount => _items.where((item) => item.isAvailable).length;
  int get _outOfStockCount => _items.where((item) => !item.isAvailable).length;
  bool get _hasFilters => _availableOnly || _outOfStockOnly;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openMenu() {
    VendorShell.openDrawer(context);
  }

  Future<void> _openFilterSheet(_VendorFoodLayout layout) async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        layout: layout,
        availableOnly: _availableOnly,
        outOfStockOnly: _outOfStockOnly,
      ),
    );

    if (result != null) {
      setState(() {
        _availableOnly = result.availableOnly;
        _outOfStockOnly = result.outOfStockOnly;
      });
    }
  }

  void _openAddItemSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.94,
        child: const ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          child: VendorAddFoodPage(),
        ),
      ),
    );
  }

  void _editItem(_FoodItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.94,
        child: const ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          child: VendorEditFoodPage(),
        ),
      ),
    );
  }

  void _toggleAvailability(String id, bool value) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index] = _items[index].copyWith(isAvailable: value);
      }
    });
    _showSnack(value ? 'Item available' : 'Item marked out of stock');
  }

  Future<void> _deleteItem(_FoodItem item) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeleteConfirmSheet(itemName: item.name),
    );

    if (confirmed == true) {
      setState(() => _items.removeWhere((i) => i.id == item.id));
      _showSnack('${item.name} deleted');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _textMain,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(24),
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCanvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _VendorFoodLayout.fromWidth(constraints.maxWidth);

          return Column(
            children: [
              VendorPageHeader(
                title: 'Food Items',
                maxContentWidth: layout.maxContentWidth,
                horizontalPadding: layout.horizontalPadding,
                isDesktop: layout.isDesktop,
                scale: layout.scale,
                onMenuTap: _openMenu,
                trailingIcon: Icons.add_rounded,
                onTrailingTap: _openAddItemSheet,
              ),
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        layout.horizontalPadding,
                        layout.topPadding,
                        layout.horizontalPadding,
                        layout.bottomPadding,
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
                                _SearchBar(
                                  layout: layout,
                                  controller: _searchController,
                                  query: _query,
                                  hasFilters: _hasFilters,
                                  onChanged: (v) => setState(() => _query = v),
                                  onClear: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  onFilterTap: () => _openFilterSheet(layout),
                                ),
                                SizedBox(height: layout.cardGap),
                                _StatsGrid(
                                  layout: layout,
                                  total: _items.length,
                                  available: _availableCount,
                                  outOfStock: _outOfStockCount,
                                ),
                                if (_hasFilters) ...[
                                  SizedBox(height: 16 * layout.scale),
                                  _ActiveFilters(
                                    availableOnly: _availableOnly,
                                    outOfStockOnly: _outOfStockOnly,
                                  ),
                                ],
                                SizedBox(height: layout.sectionGap),
                                _SectionHeader(
                                  title: 'Menu Items',
                                  count: _filteredItems.length,
                                  layout: layout,
                                ),
                                SizedBox(height: layout.cardGap),
                                _FoodItemsGrid(
                                  layout: layout,
                                  items: _filteredItems,
                                  onToggle: _toggleAvailability,
                                  onEdit: _editItem,
                                  onDelete: _deleteItem,
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
    );
  }
}

// ─── Layout Configuration ───

class _VendorFoodLayout {
  final bool isDesktop;
  final bool isTablet;
  final double maxContentWidth;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double scale;
  final double sectionGap;
  final double cardGap;
  final double gridGap;
  final int gridColumns;

  const _VendorFoodLayout({
    required this.isDesktop,
    required this.isTablet,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.scale,
    required this.sectionGap,
    required this.cardGap,
    required this.gridGap,
    required this.gridColumns,
  });

  static _VendorFoodLayout fromWidth(double width) {
    if (width >= 1100) {
      return const _VendorFoodLayout(
        isDesktop: true,
        isTablet: false,
        maxContentWidth: 1080,
        horizontalPadding: 40,
        topPadding: 32,
        bottomPadding: 64,
        scale: 1.0,
        sectionGap: 36,
        cardGap: 24,
        gridGap: 24,
        gridColumns: 2,
      );
    }
    if (width >= 760) {
      return const _VendorFoodLayout(
        isDesktop: false,
        isTablet: true,
        maxContentWidth: 720,
        horizontalPadding: 32,
        topPadding: 24,
        bottomPadding: 56,
        scale: 1.0,
        sectionGap: 32,
        cardGap: 20,
        gridGap: 20,
        gridColumns: 2,
      );
    }
    final scale = (width / 390).clamp(0.9, 1.1);
    return _VendorFoodLayout(
      isDesktop: false,
      isTablet: false,
      maxContentWidth: 430,
      horizontalPadding: width < 360 ? 16 : 20,
      topPadding: 20,
      bottomPadding: 100,
      scale: scale,
      sectionGap: 28,
      cardGap: 16,
      gridGap: 16,
      gridColumns: 1,
    );
  }
}

// ─── Components ───

class _SearchBar extends StatefulWidget {
  final _VendorFoodLayout layout;
  final TextEditingController controller;
  final String query;
  final bool hasFilters;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;

  const _SearchBar({
    required this.layout,
    required this.controller,
    required this.query,
    required this.hasFilters,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
  });

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
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
    final scale = widget.layout.scale;
    return Container(
      height: 52 * scale,
      decoration: BoxDecoration(
        color: _VendorFoodItemsPageState._surface,
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: _isFocused
              ? _VendorFoodItemsPageState._primaryRed
              : _VendorFoodItemsPageState._borderSoft,
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _VendorFoodItemsPageState._textMain.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 16 * scale),
          Icon(
            Icons.search_rounded,
            color: _isFocused
                ? _VendorFoodItemsPageState._primaryRed
                : _VendorFoodItemsPageState._textMuted,
            size: 22 * scale,
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: widget.controller,
              onChanged: widget.onChanged,
              style: TextStyle(
                color: _VendorFoodItemsPageState._textMain,
                fontSize: 15 * scale,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search items...',
                hintStyle: TextStyle(
                  color: _VendorFoodItemsPageState._textMuted.withOpacity(0.7),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hoverColor: Colors.transparent,
                fillColor: Colors.transparent,
                filled: true,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.query.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 20 * scale,
                color: _VendorFoodItemsPageState._textMuted,
              ),
              onPressed: widget.onClear,
            ),
          Container(
            width: 1,
            height: 24 * scale,
            color: _VendorFoodItemsPageState._borderSoft,
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onFilterTap,
              borderRadius: BorderRadius.circular(16 * scale),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: widget.hasFilters
                          ? _VendorFoodItemsPageState._primaryRed
                          : _VendorFoodItemsPageState._textMuted,
                      size: 22 * scale,
                    ),
                    if (widget.hasFilters)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8 * scale,
                          height: 8 * scale,
                          decoration: const BoxDecoration(
                            color: _VendorFoodItemsPageState._primaryRed,
                            shape: BoxShape.circle,
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
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final _VendorFoodLayout layout;
  final int total;
  final int available;
  final int outOfStock;

  const _StatsGrid({
    required this.layout,
    required this.total,
    required this.available,
    required this.outOfStock,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = layout.cardGap;
        final width = (constraints.maxWidth - spacing * 2) / 3;

        return Row(
          children: [
            SizedBox(
              width: width,
              child: _StatCard(
                layout: layout,
                label: 'Total Items',
                value: '$total',
                icon: Icons.inventory_2_rounded,
                color: _VendorFoodItemsPageState._textMain,
              ),
            ),
            SizedBox(width: spacing),
            SizedBox(
              width: width,
              child: _StatCard(
                layout: layout,
                label: 'Available',
                value: '$available',
                icon: Icons.check_circle_rounded,
                color: _VendorFoodItemsPageState._success,
              ),
            ),
            SizedBox(width: spacing),
            SizedBox(
              width: width,
              child: _StatCard(
                layout: layout,
                label: 'Out of Stock',
                value: '$outOfStock',
                icon: Icons.warning_rounded,
                color: _VendorFoodItemsPageState._primaryRed,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final _VendorFoodLayout layout;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.layout,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: _VendorFoodItemsPageState._surface,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: _VendorFoodItemsPageState._borderSoft),
        boxShadow: [
          BoxShadow(
            color: _VendorFoodItemsPageState._textMain.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8 * scale),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
                child: Icon(icon, color: color, size: 18 * scale),
              ),
            ],
          ),
          SizedBox(height: 16 * scale),
          Text(
            value,
            style: TextStyle(
              color: _VendorFoodItemsPageState._textMain,
              fontSize: 24 * scale,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _VendorFoodItemsPageState._textMuted,
              fontSize: 12 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  final bool availableOnly;
  final bool outOfStockOnly;

  const _ActiveFilters({
    required this.availableOnly,
    required this.outOfStockOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (availableOnly) const _FilterChip(label: 'Available only'),
        if (outOfStockOnly) const _FilterChip(label: 'Out of stock only'),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;

  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _VendorFoodItemsPageState._primaryRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _VendorFoodItemsPageState._primaryRed.withOpacity(0.2),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _VendorFoodItemsPageState._primaryRed,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final _VendorFoodLayout layout;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: _VendorFoodItemsPageState._textMain,
            fontSize: 18 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(width: 12 * scale),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10 * scale,
            vertical: 4 * scale,
          ),
          decoration: BoxDecoration(
            color: _VendorFoodItemsPageState._borderSoft,
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: _VendorFoodItemsPageState._textMuted,
              fontSize: 12 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _FoodItemsGrid extends StatelessWidget {
  final _VendorFoodLayout layout;
  final List<_FoodItem> items;
  final void Function(String, bool) onToggle;
  final ValueChanged<_FoodItem> onEdit;
  final ValueChanged<_FoodItem> onDelete;

  const _FoodItemsGrid({
    required this.layout,
    required this.items,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: _VendorFoodItemsPageState._textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: TextStyle(
                color: _VendorFoodItemsPageState._textMain,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.min(layout.gridColumns, items.length);
        final spacing = layout.gridGap;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: _FoodItemCard(
                layout: layout,
                item: item,
                onToggle: (v) => onToggle(item.id, v),
                onEdit: () => onEdit(item),
                onDelete: () => onDelete(item),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FoodItemCard extends StatelessWidget {
  final _VendorFoodLayout layout;
  final _FoodItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FoodItemCard({
    required this.layout,
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: _VendorFoodItemsPageState._surface,
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(color: _VendorFoodItemsPageState._borderSoft),
        boxShadow: [
          BoxShadow(
            color: _VendorFoodItemsPageState._textMain.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      foregroundDecoration: item.isAvailable
          ? null
          : BoxDecoration(
              color: _VendorFoodItemsPageState._surface.withOpacity(0.4),
              borderRadius: BorderRadius.circular(24 * scale),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FoodThumbnail(item: item, scale: scale),
          SizedBox(width: 16 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _VendorFoodItemsPageState._textMain,
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    _ActionMenu(
                      onEdit: onEdit,
                      onDelete: onDelete,
                      scale: scale,
                    ),
                  ],
                ),
                SizedBox(height: 4 * scale),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _VendorFoodItemsPageState._textMuted,
                    fontSize: 13 * scale,
                    height: 1.3,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 12 * scale),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₹${item.price}',
                      style: TextStyle(
                        color: _VendorFoodItemsPageState._textMain,
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _CustomToggle(
                      value: item.isAvailable,
                      onChanged: onToggle,
                      scale: scale,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodThumbnail extends StatelessWidget {
  final _FoodItem item;
  final double scale;

  const _FoodThumbnail({required this.item, required this.scale});

  @override
  Widget build(BuildContext context) {
    final size = 80.0 * scale;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: item.isVeg
              ? [
                  const Color(0xFFD1FAE5),
                  const Color(0xFFA7F3D0),
                ] // Emerald lights
              : [
                  const Color(0xFFFFEDD5),
                  const Color(0xFFFDBA74),
                ], // Orange lights
        ),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: _VendorFoodItemsPageState._textMain.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          item.isVeg ? Icons.eco_rounded : Icons.restaurant_rounded,
          color: item.isVeg
              ? _VendorFoodItemsPageState._success
              : _VendorFoodItemsPageState._warning,
          size: 32 * scale,
        ),
      ),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final double scale;

  const _ActionMenu({
    required this.onEdit,
    required this.onDelete,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SmallIconButton(
          icon: Icons.edit_rounded,
          color: _VendorFoodItemsPageState._textMuted,
          onTap: onEdit,
          scale: scale,
        ),
        SizedBox(width: 4 * scale),
        _SmallIconButton(
          icon: Icons.delete_outline_rounded,
          color: _VendorFoodItemsPageState._primaryRed,
          onTap: onDelete,
          scale: scale,
        ),
      ],
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double scale;

  const _SmallIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8 * scale),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8 * scale),
        child: Padding(
          padding: EdgeInsets.all(6 * scale),
          child: Icon(icon, color: color, size: 18 * scale),
        ),
      ),
    );
  }
}

class _CustomToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double scale;

  const _CustomToggle({
    required this.value,
    required this.onChanged,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44 * scale,
        height: 24 * scale,
        padding: EdgeInsets.all(2 * scale),
        decoration: BoxDecoration(
          color: value
              ? _VendorFoodItemsPageState._success
              : _VendorFoodItemsPageState._borderSoft,
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20 * scale,
            height: 20 * scale,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final _VendorFoodLayout layout;
  final bool availableOnly;
  final bool outOfStockOnly;

  const _FilterSheet({
    required this.layout,
    required this.availableOnly,
    required this.outOfStockOnly,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool _availableOnly = widget.availableOnly;
  late bool _outOfStockOnly = widget.outOfStockOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: _VendorFoodItemsPageState._surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _VendorFoodItemsPageState._textMain,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _availableOnly = false;
                      _outOfStockOnly = false;
                    });
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: _VendorFoodItemsPageState._primaryRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _FilterRow(
              title: 'Available Only',
              value: _availableOnly,
              onChanged: (v) => setState(() {
                _availableOnly = v;
                if (v) _outOfStockOnly = false;
              }),
            ),
            const SizedBox(height: 16),
            _FilterRow(
              title: 'Out of Stock Only',
              value: _outOfStockOnly,
              onChanged: (v) => setState(() {
                _outOfStockOnly = v;
                if (v) _availableOnly = false;
              }),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _VendorFoodItemsPageState._primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(
                  context,
                  _FilterResult(
                    availableOnly: _availableOnly,
                    outOfStockOnly: _outOfStockOnly,
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FilterRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _VendorFoodItemsPageState._textMain,
          ),
        ),
        _CustomToggle(value: value, onChanged: onChanged, scale: 1.0),
      ],
    );
  }
}

class _DeleteConfirmSheet extends StatelessWidget {
  final String itemName;

  const _DeleteConfirmSheet({required this.itemName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: _VendorFoodItemsPageState._surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _VendorFoodItemsPageState._primaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: _VendorFoodItemsPageState._primaryRed,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Delete Item',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _VendorFoodItemsPageState._textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete "$itemName"? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _VendorFoodItemsPageState._textMuted,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                        color: _VendorFoodItemsPageState._borderSoft,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: _VendorFoodItemsPageState._textMain,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _VendorFoodItemsPageState._primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.w700),
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

// ─── Data Models ───

class _FoodItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String category;
  final bool isAvailable;
  final bool isVeg;

  const _FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.isAvailable,
    required this.isVeg,
  });

  _FoodItem copyWith({
    String? id,
    String? name,
    String? description,
    int? price,
    String? category,
    bool? isAvailable,
    bool? isVeg,
  }) {
    return _FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      isVeg: isVeg ?? this.isVeg,
    );
  }
}

class _FilterResult {
  final bool availableOnly;
  final bool outOfStockOnly;

  const _FilterResult({
    required this.availableOnly,
    required this.outOfStockOnly,
  });
}
