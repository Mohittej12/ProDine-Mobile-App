import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/features/employee/data/employee_cart_store.dart';
import 'package:pro_dine/features/employee/data/employee_favorites_store.dart';

class EmployeeFavoritesPage extends StatefulWidget {
  const EmployeeFavoritesPage({super.key});

  @override
  State<EmployeeFavoritesPage> createState() => _EmployeeFavoritesPageState();
}

class _EmployeeFavoritesPageState extends State<EmployeeFavoritesPage> {
  static const Color _primaryRed = Color(0xFFFF1F1F);
  static const Color _darkText = Color(0xFF101828);
  static const Color _mutedText = Color(0xFF667085);
  static const Color _screenBg = Color(0xFFFFFCF8);
  static const Color _softBorder = Color(0xFFEDEFF3);
  static const Color _green = Color(0xFF12B76A);

  String _selectedMeal = 'All';

  List<EmployeeFavoriteItem> _filtered(List<EmployeeFavoriteItem> items) {
    if (_selectedMeal == 'All') return items;
    return items.where((item) => item.meal == _selectedMeal).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = _FavoritesLayout.fromWidth(constraints.maxWidth);
            final bottomSafe = MediaQuery.paddingOf(context).bottom;

            return ValueListenableBuilder<List<EmployeeFavoriteItem>>(
              valueListenable: EmployeeFavoritesStore.instance,
              builder: (context, favorites, _) {
                final items = _filtered(favorites);

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        layout.horizontalPadding,
                        layout.topPadding,
                        layout.horizontalPadding,
                        32 + bottomSafe,
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
                                _FavoritesHeader(
                                  layout: layout,
                                  totalCount: favorites.length,
                                  visibleCount: items.length,
                                  onBack: () {
                                    HapticFeedback.selectionClick();
                                    if (context.canPop()) context.pop();
                                  },
                                ),
                                SizedBox(height: layout.sectionGap),
                                _MealFilter(
                                  layout: layout,
                                  selectedMeal: _selectedMeal,
                                  onChanged: (meal) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedMeal = meal);
                                  },
                                ),
                                SizedBox(height: layout.sectionGap),
                                if (items.isEmpty)
                                  _FavoritesEmptyState(
                                    hasFavorites: favorites.isNotEmpty,
                                    onOpenMenu: () =>
                                        context.push(AppRoutes.employeeMenu),
                                  )
                                else
                                  _FavoritesGrid(
                                    layout: layout,
                                    items: items,
                                    onRemove: _removeFavorite,
                                    onAddToCart: _addToCart,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _removeFavorite(EmployeeFavoriteItem item) {
    HapticFeedback.selectionClick();
    EmployeeFavoritesStore.instance.remove(item.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _darkText,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(
            '${item.name} removed from favorites',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
  }

  void _addToCart(EmployeeFavoriteItem item) {
    if (!item.isAvailable) return;

    HapticFeedback.lightImpact();
    EmployeeCartStore.instance.addItem(
      id: item.id,
      name: item.name,
      shopName: item.restaurant,
      meal: item.meal,
      price: _priceToInt(item.price),
      imagePath: item.imagePath,
    );
  }

  int _priceToInt(String price) {
    final digits = RegExp(r'\d+').allMatches(price).map((m) => m.group(0)!);
    return int.tryParse(digits.join()) ?? 0;
  }
}

class _FavoritesLayout {
  const _FavoritesLayout({
    required this.isDesktop,
    required this.isTablet,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.topPadding,
    required this.sectionGap,
    required this.gridColumns,
    required this.gridSpacing,
    required this.scale,
  });

  final bool isDesktop;
  final bool isTablet;
  final double maxContentWidth;
  final double horizontalPadding;
  final double topPadding;
  final double sectionGap;
  final int gridColumns;
  final double gridSpacing;
  final double scale;

  static _FavoritesLayout fromWidth(double width) {
    if (width >= 1180) {
      return const _FavoritesLayout(
        isDesktop: true,
        isTablet: false,
        maxContentWidth: 1180,
        horizontalPadding: 48,
        topPadding: 28,
        sectionGap: 22,
        gridColumns: 4,
        gridSpacing: 22,
        scale: 1,
      );
    }

    if (width >= 760) {
      return const _FavoritesLayout(
        isDesktop: false,
        isTablet: true,
        maxContentWidth: 760,
        horizontalPadding: 34,
        topPadding: 24,
        sectionGap: 20,
        gridColumns: 3,
        gridSpacing: 20,
        scale: 1,
      );
    }

    return _FavoritesLayout(
      isDesktop: false,
      isTablet: false,
      maxContentWidth: 430,
      horizontalPadding: width < 370 ? 14 : 16,
      topPadding: 18,
      sectionGap: 18,
      gridColumns: 2,
      gridSpacing: width < 370 ? 12 : 14,
      scale: width < 370 ? 0.92 : 1,
    );
  }

  double itemImageHeight(double itemWidth) {
    return (itemWidth * 0.64).clamp(100.0, isDesktop ? 158.0 : 142.0);
  }

  double itemHeight(double itemWidth) {
    return itemImageHeight(itemWidth) + (itemWidth < 150 ? 102 : 112);
  }
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader({
    required this.layout,
    required this.totalCount,
    required this.visibleCount,
    required this.onBack,
  });

  final _FavoritesLayout layout;
  final int totalCount;
  final int visibleCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _HeaderIcon(icon: Icons.arrow_back_rounded, onTap: onBack),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 8 * scale,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFEF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$visibleCount of $totalCount',
                style: TextStyle(
                  color: _EmployeeFavoritesPageState._primaryRed,
                  fontSize: 12.5 * scale,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 18 * scale),
        Text(
          'Favorites',
          style: TextStyle(
            color: _EmployeeFavoritesPageState._darkText,
            fontSize: layout.isDesktop ? 42 : 32 * scale,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.9,
          ),
        ),
        SizedBox(height: 8 * scale),
        Text(
          'Saved dishes from your cafeteria menu, ready for quick ordering.',
          style: TextStyle(
            color: _EmployeeFavoritesPageState._mutedText,
            fontSize: layout.isDesktop ? 15 : 13.2 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: _EmployeeFavoritesPageState._darkText),
        ),
      ),
    );
  }
}

class _MealFilter extends StatelessWidget {
  const _MealFilter({
    required this.layout,
    required this.selectedMeal,
    required this.onChanged,
  });

