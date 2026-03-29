import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      icon: Icons.eco_rounded,
      color: AppColors.primaryGreen,
      titleKey: 'onboarding_title_1',
      descKey: 'onboarding_desc_1',
    ),
    OnboardingData(
      icon: Icons.analytics_rounded,
      color: AppColors.secondaryBlue,
      titleKey: 'onboarding_title_2',
      descKey: 'onboarding_desc_2',
    ),
    OnboardingData(
      icon: Icons.settings_remote_rounded,
      color: Colors.orange,
      titleKey: 'onboarding_title_3',
      descKey: 'onboarding_desc_3',
    ),
    OnboardingData(
      icon: Icons.auto_fix_high_rounded,
      color: Colors.purple,
      titleKey: 'onboarding_title_4',
      descKey: 'onboarding_desc_4',
    ),
    OnboardingData(
      icon: Icons.rocket_launch_rounded,
      color: AppColors.primaryGreen,
      titleKey: 'onboarding_title_5',
      descKey: 'onboarding_desc_5',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onFinish() {
    context.read<AuthProvider>().completeOnboarding();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _OnboardingPage(data: _pages[index]);
            },
          ),
          
          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: TextButton(
              onPressed: _onFinish,
              child: Text(
                l10n.t('skip'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicators
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => _buildDot(index),
                  ),
                ),

                // Next Button
                GestureDetector(
                  onTap: () {
                    if (_currentPage == _pages.length - 1) {
                      _onFinish();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubic,
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 56,
                    width: _currentPage == _pages.length - 1 ? 140 : 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _currentPage == _pages.length - 1
                          ? Text(
                              l10n.t('get_started'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppColors.primaryGreen : Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 100,
              color: data.color,
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
          const SizedBox(height: 60),
          Text(
            l10n.t(data.titleKey),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ).animate().slideY(begin: 0.3, duration: 500.ms).fadeIn(delay: 200.ms),
          const SizedBox(height: 20),
          Text(
            l10n.t(data.descKey),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey,
              height: 1.5,
            ),
          ).animate().slideY(begin: 0.3, duration: 500.ms).fadeIn(delay: 400.ms),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class OnboardingData {
  final IconData icon;
  final Color color;
  final String titleKey;
  final String descKey;

  OnboardingData({
    required this.icon,
    required this.color,
    required this.titleKey,
    required this.descKey,
  });
}
