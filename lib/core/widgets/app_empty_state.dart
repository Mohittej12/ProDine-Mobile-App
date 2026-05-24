import 'package:flutter/material.dart';

class AppEmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;

  const AppEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}