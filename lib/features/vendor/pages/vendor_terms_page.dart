import 'package:flutter/material.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_page_header.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_shell.dart';

class VendorTermsPage extends StatelessWidget {
  const VendorTermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1100;
        final scale = (width / 390).clamp(0.88, 1.0).toDouble();

        return Column(
          children: [
            VendorPageHeader(
              title: 'Terms & Disclaimer',
              maxContentWidth: isDesktop ? 1180 : (width >= 760 ? 760 : 430),
              horizontalPadding: isDesktop ? 42 : (width >= 760 ? 32 : 16),
              isDesktop: isDesktop,
              scale: scale,
              onMenuTap: () => VendorShell.openDrawer(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildIconHeader(),
                    const SizedBox(height: 24),
                    const Text(
                      'Terms of Service / Disclaimer',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A3F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Please read these terms carefully. They outline the responsibilities and guidelines for all platform users.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black38,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildLegalSection(
                      title: 'For Users',
                      color: const Color(0xFF27AE60),
                      icon: Icons.person_rounded,
                      rules: [
                        'Orders are subject to item availability as provided by the vendor.',
                        'Food quality, taste, and preparation are the responsibility of the respective vendor.',
                        'Payments are processed securely through a payment gateway.',
                        'Users must collect their orders within the specified time. Unclaimed orders may not be served.',
                        'For any issues related to food or orders, users may contact the vendor or support team.',
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildLegalSection(
                      title: 'For Admin',
                      color: const Color(0xFF9B51E0),
                      icon: Icons.admin_panel_settings_rounded,
                      rules: [
                        'This platform is intended for internal monitoring and management purposes.',
                        'Admins oversee system operations but are not responsible for vendor-specific issues such as food quality or order fulfillment.',
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildLegalSection(
                      title: 'For Vendors',
                      color: const Color(0xFFF2994A),
                      icon: Icons.store_rounded,
                      rules: [
                        'Vendors are responsible for maintaining accurate menu items, pricing, and available quantities.',
                        'Vendors must ensure timely preparation and fulfillment of all confirmed orders.',
                        'Food quality, hygiene, and service are the sole responsibility of the vendor.',
                        'Any issues related to order fulfillment, delays, or refunds must be handled by the vendor as per guidelines.',
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildDisclaimerBox(),
                    const SizedBox(height: 24),
                    _buildSupportBox(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIconHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.description_rounded,
        color: Color(0xFF4A90E2),
        size: 40,
      ),
    );
  }

  Widget _buildLegalSection({
    required String title,
    required Color color,
    required IconData icon,
    required List<String> rules,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
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
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: rules
                  .map(
                    (rule) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: color,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              rule,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A3F),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text(
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
          Text(
            'By using this platform, you acknowledge and agree to these terms. The platform acts as an intermediary and is not responsible for direct vendor-customer interactions.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.support_agent_rounded,
            color: Color(0xFF4A90E2),
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            'Need Help?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A3F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'If you have any questions about these terms, please contact our support team.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black38,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F80ED),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
