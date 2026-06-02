import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  late bool _darkMode;

  @override
  void initState() {
    super.initState();
    _darkMode = AppTheme.themeNotifier.value == ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.p16),
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            value: _pushNotifications,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() {
                _pushNotifications = val;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Email Notifications'),
            value: _emailNotifications,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() {
                _emailNotifications = val;
              });
            },
          ),
          const Divider(),
          const Text(
            'Preferences',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _darkMode,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() {
                _darkMode = val;
                AppTheme.toggleTheme(val);
              });
            },
          ),
          const Divider(),
          const Text(
            'Account',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          ListTile(
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/change-password'),
          ),
          ListTile(
            title: const Text('Reset via Email'),
            subtitle: const Text('Send recovery link to your inbox'),
            trailing: const Icon(Icons.mail_outline_rounded, size: 16),
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
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/privacy-policy'),
          ),
          ListTile(
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/terms-of-service'),
          ),
        ],
      ),
    );
  }
}
