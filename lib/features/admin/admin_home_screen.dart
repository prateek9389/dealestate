import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/seller_submission_model.dart';
import '../../models/buyer_requirement_model.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with SingleTickerProviderStateMixin {
  String selectedSellerFilter = 'pending';
  String selectedBuyerFilter = 'all';
  String selectedRenterFilter = 'all';
  late TabController _tabController;
  late Stream<List<NotificationModel>> _adminNotificationsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _adminNotificationsStream = NotificationService().getNotificationsStream('admin');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Hub',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: isDark ? Colors.white : const Color(0xFF1754CF),
                  ),
            ),
            const Text(
              'Network Activity Monitor',
              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: _adminNotificationsStream,
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.where((n) => !n.isRead).length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFF1754CF), size: 24),
                    onPressed: () => context.push('/notifications'),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF1754CF), size: 24),
            onSelected: (value) {
              setState(() {
                if (_tabController.index == 0) {
                  selectedSellerFilter = value;
                } else if (_tabController.index == 1) {
                  selectedBuyerFilter = value;
                } else {
                  selectedRenterFilter = value;
                }
              });
            },
            itemBuilder: (context) {
              if (_tabController.index == 0) {
                return [
                  const PopupMenuItem(value: 'all', child: Text('Show All')),
                  const PopupMenuItem(value: 'pending', child: Text('Pending Only')),
                  const PopupMenuItem(value: 'approved', child: Text('Approved')),
                  const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
                ];
              } else {
                return [
                  const PopupMenuItem(value: 'all', child: Text('Show All')),
                  const PopupMenuItem(value: 'pending', child: Text('Pending Leads')),
                  const PopupMenuItem(value: 'in_progress', child: Text('In Progress')),
                  const PopupMenuItem(value: 'fulfilled', child: Text('Fulfilled')),
                ];
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1754CF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1754CF),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 4,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'SELLERS'),
            Tab(text: 'BUYERS'),
            Tab(text: 'RENTERS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SellerSubmissionsList(filter: selectedSellerFilter),
          BuyerRequirementsList(filter: selectedBuyerFilter, type: 'buy'),
          BuyerRequirementsList(filter: selectedRenterFilter, type: 'rent'),
        ],
      ),
    );
  }
}

class SellerSubmissionsList extends StatefulWidget {
  final String filter;
  const SellerSubmissionsList({super.key, required this.filter});

  @override
  State<SellerSubmissionsList> createState() => _SellerSubmissionsListState();
}

