import 'package:flutter/material.dart';

class VendorPageHeader extends StatelessWidget {
  const VendorPageHeader({
    super.key,
    required this.title,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.isDesktop,
    required this.scale,
    required this.onMenuTap,
    this.trailingIcon,
    this.onTrailingTap,
  });

  static const Color textDark = Color(0xFF141827);
  static const Color border = Color(0xFFE6E8EC);

  final String title;
  final double maxContentWidth;
  final double horizontalPadding;
  final bool isDesktop;
  final double scale;
  final VoidCallback onMenuTap;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    final height = isDesktop ? 88.0 : 58.0 * scale;

    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: VendorHeaderIconButton(
                    icon: Icons.menu_rounded,
                    onTap: onMenuTap,
                    isDesktop: isDesktop,
                    scale: scale,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 56 * scale),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textDark,
                      fontSize: isDesktop ? 24 : 18.5 * scale,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (trailingIcon != null && onTrailingTap != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: VendorHeaderIconButton(
                      icon: trailingIcon!,
                      onTap: onTrailingTap!,
                      isDesktop: isDesktop,
                      scale: scale,
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

class VendorHeaderIconButton extends StatelessWidget {
  const VendorHeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.isDesktop,
    required this.scale,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isDesktop;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: isDesktop ? 46 : 40 * scale,
          height: isDesktop ? 46 : 40 * scale,
          child: Icon(
            icon,
            color: VendorPageHeader.textDark,
            size: isDesktop ? 25 : 23 * scale,
          ),
        ),
      ),
    );
  }
}
