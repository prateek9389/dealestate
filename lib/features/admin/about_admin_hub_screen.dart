import 'package:flutter/material.dart';

class AboutAdminHubScreen extends StatelessWidget {
  const AboutAdminHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Admin Hub Info', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1754CF), Color(0xFF64B5F6)]),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1754CF).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 50),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'DealEstate Admin Hub',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
                  ),
                  const Text(
                    'Version 2.0.4 r14 (Stable)',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            _buildInfoCard(isDark, [
              _buildInfoRow('Developer', 'Antigravity AI Core'),
              _buildInfoRow('Engine', 'Flutter 3.x • Dart 3.x'),
              _buildInfoRow('Backend', 'Firebase Stack v12'),
              _buildInfoRow('Environment', 'Production (Brokerage)'),
              _buildInfoRow('Build ID', 'DE_A_2026_03_16_HUB'),
            ]),
            const SizedBox(height: 32),
            const Text(
              'The Admin Hub is the central command center for DealEstate brokerage operations. It provides real-time monitoring of property submissions, user communications, and platform security.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 48),
            const Text('© 2026 DealEstate Brokerage Solutions', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w700, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }
}
