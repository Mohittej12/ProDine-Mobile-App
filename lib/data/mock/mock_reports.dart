import 'package:pro_dine/data/models/report_model.dart';

final List<ReportModel> mockReports = [
  ReportModel(
    id: '1',
    title: 'Sales Report',
    data: {'totalSales': 5000, 'totalOrders': 50},
    generatedAt: DateTime.now(),
  ),
  ReportModel(
    id: '2',
    title: 'Vendor Performance',
    data: {'vendor1': 'Good', 'vendor2': 'Average'},
    generatedAt: DateTime.now().subtract(const Duration(days: 7)),
  ),
];