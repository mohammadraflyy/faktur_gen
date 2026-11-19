import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import '../main.dart';
import '../models/dashboard_summary.dart';
import '../models/history_model.dart';
import '../models/history_view.dart';
import '../models/faktur_model.dart';
import '../models/settings_model.dart';
import '../models/struk_model.dart';
import '../services/export_service.dart';
import '../services/history_service.dart';
import '../services/pdf_service.dart';
import '../services/settings_service.dart';
import '../services/struk_pdf_service.dart';
import '../pages/pdf_preview_page.dart';
import '../pages/faktur_page.dart';
import '../pages/struk_page.dart';
import '../services/locale_service.dart';
import '../widgets/status_label.dart';

class HistoryPage extends StatefulWidget {
  final bool unpaidOnly;

  const HistoryPage({super.key, this.unpaidOnly = false});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  List<HistoryEntry> _entries = [];
  List<HistoryEntry> _filtered = [];
  bool _isLoading = true;
  bool _showLoadingText = false;
  bool _failed = false;
  Timer? _loadingTimer;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late HistoryFilter _filter;
  late final TabController _tabCtrl;

  SettingsModel _settings = SettingsModel();

  NumberFormat get _currency => NumberFormat.currency(
        locale: _settings.currencyLocale,
        symbol: _settings.currencySymbol,
        decimalDigits: 0,
      );

  String get _dateLocale => LocaleService.isEn ? 'en_US' : 'id_ID';

