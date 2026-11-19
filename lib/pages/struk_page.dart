import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import '../main.dart';
import '../models/catalog_model.dart';
import '../models/faktur_model.dart';
import '../models/history_model.dart';
import '../models/reminder_model.dart';
import '../models/settings_model.dart';
import '../models/struk_model.dart';
import '../services/catalog_service.dart';
import '../services/history_service.dart';
import '../services/locale_service.dart';
import '../services/settings_service.dart';
import '../services/struk_pdf_service.dart';
import '../services/subscription_service.dart';
import '../widgets/catalog_picker_sheet.dart';
import '../widgets/item_edit_sheet.dart';
import '../widgets/paywall_sheet.dart';
import '../widgets/total_bar.dart';
import 'document_ready_page.dart';
import 'pdf_preview_page.dart';

/// Receipts keep the green accent: #047857 under white text (5.48:1), or
/// #34D399 under the dark theme's #0F1117 onPrimary (9.82:1). The input
/// theme hard-codes blue focus, so that is swapped too.
ThemeData _strukTheme(ThemeData base) {
  final green = base.brightness == Brightness.dark
      ? AppColors.strukGreenSoft
      : AppColors.strukGreen;
  final input = base.inputDecorationTheme;
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(primary: green, secondary: green),
    inputDecorationTheme: input.copyWith(
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: green, width: 2),
      ),
      floatingLabelStyle: input.floatingLabelStyle?.copyWith(color: green),
    ),
  );
}

class StrukPage extends StatelessWidget {
  final HistoryEntry? initialEntry;
  final List<ReminderItem>? reminderItems;
  final String? reminderContactName;
  const StrukPage({
    super.key,
    this.initialEntry,
    this.reminderItems,
    this.reminderContactName,
  });

  // The form's state sits below this Theme, so the sheets and dialogs it
  // opens are green as well.
  @override
  Widget build(BuildContext context) => Theme(
        data: _strukTheme(Theme.of(context)),
        child: _StrukForm(
          initialEntry: initialEntry,
          reminderItems: reminderItems,
          reminderContactName: reminderContactName,
        ),
      );
}

class _StrukForm extends StatefulWidget {
  final HistoryEntry? initialEntry;
  final List<ReminderItem>? reminderItems;
  final String? reminderContactName;
  const _StrukForm({
    this.initialEntry,
    this.reminderItems,
    this.reminderContactName,
  });

  @override
  State<_StrukForm> createState() => _StrukFormState();
}

class _StrukFormState extends State<_StrukForm> {
  final _struk = StrukModel();
  SettingsModel _settings = SettingsModel();

  final _nomorCtrl = TextEditingController();
  final _kasirCtrl = TextEditingController();
  final _diskonCtrl = TextEditingController();
  final _bayarCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();

  // Same split as the invoice form: typing happens in sheets or the cash
  // field, so only these listeners rebuild, never the whole page.
  final _items = ValueNotifier<List<ItemStruk>>([]);
  final _total = ValueNotifier<double>(0);
  final _paid = ValueNotifier<double>(0);

  bool _isLoading = true;
  bool _isDirty = false;
  bool _isGenerating = false;

  NumberFormat get _currency => NumberFormat.currency(
        locale: _settings.currencyLocale,
        symbol: _settings.currencySymbol,
        decimalDigits: 0,
      );

  String get _dateLocale => LocaleService.isEn ? 'en_US' : 'id_ID';

  @override
  void initState() {
    super.initState();
    _items.addListener(_recalcTotal);
    _loadSettings();
  }

  void _recalcTotal() {
    _struk.items = _items.value;
    _total.value = _struk.total;
  }

