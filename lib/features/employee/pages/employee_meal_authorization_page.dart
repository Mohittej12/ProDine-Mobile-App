import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/core/widgets/app_button.dart';
import 'package:pro_dine/core/widgets/app_text_field.dart';
import 'package:pro_dine/features/employee/data/employee_order_store.dart';
import 'package:pro_dine/features/employee/data/employee_profile_store.dart';

class EmployeeMealAuthorizationPage extends StatefulWidget {
  const EmployeeMealAuthorizationPage({
    super.key,
    this.selectedMealType,
  });

  final String? selectedMealType;

  @override
  State<EmployeeMealAuthorizationPage> createState() =>
      _EmployeeMealAuthorizationPageState();
}

class _EmployeeMealAuthorizationPageState
    extends State<EmployeeMealAuthorizationPage> {
  bool isOffTicket = false; // Toggle state
  late final String _selectedMealType;
  late final TextEditingController _employeeNameController;
  late final TextEditingController _employeeIdController;

  @override
  void initState() {
    super.initState();
    final profile = EmployeeProfileStore.instance.value;
    _selectedMealType = widget.selectedMealType ?? 'Breakfast';
    _employeeNameController = TextEditingController(text: profile.name);
    _employeeIdController = TextEditingController(
      text: _formatEmployeeId(profile.employeeId),
    );
  }

  @override
  void dispose() {
    _employeeNameController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  void _submitRequest() async {
    final profile = EmployeeProfileStore.instance.value;
    final orderIntent =
        isOffTicket ? 'Ticketing-Off Ticket' : 'Ticketing-Ticket ID';
    final order = EmployeeOrderEntry(
      orderId: _generateOrderId(),
      employeeId: profile.employeeId,
      userName: profile.name,
      shopId: 'MEAL_COUNTER',
      shopName: 'Meal Counter',
      orderIntent: orderIntent,
      items: [
        EmployeeOrderItem(
          name: _selectedMealType,
          meal: _selectedMealType,
          quantity: 1,
          price: 0,
          imagePath: 'assets/images/auth_login_header.png',
        ),
      ],
      amount: 0,
      status: 'ordered',
      pickupSlot: '',
      isTicketing: true,
      createdAt: DateTime.now(),
    );

    try {
      await EmployeeOrderStore.instance.saveOrder(order);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.employeeOrders);
    } catch (e, stackTrace) {
      debugPrint('Ticketing order save failed: $e');
      debugPrint('$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to raise order: ${e.toString()}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }
  }

  static String _generateOrderId() {
    final random = Random();
    return 'ORD-${random.nextInt(9000) + 1000}';
  }

  static String _formatEmployeeId(String rawId) {
    final digits = rawId.replaceAll(RegExp(r'\D'), '');
    final idDigits = digits.length >= 5
        ? digits.substring(digits.length - 5)
        : digits.padLeft(5, '0');
    return 'EMP-$idDigits';
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5), // Premium canvas gray
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // Theme Consistency Glows
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF4D4D).withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFB84D).withOpacity(0.04),
                ),
              ),
            ),

            Align(
              alignment: Alignment.topCenter,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(bottom: keyboardInset + 20),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(0, 40, 0, 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 28),
                          _buildMealInfoCard(),
                          const SizedBox(height: 28),
                          _buildAccessTypeSelection(),

                          // Dynamic Content with Smooth Transition
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: isOffTicket
                                ? _buildOffTicketForm()
                                : const SizedBox(height: 24),
                          ),

                          _buildPaymentInfoBox(),
                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: AppButton(
                              text: 'Submit Request',
                              onPressed: _submitRequest,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () => context.pop(),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.black45,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFFF4D4D),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.help_outline, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Meal Authorization',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A3F),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Company-sponsored Meal request',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.45),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close, color: Colors.black26, size: 28),
        ),
      ],
    );
  }

  Widget _buildMealInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/auth_login_header.png',
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedMealType,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A3F),
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Meal Counter',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.45),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEAEA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Company Sponsored',
                    style: TextStyle(
                      color: Color(0xFFFF4D4D),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text.rich(
          TextSpan(
            text: 'Meal Access Type ',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: Color(0xFF1A1A3F),
            ),
            children: [
              TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose how the dinner meal will be served',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withOpacity(0.4),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildToggleItem(
                  'Ticket ID',
                  Icons.confirmation_number_outlined,
                  !isOffTicket,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildToggleItem(
                  'Off - Ticket',
                  Icons.storefront_outlined,
                  isOffTicket,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleItem(String label, IconData icon, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => isOffTicket = label == 'Off - Ticket'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.black : Colors.black38,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.black38,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffTicketForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        const Text.rich(
          TextSpan(
            text: 'Employee Details ',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: Color(0xFF1A1A3F),
            ),
            children: [
              TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _employeeNameController,
          readOnly: true,
          hint: 'full name',
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _employeeIdController,
          readOnly: true,
          hint: 'employee ID',
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildPaymentInfoBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.help_outline, color: Color(0xFFFF4D4D), size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'No payment required. This meal is sponsored by your organization.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
