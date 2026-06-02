import 'package:flutter/material.dart';
import '../../widgets/responsive_layout.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FutureBuilder<UserModel?>(
      future: AuthService().getCurrentUser(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userModel = userSnapshot.data;
        if (userModel == null) {
          return const Scaffold(body: Center(child: Text('Please log in to view notifications.')));
        }

        final String notificationUid = userModel.role == 'admin' ? 'admin' : userModel.id;

        // Mark all as read when opening
        NotificationService().markAllAsRead(notificationUid);

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w900)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: ResponsiveLayout(
            maxWidth: 800,
            child: StreamBuilder<List<NotificationModel>>(
              stream: NotificationService().getNotificationsStream(notificationUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(context, notification, isDark);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel note, bool isDark) {
    IconData iconData;
    Color iconColor;

    switch (note.type) {
      case 'message':
        iconData = Icons.chat_bubble_rounded;
        iconColor = const Color(0xFF1754CF);
        break;
      case 'property':
        iconData = Icons.home_work_rounded;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.notifications_rounded;
        iconColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: note.isRead ? null : Border.all(color: iconColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 22),
        ),
        title: Text(
          note.title,
          style: TextStyle(
            fontWeight: note.isRead ? FontWeight.w600 : FontWeight.w900,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              note.body,
              style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.3),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('MMM d, h:mm a').format(note.timestamp),
              style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        onTap: () {
          if (note.type == 'message' && note.relatedId != null) {
            context.push('/chat');
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet.',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll notify you when something important happens.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
