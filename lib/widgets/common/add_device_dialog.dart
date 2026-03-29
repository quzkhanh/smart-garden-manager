import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

class AddDeviceDialog extends StatefulWidget {
  const AddDeviceDialog({super.key});

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'pump';

  final List<Map<String, dynamic>> _deviceTypes = [
    {'id': 'pump', 'icon': LucideIcons.droplets, 'label': 'pump'},
    {'id': 'mist', 'icon': LucideIcons.cloud, 'label': 'mist'},
    {'id': 'fan', 'icon': LucideIcons.wind, 'label': 'fan'},
    {'id': 'light', 'icon': LucideIcons.lightbulb, 'label': 'light'},
    {'id': 'valve', 'icon': LucideIcons.settings, 'label': 'valve'},
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    String _getDefaultName(String type, AppLocalizations l10n) {
      final typeLabel = l10n.t(type);
      final prefix = l10n.t('new_device_prefix');
      return '$prefix $typeLabel';
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.t('add_device')),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.t('device_name'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'VD: Máy bơm chính',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.t('device_type'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _deviceTypes.map((type) {
                final isSelected = _selectedType == type['id'];
                return ChoiceChip(
                  label: Text(l10n.t(type['label'])),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type['id']);
                    }
                  },
                  selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primaryGreen,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryGreen : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.t('cancel')),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _controller.text.trim().isEmpty 
                ? _getDefaultName(_selectedType, l10n)
                : _controller.text.trim();
                
            Navigator.pop(context, {
              'name': name,
              'type': _selectedType,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(l10n.t('confirm')),
        ),
      ],
    );
  }
}
