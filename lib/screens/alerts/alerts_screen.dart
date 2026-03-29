import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/alert_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_skeleton.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final alertProvider = context.watch<AlertProvider>();

    return Scaffold(
      body: SafeArea(
        child: alertProvider.isLoading
            ? _buildLoadingState()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with title + delete-read button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          l10n.t('alerts'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // Show delete-read button only on 'Read' tab
                        if (alertProvider.filter == AlertFilter.read &&
                            alertProvider.readCount > 0)
                          _DeleteReadButton(
                            key: const ValueKey('delete_read_btn'),
                            onTap: () => _confirmDeleteRead(
                                context, alertProvider, l10n),
                          ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  // Filter tabs
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: l10n.t('all'),
                          isSelected:
                              alertProvider.filter == AlertFilter.all,
                          onTap: () =>
                              alertProvider.setFilter(AlertFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: l10n.t('unread'),
                          isSelected:
                              alertProvider.filter == AlertFilter.unread,
                          onTap: () =>
                              alertProvider.setFilter(AlertFilter.unread),
                          badge: alertProvider.unreadCount > 0
                              ? alertProvider.unreadCount
                              : null,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: l10n.t('read'),
                          isSelected:
                              alertProvider.filter == AlertFilter.read,
                          onTap: () =>
                              alertProvider.setFilter(AlertFilter.read),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                  // Alert list
                  Expanded(
                    child: alertProvider.alerts.isEmpty
                        ? EmptyState(
                            icon: LucideIcons.bell,
                            title: l10n.t('no_alerts'),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: alertProvider.alerts.length,
                            itemBuilder: (context, index) {
                              final alert = alertProvider.alerts[index];
                              return Dismissible(
                                key: ValueKey(alert.id),
                                direction: DismissDirection.endToStart,
                                background: _buildDismissBackground(
                                    context, l10n),
                                onDismissed: (_) {
                                  alertProvider.deleteAlert(alert.id);
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.t('delete_alert'),
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        backgroundColor:
                                            AppColors.alertHigh,
                                        behavior:
                                            SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        duration:
                                            const Duration(seconds: 2),
                                      ),
                                    );
                                },
                                child: AlertCard(
                                  alert: alert,
                                  onTap: () {
                                    if (!alert.isRead) {
                                      alertProvider
                                          .markAsRead(alert.id);
                                    }
                                  },
                                ).animate().fadeIn(
                                      delay: Duration(
                                          milliseconds: 200 + index * 60),
                                      duration: 400.ms,
                                    ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDismissBackground(
      BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.alertHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.trash2,
              color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(
            l10n.t('delete'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRead(
    BuildContext context,
    AlertProvider alertProvider,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.t('delete_read'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          l10n.t('delete_read_confirm'),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  alertProvider.deleteReadAlerts();
                },
                icon: const Icon(LucideIcons.trash2, size: 18),
                label: Text(l10n.t('delete')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.alertHigh,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.t('cancel')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          LoadingSkeleton(width: 120, height: 32),
          SizedBox(height: 16),
          CardSkeleton(),
          SizedBox(height: 8),
          CardSkeleton(),
          SizedBox(height: 8),
          CardSkeleton(),
        ],
      ),
    );
  }
}

// ── Delete Read Button ────────────────────────────────────────────────────────

class _DeleteReadButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DeleteReadButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(
        LucideIcons.eraser,
        size: 16,
        color: AppColors.alertHigh,
      ),
      label: Text(
        l10n.t('delete_read'),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.alertHigh,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      ),
    );
  }
}

// ── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badge;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen
                : (theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected ? Colors.white : null,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : AppColors.alertHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
