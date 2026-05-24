import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/features/employee/data/employee_cart_store.dart';
import 'package:pro_dine/features/employee/data/employee_order_store.dart';
import 'package:pro_dine/features/employee/data/employee_profile_store.dart';

String _generateOrderId() {
  final random = Random();
  return 'ORD-${random.nextInt(9000) + 1000}';
}

String _formatEmployeeId(String rawId) {
  final digits = rawId.replaceAll(RegExp(r'\D'), '');
  final idDigits = digits.length >= 5
      ? digits.substring(digits.length - 5)
      : digits.padLeft(5, '0');
  return 'EMP-$idDigits';
}

class EmployeeCheckoutPage extends StatelessWidget {
  const EmployeeCheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CheckoutTheme.screenBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = _CheckoutLayout.fromWidth(constraints.maxWidth);

            return Column(
              children: [
                _CheckoutHeader(
                  layout: layout,
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    }
                  },
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: layout.maxContentWidth,
                      ),
                      child: layout.isDesktop
                          ? _DesktopCheckoutBody(
                              layout: layout,
                              onPayNow: () => _placeOrder(context),
                            )
                          : _MobileCheckoutBody(
                              layout: layout,
                              onPayNow: () => _placeOrder(context),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _placeOrder(BuildContext context) {
    final cartItems = EmployeeCartStore.instance.items;
    if (cartItems.isEmpty) return;

    final profile = EmployeeProfileStore.instance.value;
    final shopName = cartItems.first.shopName;
    final pickupSlot = EmployeeCartStore.instance.selectedPickupSlot(shopName);
    final subtotal = cartItems.fold<int>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final isTicketing = EmployeeCartStore.instance.isTicketingMode;
    final orderId = _generateOrderId();
    final employeeId = _formatEmployeeId(profile.employeeId);

    final order = EmployeeOrderEntry(
      orderId: orderId,
      employeeId: employeeId,
      userName: profile.name,
      shopId: shopName == 'Meal Counter' ? 'MEAL_COUNTER' : 'TUCK_SHOP',
      shopName: shopName,
      orderIntent: isTicketing ? 'Ticketing' : 'Pre-Order',
      items: cartItems
          .map(
            (item) => EmployeeOrderItem(
              name: item.name,
              meal: item.meal,
              quantity: item.quantity,
              price: item.price,
              imagePath: item.imagePath,
            ),
          )
          .toList(),
      amount: subtotal,
      status: 'ordered',
      pickupSlot: pickupSlot ?? '',
      isTicketing: isTicketing,
      createdAt: DateTime.now(),
    );

    EmployeeOrderStore.instance.addOrder(order);
    EmployeeCartStore.instance.clear();
    context.pushReplacement(
      AppRoutes.employeePaymentStatus,
      extra: order,
    );
  }
}

class _CheckoutTheme {
  const _CheckoutTheme._();

  static const Color primaryRed = Color(0xFFFF1F1F);
  static const Color textDark = Color(0xFF141827);
  static const Color textMuted = Color(0xFF667085);
  static const Color screenBg = Color(0xFFF6F7F9);
  static const Color cardBorder = Color(0xFFE6E8EC);
  static const Color divider = Color(0xFFE5E7EB);
}

class _CheckoutLayout {
  const _CheckoutLayout({
    required this.isDesktop,
    required this.isTablet,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.topPadding,
    required this.scale,
    required this.cardRadius,
    required this.cardPadding,
    required this.sectionGap,
  });

  final bool isDesktop;
  final bool isTablet;
  final double maxContentWidth;
  final double horizontalPadding;
  final double topPadding;
  final double scale;
  final double cardRadius;
  final double cardPadding;
  final double sectionGap;

  static _CheckoutLayout fromWidth(double width) {
    if (width >= 1100) {
      return const _CheckoutLayout(
        isDesktop: true,
        isTablet: false,
        maxContentWidth: 1120,
        horizontalPadding: 42,
        topPadding: 30,
        scale: 1,
        cardRadius: 22,
        cardPadding: 28,
        sectionGap: 24,
      );
    }

    if (width >= 760) {
      return const _CheckoutLayout(
        isDesktop: false,
        isTablet: true,
        maxContentWidth: 720,
        horizontalPadding: 32,
        topPadding: 26,
        scale: 1,
        cardRadius: 22,
        cardPadding: 24,
        sectionGap: 20,
      );
    }

    final scale = (width / 390).clamp(0.88, 1.0).toDouble();

    return _CheckoutLayout(
      isDesktop: false,
      isTablet: false,
      maxContentWidth: 430,
      horizontalPadding: width < 360 ? 16 : 16,
      topPadding: 20,
      scale: scale,
      cardRadius: 12,
      cardPadding: width < 360 ? 18 : 20,
      sectionGap: 14,
    );
  }
}

class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader({
    required this.layout,
    required this.onBack,
  });

