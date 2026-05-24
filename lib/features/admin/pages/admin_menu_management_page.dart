import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/features/admin/widgets/admin_shell.dart';
import 'package:pro_dine/features/employee/data/employee_order_store.dart';

class AdminMenuManagementPage extends StatefulWidget {
  const AdminMenuManagementPage({super.key});

  @override
  State<AdminMenuManagementPage> createState() =>
      _AdminMenuManagementPageState();
}

class _AdminMenuManagementPageState extends State<AdminMenuManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  final EmployeeOrderStore _orderStore = EmployeeOrderStore.instance;

  List<_CafeteriaMenu> get _cafeterias {
    return [
      _cafeteriaFor(
        name: 'Meal Counter',
        description: 'Breakfast, lunch, and dinner menu operations',
        totalItems: 24,
        activeItems: 22,
      ),
      _cafeteriaFor(
        name: 'Tuck Shop',
        description: 'Snacks, beverages, and quick food items',
        totalItems: 18,
        activeItems: 16,
      ),
    ];
  }

  _CafeteriaMenu _cafeteriaFor({
    required String name,
    required String description,
    required int totalItems,
    required int activeItems,
  }) {
    final todayOrders = _todayOrdersFor(name);
    final activeQueue = _activeOrdersFor(name);
    return _CafeteriaMenu(
      name: name,
      description: description,
      totalItems: totalItems,
      activeItems: activeItems,
      inactiveItems: totalItems - activeItems,
      todayOrders: todayOrders,
      status: _CafeteriaStatus.active,
      lastUpdated: activeQueue == 0 ? 'No live queue' : '$activeQueue active',
    );
  }

  List<_CafeteriaMenu> get _visibleCafeterias {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) return _cafeterias;

    return _cafeterias.where((cafeteria) {
      return cafeteria.name.toLowerCase().contains(query) ||
          cafeteria.description.toLowerCase().contains(query);
    }).toList();
  }

  int get _totalItems =>
      _cafeterias.fold<int>(0, (sum, item) => sum + item.totalItems);

  int get _activeItems =>
      _cafeterias.fold<int>(0, (sum, item) => sum + item.activeItems);

  int get _todayOrders =>
      _cafeterias.fold<int>(0, (sum, item) => sum + item.todayOrders);

  @override
  void initState() {
    super.initState();
    _orderStore.addListener(_handleOrdersChanged);
  }

  @override
  void dispose() {
    _orderStore.removeListener(_handleOrdersChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleOrdersChanged() {
    if (mounted) setState(() {});
  }

  int _todayOrdersFor(String cafeteria) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _orderStore.orders
        .where((order) =>
            order.shopName == cafeteria &&
            !order.createdAt.isBefore(start) &&
            order.createdAt.isBefore(end))
        .length;
  }

  int _activeOrdersFor(String cafeteria) {
    return _orderStore.orders
        .where((order) =>
            order.shopName == cafeteria &&
            order.status.toLowerCase() == 'ordered')
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _MenuTheme.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = _MenuLayout.fromWidth(constraints.maxWidth);

            return Column(
              children: [
                _MenuHeader(
                  layout: layout,
                  searchController: _searchController,
                  onSearchChanged: (_) => setState(() {}),
                  onMenuTap: () => AdminShell.openDrawer(context),
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
                          34,
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
                                  _MenuSummaryStrip(
                                    layout: layout,
                                    totalItems: _totalItems,
                                    activeItems: _activeItems,
                                    todayOrders: _todayOrders,
                                    cafeteriaCount: _cafeterias.length,
                                  ),
                                  SizedBox(height: layout.sectionGap),
                                  _SectionHeader(
                                    layout: layout,
                                    title: 'Select Cafeteria',
                                    subtitle:
                                        'Live cafeteria intent from employee orders.',
                                  ),
                                  SizedBox(height: layout.sectionGap),
                                  _CafeteriaGrid(
                                    layout: layout,
                                    cafeterias: _visibleCafeterias,
                                    onTap: () {
                                      context.push(AppRoutes.adminFoodItems);
                                    },
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

class _MenuTheme {
  const _MenuTheme._();

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

class _MenuLayout {
  const _MenuLayout({
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

  static _MenuLayout fromWidth(double width) {
    if (width >= 1180) {
      return const _MenuLayout(
        isDesktop: true,
        isTablet: false,
        maxContentWidth: 1240,
        pagePadding: 36,
        contentTopPadding: 28,
        topBarHeight: 88,
        sectionGap: 18,
        cardRadius: 22,
        cardPadding: 20,
        scale: 1,
      );
    }

    if (width >= 760) {
      return const _MenuLayout(
        isDesktop: false,
        isTablet: true,
        maxContentWidth: 760,
        pagePadding: 28,
        contentTopPadding: 24,
        topBarHeight: 90,
        sectionGap: 18,
        cardRadius: 22,
        cardPadding: 20,
        scale: 1,
      );
    }

    final scale = (width / 390).clamp(0.88, 1.0).toDouble();

    return _MenuLayout(
      isDesktop: false,
      isTablet: false,
      maxContentWidth: 430,
      pagePadding: width < 360 ? 14 : 16,
      contentTopPadding: 18,
      topBarHeight: 82 * scale,
      sectionGap: 16,
      cardRadius: 20,
      cardPadding: width < 360 ? 15 : 16,
      scale: scale,
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({
    required this.layout,
    required this.searchController,
    required this.onSearchChanged,
    required this.onMenuTap,
  });

  final _MenuLayout layout;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: layout.topBarHeight,
      decoration: const BoxDecoration(
        color: _MenuTheme.surface,
        border: Border(bottom: BorderSide(color: _MenuTheme.border, width: 1)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: layout.pagePadding),
            child: Row(
              children: [
                if (!layout.isDesktop) ...[
                  Material(
                    color: const Color(0xFFF1F0EE),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: onMenuTap,
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 46 * layout.scale,
                        height: 46 * layout.scale,
                        child: Icon(
                          Icons.menu_rounded,
                          color: _MenuTheme.text,
                          size: 26 * layout.scale,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14 * layout.scale),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menu Management',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _MenuTheme.text,
                          fontSize: layout.isDesktop ? 25 : 23.5 * layout.scale,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                      SizedBox(height: 5 * layout.scale),
                      Text(
                        'Control cafeteria menu items and availability',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _MenuTheme.muted,
                          fontSize: layout.isDesktop ? 13.5 : 13 * layout.scale,
                          height: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (layout.isDesktop) ...[
                  SizedBox(
                    width: 360,
                    child: _SearchField(
                      layout: layout,
                      controller: searchController,
                      onChanged: onSearchChanged,
                    ),
                  ),
                ] else
                  _CompactSearchButton(
                    layout: layout,
                    controller: searchController,
                    onChanged: onSearchChanged,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactSearchButton extends StatelessWidget {
  const _CompactSearchButton({
    required this.layout,
    required this.controller,
    required this.onChanged,
  });

  final _MenuLayout layout;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _MenuTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) {
              return _SearchBottomSheet(
                layout: layout,
                controller: controller,
                onChanged: onChanged,
              );
            },
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 46 * layout.scale,
          height: 46 * layout.scale,
          child: Icon(
            Icons.search_rounded,
            color: _MenuTheme.muted,
            size: 25 * layout.scale,
          ),
        ),
      ),
    );
  }
}

class _SearchBottomSheet extends StatelessWidget {
  const _SearchBottomSheet({
    required this.layout,
    required this.controller,
    required this.onChanged,
  });

  final _MenuLayout layout;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: const BoxDecoration(
          color: _MenuTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: _SearchField(
            layout: layout,
            controller: controller,
            onChanged: onChanged,
            autofocus: true,
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.layout,
    required this.controller,
    required this.onChanged,
    this.autofocus = false,
  });

  final _MenuLayout layout;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: layout.isDesktop ? 46 : 50 * layout.scale,
      decoration: BoxDecoration(
        color: _MenuTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _MenuTheme.border),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        cursorColor: _MenuTheme.red,
        style: TextStyle(
          color: _MenuTheme.text,
          fontSize: layout.isDesktop ? 13.5 : 13 * layout.scale,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _MenuTheme.muted,
            size: layout.isDesktop ? 22 : 21 * layout.scale,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                    FocusScope.of(context).unfocus();
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _MenuTheme.muted,
                    size: 20,
                  ),
                ),
          hintText: 'Search cafeterias',
          hintStyle: TextStyle(
            color: _MenuTheme.softText,
            fontSize: layout.isDesktop ? 13.5 : 13 * layout.scale,
            fontWeight: FontWeight.w600,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14 * layout.scale,
            vertical: 13 * layout.scale,
          ),
        ),
      ),
    );
  }
}

class _MenuSummaryStrip extends StatelessWidget {
  const _MenuSummaryStrip({
    required this.layout,
    required this.totalItems,
    required this.activeItems,
    required this.todayOrders,
    required this.cafeteriaCount,
  });

  final _MenuLayout layout;
  final int totalItems;
  final int activeItems;
  final int todayOrders;
  final int cafeteriaCount;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryData(
        label: 'Cafeterias',
        value: cafeteriaCount.toString(),
        icon: Icons.storefront_rounded,
        fg: _MenuTheme.red,
        bg: _MenuTheme.redSoft,
      ),
      _SummaryData(
        label: 'Total Items',
        value: totalItems.toString(),
        icon: Icons.restaurant_menu_rounded,
        fg: _MenuTheme.text,
        bg: const Color(0xFFF1F0EE),
      ),
      _SummaryData(
        label: 'Active Items',
        value: activeItems.toString(),
        icon: Icons.check_rounded,
        fg: _MenuTheme.green,
        bg: _MenuTheme.greenSoft,
      ),
      _SummaryData(
        label: 'Orders Today',
        value: todayOrders.toString(),
        icon: Icons.receipt_long_rounded,
        fg: _MenuTheme.amber,
        bg: _MenuTheme.amberSoft,
      ),
    ];

    if (layout.isDesktop || layout.isTablet) {
      return Row(
        children: items.map((item) {
          final isLast = item == items.last;
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
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.45,
      ),
      itemBuilder: (_, index) {
        return _SummaryTile(layout: layout, data: items[index]);
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.layout, required this.data});

  final _MenuLayout layout;
  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(13 * layout.scale),
      decoration: BoxDecoration(
        color: _MenuTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _MenuTheme.border),
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
                    color: _MenuTheme.text,
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
                    color: _MenuTheme.muted,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.layout,
    required this.title,
    required this.subtitle,
  });

  final _MenuLayout layout;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _MenuTheme.text,
                  fontSize: layout.isDesktop ? 21 : 20 * layout.scale,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6 * layout.scale),
              Text(
                subtitle,
                maxLines: layout.isDesktop ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _MenuTheme.muted,
                  fontSize: layout.isDesktop ? 13 : 12.5 * layout.scale,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CafeteriaGrid extends StatelessWidget {
  const _CafeteriaGrid({
    required this.layout,
    required this.cafeterias,
    required this.onTap,
  });

  final _MenuLayout layout;
  final List<_CafeteriaMenu> cafeterias;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (cafeterias.isEmpty) {
      return _EmptyState(layout: layout);
    }

    if (layout.isDesktop) {
      return GridView.builder(
        itemCount: cafeterias.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 1.95,
        ),
        itemBuilder: (_, index) {
          return _CafeteriaCard(
            layout: layout,
            cafeteria: cafeterias[index],
            onTap: onTap,
          );
        },
      );
    }

    return Column(
      children: cafeterias.map((cafeteria) {
        return Padding(
          padding: EdgeInsets.only(bottom: 14 * layout.scale),
          child: _CafeteriaCard(
            layout: layout,
            cafeteria: cafeteria,
            onTap: onTap,
          ),
        );
      }).toList(),
    );
  }
}

class _CafeteriaCard extends StatelessWidget {
  const _CafeteriaCard({
    required this.layout,
    required this.cafeteria,
    required this.onTap,
  });

  final _MenuLayout layout;
  final _CafeteriaMenu cafeteria;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeRate = cafeteria.totalItems == 0
        ? 0.0
        : cafeteria.activeItems / cafeteria.totalItems;

    return Material(
      color: _MenuTheme.surface,
      borderRadius: BorderRadius.circular(layout.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        child: Container(
          padding: EdgeInsets.all(layout.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(layout.cardRadius),
            border: Border.all(color: _MenuTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: layout.isDesktop ? 48 : 46 * layout.scale,
                    height: layout.isDesktop ? 48 : 46 * layout.scale,
                    decoration: BoxDecoration(
                      color: _MenuTheme.redSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      color: _MenuTheme.red,
                      size: layout.isDesktop ? 23 : 22 * layout.scale,
                    ),
                  ),
                  SizedBox(width: 13 * layout.scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cafeteria.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _MenuTheme.text,
                            fontSize: layout.isDesktop ? 18 : 17 * layout.scale,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.35,
                          ),
                        ),
                        SizedBox(height: 5 * layout.scale),
                        Text(
                          cafeteria.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _MenuTheme.muted,
                            fontSize:
                                layout.isDesktop ? 12.5 : 12 * layout.scale,
                            height: 1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(status: cafeteria.status, layout: layout),
                ],
              ),
              SizedBox(height: 16 * layout.scale),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: activeRate.clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFF0EFED),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    _MenuTheme.green,
                  ),
                ),
              ),
              SizedBox(height: 8 * layout.scale),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${cafeteria.activeItems} of ${cafeteria.totalItems} items active',
                      style: TextStyle(
                        color: _MenuTheme.muted,
                        fontSize: layout.isDesktop ? 12 : 11.5 * layout.scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    cafeteria.lastUpdated,
                    style: TextStyle(
                      color: _MenuTheme.softText,
                      fontSize: layout.isDesktop ? 12 : 11.5 * layout.scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16 * layout.scale),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10 * layout.scale,
                mainAxisSpacing: 10 * layout.scale,
                childAspectRatio: layout.isDesktop ? 2.35 : 2.18,
                children: [
                  _MenuStatBox(
                    layout: layout,
                    label: 'Total Items',
                    value: cafeteria.totalItems.toString(),
                    color: _MenuTheme.text,
                  ),
                  _MenuStatBox(
                    layout: layout,
                    label: 'Active Items',
                    value: cafeteria.activeItems.toString(),
                    color: _MenuTheme.green,
                  ),
                  _MenuStatBox(
                    layout: layout,
                    label: 'Inactive',
                    value: cafeteria.inactiveItems.toString(),
                    color: _MenuTheme.redDark,
                  ),
                  _MenuStatBox(
                    layout: layout,
                    label: 'Orders Today',
                    value: cafeteria.todayOrders.toString(),
                    color: _MenuTheme.amber,
                  ),
                ],
              ),
              SizedBox(height: 16 * layout.scale),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _MenuTheme.text,
                        side: const BorderSide(color: _MenuTheme.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 13 * layout.scale,
                        ),
                      ),
                      child: Text(
                        'Manage Items',
                        style: TextStyle(
                          color: _MenuTheme.text,
                          fontSize: layout.isDesktop ? 13.5 : 13 * layout.scale,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10 * layout.scale),
                  Material(
                    color: _MenuTheme.red,
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(15),
                      child: SizedBox(
                        width: 48 * layout.scale,
                        height: 48 * layout.scale,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 21 * layout.scale,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.layout});

  final _CafeteriaStatus status;
  final _MenuLayout layout;

  @override
  Widget build(BuildContext context) {
    final active = status == _CafeteriaStatus.active;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * layout.scale,
        vertical: 7 * layout.scale,
      ),
      decoration: BoxDecoration(
        color: active ? _MenuTheme.greenSoft : _MenuTheme.redSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6 * layout.scale,
            height: 6 * layout.scale,
            decoration: BoxDecoration(
              color: active ? _MenuTheme.green : _MenuTheme.redDark,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6 * layout.scale),
          Text(
            active ? 'Active' : 'Inactive',
            style: TextStyle(
              color: active ? _MenuTheme.green : _MenuTheme.redDark,
              fontSize: layout.isDesktop ? 12 : 11.5 * layout.scale,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuStatBox extends StatelessWidget {
  const _MenuStatBox({
    required this.layout,
    required this.label,
    required this.value,
    required this.color,
  });

  final _MenuLayout layout;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 13 * layout.scale,
        vertical: 11 * layout.scale,
      ),
      decoration: BoxDecoration(
        color: _MenuTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _MenuTheme.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _MenuTheme.muted,
              fontSize: 11.5 * layout.scale,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7 * layout.scale),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 17 * layout.scale,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.layout});

  final _MenuLayout layout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 24 * layout.scale,
        vertical: 42 * layout.scale,
      ),
      decoration: BoxDecoration(
        color: _MenuTheme.surface,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        border: Border.all(color: _MenuTheme.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            color: _MenuTheme.softText,
            size: 46 * layout.scale,
          ),
          SizedBox(height: 14 * layout.scale),
          Text(
            'No cafeterias found',
            style: TextStyle(
              color: _MenuTheme.text,
              fontSize: 18 * layout.scale,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7 * layout.scale),
          Text(
            'Try searching with another cafeteria name.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _MenuTheme.muted,
              fontSize: 13 * layout.scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CafeteriaMenu {
  const _CafeteriaMenu({
    required this.name,
    required this.description,
    required this.totalItems,
    required this.activeItems,
    required this.inactiveItems,
    required this.todayOrders,
    required this.status,
    required this.lastUpdated,
  });

  final String name;
  final String description;
  final int totalItems;
  final int activeItems;
  final int inactiveItems;
  final int todayOrders;
  final _CafeteriaStatus status;
  final String lastUpdated;
}

enum _CafeteriaStatus { active }

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
