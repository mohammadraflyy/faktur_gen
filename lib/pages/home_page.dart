import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/reminder_model.dart';
import '../models/settings_model.dart';
import '../services/reminder_service.dart';
import '../services/settings_service.dart';
import 'dashboard_page.dart';
import 'faktur_page.dart';
import 'history_page.dart';
import 'reminder_page.dart';
import 'struk_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SettingsModel _settings = SettingsModel();
  List<ReminderModel> _upcomingReminders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      SettingsService.load(),
      ReminderService.getUpcoming(),
    ]);
    if (mounted) {
      setState(() {
        _settings = results[0] as SettingsModel;
        _upcomingReminders = results[1] as List<ReminderModel>;
      });
      _checkDueReminders();
    }
  }

  void _checkDueReminders() {
    final dueList =
        _upcomingReminders.where((r) => r.isDue || r.isOverdue).toList();
    if (dueList.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _DueRemindersSheet(
          reminders: dueList,
          onAction: (r, action) async {
            if (action == 'done') {
              await ReminderService.updateStatus(r.id, ReminderStatus.done);
            } else if (action == 'invoice') {
              if (mounted) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FakturPage(
                      reminderItems: r.lastItems,
                      reminderContactName: r.contactName,
                    ),
                  ),
                );
              }
              return;
            } else if (action == 'struk') {
              if (mounted) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StrukPage(
                      reminderItems: r.lastItems,
                      reminderContactName: r.contactName,
                    ),
                  ),
                );
              }
              return;
            }
            _loadData();
          },
        ),
      );
    });
  }

  Future<void> _openSettings() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
    if (changed == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 600;
    final hPad = isTablet ? ((width - 600) / 2).clamp(24.0, 9999.0) : 20.0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 40),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Faktur Gen',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Buat invoice & struk dengan mudah',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                _iconBtn(
                  icon: Icons.bar_chart_rounded,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const DashboardPage())),
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _iconBtn(
                  icon: Icons.history_rounded,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HistoryPage())),
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _reminderBtn(theme),
                const SizedBox(width: 8),
                _iconBtn(
                  icon: Icons.settings_outlined,
                  onTap: _openSettings,
                  theme: theme,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Store banner
            _buildStoreBanner(theme),

            const SizedBox(height: 32),

            // Section label
            Text(
              'Buat Dokumen',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),

            // Doc cards
            _DocCard(
              title: 'Invoice',
              subtitle: 'Faktur profesional dengan PPN 11%',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF2563EB),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FakturPage()),
              ),
            ),
            const SizedBox(height: 12),
            _DocCard(
              title: 'Struk',
              subtitle: 'Struk kasir untuk barang atau jasa',
              icon: Icons.receipt_outlined,
              color: const Color(0xFF059669),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StrukPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reminderBtn(ThemeData theme) {
    final dueCount =
        _upcomingReminders.where((r) => r.isDue || r.isOverdue).length;
    return Stack(
      children: [
        _iconBtn(
          icon: Icons.notifications_outlined,
          onTap: () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ReminderPage()));
            _loadData();
          },
          theme: theme,
        ),
        if (dueCount > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$dueCount',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Material(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  Widget _buildStoreBanner(ThemeData theme) {
    final hasData = !_settings.isEmpty;
    return GestureDetector(
      onTap: _openSettings,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.dividerTheme.color ?? Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _settings.hasLogo
                    ? null
                    : theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                image: _settings.hasLogo
                    ? DecorationImage(
                        image: MemoryImage(_settings.logoBytes!),
                        fit: BoxFit.contain)
                    : null,
              ),
              child: _settings.hasLogo
                  ? null
                  : Icon(Icons.storefront_outlined,
                      color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: hasData
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _settings.namaToko,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (_settings.alamat.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _settings.alamat,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atur profil toko',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tambahkan nama, alamat, dan logo',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                size: 20),
          ],
        ),
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DocCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.dividerTheme.color ?? Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Due Reminders Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DueRemindersSheet extends StatelessWidget {
  final List<ReminderModel> reminders;
  final void Function(ReminderModel r, String action) onAction;

  const _DueRemindersSheet({
    required this.reminders,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.notifications_active,
                      color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengingat Jatuh Tempo',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${reminders.length} pengingat perlu ditindaklanjuti',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: reminders.length,
                itemBuilder: (_, i) {
                  final r = reminders[i];
                  final isOverdue = r.isOverdue;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOverdue
                            ? Colors.red.shade300
                            : Colors.orange.shade300,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.contactName,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    r.serviceName,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isOverdue
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isOverdue
                                    ? 'Terlewat'
                                    : 'Hari ini',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isOverdue ? Colors.red : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(r.reminderDate),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (r.hasLastItems) ...[
                              Expanded(
                                child: SizedBox(
                                  height: 34,
                                  child: OutlinedButton.icon(
                                    onPressed: () => onAction(
                                      r,
                                      r.docType == ReminderDocType.struk
                                          ? 'struk'
                                          : 'invoice',
                                    ),
                                    icon: Icon(
                                      r.docType == ReminderDocType.struk
                                          ? Icons.receipt_outlined
                                          : Icons.receipt_long_outlined,
                                      size: 14,
                                    ),
                                    label: Text(
                                      r.docType == ReminderDocType.struk
                                          ? 'Buat Struk'
                                          : 'Buat Invoice',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          r.docType == ReminderDocType.struk
                                              ? const Color(0xFF059669)
                                              : const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: SizedBox(
                                height: 34,
                                child: FilledButton.icon(
                                  onPressed: () => onAction(r, 'done'),
                                  icon: const Icon(Icons.check, size: 14),
                                  label: const Text('Selesai',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
