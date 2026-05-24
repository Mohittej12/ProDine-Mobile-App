import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double height;
  final bool isBrand;

  const AppLogo({
    super.key,
    this.height = 60,
    this.isBrand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      isBrand ? 'assets/images/brand_logo.png' : 'assets/images/app_logo.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
