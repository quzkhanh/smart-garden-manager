import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/alert_provider.dart';
import '../screens/login/login_screen.dart';
import '../screens/login/otp_screen.dart';
import '../screens/login/qr_login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/area_detail/area_detail_screen.dart';
import '../screens/area_config/area_config_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/devices/devices_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoginRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/otp' ||
            state.matchedLocation == '/qr-login';

        if (!isAuthenticated) {
          // Not authenticated
          if (authProvider.state == AuthState.otpSent ||
              authProvider.state == AuthState.verifying) {
            return state.matchedLocation == '/otp' ? null : '/otp';
          }
          if (authProvider.state == AuthState.qrWaiting) {
            return state.matchedLocation == '/qr-login' ? null : '/qr-login';
          }
          // State is unauthenticated — always go to /login
          if (state.matchedLocation != '/login') {
            return '/login';
          }
          return null;
        }

        // Authenticated - redirect from login pages
        if (isLoginRoute) {
          return '/';
        }
        return null;
      },
      routes: [
        // Login routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) => const OtpScreen(),
        ),
        GoRoute(
          path: '/qr-login',
          builder: (context, state) => const QrLoginScreen(),
        ),

        GoRoute(
          path: '/area/:areaId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final areaId = state.pathParameters['areaId']!;
            return AreaDetailScreen(areaId: areaId);
          },
        ),
        GoRoute(
          path: '/area/:areaId/config',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final areaId = state.pathParameters['areaId']!;
            return AreaConfigScreen(areaId: areaId);
          },
        ),

        // Main app with bottom navigation
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return _MainShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/alerts',
              builder: (context, state) => const AlertsScreen(),
            ),
            GoRoute(
              path: '/devices',
              builder: (context, state) => const DevicesScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    );
  }
}

class _MainShell extends StatelessWidget {
  final Widget child;

  const _MainShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return _MainShellBody(child: child);
  }
}

class _MainShellBody extends StatelessWidget {
  final Widget child;

  const _MainShellBody({required this.child});

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/alerts')) return 1;
    if (location.startsWith('/devices')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = _getCurrentIndex(context);
    final isDark = theme.brightness == Brightness.dark;
    final alertProvider = context.watch<AlertProvider>();

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2128) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: _getNavLabel(context, 0),
                  isSelected: currentIndex == 0,
                  onTap: () => context.go('/'),
                ),
                _NavItem(
                  icon: Icons.notifications_outlined,
                  label: _getNavLabel(context, 1),
                  isSelected: currentIndex == 1,
                  badge: alertProvider.unreadCount,
                  onTap: () => context.go('/alerts'),
                ),
                _NavItem(
                  icon: Icons.devices_rounded,
                  label: _getNavLabel(context, 2),
                  isSelected: currentIndex == 2,
                  onTap: () => context.go('/devices'),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: _getNavLabel(context, 3),
                  isSelected: currentIndex == 3,
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getNavLabel(BuildContext context, int index) {
    // Simple label lookup
    final locale = Localizations.localeOf(context);
    final isVi = locale.languageCode == 'vi';
    switch (index) {
      case 0:
        return isVi ? 'Trang chủ' : 'Home';
      case 1:
        return isVi ? 'Cảnh báo' : 'Alerts';
      case 2:
        return isVi ? 'Thiết bị' : 'Devices';
      case 3:
        return isVi ? 'Cài đặt' : 'Settings';
      default:
        return '';
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isSelected
        ? (isDark ? const Color(0xFF66DD6A) : theme.colorScheme.primary)
        : (isDark
            ? Colors.white.withValues(alpha: 0.55)
            : Colors.black.withValues(alpha: 0.45));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
