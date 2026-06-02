import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/property_card.dart';
import '../../widgets/toggle_switch.dart';
import '../../widgets/responsive_layout.dart';
import '../../services/firestore_service.dart';
import '../../models/admin_post_model.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _transactionType = 0; // 0 for Buy, 1 for Rent
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<AdminPostModel> _adminPosts = [];
  String? _userName;
  String? _userRole;
  late Stream<List<NotificationModel>> _notificationStream;

  @override
  void initState() {
    super.initState();
    _fetchAdminPosts();
    _loadUserData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService().getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _userName = user.name.split(' ')[0]; // Just the first name
        _userRole = user.role;
        _notificationStream = NotificationService()
            .getNotificationsStream(_userRole == 'admin' ? 'admin' : user.id);
      });
    } else {
      _notificationStream = Stream.value([]);
    }
  }

  Future<void> _fetchAdminPosts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final posts = await _firestoreService.getAdminPosts();
      if (mounted) {
        setState(() {
          _adminPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterType = _transactionType == 0 ? 'buy' : 'rent';
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          maxWidth: 800,
          child: Column(
            children: [
              _buildHeader(context),
              _buildSearchBar(context),
              Expanded(
                child: StreamBuilder<List<AdminPostModel>>(
                  stream: _firestoreService.getAdminPostsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allPosts = snapshot.data ?? _adminPosts;
                    final properties = allPosts.where((post) {
                      final matchesType = post.transactionType == filterType;
                      // Filter out original owner if they are currently logged in
                      final matchesOwner = post.ownerId != currentUserId;
                      final query = _searchQuery.toLowerCase();
                      final matchesSearch = post.title.toLowerCase().contains(query) ||
                          post.location.toLowerCase().contains(query) ||
                          post.propertyType.toLowerCase().contains(query);
                      return matchesType && matchesOwner && (_searchQuery.isEmpty || matchesSearch);
                    }).toList();

                    return RefreshIndicator(
                      onRefresh: _fetchAdminPosts,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: _buildTitleAndToggle(context),
                          ),
                          if (properties.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyState(),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.p16,
                                vertical: AppSizes.p8,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final property = properties[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: AppSizes.p16),
                                      child: PropertyCard(property: property),
                                    );
                                  },
                                  childCount: properties.length,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.p24, AppSizes.p24, AppSizes.p24, AppSizes.p8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hello, ${_userName ?? 'there'} 👋',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
             child: StreamBuilder<List<NotificationModel>>(
              stream: _userName == null ? Stream.value([]) : _notificationStream,
              builder: (context, snapshot) {
                final unreadCount = snapshot.data?.where((n) => !n.isRead).length ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_rounded, 
                        color: Colors.black.withValues(alpha: 0.6),
                        size: 26,
                      ),
                      onPressed: () => context.push('/notifications'),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search city, locality, project...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.blue, size: 24),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                ),
                fillColor: Colors.transparent,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p8),
        ],
      ),
    );
  }

  Widget _buildTitleAndToggle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.p8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Find Your Dream Home',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p16),
          ToggleSwitch(
            optionText1: 'Buy Properties',
            optionText2: 'Rent Properties',
            onToggle: (index) {
              setState(() {
                _transactionType = index;
              });
            },
          ),
          const SizedBox(height: AppSizes.p16),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: AppSizes.p16),
          const Text(
            'No properties found in this category.',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          TextButton(
            onPressed: _fetchAdminPosts,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
