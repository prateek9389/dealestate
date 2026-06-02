import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RoleGuard extends StatelessWidget {
  final Widget userWidget;
  final Widget adminWidget;

  const RoleGuard({
    super.key,
    required this.userWidget,
    required this.adminWidget,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService().getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return userWidget; // Fallback to user
        }

        if (snapshot.data == 'admin') {
          return adminWidget;
        }

        return userWidget;
      },
    );
  }
}
