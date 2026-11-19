import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/settings_model.dart';
import '../../services/locale_service.dart';
import '../../services/settings_service.dart';

mixin SettingsSubPageMixin<T extends StatefulWidget> on State<T> {
  bool isSaving = false;

  Future<void> saveSettings(SettingsModel settings) async {
    setState(() => isSaving = true);
    await SettingsService.save(settings);
    setState(() => isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('settings.saved')),
          backgroundColor: AppColors.successFor(Theme.of(context).brightness),
          duration: const Duration(seconds: 1),
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: required
          ? (v) => (v == null || v.isEmpty)
              ? tr('settings.required').replaceAll('{label}', label)
              : null
          : null,
    );
  }

  Widget buildSaveButton(ThemeData theme, VoidCallback onSave) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isSaving ? null : onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        child: isSaving
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Text(tr('common.save')),
      ),
    );
  }
}
