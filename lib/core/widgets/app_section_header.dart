import 'package:flutter/material.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;

  const AppSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}