import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/cubit/auth_state.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/main_shell.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/query/presentation/pages/query_page.dart';
import '../features/community/presentation/pages/community_feed_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/report/presentation/pages/report_form_page.dart';
import '../features/report/presentation/pages/report_detail_page.dart';
import '../features/report/presentation/pages/my_reports_page.dart';
import '../features/community/presentation/pages/post_detail_page.dart';
import '../features/community/presentation/pages/create_post_page.dart';
import '../features/appeal/presentation/pages/appeal_form_page.dart';
import '../features/appeal/presentation/pages/appeal_status_page.dart';
import '../features/profile/presentation/pages/settings_page.dart';
import '../features/alerts/presentation/pages/alerts_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authCubit.state;
      final isLoggedIn = authState is AuthAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }
      if (isLoggedIn && isLoginRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: '/query',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: QueryPage(),
            ),
          ),
          GoRoute(
            path: '/community',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CommunityFeedPage(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) => const ReportFormPage(),
      ),
      GoRoute(
        path: '/report/:id',
        builder: (context, state) => ReportDetailPage(
          reportId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/my-reports',
        builder: (context, state) => const MyReportsPage(),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) => PostDetailPage(
          postId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/post/create',
        builder: (context, state) => const CreatePostPage(),
      ),
      GoRoute(
        path: '/appeal',
        builder: (context, state) => const AppealFormPage(),
      ),
      GoRoute(
        path: '/appeal/:id',
        builder: (context, state) => AppealStatusPage(
          appealId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsPage(),
      ),
    ],
  );
}

/// A [ChangeNotifier] wrapper around a [Stream] to allow GoRouter to
/// refresh when the stream emits.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