  final _CheckoutLayout layout;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final height = layout.isDesktop ? 88.0 : 58.0 * layout.scale;

    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _CheckoutTheme.cardBorder,
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: layout.horizontalPadding,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: onBack,
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: layout.isDesktop ? 46 : 40 * layout.scale,
                        height: layout.isDesktop ? 46 : 40 * layout.scale,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: _CheckoutTheme.textDark,
                          size: layout.isDesktop ? 28 : 25 * layout.scale,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  'Checkout',
                  style: TextStyle(
                    color: _CheckoutTheme.textDark,
                    fontSize: layout.isDesktop ? 24 : 19 * layout.scale,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.35,
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

class _MobileCheckoutBody extends StatelessWidget {
  const _MobileCheckoutBody({
    required this.layout,
    required this.onPayNow,
  });

  final _CheckoutLayout layout;
  final VoidCallback onPayNow;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        layout.horizontalPadding,
        20 * layout.scale,
        layout.horizontalPadding,
        18 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        _OrderSummaryCard(layout: layout),
        SizedBox(height: 12 * layout.scale),
        _PlaceOrderCard(layout: layout, onPlaceOrder: onPayNow),
        SizedBox(height: 16 * layout.scale),
      ],
    );
  }
}

class _DesktopCheckoutBody extends StatelessWidget {
  const _DesktopCheckoutBody({
    required this.layout,
    required this.onPayNow,
  });

  final _CheckoutLayout layout;
  final VoidCallback onPayNow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        layout.horizontalPadding,
        layout.topPadding,
        layout.horizontalPadding,
        30,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 12,
            child: _OrderSummaryCard(layout: layout),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PlaceOrderCard(layout: layout, onPlaceOrder: onPayNow),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.layout});

  final _CheckoutLayout layout;

  @override
  Widget build(BuildContext context) {
    final cartItems = EmployeeCartStore.instance.items;
    final isEmpty = cartItems.isEmpty;
    final shopName = isEmpty ? 'Your cart' : cartItems.first.shopName;
    final pickupSlot = isEmpty
        ? null
        : EmployeeCartStore.instance.selectedPickupSlot(shopName);
    final subtotal = cartItems.fold<int>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final isTicketing = !isEmpty && EmployeeCartStore.instance.isTicketingMode;
    final labelText =
        !isEmpty ? (isTicketing ? 'Ticketing' : 'Pre-Order') : null;

    return _SectionCard(
      layout: layout,
      title: 'Order Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEmpty) ...[
            Text(
              'Your cart is empty. Add items from one restaurant or cafeteria to continue.',
              style: TextStyle(
                color: _CheckoutTheme.textMuted,
                fontSize: layout.isDesktop ? 15 : 14 * layout.scale,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            Text(
              shopName,
              style: TextStyle(
                color: _CheckoutTheme.textDark,
                fontSize: layout.isDesktop ? 18 : 16 * layout.scale,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            if (labelText != null)
              Container(
                margin: EdgeInsets.only(bottom: 16 * layout.scale),
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * layout.scale,
                  vertical: 8 * layout.scale,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF9F4),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  labelText,
                  style: TextStyle(
                    color: const Color(0xFF16A34A),
                    fontSize: layout.isDesktop ? 13 : 12 * layout.scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (pickupSlot != null) ...[
              SizedBox(height: 12 * layout.scale),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14 * layout.scale),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3EC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: _CheckoutTheme.primaryRed,
                      size: 20 * layout.scale,
                    ),
                    SizedBox(width: 10 * layout.scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pickup slot',
                            style: TextStyle(
                              color: _CheckoutTheme.textDark,
                              fontSize:
                                  layout.isDesktop ? 14 : 13 * layout.scale,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4 * layout.scale),
                          Text(
                            pickupSlot,
                            style: TextStyle(
                              color: _CheckoutTheme.textMuted,
                              fontSize:
                                  layout.isDesktop ? 15 : 14 * layout.scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18 * layout.scale),
            ],
            ...cartItems.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 18 * layout.scale),
                child: _SummaryItem(
                  layout: layout,
                  name: item.name,
                  details: 'Qty: ${item.quantity} · ₹${item.price} each',
                  quantity: 'x${item.quantity}',
                  price: '₹${item.price * item.quantity}',
                  imagePath: item.imagePath,
                ),
              ),
            ),
            SizedBox(height: 18 * layout.scale),
            _AmountRow(
              label: 'Subtotal',
              value: '₹$subtotal',
              labelColor: _CheckoutTheme.textMuted,
              valueColor: _CheckoutTheme.textDark,
              labelSize: layout.isDesktop ? 16 : 14 * layout.scale,
              valueSize: layout.isDesktop ? 16 : 14 * layout.scale,
              isBold: false,
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 22 * layout.scale),
              child: const Divider(
                height: 1,
                thickness: 1,
                color: _CheckoutTheme.divider,
              ),
            ),
            _AmountRow(
              label: 'Total',
              value: '₹$subtotal',
              labelColor: _CheckoutTheme.textDark,
              valueColor: _CheckoutTheme.primaryRed,
              labelSize: layout.isDesktop ? 18 : 16 * layout.scale,
              valueSize: layout.isDesktop ? 23 : 21 * layout.scale,
              isBold: true,
            ),
            if (!layout.isDesktop) SizedBox(height: 40 * layout.scale),
          ],
        ],
      ),
    );
  }
}

