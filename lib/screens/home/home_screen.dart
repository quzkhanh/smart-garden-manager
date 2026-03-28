import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/garden_provider.dart';
import '../../providers/alert_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/area_card.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/common/loading_skeleton.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final alertProvider = context.watch<AlertProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;
    final isMedium = screenWidth > 600;

    return Scaffold(
      body: SafeArea(
        child: garden.isLoading
            ? _buildLoadingState()
            : RefreshIndicator(
                onRefresh: () => garden.loadData(),
                color: AppColors.primaryGreen,
                child: CustomScrollView(
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('my_garden'),
                              style: theme.textTheme.headlineLarge,
                            ).animate().fadeIn(duration: 400.ms),
                            const SizedBox(height: 4),
                            Text(
                              l10n.t('overview'),
                              style: theme.textTheme.bodyMedium,
                            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                          ],
                        ),
                      ),
                    ),

                    // Summary cards
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (isWide) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: SummaryCard(
                                      icon: Icons.grid_view_rounded,
                                      color: AppColors.primaryGreen,
                                      label: l10n.t('total_areas'),
                                      value: '${garden.totalAreas}',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SummaryCard(
                                      icon: Icons.trending_up_rounded,
                                      color: AppColors.secondaryBlue,
                                      label: l10n.t('active_devices'),
                                      value: '${garden.totalActiveDevices}',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SummaryCard(
                                      icon: Icons.notifications_outlined,
                                      color: AppColors.alertHigh,
                                      label: l10n.t('alerts_count'),
                                      value: '${alertProvider.unreadCount}',
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                SummaryCard(
                                  icon: Icons.grid_view_rounded,
                                  color: AppColors.primaryGreen,
                                  label: l10n.t('total_areas'),
                                  value: '${garden.totalAreas}',
                                ),
                                const SizedBox(height: 10),
                                SummaryCard(
                                  icon: Icons.trending_up_rounded,
                                  color: AppColors.secondaryBlue,
                                  label: l10n.t('active_devices'),
                                  value: '${garden.totalActiveDevices}',
                                ),
                                const SizedBox(height: 10),
                                SummaryCard(
                                  icon: Icons.notifications_outlined,
                                  color: AppColors.alertHigh,
                                  label: l10n.t('alerts_count'),
                                  value: '${alertProvider.unreadCount}',
                                ),
                              ],
                            );
                          },
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // Area list
                    if (isWide || isMedium)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isWide ? 3 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 4,
                            childAspectRatio: isWide ? 0.85 : 0.75,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final area = garden.areas[index];
                              return AreaCard(
                                area: area,
                                onTap: () => context.push('/area/${area.id}'),
                              ).animate().fadeIn(
                                    delay: Duration(milliseconds: 300 + index * 80),
                                    duration: 400.ms,
                                  );
                            },
                            childCount: garden.areas.length,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final area = garden.areas[index];
                              return AreaCard(
                                area: area,
                                onTap: () => context.push('/area/${area.id}'),
                              ).animate().fadeIn(
                                    delay: Duration(milliseconds: 300 + index * 80),
                                    duration: 400.ms,
                                  );
                            },
                            childCount: garden.areas.length,
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingSkeleton(width: 160, height: 32),
          const SizedBox(height: 8),
          const LoadingSkeleton(width: 100, height: 16),
          const SizedBox(height: 24),
          const CardSkeleton(),
          const SizedBox(height: 8),
          const CardSkeleton(),
          const SizedBox(height: 8),
          const CardSkeleton(),
        ],
      ),
    );
  }
}
