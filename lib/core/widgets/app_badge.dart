import 'package:flutter/material.dart';

class AppBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;

  const AppBadge({
    super.key,
    required this.text,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor.withOpacity(0.1),
    );
  }
}