class _SellerSubmissionsListState extends State<SellerSubmissionsList> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Query query = FirebaseFirestore.instance.collection('seller_submissions');
    if (widget.filter != 'all') {
      query = query.where('status', isEqualTo: widget.filter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Sync Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No seller submissions found.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final submission = SellerSubmissionModel.fromMap(data, docs[index].id);

            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [const Color(0xFF1754CF).withValues(alpha: 0.1), const Color(0xFF1754CF).withValues(alpha: 0.05)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Stack(
                            children: [
                              const Center(
                                child: Icon(Icons.home_work_rounded, size: 48, color: Color(0xFF1754CF)),
                              ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: _buildStatusBadge(submission.status),
                              ),
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    submission.propertyType.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      submission.title,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '₹${submission.price}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1754CF),
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    submission.location,
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: const Color(0xFF1754CF).withValues(alpha: 0.1),
                                    child: Text(
                                      submission.userName.isNotEmpty ? submission.userName.substring(0, 1).toUpperCase() : '?',
                                      style: const TextStyle(color: Color(0xFF1754CF), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          submission.userName,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          submission.contactEmail,
                                          style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _buildContactAction(
                                        Icons.phone_rounded,
                                        () => _launchUrl('tel:${submission.contactPhone}'),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildContactAction(
                                        Icons.message_rounded,
                                        () => _launchUrl('sms:${submission.contactPhone}'),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildContactAction(
                                        Icons.chat_bubble_outline_rounded,
                                        () => _launchUrl('https://wa.me/${submission.contactPhone.replaceAll(RegExp(r'[^0-9]'), '')}'),
                                        color: Colors.green,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                                      ),
                                      onPressed: _isProcessing || submission.status != 'pending' 
                                        ? null 
                                        : () => _rejectSubmission(submission),
                                      child: Text(
                                        submission.status == 'rejected' ? 'Rejected' : 'Reject', 
                                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 13)
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1754CF),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: _isProcessing || submission.status != 'pending'
                                        ? null 
                                        : () {
                                          context.push('/admin/publish', extra: {'submission': submission});
                                        },
                                      child: Text(
                                        submission.status == 'approved' ? 'Posted' : 'Post', 
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _rejectSubmission(SellerSubmissionModel submission) async {
    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance
          .collection('seller_submissions')
          .doc(submission.id)
          .update({'status': 'rejected'});
      
      final notification = NotificationModel(
        id: '',
        title: 'Property Rejected',
        body: 'Your property "${submission.title}" was not approved by the admin.',
        type: 'property',
        timestamp: DateTime.now(),
        isRead: false,
        relatedId: submission.id,
      );
      
      await NotificationService().sendNotification(submission.userId, notification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission rejected successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'approved') color = Colors.green;
    if (status == 'rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class BuyerRequirementsList extends StatelessWidget {
  final String filter;
  final String type; // 'buy' or 'rent'
  const BuyerRequirementsList({super.key, required this.filter, required this.type});

  Future<void> _fulfillRequirement(BuildContext context, BuyerRequirementModel req) async {
    try {
      await FirebaseFirestore.instance.collection('buyer_requirements').doc(req.id).update({'status': 'fulfilled'});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as fulfilled')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Query query = FirebaseFirestore.instance.collection('buyer_requirements')
        .where('requirementType', isEqualTo: type);
        
    if (filter != 'all') {
      query = query.where('status', isEqualTo: filter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Sync Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No buyer requirements found.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final requirement = BuyerRequirementModel.fromMap(data, docs[index].id);

            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1754CF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            requirement.transactionType.toUpperCase(),
                            style: const TextStyle(color: Color(0xFF1754CF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ),
                        _buildStatusBadge(requirement.status),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Budget: ₹${requirement.minBudget} - ₹${requirement.maxBudget}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.maps_home_work_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${requirement.propertyType} in ${requirement.preferredLocation}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF1754CF).withValues(alpha: 0.1),
                          child: Text(
                            requirement.userName.isNotEmpty ? requirement.userName.substring(0, 1).toUpperCase() : '?',
                            style: const TextStyle(color: Color(0xFF1754CF), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                requirement.userName,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                requirement.contactEmail,
                                style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _buildContactAction(
                              Icons.phone_rounded,
                              () => _launchUrl('tel:${requirement.contactPhone}'),
                            ),
                            const SizedBox(width: 8),
                            _buildContactAction(
                              Icons.message_rounded,
                              () => _launchUrl('sms:${requirement.contactPhone}'),
                            ),
                            const SizedBox(width: 8),
                            _buildContactAction(
                              Icons.chat_bubble_outline_rounded,
                              () => _launchUrl('https://wa.me/${requirement.contactPhone.replaceAll(RegExp(r'[^0-9]'), '')}'),
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: requirement.status == 'fulfilled' 
                                ? null 
                                : () => _fulfillRequirement(context, requirement),
                            child: Text(requirement.status == 'fulfilled' ? 'Fulfilled' : 'Dismiss', 
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w800, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1754CF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              context.push('/chat?userId=${requirement.userId}');
                            },
                            child: const Text('Contact', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'fulfilled') color = Colors.green;
    if (status == 'in_progress') color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

void _launchUrl(String url) async {
  final uri = Uri.parse(url);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication); // Force external OS dialer/messaging app
  } catch (e) {
    debugPrint('Could not launch $url : $e');
  }
}

Widget _buildContactAction(IconData icon, VoidCallback onTap, {Color color = const Color(0xFF1754CF)}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 16),
    ),
  );
}
