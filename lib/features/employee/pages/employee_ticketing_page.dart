import 'package:flutter/material.dart';
import 'package:pro_dine/core/constants/app_strings.dart';

class EmployeeTicketingPage extends StatelessWidget {
  const EmployeeTicketingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ticketing')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Role: Employee'),
            SizedBox(height: 16),
            Text(AppStrings.uiPlaceholderNote),
          ],
        ),
      ),
    );
  }
}