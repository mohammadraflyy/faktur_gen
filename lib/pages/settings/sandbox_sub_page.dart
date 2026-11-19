import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/backup_service.dart';
import '../../services/locale_service.dart';
import '../../services/notification_service.dart';
import '../../services/reminder_service.dart';

class SandboxSubPage extends StatefulWidget {
  const SandboxSubPage({super.key});

  @override
  State<SandboxSubPage> createState() => _SandboxSubPageState();
}

class _SandboxSubPageState extends State<SandboxSubPage> {
  int _pendingNotifCount = 0;
  int _activeReminderCount = 0;
  String _lastBackup = '-';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final pending = await NotificationService.getPending();
    final reminders = await ReminderService.getUpcoming();
    final lastBackup = await BackupService.getLastAutoBackupTime();
    if (mounted) {
      setState(() {
        _pendingNotifCount = pending.length;
        _activeReminderCount = reminders.length;
        _lastBackup = lastBackup != null
            ? '${lastBackup.day}/${lastBackup.month}/${lastBackup.year}'
            : tr('sandbox.never');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('sandbox.title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info cards
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: theme.colorScheme.outlineVariant, width: 0.8),
            ),
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('sandbox.notif_status'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _infoRow(theme, tr('sandbox.active_reminders'),
                          '$_activeReminderCount'),
                      const SizedBox(height: 6),
                      _infoRow(theme, tr('sandbox.scheduled_notifs'),
                          '$_pendingNotifCount'),
                      const SizedBox(height: 6),
                      _infoRow(theme, tr('sandbox.last_backup'),
                          _lastBackup),
                      const SizedBox(height: 4),
                      Text(
                        tr('sandbox.backup_note'),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),

          // Test actions
          Text(
            tr('sandbox.test_actions'),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          _sandboxTile(
            theme,
            icon: Icons.notifications_active_outlined,
            title: tr('sandbox.test_notif'),
            subtitle: tr('sandbox.test_notif_sub'),
            onTap: () async {
              await NotificationService.showTestNotification();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr('sandbox.test_sent')),
                  backgroundColor:
                      AppColors.successFor(theme.brightness),
                ),
              );
              _loadInfo();
            },
          ),
          const SizedBox(height: 10),
          _sandboxTile(
            theme,
            icon: Icons.refresh_rounded,
            title: tr('sandbox.reschedule_all'),
            subtitle: tr('sandbox.reschedule_sub'),
            onTap: () async {
              await ReminderService.rescheduleNotifications();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr('sandbox.rescheduled')),
                  backgroundColor:
                      AppColors.successFor(theme.brightness),
                ),
              );
              _loadInfo();
            },
          ),
          const SizedBox(height: 10),
          _sandboxTile(
            theme,
            icon: Icons.cancel_outlined,
            title: tr('sandbox.cancel_all'),
            subtitle: tr('sandbox.cancel_sub'),
            color: Colors.red,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(tr('sandbox.cancel_confirm')),
                  content: Text(tr('sandbox.cancel_warn')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(tr('common.cancel')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(tr('sandbox.cancel_yes'),
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm != true || !mounted) return;
              await NotificationService.cancelAll();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('sandbox.cancelled'))),
              );
              _loadInfo();
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _sandboxTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? theme.colorScheme.primary;
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerTheme.color ?? Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: c, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5))),
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
