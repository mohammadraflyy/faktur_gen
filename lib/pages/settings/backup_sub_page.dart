import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/backup_service.dart';
import '../../services/locale_service.dart';

class BackupSubPage extends StatelessWidget {
  const BackupSubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('settings.backup'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _BackupTile(
            theme: theme,
            icon: Icons.upload_file_rounded,
            title: tr('settings.export_backup'),
            subtitle: tr('settings.export_backup_sub'),
            onTap: () async {
              try {
                await BackupService.export();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${tr('common.export_fail')}: $e')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 12),
          _BackupTile(
            theme: theme,
            icon: Icons.download_rounded,
            title: tr('settings.import_backup'),
            subtitle: tr('settings.import_backup_sub'),
            onTap: () => _confirmImport(context),
          ),
          const SizedBox(height: 16),
          Text(
            tr('settings.backup_note'),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmImport(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('settings.import_confirm')),
        content: Text(tr('settings.import_warn')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('common.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('settings.import'),
                style: TextStyle(
                    color: AppColors.warningFor(Theme.of(ctx).brightness))),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final success = await BackupService.import();
      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('settings.import_success')),
            backgroundColor: AppColors.successFor(Theme.of(context).brightness),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('settings.import_invalid'))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('common.import_fail')}: $e')),
        );
      }
    }
  }
}

class _BackupTile extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BackupTile({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerTheme.color ?? Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
