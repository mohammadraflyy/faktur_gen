import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/history_model.dart';
import '../models/reminder_model.dart';
import '../models/settings_model.dart';
import '../services/history_service.dart';
import '../services/reminder_service.dart';
import '../services/settings_service.dart';
import 'reminder_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<HistoryEntry> _entries = [];
  List<ReminderModel> _reminders = [];
  SettingsModel _settings = SettingsModel();
  bool _isLoading = true;

  NumberFormat get _currency => NumberFormat.currency(
        locale: _settings.currencyLocale,
        symbol: _settings.currencySymbol,
        decimalDigits: 0,
      );

  final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      HistoryService.load(),
      SettingsService.load(),
      ReminderService.getUpcoming(),
    ]);
    if (mounted) {
      setState(() {
        _entries = results[0] as List<HistoryEntry>;
        _settings = results[1] as SettingsModel;
        _reminders = results[2] as List<ReminderModel>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final thisMonth = _entries.where((e) =>
        e.createdAt.year == now.year && e.createdAt.month == now.month);
    final lastMonth = _entries.where((e) =>
        e.createdAt.year == (now.month == 1 ? now.year - 1 : now.year) &&
        e.createdAt.month == (now.month == 1 ? 12 : now.month - 1));

    final totalThisMonth = thisMonth.fold(0.0, (s, e) => s + e.totalAmount);
    final totalLastMonth = lastMonth.fold(0.0, (s, e) => s + e.totalAmount);
    final invoiceCount = thisMonth.where((e) => e.docType == DocType.invoice).length;
    final strukCount = thisMonth.where((e) => e.docType == DocType.struk).length;
    final unpaidCount = _entries.where((e) =>
        e.docType == DocType.invoice &&
        e.paymentStatus == PaymentStatus.unpaid).length;
    final unpaidTotal = _entries
        .where((e) =>
            e.docType == DocType.invoice &&
            e.paymentStatus == PaymentStatus.unpaid)
        .fold(0.0, (s, e) => s + e.totalAmount);

    // Monthly breakdown (last 6 months)
    final monthlyData = <String, double>{};
    for (var i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final label = DateFormat('MMM', 'id_ID').format(m);
      final total = _entries
          .where((e) => e.createdAt.year == m.year && e.createdAt.month == m.month)
          .fold(0.0, (s, e) => s + e.totalAmount);
      monthlyData[label] = total;
    }
    final maxMonthly = monthlyData.values.fold(0.0, (a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _statCard(
                  theme,
                  label: 'Bulan Ini',
                  value: _currency.format(totalThisMonth),
                  sub: '${invoiceCount + strukCount} dokumen',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  theme,
                  label: 'Bulan Lalu',
                  value: _currency.format(totalLastMonth),
                  sub: '${lastMonth.length} dokumen',
                  icon: Icons.history_rounded,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  theme,
                  label: 'Invoice',
                  value: '$invoiceCount',
                  sub: 'bulan ini',
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  theme,
                  label: 'Struk',
                  value: '$strukCount',
                  sub: 'bulan ini',
                  icon: Icons.receipt_outlined,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
          if (unpaidCount > 0) ...[
            const SizedBox(height: 12),
            _statCard(
              theme,
              label: 'Belum Lunas',
              value: _currency.format(unpaidTotal),
              sub: '$unpaidCount invoice',
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFD97706),
            ),
          ],

          const SizedBox(height: 28),

          // Chart
          Text(
            'Pendapatan 6 Bulan Terakhir',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 180,
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.dividerTheme.color ?? Colors.grey.shade200,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthlyData.entries.map((e) {
                final ratio = maxMonthly > 0 ? e.value / maxMonthly : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (e.value > 0)
                          Text(
                            _shortCurrency(e.value),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          height: (ratio * 100).clamp(4, 100),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.key,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Upcoming reminders
          if (_reminders.isNotEmpty) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pengingat Layanan',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ReminderPage()));
                    _load();
                  },
                  child: Text(
                    'Lihat Semua',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._reminders.take(5).map((r) => _reminderTile(theme, r)),
          ],
        ],
      ),
    );
  }

  Widget _reminderTile(ThemeData theme, ReminderModel r) {
    final isOverdue = r.isOverdue;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOverdue
              ? Colors.red.shade300
              : (theme.dividerTheme.color ?? Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isOverdue
                  ? Colors.red.withValues(alpha: 0.08)
                  : Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              size: 16,
              color: isOverdue ? Colors.red : Colors.orange,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r.contactName} — ${r.serviceName}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _dateFormat.format(r.reminderDate),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isOverdue
                        ? Colors.red
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          if (isOverdue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Terlewat',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  String _shortCurrency(double v) {
    if (v >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)}M';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return v.toInt().toString();
  }

  Widget _statCard(
    ThemeData theme, {
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}
