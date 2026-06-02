import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Admin Console',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<UserModel?>(
        future: AuthService().getCurrentUser(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1754CF).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1754CF), width: 2),
                          image: user?.profilePictureUrl != null && user!.profilePictureUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(user.profilePictureUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (user?.profilePictureUrl == null || user!.profilePictureUrl.isEmpty)
                            ? Center(
                                child: Text(
                                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'A',
                                  style: const TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1754CF),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        user?.name ?? 'Broker Admin',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5),
                      ),
                      Text(
                        user?.email ?? 'support@dealestate.com',
                        style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1754CF), Color(0xFF3F7AF0)]),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'MASTER BROKER',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                
                _buildProfileItem(
                  context,
                  icon: Icons.menu_book_rounded,
                  title: 'Brokerage Guide',
                  subtitle: 'How to use this platform',
                  isDark: isDark,
                  onTap: () => context.push('/admin/guide'),
                ),
                _buildProfileItem(
                  context,
                  icon: Icons.vpn_key_rounded,
                  title: 'Change Password',
                  subtitle: 'Update admin credentials',
                  isDark: isDark,
                  onTap: () => context.push('/change-password'),
                ),
                _buildProfileItem(
                  context,
                  icon: Icons.mail_lock_rounded,
                  title: 'Reset via Email',
                  subtitle: 'Send recovery link to admin inbox',
                  isDark: isDark,
                  onTap: () async {
                    final user = await AuthService().getCurrentUser();
                    if (user != null) {
                      try {
                        await AuthService().sendPasswordResetEmail(user.email);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Recovery link sent to ${user.email}')),
                          );
                        }
                      } catch (e) {
                         if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      }
                    }
                  },
                ),
                _buildProfileItem(
                  context,
                  icon: Icons.shield_rounded,
                  title: 'Access Control',
                  subtitle: 'Manage roles & permissions',
                  isDark: isDark,
                  onTap: () => context.push('/admin/access-control'),
                ),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.red, width: 1)),
                    ),
                    onPressed: () async {
                      await AuthService().logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    child: const Text('Exit Admin Console', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 100), // Spacing for floating nav
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1754CF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF1754CF), size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