  String _fmtQty(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  static MetodeBayar _parseMetodeBayar(String? value) {
    if (value == null) return MetodeBayar.tunai;
    for (final m in MetodeBayar.values) {
      if (m.label == value || m.name == value) return m;
    }
    return MetodeBayar.tunai;
  }

  Future<void> _loadSettings() async {
    final s = await SettingsService.load();
    final nomorStruk =
        await SettingsService.generateStrukNumber(prefix: s.strukPrefix);
    if (!mounted) return;
    setState(() {
      _settings = s;
      _struk.namaToko = s.namaToko;
      _struk.alamatToko = s.alamat;
      _struk.teleponToko = s.telepon;
      _nomorCtrl.text = nomorStruk;

      final entry = widget.initialEntry;
      final reminderItems = widget.reminderItems;
      if (entry != null) {
        _kasirCtrl.text = entry.namaKasir ?? '';
        _struk.diskon = entry.diskon ?? 0;
        _diskonCtrl.text =
            _struk.diskon > 0 ? _struk.diskon.toInt().toString() : '';
        _struk.metodeBayar = _parseMetodeBayar(entry.metodeBayar);
        _paid.value = entry.jumlahBayar ?? 0;
        _bayarCtrl.text =
            _paid.value > 0 ? _paid.value.toInt().toString() : '';
        _catatanCtrl.text = entry.catatan;
        _items.value = entry.items
            .map((i) => ItemStruk(
                  nama: i.nama,
                  kuantitas: i.kuantitas,
                  satuan: i.satuan,
                  hargaSatuan: i.hargaSatuan,
                  diskon: i.diskon,
                ))
            .toList();
      } else {
        _catatanCtrl.text = s.footerStruk;
        if (reminderItems != null && reminderItems.isNotEmpty) {
          _kasirCtrl.text = widget.reminderContactName ?? '';
          _items.value = reminderItems
              .map((i) => ItemStruk(
                    nama: i.nama,
                    kuantitas: i.kuantitas,
                    satuan: i.satuan,
                    hargaSatuan: i.hargaSatuan,
                  ))
              .toList();
        }
      }
      _isLoading = false;
      _recalcTotal();
    });
  }

  @override
  void dispose() {
    _nomorCtrl.dispose();
    _kasirCtrl.dispose();
    _diskonCtrl.dispose();
    _bayarCtrl.dispose();
    _catatanCtrl.dispose();
    _items.dispose();
    _total.dispose();
    _paid.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _syncToModel() {
    _struk.namaToko = _settings.namaToko;
    _struk.alamatToko = _settings.alamat;
    _struk.teleponToko = _settings.telepon;
    _struk.nomorStruk = _nomorCtrl.text.trim();
    _struk.namaKasir = _kasirCtrl.text.trim();
    _struk.jumlahBayar = _paid.value;
    _struk.catatan = _catatanCtrl.text;
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _editNumber() async {
    var draft = _nomorCtrl.text;
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('receipt.number')),
        content: TextFormField(
          initialValue: draft,
          autofocus: true,
          onChanged: (v) => draft = v,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('common.cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, draft.trim()),
              child: Text(tr('common.save'))),
        ],
      ),
    );
    if (value == null || value.isEmpty || !mounted) return;
    setState(() {
      _nomorCtrl.text = value;
      _isDirty = true;
    });
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _struk.tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_struk.tanggal),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _struk.tanggal = DateTime(pickedDate.year, pickedDate.month,
          pickedDate.day, pickedTime.hour, pickedTime.minute);
      _isDirty = true;
    });
  }

  // The item sheet edits ItemFaktur; a receipt item maps onto it one to one,
  // and its discount travels in ItemEditResult.discount.
  ItemFaktur _toSheetItem(ItemStruk i) => ItemFaktur(
        namaBarang: i.nama,
        deskripsi: i.deskripsi,
        kuantitas: i.kuantitas,
        satuan: i.satuan,
        hargaSatuan: i.hargaSatuan,
      );

  ItemStruk _fromSheet(ItemEditResult r) => ItemStruk(
        nama: r.item!.namaBarang,
        deskripsi: r.item!.deskripsi,
        kuantitas: r.item!.kuantitas,
        satuan: r.item!.satuan,
        hargaSatuan: r.item!.hargaSatuan,
        diskon: r.discount,
      );

  Future<void> _addItem() async {
    final result = await showItemEditSheet(context,
        item: ItemFaktur(satuan: 'pcs'),
        currency: _currency,
        isNew: true,
        discount: 0);
    if (result == null || result.deleted) return;
    _markDirty();
    _items.value = [..._items.value, _fromSheet(result)];
  }

  Future<void> _editItem(int index) async {
    final item = _items.value[index];
    final result = await showItemEditSheet(context,
        item: _toSheetItem(item), currency: _currency, discount: item.diskon);
    if (result == null) return;
    if (result.deleted) {
      _removeItem(index);
      return;
    }
    _markDirty();
    _items.value = [..._items.value]..[index] = _fromSheet(result);
  }

  void _stepQty(int index, int delta) {
    final item = _items.value[index];
    if (item.kuantitas + delta < 1) return;
    item.kuantitas += delta;
    _markDirty();
    // Same item objects in a new list: listeners fire, swipe keys stay.
    _items.value = [..._items.value];
  }

  void _removeItem(int index) {
    final list = [..._items.value];
    final removed = list.removeAt(index);
    _markDirty();
    _items.value = list;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content:
            Text(tr('invoice.item_removed').replaceAll('{name}', removed.nama)),
        duration: const Duration(seconds: 4),
        persist: false,
        action: SnackBarAction(
          label: tr('common.undo'),
          onPressed: () {
            if (!mounted) return;
            final restored = [..._items.value];
            restored.insert(index.clamp(0, restored.length), removed);
            _items.value = restored;
          },
        ),
      ));
  }

  Future<void> _addFromCatalog() async {
    final items = await CatalogService.loadAll();
    if (!mounted) return;
    final selected = await showModalBottomSheet<CatalogItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CatalogPickerSheet(
        items: items,
        currencySymbol: _settings.currencySymbol,
        currencyLocale: _settings.currencyLocale,
      ),
    );
    if (selected == null) return;
    _markDirty();
    _items.value = [
      ..._items.value,
      ItemStruk(
        nama: selected.nama,
        deskripsi: selected.deskripsi,
        satuan: selected.satuan,
        hargaSatuan: selected.hargaSatuan,
      ),
    ];
  }

  void _setMethod(MetodeBayar m) => setState(() {
        _struk.metodeBayar = m;
        _isDirty = true;
      });

  void _setPaid(double value) {
    _bayarCtrl.text = value.round().toString();
    _paid.value = value;
    _markDirty();
  }

  Future<void> _generatePdf() async {
    if (_isGenerating) return;
    _syncToModel();
    if (_struk.nomorStruk.isEmpty) {
      _showMessage(tr('receipt.need_number'));
      _editNumber();
      return;
    }
    if (_items.value.isEmpty) {
      _showMessage(tr('invoice.need_item'));
      return;
    }

    setState(() => _isGenerating = true);
    final bool saved;
    var isPro = false;
    try {
      saved = await _saveDocument();
      if (saved) isPro = await SubscriptionService.isPro();
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
    if (!saved || !mounted) return;
    await _openReady(isPro);
  }

  /// Checks the quota, then stores the history entry.
  /// False when the paywall blocked it.
  Future<bool> _saveDocument() async {
    if (!await SubscriptionService.canCreateDocument()) {
      if (mounted) showPaywallSheet(context);
      return false;
    }
    final struk = _struk;
    await HistoryService.add(HistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      docType: DocType.struk,
      nomorDokumen: struk.nomorStruk,
      namaKlien: struk.namaKasir,
      totalAmount: struk.total,
      tanggalDokumen: struk.tanggal,
      createdAt: DateTime.now(),
      items: struk.items
          .map((i) => HistoryItem(
                nama: i.nama,
                kuantitas: i.kuantitas,
                satuan: i.satuan,
                hargaSatuan: i.hargaSatuan,
                subtotal: i.subtotal,
                diskon: i.diskon,
              ))
          .toList(),
      catatan: struk.catatan,
      namaToko: struk.namaToko,
      alamatToko: struk.alamatToko,
      namaKasir: struk.namaKasir,
      diskon: struk.diskon,
      metodeBayar: struk.metodeBayar.label,
      jumlahBayar: struk.jumlahBayar,
      kembalian: struk.kembalian,
    ));
    await SubscriptionService.incrementDocCount();
    _isDirty = false;
    return true;
  }

  Future<void> _openReady(bool isPro) async {
    final struk = _struk;
    final settings = _settings;
    final total = _currency.format(struk.total);
    final now = DateTime.now();
    final remindAt = defaultReminderDate(null, now);
    final ready = DocumentReadyPage(
      title: tr('done.receipt_ready'),
      summary:
          struk.namaKasir.isEmpty ? total : '${struk.namaKasir} · $total',
      shareMessage: tr('done.receipt_message')
          .replaceAll('{number}', struk.nomorStruk)
          .replaceAll('{amount}', total),
      reminderLabel: tr('done.remind_later'),
      reminder: ReminderModel(
        id: now.millisecondsSinceEpoch.toString(),
        // Stored data, not UI text: same fallback the old dialog saved.
        contactName: struk.namaKasir.isNotEmpty ? struk.namaKasir : 'Pelanggan',
        serviceName: struk.items.isNotEmpty ? struk.items.first.nama : '',
        reminderDate: DateUtils.dateOnly(remindAt),
        reminderHour: remindAt.hour,
        reminderMinute: remindAt.minute,
        docType: ReminderDocType.struk,
        lastItems: struk.items
            .map((i) => ReminderItem(
                  nama: i.nama,
                  kuantitas: i.kuantitas,
                  satuan: i.satuan,
                  hargaSatuan: i.hargaSatuan,
                ))
            .toList(),
      ),
      preview: PdfPreviewPage(
        title: tr('receipt.preview_title'),
        filename: 'Struk_${struk.nomorStruk.replaceAll('/', '-')}.pdf',
        buildPdf: (format) => StrukPdfService.buildBytes(struk, format,
            logoBytes: settings.logoBytes,
            currencySymbol: settings.currencySymbol,
            currencyLocale: settings.currencyLocale,
            templateConfig: settings.templateConfig,
            showWatermark: !isPro),
        initialPageFormat:
            const PdfPageFormat(226.77, double.infinity, marginAll: 12),
        canChangePageFormat: false,
      ),
    );
    // Saved already: the form closes with the ready screen so back and
    // "Selesai" return to the caller, which reloads only after that. The new
    // route sits outside StrukPage, so it gets its own green.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) =>
            Theme(data: _strukTheme(Theme.of(ctx)), child: ready),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  void _resetForm() {
    setState(() {
      _isDirty = false;
      _nomorCtrl.clear();
      _kasirCtrl.clear();
      _diskonCtrl.clear();
      _bayarCtrl.clear();
      _catatanCtrl.clear();
      _struk.tanggal = DateTime.now();
      _struk.metodeBayar = MetodeBayar.tunai;
      _struk.diskon = 0;
      _paid.value = 0;
      _items.value = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width >= 600 ? ((width - 680) / 2).clamp(24.0, 9999.0) : 20.0;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(tr('invoice.leave_title')),
            content: Text(tr('invoice.leave_body')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(tr('common.cancel'))),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('invoice.leave'),
                    style: TextStyle(
                        color: AppColors.errorFor(Theme.of(ctx).brightness))),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: tr('invoice.reset_form'),
              onPressed: _resetForm,
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
          children: [
            _buildHeader(theme),
            if (_settings.isEmpty) ...[
              const SizedBox(height: 8),
              Text(tr('invoice.store_missing'),
                  style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 24),
            _buildItems(theme),
            const Divider(height: 1),
            const SizedBox(height: 24),
            _buildPayment(theme),
            const Divider(height: 1),
            _buildExtrasRow(theme),
          ],
        ),
        bottomNavigationBar: TotalBar(
          total: _total,
          currency: _currency,
          actionLabel: tr('receipt.make'),
          busy: _isGenerating,
          onAction: _generatePdf,
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final when =
        DateFormat('d MMM, HH:mm', _dateLocale).format(_struk.tanggal);
    return InkWell(
      onTap: _editNumber,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('receipt.new_title'), style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('${_nomorCtrl.text} · $when',
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildItems(ThemeData theme) {
    return ValueListenableBuilder<List<ItemStruk>>(
      valueListenable: _items,
      builder: (context, items, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('invoice.items'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(tr('invoice.no_items'),
                  style: theme.textTheme.bodySmall),
            ),
          for (var i = 0; i < items.length; i++) _itemRow(theme, items[i], i),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, size: 18),
                label: Text(tr('invoice.add_item')),
              ),
              TextButton(
                onPressed: _addFromCatalog,
                child: Text(tr('invoice.from_catalog')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemRow(ThemeData theme, ItemStruk item, int index) {
    final isDark = theme.brightness == Brightness.dark;
    final price = '${_currency.format(item.hargaSatuan)} / ${item.satuan}';
    return Dismissible(
      key: ObjectKey(item),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.errorFor(theme.brightness),
        child: Icon(Icons.delete_outline,
            // #0F1117 on #F87171 = 6.82:1; white on #B91C1C = 6.47:1.
            color: isDark ? const Color(0xFF0F1117) : Colors.white,
            semanticLabel: tr('common.delete')),
      ),
      onDismissed: (_) => _removeItem(index),
      child: InkWell(
        onTap: () => _editItem(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nama, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      item.diskon > 0
                          ? '$price · −${_currency.format(item.diskon)}'
                          : price,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: tr('item.qty_less'),
                onPressed:
                    item.kuantitas >= 2 ? () => _stepQty(index, -1) : null,
                icon: const Icon(Icons.remove),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 32),
                child: Text(_fmtQty(item.kuantitas),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall),
              ),
              IconButton(
                tooltip: tr('item.qty_more'),
                onPressed: () => _stepQty(index, 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayment(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr('receipt.payment'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        // "Kartu" stands for debit and kredit; a kredit receipt stays kredit
        // because tapping the already selected segment changes nothing.
        SegmentedButton<MetodeBayar>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
                value: MetodeBayar.tunai, label: Text(tr('receipt.cash'))),
            ButtonSegment(
                value: MetodeBayar.transfer,
                label: Text(tr('receipt.transfer'))),
            ButtonSegment(
                value: MetodeBayar.qris, label: Text(MetodeBayar.qris.label)),
            ButtonSegment(
                value: MetodeBayar.debit, label: Text(tr('receipt.card'))),
          ],
          selected: {paymentSegment(_struk.metodeBayar)},
          onSelectionChanged: (s) => _setMethod(s.first),
          style: SegmentedButton.styleFrom(
            // A tint, not a fill: the filled green belongs to "Buat struk".
            selectedBackgroundColor: primary.withValues(alpha: 0.12),
            selectedForegroundColor: primary,
          ),
        ),
        if (_struk.metodeBayar == MetodeBayar.tunai) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _bayarCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: tr('receipt.cash_received'),
              prefixText: _settings.currencySymbol,
            ),
            onChanged: (v) {
              _paid.value = double.tryParse(v) ?? 0;
              _markDirty();
            },
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => _setPaid(_total.value),
                child: Text(tr('receipt.exact')),
              ),
              // Fixed rupiah notes; they mean nothing in other currencies.
              if (_settings.currency == 'IDR')
                for (final amount in const [50000.0, 100000.0])
                  TextButton(
                    onPressed: () => _setPaid(amount),
                    child: Text(_currency.format(amount)),
                  ),
            ],
          ),
          _buildChange(theme),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildChange(ThemeData theme) {
    return ListenableBuilder(
      listenable: Listenable.merge([_total, _paid]),
      builder: (context, _) {
        final change = cashChange(total: _total.value, paid: _paid.value);
        if (change == null) return const SizedBox.shrink();
        final short = change < 0;
        final color = short ? AppColors.errorFor(theme.brightness) : null;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(tr(short ? 'receipt.short' : 'receipt.change'),
                    style: theme.textTheme.bodyLarge?.copyWith(color: color)),
              ),
              Text(_currency.format(change.abs()),
                  style: theme.textTheme.titleMedium?.copyWith(color: color)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExtrasRow(ThemeData theme) {
    final kasir = _kasirCtrl.text.trim();
    final note = _catatanCtrl.text.trim();
    final parts = [
      if (_struk.diskon > 0)
        '${tr('receipt.discount')} ${_currency.format(_struk.diskon)}',
      if (kasir.isNotEmpty) kasir,
      if (note.isNotEmpty) note,
    ];
    return InkWell(
      onTap: _showExtrasSheet,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('receipt.extras'), style: theme.textTheme.titleSmall),
                  if (parts.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(parts.join(' · '),
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Future<void> _showExtrasSheet() async {
    String snapshot() =>
        '${_diskonCtrl.text}|${_kasirCtrl.text}|${_catatanCtrl.text}';
    final before = snapshot();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr('receipt.extras_title'),
                    style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _diskonCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: tr('receipt.discount'),
                    prefixText: _settings.currencySymbol,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _kasirCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      InputDecoration(labelText: tr('receipt.cashier')),
                ),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('receipt.date')),
                  trailing: Text(DateFormat('d MMM yyyy, HH:mm', _dateLocale)
                      .format(_struk.tanggal)),
                  onTap: () async {
                    await _pickDateTime();
                    setSheet(() {});
                  },
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _catatanCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: tr('invoice.notes')),
                ),
                const SizedBox(height: 20),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(tr('common.done'))),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    _struk.diskon = double.tryParse(_diskonCtrl.text) ?? 0;
    _recalcTotal();
    setState(() {
      if (snapshot() != before) _isDirty = true;
    });
  }
}