  @override
  void initState() {
    super.initState();
    _filter = widget.unpaidOnly ? HistoryFilter.unpaid : HistoryFilter.all;
    _tabCtrl = TabController(
      length: HistoryFilter.values.length,
      initialIndex: _filter.index,
      vsync: this,
    );
    _load();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _tabCtrl.dispose();
    _searchCtrl.dispose();
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
      ]);
      if (!mounted) return;
      setState(() {
        _entries = results[0] as List<HistoryEntry>;
        _settings = results[1] as SettingsModel;
        _applyFilter();
        _isLoading = false;
        _failed = false;
      });
    } catch (e) {
      debugPrint('[History] load failed: $e');
      if (!mounted) return;
      if (!_isLoading) {
        // Failed refresh: keep the list already on screen.
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('history.load_failed'))));
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

  void _applyFilter() {
    _filtered = filterHistory(_entries, _filter, _searchQuery);
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilter();
    });
  }

  void _onTab(int index) {
    setState(() {
      _filter = HistoryFilter.values[index];
      _applyFilter();
    });
  }

  void _clearFilter() {
    _searchCtrl.clear();
    _tabCtrl.index = 0;
    setState(() {
      _searchQuery = '';
      _filter = HistoryFilter.all;
      _applyFilter();
    });
  }

  Future<void> _exportCsv() async {
    if (_filtered.isEmpty) return;
    try {
      await ExportService.exportCsv(_filtered);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('common.export_fail')}: $e')),
        );
      }
    }
  }

  void _delete(HistoryEntry entry) {
    setState(() {
      _entries = [..._entries]..remove(entry);
      _applyFilter();
    });
    // Undo waits for this, so the restore never interleaves with the delete.
    final deleting = HistoryService.delete(entry.id).then((_) => true,
        onError: (Object e) {
      debugPrint('[History] delete failed: $e');
      return false;
    });
    deleting.then((ok) {
      if (!ok && mounted) _load();
    });
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(
            tr('history.deleted').replaceAll('{name}', entry.nomorDokumen)),
        duration: const Duration(seconds: 4),
        persist: false,
        action: SnackBarAction(
          label: tr('common.undo'),
          // Still runs after leaving the tab; only the reload needs this page.
          onPressed: () async {
            if (await deleting) await HistoryService.add(entry);
            if (mounted) _load();
          },
        ),
      ));
  }

  void _duplicateEntry(HistoryEntry entry) {
    if (entry.docType == DocType.invoice) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FakturPage(initialEntry: entry),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StrukPage(initialEntry: entry),
        ),
      );
    }
  }

  void _showDetail(HistoryEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DetailSheet(
        entry: entry,
        currency: _currency,
        onDuplicate: () => _duplicateEntry(entry),
        onStatusChanged: (status) async {
          await HistoryService.updateStatus(entry.id, status);
          await _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('history.title')),
        actions: [
          if (_entries.isNotEmpty)
            TextButton(
              onPressed: _exportCsv,
              child: Text(tr('history.export_csv')),
            ),
        ],
      ),
      body: _body(theme),
    );
  }

  Widget _body(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: _showLoadingText
            ? Text(tr('dashboard.loading'), style: theme.textTheme.bodySmall)
            : const SizedBox.shrink(),
      );
    }
    if (_failed) {
      return Center(
        child: _message(theme, tr('history.load_failed'),
            tr('dashboard.retry'), _retry),
      );
    }
    if (_entries.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
          children: [
            Text(tr('history.empty'),
                style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(tr('history.empty_sub'),
                style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return Column(
      children: [
        _searchAndTabs(theme),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _filtered.isEmpty
                ? ListView(
                    children: [
                      _message(
                        theme,
                        _filter == HistoryFilter.unpaid && _searchQuery.isEmpty
                            ? tr('history.no_unpaid')
                            : tr('history.no_match'),
                        tr('history.clear_filter'),
                        _clearFilter,
                      ),
                    ],
                  )
                : _list(theme),
          ),
        ),
      ],
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

  Widget _searchAndTabs(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: tr('history.search'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: tr('history.clear_search'),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearch('');
                      },
                    ),
            ),
          ),
        ),
        TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          // 4 + the tab's own 16 lines the first label up with the 20dp page edge.
          padding: const EdgeInsets.symmetric(horizontal: 4),
          dividerColor: theme.dividerTheme.color,
          onTap: _onTab,
          tabs: [
            Tab(height: 48, text: tr('history.all')),
            Tab(height: 48, text: tr('history.invoice')),
            Tab(height: 48, text: tr('history.receipt')),
            Tab(height: 48, text: tr('history.unpaid')),
          ],
        ),
      ],
    );
  }

  Widget _list(ThemeData theme) {
    final width = MediaQuery.sizeOf(context).width;
    // Keep rows a readable width on tablets.
    final hPad = width >= 600 ? ((width - 680) / 2).clamp(20.0, 9999.0) : 20.0;
    final now = DateTime.now();
    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 32),
      children: [
        for (final (day, entries) in groupByDay(_filtered)) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Semantics(
              header: true,
              child: Text(_dayLabel(day, now),
                  style: theme.textTheme.bodySmall),
            ),
          ),
          const Divider(height: 1),
          for (final e in entries) ...[
            _entryRow(theme, e, now),
            const Divider(height: 1),
          ],
        ],
      ],
    );
  }

  String _dayLabel(DateTime day, DateTime now) {
    // UTC dates so a DST change cannot make a day 23 hours long.
    final ago = DateTime.utc(now.year, now.month, now.day)
        .difference(DateTime.utc(day.year, day.month, day.day))
        .inDays;
    if (ago == 0) return tr('history.today');
    if (ago == 1) return tr('history.yesterday');
    return DateFormat('d MMMM yyyy', _dateLocale).format(day);
  }

  Widget _entryRow(ThemeData theme, HistoryEntry e, DateTime now) {
    final isDark = theme.brightness == Brightness.dark;
    final type = e.docType == DocType.invoice
        ? tr('history.invoice')
        : tr('history.receipt');
    final method = e.metodeBayar;
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      resizeDuration: MediaQuery.disableAnimationsOf(context)
          ? null
          : const Duration(milliseconds: 200),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.errorFor(theme.brightness),
        child: Icon(Icons.delete_outline,
            // #0F1117 on #F87171 = 6.82:1; white on #B91C1C = 6.47:1.
            color: isDark ? const Color(0xFF0F1117) : Colors.white,
            semanticLabel: tr('common.delete')),
      ),
      onDismissed: (_) => _delete(e),
      child: InkWell(
        onTap: () => _showDetail(e),
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
                      [
                        e.nomorDokumen,
                        type,
                        if (method != null && method.isNotEmpty) method,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_currency.format(e.totalAmount),
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  _status(theme, e, now),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _status(ThemeData theme, HistoryEntry e, DateTime now) {
    final b = theme.brightness;
    if (e.docType == DocType.struk || e.paymentStatus == PaymentStatus.paid) {
      return StatusLabel(
          text: tr('history.paid'), color: AppColors.successFor(b));
    }
    final late = e.jatuhTempo == null ? 0 : DashboardSummary.daysOverdue(e, now);
    if (late > 0) {
      return StatusLabel(
          text: trN('history.days_late', late), color: AppColors.errorFor(b));
    }
    return StatusLabel(
        text: tr('history.unpaid'), color: AppColors.warningFor(b));
  }
}

// ─── Detail Bottom Sheet ─────────────────────────────────────────────────────

class _DetailSheet extends StatefulWidget {
  final HistoryEntry entry;
  final NumberFormat currency;
  final VoidCallback? onDuplicate;
  final Future<void> Function(PaymentStatus)? onStatusChanged;

  const _DetailSheet({
    required this.entry,
    required this.currency,
    this.onDuplicate,
    this.onStatusChanged,
  });

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  late HistoryEntry entry;
  NumberFormat get currency => widget.currency;
  VoidCallback? get onDuplicate => widget.onDuplicate;

  @override
  void initState() {
    super.initState();
    entry = widget.entry;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInvoice = entry.docType == DocType.invoice;
    final paid = entry.paymentStatus == PaymentStatus.paid;
    final locale = LocaleService.isEn ? 'en_US' : 'id_ID';
    final dateFmt = DateFormat('dd MMMM yyyy', locale);
    final dateTimeFmt = DateFormat('dd MMM yyyy, HH:mm', locale);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          isInvoice
                              ? tr('history.invoice')
                              : tr('history.receipt'),
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 2),
                      Text(entry.nomorDokumen,
                          style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _handlePrint(context),
                  icon: const Icon(Icons.print_outlined),
                  tooltip: tr('history.print'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _sectionTitle(theme, tr('history.doc_info')),
            _infoRow(theme, tr('history.doc_date'),
                dateFmt.format(entry.tanggalDokumen)),
            _infoRow(theme, tr('history.created_at'),
                dateTimeFmt.format(entry.createdAt)),
            if (isInvoice) ...[
              if (entry.jatuhTempo != null)
                _infoRow(theme, tr('history.due_date'),
                    dateFmt.format(entry.jatuhTempo!)),
              if (entry.namaPenjual != null && entry.namaPenjual!.isNotEmpty)
                _infoRow(theme, tr('history.seller'), entry.namaPenjual!),
              if (entry.namaKlien.isNotEmpty)
                _infoRow(theme, tr('history.buyer'), entry.namaKlien),
              if (entry.npwpPembeli != null && entry.npwpPembeli!.isNotEmpty)
                _infoRow(theme, tr('history.buyer_npwp'), entry.npwpPembeli!),
              if (entry.teleponPembeli != null &&
                  entry.teleponPembeli!.isNotEmpty)
                _infoRow(
                    theme, tr('history.buyer_phone'), entry.teleponPembeli!),
              if (entry.alamatPembeli != null &&
                  entry.alamatPembeli!.isNotEmpty)
                _infoRow(
                    theme, tr('history.buyer_address'), entry.alamatPembeli!),
            ] else ...[
              if (entry.namaToko != null && entry.namaToko!.isNotEmpty)
                _infoRow(theme, tr('history.store'), entry.namaToko!),
              if (entry.alamatToko != null && entry.alamatToko!.isNotEmpty)
                _infoRow(theme, tr('history.store_address'), entry.alamatToko!),
              if (entry.namaKasir != null && entry.namaKasir!.isNotEmpty)
                _infoRow(theme, tr('history.cashier'), entry.namaKasir!),
            ],

            if (entry.items.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionTitle(
                  theme,
                  isInvoice
                      ? tr('history.items_invoice')
                      : tr('history.items_receipt')),
              const Divider(height: 1),
              for (final item in entry.items) ...[
                _itemRow(theme, item),
                const Divider(height: 1),
              ],
            ],

            const SizedBox(height: 24),
            _sectionTitle(theme, tr('history.summary')),
            ..._totals(theme),

            if (entry.catatan.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionTitle(theme, tr('history.notes')),
              Text(entry.catatan, style: theme.textTheme.bodyMedium),
            ],

            if (isInvoice) ...[
              const SizedBox(height: 24),
              const Divider(height: 1),
              InkWell(
                onTap: () async {
                  final newStatus =
                      paid ? PaymentStatus.unpaid : PaymentStatus.paid;
                  await widget.onStatusChanged?.call(newStatus);
                  setState(() => entry.paymentStatus = newStatus);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('history.payment_status'),
                                style: theme.textTheme.bodySmall),
                            const SizedBox(height: 4),
                            StatusLabel(
                              text: paid
                                  ? tr('history.paid')
                                  : tr('history.unpaid'),
                              color: paid
                                  ? AppColors.successFor(theme.brightness)
                                  : AppColors.warningFor(theme.brightness),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(tr('history.tap_to_change'),
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
            ],

            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                Navigator.pop(context);
                onDuplicate?.call();
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(tr('history.duplicate')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handlePrint(BuildContext context) async {
    final settings = await SettingsService.load();
    final logoBytes = settings.logoBytes;
    final signatureBytes = settings.signatureBytes;

    if (!context.mounted) return;

    if (entry.docType == DocType.invoice) {
      final faktur = FakturModel(
        nomorFaktur: entry.nomorDokumen,
        tanggal: entry.tanggalDokumen,
        jatuhTempo: entry.jatuhTempo,
        namaPenjual: entry.namaPenjual ?? '',
        namaPembeli: entry.namaKlien,
        npwpPembeli: entry.npwpPembeli ?? '',
        alamatPembeli: entry.alamatPembeli ?? '',
        teleponPembeli: entry.teleponPembeli ?? '',
        catatan: entry.catatan,
        taxRate: entry.taxRate ?? settings.taxRate,
        currency: entry.currency ?? settings.currency,
        items: entry.items
            .map((i) => ItemFaktur(
                  namaBarang: i.nama,
                  kuantitas: i.kuantitas,
                  satuan: i.satuan,
                  hargaSatuan: i.hargaSatuan,
                ))
            .toList(),
        bankAccounts: settings.activeBanks,
      );
      Navigator.pop(context); // close detail sheet
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewPage(
            title: tr('invoice.preview_title'),
            filename: 'Invoice_${faktur.nomorFaktur.replaceAll('/', '-')}.pdf',
            buildPdf: (format) => PdfService.buildBytes(faktur, format,
                logoBytes: logoBytes,
                signatureBytes: signatureBytes,
                templateConfig: settings.templateConfig),
          ),
        ),
      );
    } else {
      final struk = StrukModel(
        nomorStruk: entry.nomorDokumen,
        tanggal: entry.tanggalDokumen,
        namaToko: entry.namaToko ?? '',
        alamatToko: entry.alamatToko ?? '',
        namaKasir: entry.namaKasir ?? '',
        diskon: entry.diskon ?? 0,
        metodeBayar: _parseMetodeBayar(entry.metodeBayar),
        jumlahBayar: entry.jumlahBayar ?? 0,
        catatan: entry.catatan,
        items: entry.items
            .map((i) => ItemStruk(
                  nama: i.nama,
                  kuantitas: i.kuantitas,
                  satuan: i.satuan,
                  hargaSatuan: i.hargaSatuan,
                  diskon: i.diskon,
                ))
            .toList(),
      );
      Navigator.pop(context); // close detail sheet
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewPage(
            title: tr('history.preview_receipt'),
            filename: 'Struk_${struk.nomorStruk.replaceAll('/', '-')}.pdf',
            buildPdf: (format) => StrukPdfService.buildBytes(struk, format,
                logoBytes: logoBytes,
                currencySymbol: settings.currencySymbol,
                currencyLocale: settings.currencyLocale,
                templateConfig: settings.templateConfig),
            canChangePageFormat: false,
            initialPageFormat: const PdfPageFormat(226.77, double.infinity,
                marginAll: 12),
          ),
        ),
      );
    }
  }

  static MetodeBayar _parseMetodeBayar(String? value) {
    if (value == null) return MetodeBayar.tunai;
    for (final m in MetodeBayar.values) {
      if (m.label == value || m.name == value) return m;
    }
    return MetodeBayar.tunai;
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        header: true,
        child: Text(title, style: theme.textTheme.titleMedium),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    // Label above the value, so long labels survive 200% text.
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _itemRow(ThemeData theme, HistoryItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nama, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  '${_fmtQty(item.kuantitas)} ${item.satuan} × '
                  '${currency.format(item.hargaSatuan)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(currency.format(item.subtotal),
              style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  List<Widget> _totals(ThemeData theme) {
    Widget row(String label, String value, {bool bold = false}) {
      final style =
          bold ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            const SizedBox(width: 12),
            Text(value, style: style),
          ],
        ),
      );
    }

    if (entry.docType == DocType.invoice) {
      return [
        if (entry.totalDpp != null)
          row(tr('history.dpp'), currency.format(entry.totalDpp!)),
        if (entry.totalPpn != null)
          // Old entries have no taxRate; 11 is FakturModel's default.
          row(tr('history.ppn').replaceAll('{rate}', _fmtQty(entry.taxRate ?? 11)),
              currency.format(entry.totalPpn!)),
        row(tr('common.total'), currency.format(entry.totalAmount),
            bold: true),
      ];
    }
    return [
      row(tr('history.subtotal'),
          currency.format(entry.totalAmount + (entry.diskon ?? 0))),
      if (entry.diskon != null && entry.diskon! > 0)
        row(tr('history.discount'), '- ${currency.format(entry.diskon!)}'),
      row(tr('common.total'), currency.format(entry.totalAmount), bold: true),
      if (entry.metodeBayar != null)
        row(tr('history.method'), entry.metodeBayar!),
      if (entry.jumlahBayar != null && entry.jumlahBayar! > 0)
        row(tr('history.paid_amount'), currency.format(entry.jumlahBayar!)),
      if (entry.kembalian != null && entry.kembalian! > 0)
        row(tr('history.change'), currency.format(entry.kembalian!),
            bold: true),
    ];
  }

  String _fmtQty(double v) => v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toStringAsFixed(2);
}
