import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/dashboard_summary.dart';
import '../models/history_model.dart';
import '../models/reminder_model.dart';
import '../models/settings_model.dart';
import '../services/history_service.dart';
import '../services/locale_service.dart';
import '../services/reminder_service.dart';
import '../services/settings_service.dart';
import '../widgets/status_label.dart';
import 'faktur_page.dart';
import 'main_navigation.dart';

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
  bool _showLoadingText = false;
  bool _failed = false;
  int _selectedMonth = 5;
  Timer? _loadingTimer;

  NumberFormat get _currency => NumberFormat.currency(
        locale: _settings.currencyLocale,
        symbol: _settings.currencySymbol,
        decimalDigits: 0,
      );

  String get _dateLocale => LocaleService.isEn ? 'en_US' : 'id_ID';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _loadingTimer?.cancel();
    // A fast load should not flash a loading message.
    _loadingTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _isLoading) setState(() => _showLoadingText = true);
    });
    try {
      final results = await Future.wait([
        HistoryService.load(),
        SettingsService.load(),
        ReminderService.getUpcoming(),
      ]);
      if (!mounted) return;
      setState(() {
        _entries = results[0] as List<HistoryEntry>;
        _settings = results[1] as SettingsModel;
        _reminders = results[2] as List<ReminderModel>;
        _isLoading = false;
        _failed = false;
        _selectedMonth = 5;
      });
    } catch (e) {
      debugPrint('[Dashboard] load failed: $e');
      if (!mounted) return;
      if (!_isLoading) {
        // Failed pull-to-refresh: keep the numbers already on screen.
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('dashboard.load_failed'))));
      } else {
        setState(() {
          _isLoading = false;
          _failed = true;
        });
      }
    } finally {
      _loadingTimer?.cancel();
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _showLoadingText = false;
      _failed = false;
    });
    _load();
  }

  Future<void> _createInvoice() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const FakturPage()));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: _showLoadingText
              ? Text(tr('dashboard.loading'), style: theme.textTheme.bodySmall)
              : const SizedBox.shrink(),
        ),
      );
    }
    if (_failed) {
      return Scaffold(
        body: Center(
          child: _message(
              theme, tr('dashboard.load_failed'), tr('dashboard.retry'), _retry),
        ),
      );
    }

    final summary = DashboardSummary.from(_entries, DateTime.now());
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              _header(theme),
              if (_settings.namaToko.isEmpty) ...[
                const SizedBox(height: 24),
                const Divider(height: 1),
                _storeBanner(theme),
                const Divider(height: 1),
              ],
              const SizedBox(height: 40),
              if (_entries.isEmpty)
                _message(theme, tr('dashboard.empty'),
                    tr('dashboard.create_invoice'), _createInvoice)
              else ...[
                _unpaid(theme, summary),
                const SizedBox(height: 40),
                _income(theme, summary),
              ],
              if (_reminders.isNotEmpty) ...[
                const SizedBox(height: 40),
                _reminderList(theme),
              ],
              if (_entries.isNotEmpty) ...[
                const SizedBox(height: 40),
                _recent(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _message(
      ThemeData theme, String text, String action, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text,
              style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(DateFormat('EEEE, d MMMM', _dateLocale).format(DateTime.now()),
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          _settings.namaToko.isEmpty ? tr('dashboard.title') : _settings.namaToko,
          style: theme.textTheme.headlineSmall,
        ),
      ],
    );
  }

  Widget _storeBanner(ThemeData theme) {
    return InkWell(
      onTap: () => MainNavigation.goToTab(context, 3),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('dashboard.setup_store'),
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(tr('dashboard.setup_store_sub'),
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _unpaid(ThemeData theme, DashboardSummary s) {
    final now = DateTime.now();
    final error = AppColors.errorFor(theme.brightness);
    final shown = s.overdue.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('dashboard.unpaid_heading'), style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        // Shrink instead of wrapping a big amount at large text sizes.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(_currency.format(s.unpaidTotal),
              style: theme.textTheme.displaySmall),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(trN('dashboard.invoice_count', s.unpaidCount),
                style: theme.textTheme.bodySmall),
            if (s.overdue.isNotEmpty)
              StatusLabel(
                text: trN('dashboard.overdue_count', s.overdue.length),
                color: error,
              ),
          ],
        ),
        if (shown.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Divider(height: 1),
          for (final e in shown) ...[
            _overdueRow(theme, e, now, error),
            const Divider(height: 1),
          ],
        ],
        if (s.unpaidCount > shown.length)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  MainNavigation.goToTab(context, 1, unpaidOnly: true),
              child: Text(trN('dashboard.see_all', s.unpaidCount)),
            ),
          ),
      ],
    );
  }

  Widget _overdueRow(
      ThemeData theme, HistoryEntry e, DateTime now, Color error) {
    return InkWell(
      onTap: () => MainNavigation.goToTab(context, 1, unpaidOnly: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.namaKlien.isEmpty ? e.nomorDokumen : e.namaKlien,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(e.nomorDokumen, style: theme.textTheme.bodySmall),
                      StatusLabel(
                        text: trN('dashboard.days_late',
                            DashboardSummary.daysOverdue(e, now)),
                        color: error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(_currency.format(e.totalAmount),
                style: theme.textTheme.titleSmall),
          ],
        ),
      ),
    );
  }

  Widget _income(ThemeData theme, DashboardSummary s) {
    final monthName = DateFormat('MMMM', _dateLocale);
    final m = s.months[_selectedMonth];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(monthName.format(s.thisMonth.month),
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(_currency.format(s.thisMonth.total),
            style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          '${tr('dashboard.income')} · '
          '${monthName.format(s.lastMonth.month)} '
          '${_currency.format(s.lastMonth.total)}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 2),
        Text(
          '${trN('dashboard.invoice_count', s.thisMonth.invoices)} · '
          '${trN('dashboard.receipt_count', s.thisMonth.struks)}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        _chart(theme, s.months),
        const SizedBox(height: 8),
        Text(
          '${monthName.format(m.month)} · '
          '${trN('dashboard.invoice_count', m.invoices)} · '
          '${trN('dashboard.receipt_count', m.struks)} · '
          '${_currency.format(m.total)}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _chart(ThemeData theme, List<MonthTotal> months) {
    final max = months.fold<double>(0, (m, e) => e.total > m ? e.total : m);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.47);
    final monthName = DateFormat('MMMM', _dateLocale);
    final shortName = DateFormat('MMM', _dateLocale);
    return Row(
      children: [
        for (var i = 0; i < months.length; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: i == _selectedMonth,
              label: '${monthName.format(months[i].month)}, '
                  '${_currency.format(months[i].total)}',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => setState(() => _selectedMonth = i),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 72,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 20,
                              height: max == 0
                                  ? 4
                                  : 4 + 68 * months[i].total / max,
                              decoration: BoxDecoration(
                                color: i == _selectedMonth
                                    ? theme.colorScheme.primary
                                    : muted,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(shortName.format(months[i].month),
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _reminderList(ThemeData theme) {
    final error = AppColors.errorFor(theme.brightness);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('dashboard.upcoming_reminders'),
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        const Divider(height: 1),
        for (final r in _reminders.take(3)) ...[
          _reminderRow(theme, r, error),
          const Divider(height: 1),
        ],
        if (_reminders.length > 3)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => MainNavigation.goToTab(context, 2),
              child: Text(trN('dashboard.see_all', _reminders.length)),
            ),
          ),
      ],
    );
  }

  Widget _reminderRow(ThemeData theme, ReminderModel r, Color error) {
    return InkWell(
      onTap: () => MainNavigation.goToTab(context, 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.contactName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (r.serviceName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(r.serviceName, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (r.isOverdue)
              StatusLabel(text: tr('dashboard.overdue'), color: error)
            else if (r.isDue)
              StatusLabel(
                  text: tr('dashboard.today'),
                  color: AppColors.warningFor(theme.brightness))
            else
              Text(DateFormat('d MMM', _dateLocale).format(r.reminderDate),
                  style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _recent(ThemeData theme) {
    final recent = [..._entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('dashboard.recent'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        const Divider(height: 1),
        for (final e in recent.take(3)) ...[
          _recentRow(theme, e),
          const Divider(height: 1),
        ],
      ],
    );
  }

  Widget _recentRow(ThemeData theme, HistoryEntry e) {
    return InkWell(
      onTap: () => MainNavigation.goToTab(context, 1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.namaKlien.isEmpty ? e.nomorDokumen : e.namaKlien,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${e.nomorDokumen} · ${e.docType == DocType.invoice ? tr('dashboard.invoice') : tr('dashboard.receipt')}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(_currency.format(e.totalAmount),
                style: theme.textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}
