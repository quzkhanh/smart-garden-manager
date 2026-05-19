import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/alert_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../screens/login/login_screen.dart';
import '../screens/login/otp_screen.dart';
import '../screens/login/qr_login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/area_detail/area_detail_screen.dart';
import '../screens/area_config/area_config_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/devices/devices_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/access_management_screen.dart';
import '../screens/activity/activity_log_screen.dart';

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
          // No auto-redirect to onboarding - start at login

          // Not authenticated
          if (authProvider.state == AuthState.otpSent ||
              authProvider.state == AuthState.verifying) {
            return state.matchedLocation == '/otp' ? null : '/otp';
          }
          if (authProvider.state == AuthState.qrWaiting) {
            return state.matchedLocation == '/qr-login' ? null : '/qr-login';
          }
          // State is unauthenticated — always go to /login
          if (state.matchedLocation != '/login' && 
              state.matchedLocation != '/onboarding') {
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
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
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
        GoRoute(
          path: '/access-management',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AccessManagementScreen(),
        ),
        GoRoute(
          path: '/activity-log',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const ActivityLogScreen(),
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
              children: [
                Expanded(
                  child: _NavItem(
                    icon: LucideIcons.home,
                    label: _getNavLabel(context, 0),
                    isSelected: currentIndex == 0,
                    onTap: () => context.go('/'),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: LucideIcons.bell,
                    label: _getNavLabel(context, 1),
                    isSelected: currentIndex == 1,
                    badge: alertProvider.unreadCount,
                    onTap: () => context.go('/alerts'),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: LucideIcons.shieldCheck,
                    label: _getNavLabel(context, 2),
                    isSelected: currentIndex == 2,
                    onTap: () => context.go('/devices'),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: LucideIcons.settings,
                    label: _getNavLabel(context, 3),
                    isSelected: currentIndex == 3,
                    onTap: () => context.go('/settings'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getNavLabel(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context);
    switch (index) {
      case 0:
        return l10n.t('home');
      case 1:
        return l10n.t('alerts');
      case 2:
        return l10n.t('nav_devices');
      case 3:
        return l10n.t('settings');
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
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: isSelected ? const EdgeInsets.all(8) : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (badge > 0)
                  Positioned(
                    right: isSelected ? -2 : -10,
                    top: isSelected ? -2 : -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.alertHigh,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E2128) : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
              crossFadeState: isSelected ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
