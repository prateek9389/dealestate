import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import 'admin_home_screen.dart';
import 'admin_chat_list_screen.dart';
import 'admin_create_listing_screen.dart';
import 'admin_published_properties_screen.dart';
import 'admin_profile_screen.dart';

class AdminMainNavigationScreen extends StatefulWidget {
  const AdminMainNavigationScreen({super.key});

  @override
  State<AdminMainNavigationScreen> createState() => _AdminMainNavigationScreenState();
}

class _AdminMainNavigationScreenState extends State<AdminMainNavigationScreen> {
  int _selectedIndex = 0;
  bool _isVerifying = true;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  Future<void> _checkAdminRole() async {
    final role = await AuthService().getUserRole();
    if (mounted) {
      if (role != 'admin') {
        context.go('/home');
      } else {
        setState(() => _isVerifying = false);
      }
    }
  }

  final List<Widget> _screens = [
    const AdminHomeScreen(),
    const AdminChatListScreen(isTab: true),
    const AdminCreateListingScreen(isTab: true),
    const AdminPublishedPropertiesScreen(),
    const AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isVerifying) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.grid_view_rounded, Icons.grid_view_outlined, "Home"),
                _buildNavItem(1, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, "Chats"),
                _buildNavItem(2, Icons.add_box_rounded, Icons.add_box_outlined, "Post"),
                _buildNavItem(3, Icons.inventory_2_rounded, Icons.inventory_2_outlined, "Published"),
                _buildNavItem(4, Icons.admin_panel_settings_rounded, Icons.admin_panel_settings_outlined, "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = const Color(0xFF1754CF);
    final color = isSelected 
        ? accentColor 
        : (isDark ? Colors.white70 : Colors.black54);

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: index == 1 
                ? StreamBuilder<int>(
                    stream: ChatService().getTotalUnreadCountStream('admin', role: 'admin'),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.data ?? 0;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            isSelected ? activeIcon : inactiveIcon,
                            color: color,
                            size: 24,
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: -4,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isDark ? const Color(0xFF121212) : Colors.white, width: 1.5),
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    }
                  )
                : Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    color: color,
                    size: 24,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
