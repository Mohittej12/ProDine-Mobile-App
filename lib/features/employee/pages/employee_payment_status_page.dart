import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/features/employee/data/employee_order_store.dart';

class EmployeePaymentStatusPage extends StatefulWidget {
  const EmployeePaymentStatusPage({
    super.key,
    this.order,
  });

  final EmployeeOrderEntry? order;

  @override
  State<EmployeePaymentStatusPage> createState() =>
      _EmployeePaymentStatusPageState();
}

class _EmployeePaymentStatusPageState extends State<EmployeePaymentStatusPage>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      context.go(AppRoutes.employeeOrders);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.elasticOut,
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECF8F1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          color: Color(0xFF16A34A),
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Order Placed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF141827),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your order has been placed successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
