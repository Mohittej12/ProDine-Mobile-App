import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/core/widgets/app_logo.dart';
import 'package:pro_dine/data/repositories/auth_repository.dart';
import 'package:pro_dine/features/employee/data/employee_profile_store.dart';
import 'package:pro_dine/features/employee/data/employee_order_store.dart';

class EmployeeProfileFragment extends StatefulWidget {
  const EmployeeProfileFragment({super.key});

  @override
  State<EmployeeProfileFragment> createState() =>
      _EmployeeProfileFragmentState();
}

class _EmployeeProfileFragmentState extends State<EmployeeProfileFragment> {
  static const Color _primaryRed = Color(0xFFFF1F1F);
  static const Color _darkText = Color(0xFF141827);
  static const Color _mutedText = Color(0xFF667085);
  static const Color _screenBg = Color(0xFFFFFCF8);
  static const Color _cardBorder = Color(0xFFF0F0F0);

  static const String _profileImagePath = 'assets/images/auth_login_header.png';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _screenBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _ProfileLayout.fromWidth(constraints.maxWidth);
          final bottomSafe = MediaQuery.of(context).padding.bottom;

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
                  layout.isDesktop ? 56 : 150 + bottomSafe,
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
                          _Header(layout: layout),
                          SizedBox(height: layout.sectionGap),
                          ValueListenableBuilder<EmployeeProfileData>(
                            valueListenable: EmployeeProfileStore.instance,
                            builder: (context, profile, _) {
                              if (layout.isDesktop) {
                                return _DesktopProfileBody(
                                  layout: layout,
                                  profile: profile,
                                );
                              }

                              return _MobileProfileBody(
                                layout: layout,
                                profile: profile,
                              );
                            },
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
      ),
    );
  }

  void _showComingSoon(String label) {
    if (label == 'Help & Support') {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Help & Support'),
          content: const Text(
            'For development and upgradations, do contact +91 7382260206 G. Mohit Tej.\n\n'
            'For office related queries, kindly contact the Admin Team.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _darkText,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(
            '$label coming soon',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
  }

  Future<void> _openEditProfile(EmployeeProfileData profile) async {
    final updated = await showModalBottomSheet<EmployeeProfileData>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(profile: profile),
    );

    if (updated == null) return;

    EmployeeProfileStore.instance.update(updated);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _darkText,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Text(
            'Profile updated',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
  }

  Future<void> _openChangePassword() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );

    if (changed != true || !mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _darkText,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Text(
            'Password changed successfully',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account Permanently'),
        content: const Text(
          'If you click this button whole data will be deleted.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _EmployeeProfileFragmentState._primaryRed,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authRepository = AuthRepository();
      await authRepository.deleteEmployeeAccount(
        employeeId: EmployeeProfileStore.instance.value.employeeId,
      );
      await authRepository.signOut();
      if (!mounted) return;
      context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Unable to delete account. Please try again.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LogoutSheet(),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    context.go(AppRoutes.login);
  }
}

class _ProfileLayout {
  const _ProfileLayout({
    required this.isDesktop,
    required this.isTablet,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.topPadding,
    required this.scale,
    required this.sectionGap,
    required this.cardGap,
  });

  final bool isDesktop;
  final bool isTablet;
  final double maxContentWidth;
  final double horizontalPadding;
  final double topPadding;
  final double scale;
  final double sectionGap;
  final double cardGap;

  static _ProfileLayout fromWidth(double width) {
    if (width >= 1180) {
      return const _ProfileLayout(
        isDesktop: true,
        isTablet: false,
        maxContentWidth: 1180,
        horizontalPadding: 48,
        topPadding: 26,
        scale: 1.08,
        sectionGap: 28,
        cardGap: 22,
      );
    }

    if (width >= 760) {
      return const _ProfileLayout(
        isDesktop: false,
        isTablet: true,
        maxContentWidth: 760,
        horizontalPadding: 34,
        topPadding: 24,
        scale: 1.02,
        sectionGap: 24,
        cardGap: 20,
      );
    }

    final veryNarrow = width < 345;
    final narrow = width < 370;

    final scale = veryNarrow
        ? 0.88
        : narrow
            ? 0.94
            : 1.0;

    return _ProfileLayout(
      isDesktop: false,
      isTablet: false,
      maxContentWidth: 430,
      horizontalPadding: narrow ? 16 : 20,
      topPadding: 17,
      scale: scale,
      sectionGap: 18,
      cardGap: 18,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.layout});

  final _ProfileLayout layout;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;
    final brandScale = layout.isDesktop || layout.isTablet ? 1.0 : scale;

    return SizedBox(
      height: layout.isDesktop ? 48 : 44 * brandScale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppLogo(
              height: layout.isDesktop ? 21 : 17.5 * brandScale,
              isBrand: true,
            ),
          ),
          if (layout.isDesktop)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: Text(
                'Profile',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _EmployeeProfileFragmentState._darkText,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileProfileBody extends StatelessWidget {
  const _MobileProfileBody({required this.layout, required this.profile});

  final _ProfileLayout layout;
  final EmployeeProfileData profile;

  @override
  Widget build(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_EmployeeProfileFragmentState>()!;

    return Column(
      children: [
        _ProfileCard(
          layout: layout,
          profile: profile,
          onEditTap: () => state._openEditProfile(profile),
        ),
        SizedBox(height: layout.cardGap),
        _ProfileSection(
          layout: layout,
          title: 'Account',
          actions: [
            _ProfileAction(
              icon: Icons.show_chart_rounded,
              iconColor: _EmployeeProfileFragmentState._primaryRed,
              iconBg: const Color(0xFFFFEFEF),
              title: 'My Usage',
              subtitle: 'View order history & analytics',
              onTap: () => context.push(AppRoutes.employeeUsage),
            ),
            _ProfileAction(
              icon: Icons.favorite_rounded,
              iconColor: _EmployeeProfileFragmentState._primaryRed,
              iconBg: const Color(0xFFFFEFEF),
              title: 'Favorites',
              subtitle: 'Your saved meals & restaurants',
              onTap: () => context.push(AppRoutes.employeeFavorites),
            ),
            _ProfileAction(
              icon: Icons.vpn_key_rounded,
              iconColor: const Color(0xFF344054),
              iconBg: const Color(0xFFF2F4F7),
              title: 'Change Password',
              subtitle: 'Update your credentials',
              onTap: state._openChangePassword,
            ),
          ],
        ),
        SizedBox(height: layout.cardGap),
        _ProfileSection(
          layout: layout,
          title: 'Settings',
          actions: [
            _ProfileAction(
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFF344054),
              iconBg: const Color(0xFFF2F4F7),
              title: 'Terms and Disclaimer',
              subtitle: 'Manage your data & permissions',
              onTap: () => context.push(AppRoutes.employeeTerms),
            ),
            _ProfileAction(
              icon: Icons.support_agent_rounded,
              iconColor: const Color(0xFF344054),
              iconBg: const Color(0xFFF2F4F7),
              title: 'Help & Support',
              subtitle: 'FAQs, contact us & feedback',
              onTap: () => state._showComingSoon('Help & Support'),
            ),
          ],
        ),
        SizedBox(height: layout.cardGap + 6),
        _LogoutButton(layout: layout, onTap: state._confirmLogout),
        const SizedBox(height: 12),
        _DeleteAccountButton(
          layout: layout,
          onTap: state._confirmDeleteAccount,
        ),
      ],
    );
  }
}

class _DesktopProfileBody extends StatelessWidget {
  const _DesktopProfileBody({required this.layout, required this.profile});

  final _ProfileLayout layout;
  final EmployeeProfileData profile;

  @override
  Widget build(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_EmployeeProfileFragmentState>()!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 380,
          child: Column(
            children: [
              _ProfileCard(
                layout: layout,
                profile: profile,
                onEditTap: () => state._openEditProfile(profile),
              ),
              SizedBox(height: layout.cardGap),
              _LogoutButton(layout: layout, onTap: state._confirmLogout),
              const SizedBox(height: 12),
              _DeleteAccountButton(
                layout: layout,
                onTap: state._confirmDeleteAccount,
              ),
            ],
          ),
        ),
        SizedBox(width: layout.cardGap),
        Expanded(
          child: Column(
            children: [
              _ProfileSection(
                layout: layout,
                title: 'Account',
                actions: [
                  _ProfileAction(
                    icon: Icons.show_chart_rounded,
                    iconColor: _EmployeeProfileFragmentState._primaryRed,
                    iconBg: const Color(0xFFFFEFEF),
                    title: 'My Usage',
                    subtitle: 'View order history & analytics',
                    onTap: () => context.push(AppRoutes.employeeUsage),
                  ),
                  _ProfileAction(
                    icon: Icons.favorite_rounded,
                    iconColor: _EmployeeProfileFragmentState._primaryRed,
                    iconBg: const Color(0xFFFFEFEF),
                    title: 'Favorites',
                    subtitle: 'Your saved meals & restaurants',
                    onTap: () => context.push(AppRoutes.employeeFavorites),
                  ),
                  _ProfileAction(
                    icon: Icons.vpn_key_rounded,
                    iconColor: const Color(0xFF344054),
                    iconBg: const Color(0xFFF2F4F7),
                    title: 'Change Password',
                    subtitle: 'Update your credentials',
                    onTap: state._openChangePassword,
                  ),
                ],
              ),
              SizedBox(height: layout.cardGap),
              _ProfileSection(
                layout: layout,
                title: 'Settings',
                actions: [
                  _ProfileAction(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF344054),
                    iconBg: const Color(0xFFF2F4F7),
                    title: 'Terms and Disclaimer',
                    subtitle: 'Manage your data & permissions',
                    onTap: () => context.push(AppRoutes.employeeTerms),
                  ),
                  _ProfileAction(
                    icon: Icons.support_agent_rounded,
                    iconColor: const Color(0xFF344054),
                    iconBg: const Color(0xFFF2F4F7),
                    title: 'Help & Support',
                    subtitle: 'FAQs, contact us & feedback',
                    onTap: () => state._showComingSoon('Help & Support'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.layout,
    required this.profile,
    required this.onEditTap,
  });

  final _ProfileLayout layout;
  final EmployeeProfileData profile;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;
    final avatarSize = layout.isDesktop ? 92.0 : 76.0 * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        22 * scale,
        24 * scale,
        22 * scale,
        22 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28 * scale),
        border: Border.all(
          color: _EmployeeProfileFragmentState._cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Material(
              color: const Color(0xFFF3F4F6),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onEditTap,
                child: SizedBox(
                  width: 40 * scale,
                  height: 40 * scale,
                  child: Icon(
                    Icons.edit_rounded,
                    color: const Color(0xFF344054),
                    size: 18 * scale,
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Center(
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _EmployeeProfileFragmentState._primaryRed
                          .withOpacity(0.10),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      _EmployeeProfileFragmentState._profileImagePath,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_1, _2, _3) {
                        return Container(
                          color: const Color(0xFFFFEFEF),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.person_rounded,
                            color: _EmployeeProfileFragmentState._primaryRed,
                            size: 38 * scale,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16 * scale),
              Text(
                profile.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _EmployeeProfileFragmentState._darkText,
                  fontSize: layout.isDesktop ? 24 : 21 * scale,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.45,
                ),
              ),
              SizedBox(height: 8 * scale),
              Text(
                profile.phone,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _EmployeeProfileFragmentState._mutedText,
                  fontSize: layout.isDesktop ? 14 : 13.5 * scale,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10 * scale),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8 * scale,
                runSpacing: 8 * scale,
                children: [
                  _ProfileInfoPill(
                    icon: Icons.badge_rounded,
                    label: profile.employeeId,
                    scale: scale,
                  ),
                ],
              ),
              SizedBox(height: 20 * scale),
              _ProfileStats(layout: layout),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoPill extends StatelessWidget {
  const _ProfileInfoPill({
    required this.icon,
    required this.label,
    required this.scale,
  });

  final IconData icon;
  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 180 * scale),
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 7 * scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _EmployeeProfileFragmentState._primaryRed,
            size: 13 * scale,
          ),
          SizedBox(width: 6 * scale),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _EmployeeProfileFragmentState._darkText,
                fontSize: 11.5 * scale,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.layout});

  final _ProfileLayout layout;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: EmployeeOrderStore.instance,
      builder: (context, _) {
        final totalOrders = EmployeeOrderStore.instance.orders.length;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * layout.scale,
            vertical: 13 * layout.scale,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFAF7),
            borderRadius: BorderRadius.circular(20 * layout.scale),
            border: Border.all(color: const Color(0xFFFFEFEA)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ProfileStat(
                  value: totalOrders.toString(),
                  label: 'Orders',
                  layout: layout,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.value,
    required this.label,
    required this.layout,
  });

  final String value;
  final String label;
  final _ProfileLayout layout;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: _EmployeeProfileFragmentState._darkText,
            fontSize: layout.isDesktop ? 18 : 16 * scale,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 5 * scale),
        Text(
          label,
          style: TextStyle(
            color: _EmployeeProfileFragmentState._mutedText,
            fontSize: 11.5 * scale,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.layout,
    required this.title,
    required this.actions,
  });

  final _ProfileLayout layout;
  final String title;
  final List<_ProfileAction> actions;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22 * scale),
        border: Border.all(
          color: _EmployeeProfileFragmentState._cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              18 * scale,
              18 * scale,
              18 * scale,
              15 * scale,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  color: _EmployeeProfileFragmentState._darkText,
                  fontSize: layout.isDesktop ? 18 : 16.5 * scale,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          ...actions.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;
            final isLast = index == actions.length - 1;

            return Column(
              children: [
                _ProfileActionTile(layout: layout, action: action),
                if (!isLast) const Divider(height: 1, color: Color(0xFFF0F0F0)),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({required this.layout, required this.action});

  final _ProfileLayout layout;
  final _ProfileAction action;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;
    final iconSize = layout.isDesktop ? 52.0 : 44.0 * scale;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: action.onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 18 * scale,
            vertical: layout.isDesktop ? 18 : 14 * scale,
          ),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: action.iconBg,
                  borderRadius: BorderRadius.circular(13 * scale),
                ),
                child: Icon(
                  action.icon,
                  color: action.iconColor,
                  size: layout.isDesktop ? 24 : 21 * scale,
                ),
              ),
              SizedBox(width: 15 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _EmployeeProfileFragmentState._darkText,
                        fontSize: layout.isDesktop ? 15.5 : 14 * scale,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 5 * scale),
                    Text(
                      action.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _EmployeeProfileFragmentState._mutedText,
                        fontSize: layout.isDesktop ? 12.5 : 11.5 * scale,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10 * scale),
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFF98A2B3),
                size: 25 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.layout, required this.onTap});

  final _ProfileLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return SizedBox(
      width: double.infinity,
      height: layout.isDesktop ? 58 : 52 * scale,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _EmployeeProfileFragmentState._primaryRed,
          side: BorderSide(
            color: _EmployeeProfileFragmentState._primaryRed.withValues(
              alpha: 0.35,
            ),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17 * scale),
          ),
          backgroundColor: Colors.white.withOpacity(0.65),
        ),
        child: Text(
          'Logout',
          style: TextStyle(
            color: _EmployeeProfileFragmentState._primaryRed,
            fontSize: layout.isDesktop ? 15.5 : 14 * scale,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton({required this.layout, required this.onTap});

  final _ProfileLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return SizedBox(
      width: double.infinity,
      height: layout.isDesktop ? 58 : 52 * scale,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _EmployeeProfileFragmentState._primaryRed,
          side: BorderSide(
            color: _EmployeeProfileFragmentState._primaryRed.withValues(
              alpha: 0.35,
            ),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17 * scale),
          ),
          backgroundColor: Colors.white.withOpacity(0.65),
        ),
        child: Text(
          'Delete Account Permanently',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _EmployeeProfileFragmentState._primaryRed,
            fontSize: layout.isDesktop ? 15.5 : 14 * scale,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile});

  final EmployeeProfileData profile;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _editFormKey = GlobalKey<FormState>();

  late final TextEditingController _nameController = TextEditingController(
    text: widget.profile.name,
  );
  late final TextEditingController _phoneController = TextEditingController(
    text: widget.profile.phone,
  );
  late final TextEditingController _employeeIdController =
      TextEditingController(text: widget.profile.employeeId);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final wide = mediaQuery.size.width >= 760;

    return Align(
      alignment: wide ? Alignment.centerRight : Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 460 : double.infinity),
        child: Container(
          margin: EdgeInsets.only(
            right: wide ? 28 : 0,
            top: wide ? 28 : 0,
            bottom: wide ? 28 : 0,
          ),
          padding: EdgeInsets.fromLTRB(
            22,
            14,
            22,
            22 + mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(28),
              bottom: Radius.circular(wide ? 28 : 0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _editFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEFEF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: _EmployeeProfileFragmentState._primaryRed,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Profile',
                                style: TextStyle(
                                  color:
                                      _EmployeeProfileFragmentState._darkText,
                                  fontSize: 23,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.45,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Keep your workplace dining identity current.',
                                style: TextStyle(
                                  color:
                                      _EmployeeProfileFragmentState._mutedText,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _EditProfileField(
                      controller: _nameController,
                      label: 'Full name',
                      icon: Icons.person_rounded,
                      textInputAction: TextInputAction.next,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    _EditProfileField(
                      controller: _phoneController,
                      label: 'Mobile number',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    _EditProfileField(
                      controller: _employeeIdController,
                      label: 'Employee ID',
                      icon: Icons.badge_rounded,
                      textInputAction: TextInputAction.done,
                      validator: _requiredValidator,
                      onFieldSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: _EmployeeProfileFragmentState._darkText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              elevation: 0,
                              backgroundColor:
                                  _EmployeeProfileFragmentState._primaryRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  void _save() {
    if (_editFormKey.currentState?.validate() != true) return;

    Navigator.pop(
      context,
      EmployeeProfileData(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        employeeId: _employeeIdController.text.trim(),
      ),
    );
  }
}

class _EditProfileField extends StatelessWidget {
  const _EditProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      cursorColor: _EmployeeProfileFragmentState._primaryRed,
      style: const TextStyle(
        color: _EmployeeProfileFragmentState._darkText,
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF98A2B3), size: 21),
        labelStyle: const TextStyle(
          color: _EmployeeProfileFragmentState._mutedText,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEDEFF3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEDEFF3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _EmployeeProfileFragmentState._primaryRed,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD92D20)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD92D20)),
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _changePasswordFormKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _saving = false;
  String? _currentPasswordError;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final wide = mediaQuery.size.width >= 760;

    return Align(
      alignment: wide ? Alignment.centerRight : Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 460 : double.infinity),
        child: Container(
          margin: EdgeInsets.only(
            right: wide ? 28 : 0,
            top: wide ? 28 : 0,
            bottom: wide ? 28 : 0,
          ),
          padding: EdgeInsets.fromLTRB(
            22,
            14,
            22,
            22 + mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(28),
              bottom: Radius.circular(wide ? 28 : 0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _changePasswordFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEFEF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.vpn_key_rounded,
                            color: _EmployeeProfileFragmentState._primaryRed,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Change Password',
                                style: TextStyle(
                                  color:
                                      _EmployeeProfileFragmentState._darkText,
                                  fontSize: 23,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.45,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Choose a stronger password for your account.',
                                style: TextStyle(
                                  color:
                                      _EmployeeProfileFragmentState._mutedText,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _PasswordField(
                      controller: _currentController,
                      label: 'Current password',
                      obscureText: _hideCurrent,
                      textInputAction: TextInputAction.next,
                      errorText: _currentPasswordError,
                      onChanged: (_) {
                        if (_currentPasswordError == null) return;
                        setState(() => _currentPasswordError = null);
                      },
                      onToggleVisibility: () {
                        setState(() => _hideCurrent = !_hideCurrent);
                      },
                      validator: _requiredPasswordValidator,
                    ),
                    const SizedBox(height: 12),
                    _PasswordField(
                      controller: _newController,
                      label: 'New password',
                      obscureText: _hideNew,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        if (_confirmController.text.isEmpty) return;
                        _changePasswordFormKey.currentState?.validate();
                      },
                      onToggleVisibility: () {
                        setState(() => _hideNew = !_hideNew);
                      },
                      validator: _newPasswordValidator,
                    ),
                    const SizedBox(height: 12),
                    _PasswordField(
                      controller: _confirmController,
                      label: 'Confirm new password',
                      obscureText: _hideConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _save(),
                      onToggleVisibility: () {
                        setState(() => _hideConfirm = !_hideConfirm);
                      },
                      validator: _confirmPasswordValidator,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: _EmployeeProfileFragmentState._darkText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              elevation: 0,
                              backgroundColor:
                                  _EmployeeProfileFragmentState._primaryRed,
                              disabledBackgroundColor: const Color(0xFFFFB4B4),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Update',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
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
          ),
        ),
      ),
    );
  }

  String? _requiredPasswordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Enter current password';
    return null;
  }

  String? _newPasswordValidator(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Enter new password';
    if (password.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
      return 'Include at least one letter';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Include at least one number';
    }
    if (password == _currentController.text) {
      return 'New password must be different';
    }
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Confirm new password';
    if (value != _newController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _save() async {
    setState(() => _currentPasswordError = null);
    if (_changePasswordFormKey.currentState?.validate() != true) return;

    setState(() => _saving = true);
    final changed = await EmployeeProfileStore.instance.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );

    if (!mounted) return;

    if (!changed) {
      setState(() {
        _saving = false;
        _currentPasswordError = 'Current password is incorrect';
      });
      _changePasswordFormKey.currentState?.validate();
      return;
    }

    Navigator.pop(context, true);
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.validator,
    this.errorText,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final FormFieldValidator<String> validator;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      cursorColor: _EmployeeProfileFragmentState._primaryRed,
      style: const TextStyle(
        color: _EmployeeProfileFragmentState._darkText,
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF98A2B3),
          size: 21,
        ),
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: const Color(0xFF98A2B3),
          ),
        ),
        labelStyle: const TextStyle(
          color: _EmployeeProfileFragmentState._mutedText,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEDEFF3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEDEFF3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _EmployeeProfileFragmentState._primaryRed,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD92D20)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD92D20)),
        ),
      ),
    );
  }
}

class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          22,
          16,
          22,
          22 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 22),
              const Icon(
                Icons.logout_rounded,
                color: _EmployeeProfileFragmentState._primaryRed,
                size: 34,
              ),
              const SizedBox(height: 12),
              const Text(
                'Logout?',
                style: TextStyle(
                  color: _EmployeeProfileFragmentState._darkText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'You can sign in again anytime with your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _EmployeeProfileFragmentState._mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: _EmployeeProfileFragmentState._darkText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        elevation: 0,
                        backgroundColor:
                            _EmployeeProfileFragmentState._primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(fontWeight: FontWeight.w900),
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

class _ProfileAction {
  const _ProfileAction({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}
