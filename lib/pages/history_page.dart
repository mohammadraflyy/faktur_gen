import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import '../main.dart';
import '../models/history_model.dart';
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

class HistoryPage extends StatefulWidget {
  final bool unpaidOnly;

  const HistoryPage({super.key, this.unpaidOnly = false});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<HistoryEntry> _entries = [];
  List<HistoryEntry> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  DocType? _typeFilter;
  PaymentStatus? _paymentFilter;

  SettingsModel _settings = SettingsModel();

  NumberFormat get _currency => NumberFormat.currency(
        locale: _settings.currencyLocale,
        symbol: _settings.currencySymbol,
        decimalDigits: 0,
      );

  @override
  void initState() {
    super.initState();
    if (widget.unpaidOnly) _paymentFilter = PaymentStatus.unpaid;
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        HistoryService.load(),
        SettingsService.load(),
      ]);
      if (mounted) {
        setState(() {
          _entries = results[0] as List<HistoryEntry>;
          _settings = results[1] as SettingsModel;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('[History] load error: $e');
    }
  }

  void _applyFilter() {
    var list = _entries;
    if (_typeFilter != null) {
      list = list.where((e) => e.docType == _typeFilter).toList();
    }
    if (_paymentFilter != null) {
      list = list
          .where((e) =>
              e.docType == DocType.invoice &&
              e.paymentStatus == _paymentFilter)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((e) =>
              e.nomorDokumen.toLowerCase().contains(q) ||
              e.namaKlien.toLowerCase().contains(q))
          .toList();
    }
    _filtered = list;
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilter();
    });
  }

  void _onTypeFilter(DocType? type) {
    setState(() {
      _typeFilter = _typeFilter == type ? null : type;
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

  Future<bool> _confirmDeleteEntry(HistoryEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('history.delete_title')),
        content: Text('Hapus "${entry.nomorDokumen}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('common.delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await HistoryService.delete(entry.id);
      await _load();
      return true;
    }
    return false;
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('history.title')),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.file_download_outlined, size: 20),
              tooltip: tr('history.export_csv'),
              onPressed: _exportCsv,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.6,
                        child: _buildEmptyState(),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildSearchAndFilter(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: _buildList(),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSearchAndFilter() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: tr('history.search'),
              prefixIcon: Icon(Icons.search, size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearch('');
                      },
                    )
                  : null,
            ),
            style: GoogleFonts.inter(fontSize: 13),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(tr('history.all'), _typeFilter == null && _paymentFilter == null, () {
                  setState(() { _typeFilter = null; _paymentFilter = null; _applyFilter(); });
                }),
                const SizedBox(width: 6),
                _filterChip(tr('history.invoice'), _typeFilter == DocType.invoice, () => _onTypeFilter(DocType.invoice)),
                const SizedBox(width: 6),
                _filterChip(tr('history.receipt'), _typeFilter == DocType.struk, () => _onTypeFilter(DocType.struk)),
                const SizedBox(width: 6),
                _filterChip(
                  tr('history.unpaid'),
                  _paymentFilter == PaymentStatus.unpaid,
                  () {
                    setState(() {
                      _paymentFilter = _paymentFilter == PaymentStatus.unpaid ? null : PaymentStatus.unpaid;
                      if (_paymentFilter != null) _typeFilter = null;
                      _applyFilter();
                    });
                  },
                  color: AppColors.warningFor(theme.brightness),
                ),
                const SizedBox(width: 6),
                _filterChip(
                  tr('history.paid'),
                  _paymentFilter == PaymentStatus.paid,
                  () {
                    setState(() {
                      _paymentFilter = _paymentFilter == PaymentStatus.paid ? null : PaymentStatus.paid;
                      if (_paymentFilter != null) _typeFilter = null;
                      _applyFilter();
                    });
                  },
                  color: AppColors.successFor(theme.brightness),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_filtered.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap, {Color? color}) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.3)
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected
                ? accent
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text(
            tr('history.empty'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr('history.empty_sub'),
            style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 600;
    final hPad = isTablet ? ((width - 680) / 2).clamp(16.0, 9999.0) : 12.0;

    final Map<String, List<HistoryEntry>> grouped = {};
    for (final e in _filtered) {
      final key = DateFormat('dd MMMM yyyy', 'id_ID').format(e.createdAt);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 32),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateLabel = grouped.keys.elementAt(index);
        final items = grouped[dateLabel]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                dateLabel,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...items.map((entry) => _buildEntryCard(entry)),
          ],
        );
      },
    );
  }

  Widget _buildEntryCard(HistoryEntry entry) {
    final theme = Theme.of(context);
    final isInvoice = entry.docType == DocType.invoice;
    final color = isInvoice
        ? (theme.brightness == Brightness.dark
            ? AppColors.invoiceBlueSoft
            : AppColors.invoiceBlue)
        : (theme.brightness == Brightness.dark
            ? AppColors.strukGreenSoft
            : AppColors.strukGreen);
    final icon =
        isInvoice ? Icons.receipt_long_outlined : Icons.receipt_outlined;
    final typeLabel = isInvoice ? 'INV' : 'STR';
    final timeStr = DateFormat('HH:mm').format(entry.createdAt);

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.errorFor(theme.brightness).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline_rounded,
            color: AppColors.errorFor(theme.brightness), size: 22),
      ),
      confirmDismiss: (_) => _confirmDeleteEntry(entry),
      child: GestureDetector(
        onTap: () => _showDetail(entry),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: theme.cardColor,
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
                  color: color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          typeLabel,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entry.nomorDokumen,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (entry.namaKlien.isNotEmpty ||
                        (entry.docType == DocType.invoice &&
                            entry.paymentStatus == PaymentStatus.paid)) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (entry.namaKlien.isNotEmpty)
                            Flexible(
                              child: Text(
                                entry.namaKlien,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (entry.docType == DocType.invoice &&
                              entry.paymentStatus == PaymentStatus.paid) ...[
                            if (entry.namaKlien.isNotEmpty)
                              const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.successFor(Theme.of(context).brightness)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tr('history.paid').toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.successFor(Theme.of(context).brightness),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currency.format(entry.totalAmount),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
    final isDark = theme.brightness == Brightness.dark;
    final isInvoice = entry.docType == DocType.invoice;
    final color = isInvoice
        ? (isDark ? AppColors.invoiceBlueSoft : AppColors.invoiceBlue)
        : (isDark ? AppColors.strukGreenSoft : AppColors.strukGreen);
    final bgColor = color.withValues(alpha: isDark ? 0.1 : 0.06);
    final typeLabel = isInvoice ? 'Invoice' : 'Struk';
    final dateFmt = DateFormat('dd MMMM yyyy', 'id_ID');
    final dateTimeFmt = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    final cardBg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final borderColor = theme.colorScheme.outlineVariant;
    final successColor = AppColors.successFor(theme.brightness);
    final warningColor = AppColors.warningFor(theme.brightness);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    typeLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.nomorDokumen,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                Material(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _handlePrint(context),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.print_rounded, color: color, size: 22),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Info section
            _sectionTitle('Informasi Dokumen', Icons.info_outline, color),
            const SizedBox(height: 8),
            _infoRow('Tanggal Dokumen', dateFmt.format(entry.tanggalDokumen), textPrimary, textSecondary),
            _infoRow('Dibuat Pada', dateTimeFmt.format(entry.createdAt), textPrimary, textSecondary),
            if (isInvoice) ...[
              if (entry.jatuhTempo != null)
                _infoRow('Jatuh Tempo', dateFmt.format(entry.jatuhTempo!), textPrimary, textSecondary),
              if (entry.namaPenjual != null &&
                  entry.namaPenjual!.isNotEmpty)
                _infoRow('Penjual', entry.namaPenjual!, textPrimary, textSecondary),
              if (entry.namaKlien.isNotEmpty)
                _infoRow('Pembeli', entry.namaKlien, textPrimary, textSecondary),
              if (entry.npwpPembeli != null &&
                  entry.npwpPembeli!.isNotEmpty)
                _infoRow('NPWP Pembeli', entry.npwpPembeli!, textPrimary, textSecondary),
              if (entry.teleponPembeli != null &&
                  entry.teleponPembeli!.isNotEmpty)
                _infoRow('Telepon Pembeli', entry.teleponPembeli!, textPrimary, textSecondary),
              if (entry.alamatPembeli != null &&
                  entry.alamatPembeli!.isNotEmpty)
                _infoRow('Alamat Pembeli', entry.alamatPembeli!, textPrimary, textSecondary),
            ] else ...[
              if (entry.namaToko != null && entry.namaToko!.isNotEmpty)
                _infoRow('Toko', entry.namaToko!, textPrimary, textSecondary),
              if (entry.alamatToko != null && entry.alamatToko!.isNotEmpty)
                _infoRow('Alamat Toko', entry.alamatToko!, textPrimary, textSecondary),
              if (entry.namaKasir != null && entry.namaKasir!.isNotEmpty)
                _infoRow('Kasir', entry.namaKasir!, textPrimary, textSecondary),
            ],

            const SizedBox(height: 20),

            // Items section
            if (entry.items.isNotEmpty) ...[
              _sectionTitle(
                  isInvoice ? 'Item / Layanan' : 'Daftar Barang',
                  Icons.list_alt_rounded,
                  color),
              const SizedBox(height: 8),
              _buildItemsTable(color, bgColor, textPrimary, textSecondary, borderColor, cardBg),
              const SizedBox(height: 20),
            ],

            // Totals section
            _sectionTitle('Ringkasan', Icons.calculate_outlined, color),
            const SizedBox(height: 8),
            _buildTotals(color, bgColor),

            // Catatan
            if (entry.catatan.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionTitle('Catatan', Icons.notes_rounded, color),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Text(
                  entry.catatan,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: textPrimary.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
              ),
            ],

            // Payment status toggle (invoice only)
            if (entry.docType == DocType.invoice) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final newStatus =
                      entry.paymentStatus == PaymentStatus.paid
                          ? PaymentStatus.unpaid
                          : PaymentStatus.paid;
                  await widget.onStatusChanged?.call(newStatus);
                  setState(() => entry.paymentStatus = newStatus);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: (entry.paymentStatus == PaymentStatus.paid
                            ? successColor
                            : warningColor)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (entry.paymentStatus == PaymentStatus.paid
                              ? successColor
                              : warningColor)
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        entry.paymentStatus == PaymentStatus.paid
                            ? Icons.check_circle_rounded
                            : Icons.pending_rounded,
                        size: 18,
                        color: entry.paymentStatus == PaymentStatus.paid
                            ? successColor
                            : warningColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.paymentStatus == PaymentStatus.paid
                            ? tr('history.paid').toUpperCase()
                            : tr('history.unpaid').toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: entry.paymentStatus == PaymentStatus.paid
                              ? successColor
                              : warningColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        tr('history.tap_to_change'),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Buat Ulang button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onDuplicate?.call();
                },
                icon: Icon(Icons.copy_rounded, size: 18, color: color),
                label: Text(
                  tr('history.duplicate'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: color.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
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
            title: 'Preview Invoice',
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
            title: 'Preview Struk',
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

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(Color color, Color bgColor, Color textPrimary, Color textSecondary, Color borderColor, Color cardBg) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text('No',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Item',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
                Expanded(
                  child: Text('Qty',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Subtotal',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
              ],
            ),
          ),
          // Table rows
          ...List.generate(entry.items.length, (i) {
            final item = entry.items[i];
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: i.isEven ? Colors.transparent : cardBg,
                border: i < entry.items.length - 1
                    ? Border(
                        bottom: BorderSide(
                            color: borderColor, width: 0.8))
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('${i + 1}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: textSecondary)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nama,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '@ ${currency.format(item.hargaSatuan)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${_fmtQty(item.kuantitas)} ${item.satuan}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: textPrimary.withValues(alpha: 0.7)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      currency.format(item.subtotal),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotals(Color color, Color bgColor) {
    final isInvoice = entry.docType == DocType.invoice;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          if (isInvoice) ...[
            if (entry.totalDpp != null)
              _totalRow('DPP', currency.format(entry.totalDpp!), color,
                  bold: false),
            if (entry.totalPpn != null) ...[
              const Divider(height: 12),
              _totalRow('PPN (11%)', currency.format(entry.totalPpn!), color,
                  bold: false),
            ],
            const Divider(height: 12),
            _totalRow('Total', currency.format(entry.totalAmount), color,
                bold: true),
          ] else ...[
            _totalRow(
                'Subtotal',
                currency.format(
                    entry.totalAmount + (entry.diskon ?? 0)),
                color,
                bold: false),
            if (entry.diskon != null && entry.diskon! > 0) ...[
              const Divider(height: 12),
              _totalRow(
                  'Diskon', '- ${currency.format(entry.diskon!)}', color,
                  bold: false, isRed: true),
            ],
            const Divider(height: 12),
            _totalRow('Total', currency.format(entry.totalAmount), color,
                bold: true),
            if (entry.metodeBayar != null) ...[
              const Divider(height: 12),
              _totalRow('Metode', entry.metodeBayar!, color, bold: false),
            ],
            if (entry.jumlahBayar != null && entry.jumlahBayar! > 0) ...[
              const Divider(height: 12),
              _totalRow(
                  'Bayar', currency.format(entry.jumlahBayar!), color,
                  bold: false),
            ],
            if (entry.kembalian != null && entry.kembalian! > 0) ...[
              const Divider(height: 12),
              _totalRow(
                  'Kembalian', currency.format(entry.kembalian!), color,
                  bold: true),
            ],
          ],
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, Color color,
      {bool bold = false, bool isRed = false}) {
    final textColor = isRed ? Colors.red : color;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  String _fmtQty(double v) => v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toStringAsFixed(2);
}
