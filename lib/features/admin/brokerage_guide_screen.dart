import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BrokerageGuideScreen extends StatelessWidget {
  const BrokerageGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Brokerage Guide', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(isDark),
            const SizedBox(height: 32),
            _buildSectionHeader('How DealEstate Works'),
            const SizedBox(height: 16),
            _buildGuideCard(
              context,
              '1. Lead Generation',
              'Users submit property details (Sellers) or requirements (Buyers) through their simplified panel. These arrive in your Command Center as real-time leads.',
              Icons.send_rounded,
              Colors.blue,
              isDark,
            ),
            _buildGuideCard(
              context,
              '2. Verification & Approval',
              'The Broker (Admin) reviews every submission. After verification, you can "Approve" a lead to publish it as a public listing, making it visible to the entire network.',
              Icons.verified_user_rounded,
              Colors.green,
              isDark,
            ),
            _buildGuideCard(
              context,
              '3. Intelligent Matching',
              'Our system cross-references Buyer budgets with Seller prices. When a match is found, users will contact you (the Broker) to initiate the deal.',
              Icons.auto_awesome_rounded,
              Colors.purple,
              isDark,
            ),
            _buildGuideCard(
              context,
              '4. Broker-Led Negotiation',
              'All negotiations are centralized in the Admin Inbox. You act as the trusted mediator, ensuring transparency and professional handling of every client interaction.',
              Icons.handshake_rounded,
              Colors.orange,
              isDark,
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Key Features'),
            const SizedBox(height: 16),
            _buildFeatureTag('Real-time Dashboard', Icons.speed_rounded, isDark),
            _buildFeatureTag('Secure Inbox with Read Receipts', Icons.chat_outlined, isDark),
            _buildFeatureTag('Atomic Property Management', Icons.storage_rounded, isDark),
            _buildFeatureTag('Multi-Device Admin Sync', Icons.devices_other_rounded, isDark),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1754CF), Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1754CF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, color: Colors.white, size: 32),
          SizedBox(height: 16),
          Text(
            'Mastering the\nBrokerage Flow',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Learn how to leverage DealEstate to automate your real estate business.',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
    );
  }

  Widget _buildGuideCard(BuildContext context, String title, String description, IconData icon, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTag(String label, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1754CF)),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1754CF)),
          ),
        ],
      ),
    );
  }
}
