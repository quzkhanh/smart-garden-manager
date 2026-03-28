import 'package:flutter/material.dart';
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
    {'id': 'pump', 'icon': Icons.water_drop_rounded, 'label': 'pump'},
    {'id': 'mist', 'icon': Icons.cloud_rounded, 'label': 'mist'},
    {'id': 'fan', 'icon': Icons.air_rounded, 'label': 'fan'},
    {'id': 'light', 'icon': Icons.lightbulb_rounded, 'label': 'light'},
    {'id': 'valve', 'icon': Icons.settings_input_component_rounded, 'label': 'valve'},
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
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên thiết bị';
                }
                return null;
              },
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
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _controller.text.trim(),
                'type': _selectedType,
              });
            }
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
