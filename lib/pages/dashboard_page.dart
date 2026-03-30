import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/history_model.dart';
import '../services/locale_service.dart';
import '../models/reminder_model.dart';
import '../models/settings_model.dart';
import '../services/history_service.dart';
import '../services/reminder_service.dart';
import '../services/settings_service.dart';

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
  int? _selectedChartIndex;

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
    try {
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
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('[Dashboard] load error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 600;
    final hPad = isTablet ? ((width - 600) / 2).clamp(24.0, 9999.0) : 20.0;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
    final invoiceCount =
        thisMonth.where((e) => e.docType == DocType.invoice).length;
    final strukCount =
        thisMonth.where((e) => e.docType == DocType.struk).length;
    final unpaidCount = _entries
        .where((e) =>
            e.docType == DocType.invoice &&
            e.paymentStatus == PaymentStatus.unpaid)
        .length;
    final unpaidTotal = _entries
        .where((e) =>
            e.docType == DocType.invoice &&
            e.paymentStatus == PaymentStatus.unpaid)
        .fold(0.0, (s, e) => s + e.totalAmount);

    // Overdue invoices (unpaid + past due date)
    final overdueEntries = _entries.where((e) =>
        e.docType == DocType.invoice &&
        e.paymentStatus == PaymentStatus.unpaid &&
        e.jatuhTempo != null &&
        e.jatuhTempo!.isBefore(now)).toList();
    final overdueTotal = overdueEntries.fold(0.0, (s, e) => s + e.totalAmount);

    // Collected this month (paid invoices this month)
    final collectedThisMonth = thisMonth
        .where((e) => e.paymentStatus == PaymentStatus.paid)
        .fold(0.0, (s, e) => s + e.totalAmount);

    final hasData = _entries.isNotEmpty;

    // Monthly breakdown (last 6 months)
    final monthlyData = <_MonthData>[];
    for (var i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final label = DateFormat('MMM', 'id_ID').format(m);
      final monthEntries = _entries
          .where((e) =>
              e.createdAt.year == m.year && e.createdAt.month == m.month)
          .toList();
      final total = monthEntries.fold(0.0, (s, e) => s + e.totalAmount);
      final invCount = monthEntries.where((e) => e.docType == DocType.invoice).length;
      final strCount = monthEntries.where((e) => e.docType == DocType.struk).length;
      monthlyData.add(_MonthData(label: label, total: total, invoices: invCount, struks: strCount));
    }
    final maxMonthly = monthlyData.fold(0.0, (a, b) => a > b.total ? a : b.total);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 40),
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('dashboard.title'),
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr('dashboard.subtitle'),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Store banner
              _buildStoreBanner(theme),

              const SizedBox(height: 24),

              // Empty state or content
              if (!hasData)
                _buildEmptyState(theme)
              else ...[
                // Summary cards
                _sectionLabel(theme, tr('dashboard.summary')),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        theme,
                        label: tr('dashboard.this_month'),
                        value: _currency.format(totalThisMonth),
                        sub: '${invoiceCount + strukCount} ${tr('dashboard.documents')}',
                        icon: Icons.trending_up_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        theme,
                        label: tr('dashboard.last_month'),
                        value: _currency.format(totalLastMonth),
                        sub: '${lastMonth.length} ${tr('dashboard.documents')}',
                        icon: Icons.history_rounded,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.45),
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
                        label: tr('dashboard.invoice'),
                        value: '$invoiceCount',
                        sub: tr('dashboard.this_month_short'),
                        icon: Icons.receipt_long_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        theme,
                        label: tr('dashboard.receipt'),
                        value: '$strukCount',
                        sub: tr('dashboard.this_month_short'),
                        icon: Icons.receipt_outlined,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                if (unpaidCount > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          theme,
                          label: tr('dashboard.unpaid'),
                          value: _currency.format(unpaidTotal),
                          sub: '$unpaidCount ${tr('dashboard.invoice').toLowerCase()}',
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.warningFor(theme.brightness),
                        ),
                      ),
                      if (overdueEntries.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            theme,
                            label: tr('dashboard.overdue_amount'),
                            value: _currency.format(overdueTotal),
                            sub: '${overdueEntries.length} ${tr('dashboard.invoice').toLowerCase()}',
                            icon: Icons.error_outline_rounded,
                            color: AppColors.errorFor(theme.brightness),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (collectedThisMonth > 0) ...[
                  const SizedBox(height: 12),
                  _statCard(
                    theme,
                    label: tr('dashboard.collected_month'),
                    value: _currency.format(collectedThisMonth),
                    sub: tr('dashboard.this_month_short'),
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.successFor(theme.brightness),
                  ),
                ],

                // Overdue invoices list
                if (overdueEntries.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _sectionLabel(theme, tr('dashboard.overdue_invoices')),
                  const SizedBox(height: 12),
                  ...overdueEntries.take(5).map((e) {
                    final daysOverdue = now.difference(e.jatuhTempo!).inDays;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.namaKlien,
                                    style: GoogleFonts.inter(fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface)),
                                  const SizedBox(height: 2),
                                  Text('${e.nomorDokumen} · $daysOverdue ${tr('dashboard.days_overdue')}',
                                    style: GoogleFonts.inter(fontSize: 12,
                                      color: AppColors.errorFor(theme.brightness))),
                                ],
                              ),
                            ),
                            Text(_currency.format(e.totalAmount),
                              style: GoogleFonts.inter(fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 28),

                // Chart
                _sectionLabel(theme, tr('dashboard.revenue_chart')),
                const SizedBox(height: 14),
                _buildChart(theme, monthlyData, maxMonthly),
              ],

              // Upcoming reminders (show regardless of data)
              if (_reminders.isNotEmpty) ...[
                const SizedBox(height: 28),
                _sectionLabel(theme, tr('dashboard.upcoming_reminders')),
                const SizedBox(height: 12),
                ..._reminders.take(5).map((r) => _reminderTile(theme, r)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.bar_chart_rounded,
                size: 32,
                color: theme.colorScheme.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text(
            tr('dashboard.no_data'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr('dashboard.no_data_sub'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreBanner(ThemeData theme) {
    final hasData = !_settings.isEmpty;
    return GestureDetector(
      onTap: _navigateToSettings,
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
                          tr('dashboard.setup_store'),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr('dashboard.setup_store_sub'),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                size: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToSettings() {
    // Walk up to MainNavigation's PageController via the page context
    // Simpler: use the PageView's controller by finding it
    final pageView = context.findAncestorWidgetOfExactType<PageView>();
    if (pageView != null && pageView.controller != null) {
      pageView.controller!.jumpToPage(3); // Settings tab
    }
  }

  Widget _buildChart(
      ThemeData theme, List<_MonthData> monthlyData, double maxMonthly) {
    final barColor = theme.colorScheme.primary;
    final sel = _selectedChartIndex;

    return Column(
      children: [
        Container(
          height: 190,
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.dividerTheme.color ?? Colors.grey.shade200,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(monthlyData.length, (i) {
              final d = monthlyData[i];
              final ratio = maxMonthly > 0 ? d.total / maxMonthly : 0.0;
              final isLast = i == monthlyData.length - 1;
              final isSelected = sel == i;
              final isHighlighted = isSelected || (sel == null && isLast);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedChartIndex = _selectedChartIndex == i ? null : i;
                  }),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (d.total > 0)
                          Text(
                            _shortCurrency(d.total),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: isHighlighted ? 0.6 : 0.35),
                            ),
                          ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: (ratio * 110).clamp(4.0, 110.0),
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? barColor.withValues(alpha: 0.7)
                                : barColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          d.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isHighlighted
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isHighlighted
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7)
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // Detail tooltip
        if (sel != null) ...[
          const SizedBox(height: 10),
          _buildChartDetail(theme, monthlyData[sel]),
        ],
      ],
    );
  }

  Widget _reminderTile(ThemeData theme, ReminderModel r) {
    final isOverdue = r.isOverdue;
    final isDue = r.isDue && !isOverdue;
    final accentColor = isOverdue
        ? AppColors.errorFor(theme.brightness)
        : isDue
            ? AppColors.warningFor(theme.brightness)
            : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isOverdue || isDue)
              ? accentColor.withValues(alpha: 0.4)
              : (theme.dividerTheme.color ?? Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              size: 16,
              color: accentColor,
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
                        ? accentColor
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          if (isOverdue || isDue)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isOverdue ? tr('dashboard.overdue') : tr('dashboard.today'),
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: accentColor),
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
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

  Widget _buildChartDetail(ThemeData theme, _MonthData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            data.label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          _chartDetailItem(theme, _currency.format(data.total), tr('dashboard.total')),
          _chartDetailItem(theme, '${data.invoices}', tr('dashboard.invoice')),
          _chartDetailItem(theme, '${data.struks}', tr('dashboard.receipt')),
        ],
      ),
    );
  }

  Widget _chartDetailItem(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

class _MonthData {
  final String label;
  final double total;
  final int invoices;
  final int struks;

  const _MonthData({
    required this.label,
    required this.total,
    required this.invoices,
    required this.struks,
  });
}
