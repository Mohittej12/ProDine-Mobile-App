import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/features/admin/widgets/admin_shell.dart';

class TermsAndDisclaimerPage extends StatelessWidget {
  const TermsAndDisclaimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    _buildMainHeader(),
                    const SizedBox(height: 40),
                    _buildSection(
                      title: 'For Users',
                      icon: Icons.person_rounded,
                      colors: [
                        const Color(0xFF12B76A),
                        const Color(0xFF079455),
                      ],
                      items: [
                        'Orders are subject to item availability as provided by the vendor.',
                        'Food quality, taste, and preparation are the responsibility of the respective vendor.',
                        'Payments are processed securely through a payment gateway.',
                        'Users must collect their orders within the specified time. Unclaimed orders may not be served.',
                        'For any issues related to food or orders, users may contact the vendor or support team.',
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'For Admin',
                      icon: Icons.admin_panel_settings_rounded,
                      colors: [
                        const Color(0xFFFF1F1F),
                        const Color(0xFFE01818),
                      ],
                      items: [
                        'This platform is intended for internal monitoring and management purposes.',
                        'Admins oversee system operations but are not responsible for vendor-specific issues such as food quality or order fulfillment.',
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'For Vendors',
                      icon: Icons.storefront_rounded,
                      colors: [
                        const Color(0xFFFF7A1A),
                        const Color(0xFFE66D17),
                      ],
                      items: [
                        'Vendors are responsible for maintaining accurate menu items, pricing, and available quantities.',
                        'Vendors must ensure timely preparation and fulfillment of all confirmed orders.',
                        'Food quality, hygiene, and service are the sole responsibility of the vendor.',
                        'Any issues related to order fulfillment, delays, or refunds must be handled by the vendor as per guidelines.',
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDisclaimerCard(),
                    const SizedBox(height: 32),
                    _buildSupportHub(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                if (AdminShell.openDrawer(context)) return;
                if (context.canPop()) context.pop();
              },
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.menu_rounded,
                  color: Color(0xFF1A1A3F),
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms & Disclaimer',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A3F),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Legal guidelines and platform policies',
                style: TextStyle(
                  color: Colors.black26,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.description_rounded,
            color: Color(0xFF2D60FF),
            size: 32,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Terms of Service / Disclaimer',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A3F),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Please read these terms carefully. They outline the responsibilities and guidelines for all platform users.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black38,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Color> colors,
    required List<String> items,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: items
                  .map((text) => _buildRequirementPoint(text, colors[0]))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementPoint(String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: iconColor, size: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF4A5568),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A3F),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A3F).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Text(
                'Disclaimer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'By using this platform, you acknowledge and agree to these terms. The platform acts as an intermediary and is not responsible for direct vendor-customer interactions.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportHub() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: const Icon(
              Icons.headset_mic_rounded,
              color: Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Need Help?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'If you have any questions about these terms, please contact our support team.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF3B82F6),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Contact Support',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
