import 'package:flutter/material.dart';
import 'package:pro_dine/features/admin/widgets/admin_sidebar.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  const AdminShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 1024;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF1F3F5),
          drawer: AdminSidebar(currentRoute: currentRoute, isDrawer: true),
          body: SafeArea(
            child: Row(
              children: [
                if (isDesktop)
                  AdminSidebar(currentRoute: currentRoute, isDrawer: false),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      final bool isIncoming =
                          child.key == ValueKey<String>(currentRoute);

                      if (isIncoming) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(
                              1.0,
                              0.0,
                            ), // Full slide from right
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
                            begin: const Offset(
                              -0.2,
                              0.0,
                            ), // Exit slightly to the left
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
              ],
            ),
          ),
        );
      },
    );
  }

  static bool openDrawer(BuildContext context) {
    final scoped = Scaffold.maybeOf(context);
    if (scoped != null && scoped.hasDrawer) {
      scoped.openDrawer();
      return true;
    }
    final shellState = _scaffoldKey.currentState;
    if (shellState != null && shellState.hasDrawer) {
      shellState.openDrawer();
      return true;
    }
    return false;
  }
}