class _PlaceOrderCard extends StatelessWidget {
  const _PlaceOrderCard({
    required this.layout,
    required this.onPlaceOrder,
  });

  final _CheckoutLayout layout;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    final subtotal = EmployeeCartStore.instance.items.fold<int>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final isEmpty = subtotal == 0;

    return _SectionCard(
      layout: layout,
      title: 'Confirm Order',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review your items and place the order. The cart will be cleared after confirmation.',
            style: TextStyle(
              color: _CheckoutTheme.textMuted,
              fontSize: layout.isDesktop ? 15 : 14 * layout.scale,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 20 * layout.scale),
          _AmountRow(
            label: 'Order Total',
            value: '₹$subtotal',
            labelColor: _CheckoutTheme.textDark,
            valueColor: _CheckoutTheme.primaryRed,
            labelSize: layout.isDesktop ? 18 : 16 * layout.scale,
            valueSize: layout.isDesktop ? 23 : 21 * layout.scale,
            isBold: true,
          ),
          SizedBox(height: 24 * layout.scale),
          SizedBox(
            width: double.infinity,
            height: layout.isDesktop ? 58 : 56 * layout.scale,
            child: ElevatedButton(
              onPressed: isEmpty ? null : onPlaceOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isEmpty ? Colors.grey.shade400 : _CheckoutTheme.primaryRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ).copyWith(
                overlayColor: WidgetStateProperty.all(
                  Colors.white.withOpacity(0.10),
                ),
              ),
              child: Text(
                isEmpty ? 'Cart is empty' : 'Place Order · ₹$subtotal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: layout.isDesktop ? 16 : 16 * layout.scale,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.layout,
    required this.title,
    required this.child,
  });

  final _CheckoutLayout layout;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(layout.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        border: Border.all(
          color: _CheckoutTheme.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _CheckoutTheme.textDark,
              fontSize: layout.isDesktop ? 18 : 16 * layout.scale,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
          SizedBox(height: 20 * layout.scale),
          child,
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.layout,
    required this.name,
    required this.details,
    required this.quantity,
    required this.price,
    required this.imagePath,
  });

  final _CheckoutLayout layout;
  final String name;
  final String details;
  final String quantity;
  final String price;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final imageSize = layout.isDesktop ? 68.0 : 64.0 * layout.scale;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FoodImage(
          imagePath: imagePath,
          size: imageSize,
        ),
        SizedBox(width: 14 * layout.scale),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 2 * layout.scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _CheckoutTheme.textDark,
                    fontSize: layout.isDesktop ? 16 : 14.5 * layout.scale,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 7 * layout.scale),
                Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _CheckoutTheme.textMuted,
                    fontSize: layout.isDesktop ? 13 : 12 * layout.scale,
                    height: 1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 7 * layout.scale),
                Text(
                  quantity,
                  style: TextStyle(
                    color: _CheckoutTheme.textMuted,
                    fontSize: layout.isDesktop ? 13 : 12 * layout.scale,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12 * layout.scale),
        Padding(
          padding: EdgeInsets.only(top: 38 * layout.scale),
          child: Text(
            price,
            style: TextStyle(
              color: _CheckoutTheme.textDark,
              fontSize: layout.isDesktop ? 16 : 14 * layout.scale,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _FoodImage extends StatelessWidget {
  const _FoodImage({
    required this.imagePath,
    required this.size,
  });

  final String imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) {
            return Container(
              color: const Color(0xFFFFF2EC),
              alignment: Alignment.center,
              child: const Icon(
                Icons.restaurant_rounded,
                color: _CheckoutTheme.primaryRed,
                size: 24,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
    required this.labelSize,
    required this.valueSize,
    required this.isBold,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final double labelSize;
  final double valueSize;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: labelSize,
              height: 1.1,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
              letterSpacing: -0.15,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: valueSize,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
