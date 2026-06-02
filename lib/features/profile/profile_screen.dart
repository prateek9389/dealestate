import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/responsive_layout.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<Map<String, dynamic>>(
      future: () async {
        final user = await AuthService().getCurrentUser();
        if (user == null) return {'user': null, 'submissions': 0};
        final submissions = await FirestoreService().getUserSubmissions(user.id);
        return {'user': user, 'submissions': submissions.length};
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data;
        final user = data?['user'] as UserModel?;
        final submissionCount = data?['submissions'] as int? ?? 0;
        
        final name = user?.name.isNotEmpty == true ? user!.name : 'Guest User';
        final email = user?.email.isNotEmpty == true ? user!.email : 'Sign in to sync data';
        final memberSince = user?.createdAt.year.toString() ?? '2024';

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
          body: SafeArea(
            child: ResponsiveLayout(
              maxWidth: 800,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p32),
                child: Column(
                  children: [
                    _buildUserHeader(context, user, name, email, submissionCount, memberSince, isDark),
                    const SizedBox(height: 48),
                    _buildSectionHeader(context, 'Personal Activity'),
                    const SizedBox(height: 12),
                    _buildProfileOption(
                      context,
                      icon: Icons.history_edu_rounded,
                      title: 'My Submissions',
                      subtitle: 'Track your selling & rental requests',
                      onTap: () => context.push('/profile/submissions'),
                    ),
                    const SizedBox(height: 12),
                    _buildProfileOption(
                      context,
                      icon: Icons.favorite_rounded,
                      title: 'Saved Listings',
                      subtitle: 'Properties you marked as favorite',
                      onTap: () => context.push('/profile/saved'),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(context, 'System & Support'),
                    const SizedBox(height: 12),
                    _buildProfileOption(
                      context,
                      icon: Icons.settings_rounded,
                      title: 'Account Settings',
                      subtitle: 'Privacy, security & preferences',
                      onTap: () => context.push('/profile/settings'),
                    ),
                    const SizedBox(height: 12),
                    _buildProfileOption(
                      context,
                      icon: Icons.lock_reset_rounded,
                      title: 'Change Password',
                      subtitle: 'Update your security credentials',
                      onTap: () => context.push('/change-password'),
                    ),
                    const SizedBox(height: 12),
                    _buildProfileOption(
                      context,
                      icon: Icons.help_center_rounded,
                      title: 'Help Center',
                      subtitle: 'Get assistance from our team',
                      onTap: () => context.push('/profile/help_support'),
                    ),
                    const SizedBox(height: 48),
                    _buildLogoutButton(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserHeader(BuildContext context, UserModel? user, String name, String email, int submissionCount, String memberSince, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [const Color(0xFF1E1E1E), const Color(0xFF121212)] 
            : [Colors.white, const Color(0xFFF0F4FF)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1754CF), Color(0xFF64B5F6)],
                  ),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  backgroundImage: user?.profilePictureUrl != null && user!.profilePictureUrl.isNotEmpty
                      ? NetworkImage(user.profilePictureUrl)
                      : null,
                  child: (user?.profilePictureUrl == null || user!.profilePictureUrl.isEmpty)
                      ? const Icon(Icons.person_rounded, size: 48, color: Color(0xFF1754CF))
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => context.push('/profile/edit'),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1754CF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1754CF).withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p20),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSizes.p24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeaderStat('Submissions', submissionCount.toString()),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(height: 30, child: VerticalDivider(width: 1)),
              ),
              _buildHeaderStat('Member since', memberSince),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontSize: 11,
            color: Color(0xFF1754CF),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1754CF).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF1754CF), size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await AuthService().logout();
            if (context.mounted) {
              context.go('/login');
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Logout Account',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
