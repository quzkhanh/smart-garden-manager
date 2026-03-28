import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class DeleteAreaDialog extends StatefulWidget {
  final String areaName;
  final VoidCallback onConfirm;

  const DeleteAreaDialog({
    super.key,
    required this.areaName,
    required this.onConfirm,
  });

  @override
  State<DeleteAreaDialog> createState() => _DeleteAreaDialogState();
}

class _DeleteAreaDialogState extends State<DeleteAreaDialog> {
  final _controller = TextEditingController();
  bool _canDelete = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final confirmWord = l10n.t('delete_confirm_word');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.t('delete_confirm_title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('delete_confirm_desc').replaceAll('{word}', confirmWord),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            enableInteractiveSelection: false, // No copy/paste
            decoration: InputDecoration(
              hintText: l10n.t('delete_confirm_hint'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            onChanged: (val) {
              setState(() {
                // Strict comparison with the localized word
                _canDelete = val.trim() == confirmWord;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.t('cancel')),
        ),
        ElevatedButton(
          onPressed: _canDelete
              ? () {
                  Navigator.pop(context);
                  widget.onConfirm();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(l10n.t('delete')),
        ),
      ],
    );
  }
}
