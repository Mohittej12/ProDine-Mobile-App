import 'package:flutter/material.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_sidebar.dart';

class VendorShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const VendorShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      drawer: VendorSidebar(currentRoute: currentRoute),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            final bool isIncoming = child.key == ValueKey<String>(currentRoute);

            if (isIncoming) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0), // Full slide from right
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(
                  opacity: Tween<double>(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(animation),
                  child: child,
                ),
              );
            } else {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.2, 0.0), // Exit slightly to the left
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(
                  opacity: Tween<double>(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(animation),
                  child: child,
                ),
              );
            }
          },
          child: KeyedSubtree(
            key: ValueKey<String>(currentRoute),
            child: child,
          ),
        ),
      ),
    );
  }

  static bool openDrawer(BuildContext context) {
    final scoped = Scaffold.maybeOf(context);
    if (scoped != null && scoped.hasDrawer) {
      scoped.openDrawer();
      return true;
    }
    return false;
  }
}