  static const List<String> _tabs = ['All', 'Breakfast', 'Lunch', 'Dinner'];

  final _FavoritesLayout layout;
  final String selectedMeal;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return SizedBox(
      height: layout.isDesktop ? 44 : 40 * scale,
      child: Row(
        children: _tabs.map((meal) {
          final selected = selectedMeal == meal;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: meal == _tabs.last ? 0 : 7),
              child: InkWell(
                onTap: () => onChanged(meal),
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? _EmployeeFavoritesPageState._primaryRed
                        : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? _EmployeeFavoritesPageState._primaryRed
                          : _EmployeeFavoritesPageState._softBorder,
                    ),
                  ),
                  child: Text(
                    meal,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : _EmployeeFavoritesPageState._mutedText,
                      fontSize: 12.4 * scale,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FavoritesGrid extends StatelessWidget {
  const _FavoritesGrid({
    required this.layout,
    required this.items,
    required this.onRemove,
    required this.onAddToCart,
  });

  final _FavoritesLayout layout;
  final List<EmployeeFavoriteItem> items;
  final ValueChanged<EmployeeFavoriteItem> onRemove;
  final ValueChanged<EmployeeFavoriteItem> onAddToCart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.min(layout.gridColumns, items.length);
        final spacing = layout.gridSpacing;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final itemHeight = layout.itemHeight(itemWidth);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: _FavoriteCard(
                item: item,
                layout: layout,
                itemWidth: itemWidth,
                onRemove: () => onRemove(item),
                onAdd: () => onAddToCart(item),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.item,
    required this.layout,
    required this.itemWidth,
    required this.onRemove,
    required this.onAdd,
  });

  final EmployeeFavoriteItem item;
  final _FavoritesLayout layout;
  final double itemWidth;
  final VoidCallback onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;
    final imageHeight = layout.itemImageHeight(itemWidth);

    return Opacity(
      opacity: item.isAvailable ? 1 : 0.62,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22 * scale),
          border: Border.all(color: _EmployeeFavoritesPageState._softBorder),
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
              height: imageHeight,
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
                          color: _EmployeeFavoritesPageState._primaryRed,
                          size: 32,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 8 * scale,
                    left: 8 * scale,
                    child: _DietBadge(isVeg: item.isVeg, scale: scale),
                  ),
                  Positioned(
                    top: 8 * scale,
                    right: 8 * scale,
                    child: _CircleAction(
                      icon: Icons.favorite_rounded,
                      color: _EmployeeFavoritesPageState._primaryRed,
                      onTap: onRemove,
                      scale: scale,
                    ),
                  ),
                  Positioned(
                    bottom: 8 * scale,
                    right: 8 * scale,
                    child: _AddButton(enabled: item.isAvailable, onTap: onAdd),
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
                        color: _EmployeeFavoritesPageState._darkText,
                        fontSize: layout.isDesktop ? 16 : 14.2 * scale,
                        height: 1.04,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.32,
                      ),
                    ),
                    SizedBox(height: 4.5 * scale),
                    Text(
                      '${item.restaurant} - ${item.meal}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _EmployeeFavoritesPageState._mutedText,
                        fontSize: layout.isDesktop ? 12 : 10.9 * scale,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3.5 * scale),
                    Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _EmployeeFavoritesPageState._mutedText,
                        fontSize: layout.isDesktop ? 11.5 : 10.3 * scale,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _EmployeeFavoritesPageState._primaryRed,
                        fontSize: layout.isDesktop ? 16 : 14.8 * scale,
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
}

class _DietBadge extends StatelessWidget {
  const _DietBadge({required this.isVeg, required this.scale});

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
            color: isVeg
                ? _EmployeeFavoritesPageState._green
                : const Color(0xFFFF7A00),
            size: 7.4 * scale,
          ),
          SizedBox(width: 5 * scale),
          Text(
            isVeg ? 'Veg' : 'Non-Veg',
            style: TextStyle(
              color: _EmployeeFavoritesPageState._darkText,
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

class _CircleAction extends StatelessWidget {
  const _CircleAction({
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

class _AddButton extends StatelessWidget {
  const _AddButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? _EmployeeFavoritesPageState._primaryRed : Colors.grey,
      shape: const CircleBorder(),
      elevation: 7,
      shadowColor: _EmployeeFavoritesPageState._primaryRed.withValues(
        alpha: 0.28,
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.add_rounded, color: Colors.white, size: 25),
        ),
      ),
    );
  }
}

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState({
    required this.hasFavorites,
    required this.onOpenMenu,
  });

  final bool hasFavorites;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _EmployeeFavoritesPageState._softBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.favorite_border_rounded,
            color: _EmployeeFavoritesPageState._primaryRed,
            size: 38,
          ),
          const SizedBox(height: 12),
          Text(
            hasFavorites ? 'No items in this meal' : 'No favorites yet',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _EmployeeFavoritesPageState._darkText,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFavorites
                ? 'Switch meal filters to view your saved dishes.'
                : 'Tap the heart on menu items to save them here.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _EmployeeFavoritesPageState._mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!hasFavorites) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: 190,
              height: 48,
              child: ElevatedButton(
                onPressed: onOpenMenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _EmployeeFavoritesPageState._primaryRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Browse Menu',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
