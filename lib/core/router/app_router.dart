import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/change_password_screen.dart';
import '../../features/home/main_navigation_screen.dart';
import '../../features/submit/submit_property_screen.dart';
import '../../features/submit/submit_requirement_screen.dart';
import '../../features/admin/admin_main_navigation_screen.dart';
import '../../features/profile/my_submissions_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/profile/help_support_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/saved_properties_screen.dart';
import '../../features/profile/privacy_policy_screen.dart';
import '../../features/profile/terms_of_service_screen.dart';
import '../../features/admin/admin_create_listing_screen.dart';
import '../../features/admin/admin_chat_list_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/admin/access_control_screen.dart';
import '../../features/admin/brokerage_guide_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/home/notifications_screen.dart';
import '../../features/home/property_details_screen.dart';
import '../../models/seller_submission_model.dart';
import '../../models/admin_post_model.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: '/submit_property',
        builder: (context, state) => const SubmitPropertyScreen(),
      ),
      GoRoute(
        path: '/property/:id',
        builder: (context, state) => PropertyDetailsScreen(propertyId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final userId = state.uri.queryParameters['userId'];
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            otherUserId: userId,
            property: extra?['property'] as AdminPostModel?,
          );
        },
      ),
      GoRoute(
        path: '/submit_requirement',
        builder: (context, state) => const SubmitRequirementScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminMainNavigationScreen(),
      ),
      GoRoute(
        path: '/admin/create_listing',
        builder: (context, state) => const AdminCreateListingScreen(),
      ),
      GoRoute(
        path: '/admin/chats',
        builder: (context, state) => const AdminChatListScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/access-control',
        builder: (context, state) => const AccessControlScreen(),
      ),
      GoRoute(
        path: '/admin/guide',
        builder: (context, state) => const BrokerageGuideScreen(),
      ),
      GoRoute(
        path: '/admin/publish',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AdminCreateListingScreen(
            initialData: extra?['submission'] as SellerSubmissionModel?,
          );
        },
      ),
      GoRoute(
        path: '/profile/submissions',
        builder: (context, state) => const MySubmissionsScreen(),
      ),
      GoRoute(
        path: '/profile/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/help_support',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/saved',
        builder: (context, state) => const SavedPropertiesScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms-of-service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
    ],
  );
}
