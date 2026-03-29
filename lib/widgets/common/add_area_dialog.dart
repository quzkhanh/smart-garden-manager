import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

class AddAreaDialog extends StatefulWidget {
  const AddAreaDialog({super.key});

  @override
  State<AddAreaDialog> createState() => _AddAreaDialogState();
}

class _AddAreaDialogState extends State<AddAreaDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<Map<String, dynamic>> _deviceTypes = [
    {'type': 'pump', 'label': 'pump', 'icon': LucideIcons.droplets, 'checked': true},
    {'type': 'fan', 'label': 'fan', 'icon': LucideIcons.wind, 'checked': true},
    {'type': 'light', 'label': 'light', 'icon': LucideIcons.lightbulb, 'checked': false},
    {'type': 'mist', 'label': 'mist', 'icon': LucideIcons.cloud, 'checked': false},
    {'type': 'valve', 'label': 'valve', 'icon': LucideIcons.settings, 'checked': false},
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
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(l10n.t('add_area')),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('area_name'),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.t('area_name_hint'),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.t('area_name_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.t('initial_devices'),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  l10n.t('select_devices'),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ..._deviceTypes.map((device) {
                  return CheckboxListTile(
                    value: device['checked'],
                    onChanged: (val) {
                      setState(() {
                        device['checked'] = val;
                      });
                    },
                    title: Text(l10n.t(device['label'])),
                    secondary: Icon(device['icon'], color: device['checked'] ? AppColors.primaryGreen : null),
                    activeColor: AppColors.primaryGreen,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.t('cancel')),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final selectedDevices = _deviceTypes
                  .where((d) => d['checked'] == true)
                  .map((d) => d['type'] as String)
                  .toList();
              
              Navigator.pop(context, {
                'name': _controller.text.trim(),
                'devices': selectedDevices,
              });
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
    );
  }
}
