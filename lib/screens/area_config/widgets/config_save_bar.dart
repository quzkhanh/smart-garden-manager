import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ConfigSaveBar extends StatelessWidget {
  final bool hasChanges;
  final bool isSaving;
  final String label;
  final VoidCallback onSave;

  const ConfigSaveBar({
    super.key,
    required this.hasChanges,
    required this.isSaving,
    required this.label,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2128) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: AnimatedOpacity(
            opacity: hasChanges ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: (hasChanges && !isSaving) ? onSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.primaryGreen.withValues(alpha: 0.5),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_upload_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
