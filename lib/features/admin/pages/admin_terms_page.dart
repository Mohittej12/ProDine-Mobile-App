import 'package:flutter/material.dart';
import 'package:pro_dine/core/constants/app_strings.dart';
import 'package:pro_dine/core/widgets/app_drawer.dart';

class AdminTermsPage extends StatelessWidget {
  const AdminTermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.terms)),
      drawer: const AppDrawer(role: 'Admin'),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Role: Admin'),
            SizedBox(height: 16),
            Text(AppStrings.uiPlaceholderNote),
          ],
        ),
      ),
    );
  }
}