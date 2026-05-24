import 'package:flutter/material.dart';

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildQuickStats(),
          const SizedBox(height: 40),
          _buildRevenueComparisonChart(),
          const SizedBox(height: 40),
          const Text('Cafeteria Performance Rankings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A3F))),
          const SizedBox(height: 20),
          _buildRankingCard('Meal Counter', '₹1.2M', '98%', Colors.green),
          const SizedBox(height: 16),
          _buildRankingCard('Tuck Shop', '₹850K', '94%', Colors.blue),
          const SizedBox(height: 16),
          _buildRankingCard('Juice Bar', '₹340K', '91%', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Executive Reports', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1A3F))),
        Text('Aggregated institutional revenue and performance analytics', style: TextStyle(color: Colors.black26, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatCard('Monthly Revenue', '₹28.4L', '↑ 14%', Colors.green),
        const SizedBox(width: 16),
        _buildStatCard('Active Vendors', '12', 'Stable', Colors.blue),
        const SizedBox(width: 16),
        _buildStatCard('Avg. Order Value', '₹145', '↓ 2%', Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String trend, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A3F))),
            Text(trend, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueComparisonChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cross-Cafeteria Revenue (Weekly)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1A1A3F))),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMultiBar('Meal Counter', 0.8, 0.6),
                _buildMultiBar('Tuck Shop', 0.5, 0.45),
                _buildMultiBar('Juice Bar', 0.3, 0.25),
                _buildMultiBar('Pizza Point', 0.65, 0.5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiBar(String label, double val1, double val2) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(width: 16, height: 160 * val1, decoration: BoxDecoration(color: const Color(0xFFFF3D00), borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 4),
            Container(width: 16, height: 160 * val2, decoration: BoxDecoration(color: const Color(0xFF1A1A3F), borderRadius: BorderRadius.circular(4))),
          ],
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildRankingCard(String name, String revenue, String efficiency, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.stars_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1A1A3F))),
                Text('Performance Tier: Premium', style: TextStyle(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(revenue, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1A1A3F))),
              Text('$efficiency Efficiency', style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}