import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/garden_provider.dart';
import '../../providers/alert_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/area_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final name = await _showAddAreaDialog(context);
          if (name != null && name.trim().isNotEmpty) {
            await garden.addArea(name.trim());
          }
        },
        backgroundColor: AppColors.primaryGreen,
        child: Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: SafeArea(
        child: garden.isLoading
            ? _buildLoadingState()
            : RefreshIndicator(
                onRefresh: () async {
                  await garden.refreshData();
                },
                color: AppColors.primaryGreen,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header & Dashboard
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Greeting Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _getGreeting(context, garden.currentWeather),
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ).animate().fadeIn(duration: 400.ms),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Dashboard Grid (3 rows, 2 columns - 1:3 Width Ratio)
                            if (garden.currentWeather != null)
                              Column(
                                children: [
                                  // Row 1: Areas + Weather Status
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: _buildCompactMetric(
                                          icon: LucideIcons.layoutGrid,
                                          value: '${garden.totalAreas}',
                                          label: l10n.t('total_areas'),
                                          color: AppColors.primaryGreen,
                                          isExpanded: true,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 3,
                                        child: _buildCompactMetric(
                                          icon: _getWeatherIcon(garden.currentWeather),
                                          value: garden.currentWeather?.description ?? 'N/A',
                                          label: l10n.t('weather_status'),
                                          color: AppColors.primaryGreen,
                                          isExpanded: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  
                                  // Row 2: Devices + Temperature
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: _buildCompactMetric(
                                          icon: LucideIcons.cpu,
                                          value: '${garden.totalDevices}',
                                          label: l10n.t('total_devices'),
                                          color: AppColors.secondaryBlue,
                                          isExpanded: true,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 3,
                                        child: _buildCompactMetric(
                                          icon: LucideIcons.thermometer,
                                          value: '${garden.currentWeather?.temp.round() ?? "--"}°C',
                                          label: l10n.t('weather_temp'),
                                          color: AppColors.alertMedium,
                                          isExpanded: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
      
                                  // Row 3: Alerts + Location
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: _buildCompactMetric(
                                          icon: LucideIcons.bellRing,
                                          value: '${alertProvider.unreadCount}',
                                          label: l10n.t('alerts_count'),
                                          color: alertProvider.unreadCount > 0 ? AppColors.alertHigh : Colors.grey,
                                          isExpanded: true,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 3,
                                        child: _buildCompactMetric(
                                          icon: LucideIcons.mapPin,
                                          value: _formatCityName(garden.currentWeather?.cityName),
                                          label: l10n.t('location'),
                                          color: Colors.orange,
                                          isExpanded: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ).animate().fadeIn(delay: 100.ms),
                          ],
                        ),
                      ),
                    ),
      
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
      
                    // Area list
                    if (garden.areas.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.leaf,
                                  size: 80,
                                  color: AppColors.primaryGreen.withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  l10n.t('no_areas'),
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.t('no_areas_desc'),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (isWide || isMedium)
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
      
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
      ),

    );
  }

  Widget _buildCompactMetric({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    bool isExpanded = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: label,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  String _getGreeting(BuildContext context, dynamic weather) {
    final l10n = AppLocalizations.of(context);
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return l10n.t('good_morning');
    if (hour >= 12 && hour < 17) return l10n.t('good_afternoon');
    if (hour >= 17 && hour < 21) return l10n.t('good_evening');
    return l10n.t('good_night');
  }

  IconData _getWeatherIcon(dynamic weather) {
    if (weather == null) return LucideIcons.cloud;
    final condition = weather.condition.toLowerCase();
    
    if (condition.contains('sun') || condition.contains('clear')) return LucideIcons.sun;
    if (condition.contains('cloud')) return LucideIcons.cloud;
    if (condition.contains('rain')) return LucideIcons.cloudRain;
    if (condition.contains('storm')) return LucideIcons.cloudLightning;
    
    return LucideIcons.sun;
  }
  String _formatCityName(String? name) {
    if (name == null || name.isEmpty) return 'N/A';
    
    // OpenWeatherMap often returns "City Name, CountryCode" 
    // or sometimes very detailed names in Vietnamese.
    // We want to keep it simple.
    
    String formatted = name.split(',').first;
    
    // Remove common suffixes to keep it clean
    formatted = formatted
        .replaceAll(' City', '')
        .replaceAll(' Thành phố', '')
        .replaceAll(' Tỉnh', '')
        .replaceAll(' Quận', '')
        .replaceAll(' Huyện', '')
        .trim();
        
    return formatted;
  }

  Future<String?> _showAddAreaDialog(BuildContext context) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.t('add_area')),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('area_name'),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.t('area_name_hint'),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Mỗi khu vực sẽ có 3 thiết bị cố định: Máy bơm, Quạt, Đèn.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx, name);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(l10n.t('confirm')),
          ),
        ],
      ),
    );
  }
}
