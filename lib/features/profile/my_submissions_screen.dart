import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/seller_submission_model.dart';
import '../../models/buyer_requirement_model.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

class MySubmissionsScreen extends StatelessWidget {
  const MySubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('My Submissions'),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => context.pop(),
          ),
          bottom: TabBar(
            labelColor: const Color(0xFF1754CF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1754CF),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Properties (Sell/Rent out)'),
              Tab(text: 'Requirements (Buy/Rent)'),
            ],
          ),
        ),
        body: uid.isEmpty
            ? const Center(child: Text('Please log in to view submissions'))
            : TabBarView(
                children: [
                  _buildPropertiesList(uid),
                  _buildRequirementsList(uid),
                ],
              ),
      ),
    );
  }

  Widget _buildPropertiesList(String uid) {
    return StreamBuilder<List<SellerSubmissionModel>>(
      stream: FirestoreService().getUserSubmissionsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading submissions'));
        }

        final submissions = snapshot.data ?? [];

        if (submissions.isEmpty) {
          return const Center(child: Text('No property submissions found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.p16),
          itemCount: submissions.length,
          itemBuilder: (context, index) {
            final sub = submissions[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: AppSizes.p16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            sub.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1754CF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '₹${sub.price}',
                            style: const TextStyle(
                              color: Color(0xFF1754CF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.p8),
                    Text('${sub.propertyType} • ${sub.transactionType.toUpperCase()}'),
                    const SizedBox(height: AppSizes.p16),
                    _buildStatusTracker(sub.status, context),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequirementsList(String uid) {
    return StreamBuilder<List<BuyerRequirementModel>>(
      stream: FirestoreService().getUserRequirementsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading requirements'));
        }

        final requirements = snapshot.data ?? [];

        if (requirements.isEmpty) {
          return const Center(child: Text('No requirements found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.p16),
          itemCount: requirements.length,
          itemBuilder: (context, index) {
            final req = requirements[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: AppSizes.p16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Looking for ${req.propertyType}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            req.transactionType.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.p8),
                    Text('Budget: ₹${req.minBudget} - ₹${req.maxBudget}'),
                    const SizedBox(height: AppSizes.p4),
                    Text('Location: ${req.preferredLocation}'),
                    const SizedBox(height: AppSizes.p16),
                    _buildStatusTracker(req.status, context),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusTracker(String status, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayStatus = status.toLowerCase();
    
    int step = 0;
    bool isRejected = false;
    
    if (displayStatus == 'pending') step = 1;
    else if (displayStatus == 'in_progress') step = 1;
    else if (displayStatus == 'approved' || displayStatus == 'fulfilled') step = 2;
    else if (displayStatus == 'rejected' || displayStatus == 'cancelled') {
      step = 2;
      isRejected = true;
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Status',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepColumn('Submitted', Icons.assignment_turned_in, true, false, isDark),
              _buildLine(step >= 1, isDark: isDark),
              _buildStepColumn('Under Review', step == 1 ? Icons.pending : Icons.find_in_page, step >= 1, false, isDark),
              _buildLine(step >= 2, isError: isRejected, isDark: isDark),
              _buildStepColumn(
                isRejected ? 'Rejected' : (displayStatus == 'fulfilled' ? 'Fulfilled' : 'Approved'),
                isRejected ? Icons.cancel : Icons.check_circle,
                step >= 2,
                isRejected,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepColumn(String title, IconData icon, bool isActive, bool isRejected, bool isDark) {
    final color = isActive
        ? (isRejected ? Colors.red : Colors.green)
        : (isDark ? Colors.grey.shade700 : Colors.grey.shade400);

    return Expanded(
      flex: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.15) : Colors.transparent,
              shape: BoxShape.circle,
              border: isActive ? null : Border.all(color: color),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(bool isActive, {bool isError = false, required bool isDark}) {
    final color = isActive
        ? (isError ? Colors.red : Colors.green)
        : (isDark ? Colors.grey.shade800 : Colors.grey.shade200);

    return Expanded(
      flex: 1,
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(top: 18),
        color: color,
      ),
    );
  }
}
