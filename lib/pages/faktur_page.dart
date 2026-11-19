import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/contact_model.dart';
import '../models/faktur_model.dart';
import '../models/history_model.dart';
import '../models/settings_model.dart';
import '../models/catalog_model.dart';
import '../models/template_model.dart';
import '../services/catalog_service.dart';
import '../services/contact_service.dart';
import '../services/history_service.dart';
import '../services/locale_service.dart';
import '../services/pdf_service.dart';
import '../services/settings_service.dart';
import '../services/subscription_service.dart';
import '../services/template_service.dart';
import '../models/reminder_model.dart';
import '../widgets/catalog_picker_sheet.dart';
import '../widgets/item_edit_sheet.dart';
import '../widgets/paywall_sheet.dart';
import '../widgets/total_bar.dart';
import 'document_ready_page.dart';
import 'pdf_preview_page.dart';

class FakturPage extends StatefulWidget {
  final HistoryEntry? initialEntry;
  final List<ReminderItem>? reminderItems;
  final String? reminderContactName;
  const FakturPage({
    super.key,
    this.initialEntry,
    this.reminderItems,
    this.reminderContactName,
  });

  @override
  State<FakturPage> createState() => _FakturPageState();
}

class _FakturPageState extends State<FakturPage> {
  final _faktur = FakturModel();

  final _nomorCtrl = TextEditingController();
  final _namaPembeliCtrl = TextEditingController();
  final _npwpPembeliCtrl = TextEditingController();
  final _alamatPembeliCtrl = TextEditingController();
  final _teleponPembeliCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();

  SettingsModel _settings = SettingsModel();
  List<ContactModel> _contacts = [];

  NumberFormat get _currency => NumberFormat.currency(
        locale: _settings.currencyLocale,
        symbol: _settings.currencySymbol,
        decimalDigits: 0,
      );

  bool _isLoading = true;
  bool _isDirty = false;

  // Items live here, not in per-field controllers: typing happens inside
  // the item sheet, so the page only rebuilds when an item is saved.
  final _items = ValueNotifier<List<ItemFaktur>>([]);
  final _total = ValueNotifier<double>(0);
  bool _isGenerating = false;

  String get _dateLocale => LocaleService.isEn ? 'en_US' : 'id_ID';

  @override
  void initState() {
    super.initState();
    _items.addListener(_recalcTotal);
    _recalcTotal();
    _loadSettings();
  }

  void _recalcTotal() {
    _faktur.items = _items.value;
    _total.value = _faktur.totalTagihan;
  }

  Future<void> _loadSettings() async {
    final s = await SettingsService.load();
    final results = await Future.wait([
      SettingsService.generateInvoiceNumber(prefix: s.invoicePrefix),
      ContactService.loadAll(),
    ]);
    if (mounted) {
      final invNum = results[0] as String;
      final contacts = results[1] as List<ContactModel>;
      setState(() {
        _settings = s;
        _contacts = contacts;
        _faktur.taxRate = s.taxRate;
        _faktur.currency = s.currency;
        _faktur.namaPenjual = s.namaToko;
        _faktur.npwpPenjual = s.npwp;
        _faktur.alamatPenjual = s.alamat;
        _faktur.teleponPenjual = s.telepon;
        _faktur.emailPenjual = s.email;
        _faktur.websitePenjual = s.website;

        final entry = widget.initialEntry;
        if (entry != null) {
          _nomorCtrl.text = invNum;
          _namaPembeliCtrl.text = entry.namaKlien;
          _npwpPembeliCtrl.text = entry.npwpPembeli ?? '';
          _alamatPembeliCtrl.text = entry.alamatPembeli ?? '';
          _teleponPembeliCtrl.text = entry.teleponPembeli ?? '';
          _catatanCtrl.text = entry.catatan;
          _faktur.catatan = entry.catatan;
          _faktur.jatuhTempo = entry.jatuhTempo;
          _items.value = entry.items
              .map((i) => ItemFaktur(
                    namaBarang: i.nama,
                    kuantitas: i.kuantitas,
                    satuan: i.satuan,
                    hargaSatuan: i.hargaSatuan,
                  ))
              .toList();
        } else if (widget.reminderItems != null &&
            widget.reminderItems!.isNotEmpty) {
          _nomorCtrl.text = invNum;
          if (widget.reminderContactName != null) {
            _namaPembeliCtrl.text = widget.reminderContactName!;
          }
          _items.value = widget.reminderItems!
              .map((i) => ItemFaktur(
                    namaBarang: i.nama,
                    kuantitas: i.kuantitas,
                    satuan: i.satuan,
                    hargaSatuan: i.hargaSatuan,
                  ))
              .toList();
        } else {
          _nomorCtrl.text = invNum;
        }
        _isLoading = false;
        _recalcTotal();
      });
    }
  }

  String _fmtQty(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  Future<void> _reloadContacts() async {
    final contacts = await ContactService.loadAll();
    if (mounted) setState(() => _contacts = contacts);
  }

  void _selectContact(ContactModel contact) {
    setState(() {
      _namaPembeliCtrl.text = contact.nama;
      _npwpPembeliCtrl.text = contact.npwp;
      _alamatPembeliCtrl.text = contact.alamat;
      _teleponPembeliCtrl.text = contact.telepon;
      _isDirty = true;
    });
  }

  Future<void> _showContactPicker() async {
    final selected = await showModalBottomSheet<ContactModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ContactPickerSheet(
        contacts: _contacts,
        onDelete: (id) async {
          await ContactService.delete(id);
          await _reloadContacts();
        },
      ),
    );
    if (selected != null) _selectContact(selected);
  }

  @override
  void dispose() {
    _nomorCtrl.dispose();
    _namaPembeliCtrl.dispose();
    _npwpPembeliCtrl.dispose();
    _alamatPembeliCtrl.dispose();
    _teleponPembeliCtrl.dispose();
    _catatanCtrl.dispose();
    _items.dispose();
    _total.dispose();
    super.dispose();
  }

  void _syncToModel() {
    _isDirty = true;
    _faktur.nomorFaktur = _nomorCtrl.text;
    _faktur.namaPenjual = _settings.namaToko;
    _faktur.npwpPenjual = _settings.npwp;
    _faktur.alamatPenjual = _settings.alamat;
    _faktur.teleponPenjual = _settings.telepon;
    _faktur.emailPenjual = _settings.email;
    _faktur.websitePenjual = _settings.website;
    _faktur.bankAccounts = _settings.activeBanks;
    _faktur.namaPembeli = _namaPembeliCtrl.text;
    _faktur.npwpPembeli = _npwpPembeliCtrl.text;
    _faktur.alamatPembeli = _alamatPembeliCtrl.text;
    _faktur.teleponPembeli = _teleponPembeliCtrl.text;
    _faktur.catatan = _catatanCtrl.text;
  }

  Future<void> _pickDate(bool isJatuhTempo) async {
    final initial = isJatuhTempo
        ? (_faktur.jatuhTempo ?? _faktur.tanggal.add(const Duration(days: 30)))
        : _faktur.tanggal;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _isDirty = true;
        if (isJatuhTempo) {
          _faktur.jatuhTempo = picked;
        } else {
          _faktur.tanggal = picked;
        }
      });
    }
  }

  Future<void> _addItem() async {
    final result = await showItemEditSheet(context,
        item: ItemFaktur(), currency: _currency, isNew: true);
    if (result == null || result.deleted) return;
    if (!_isDirty) setState(() => _isDirty = true);
    _items.value = [..._items.value, result.item!];
  }

  Future<void> _editItem(int index) async {
    final result = await showItemEditSheet(context,
        item: _items.value[index], currency: _currency);
    if (result == null) return;
    if (result.deleted) {
      _removeItem(index);
      return;
    }
    if (!_isDirty) setState(() => _isDirty = true);
    _items.value = [..._items.value]..[index] = result.item!;
  }

  void _removeItem(int index) {
    final list = [..._items.value];
    final removed = list.removeAt(index);
    if (!_isDirty) setState(() => _isDirty = true);
    _items.value = list;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(tr('invoice.item_removed')
            .replaceAll('{name}', removed.namaBarang)),
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

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _generatePdf() async {
    if (_isGenerating) return;
    _syncToModel();
    if (_faktur.nomorFaktur.trim().isEmpty) {
      _showMessage(tr('invoice.need_number'));
      return;
    }
    if (_faktur.namaPembeli.trim().isEmpty) {
      _showMessage(tr('invoice.need_client'));
      _showClientSheet();
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
      // Stay busy until the ready screen opens, so a second tap cannot save twice.
      if (saved) isPro = await SubscriptionService.isPro();
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
    if (!saved || !mounted) return;
    await _openReady(isPro);
  }

  Future<void> _openReady(bool isPro) async {
    final faktur = _faktur;
    final settings = _settings;
    final total = _currency.format(faktur.totalTagihan);
    final now = DateTime.now();
    final remindAt = defaultReminderDate(faktur.jatuhTempo, now);
    final onDueDate = faktur.jatuhTempo != null &&
        DateUtils.isSameDay(remindAt, faktur.jatuhTempo);
    final ready = DocumentReadyPage(
      title: tr('done.invoice_ready'),
      summary: '${faktur.namaPembeli} · $total',
      shareMessage: tr('done.invoice_message')
          .replaceAll('{name}', faktur.namaPembeli)
          .replaceAll('{number}', faktur.nomorFaktur)
          .replaceAll('{amount}', total),
      reminderLabel: tr(onDueDate ? 'done.remind_due' : 'done.remind_later'),
      reminder: ReminderModel(
        id: now.millisecondsSinceEpoch.toString(),
        contactName: faktur.namaPembeli,
        contactPhone: faktur.teleponPembeli,
        contactAddress: faktur.alamatPembeli,
        serviceName:
            faktur.items.isNotEmpty ? faktur.items.first.namaBarang : '',
        reminderDate: DateUtils.dateOnly(remindAt),
        reminderHour: remindAt.hour,
        reminderMinute: remindAt.minute,
        docType: ReminderDocType.invoice,
        lastItems: faktur.items
            .map((i) => ReminderItem(
                  nama: i.namaBarang,
                  kuantitas: i.kuantitas,
                  satuan: i.satuan,
                  hargaSatuan: i.hargaSatuan,
                ))
            .toList(),
      ),
      preview: PdfPreviewPage(
        title: tr('invoice.preview_title'),
        filename: 'Invoice_${faktur.nomorFaktur.replaceAll('/', '-')}.pdf',
        buildPdf: (format) => PdfService.buildBytes(faktur, format,
            logoBytes: settings.logoBytes,
            signatureBytes: settings.signatureBytes,
            templateConfig: settings.templateConfig,
            showWatermark: !isPro,
            qrisMerchantId: isPro ? settings.qrisMerchantId : null),
      ),
    );
    // The document is already saved, so the form closes with the ready
    // screen: back and "Selesai" both return to wherever the form was
    // opened from, and the caller reloads only after that.
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ready));
    if (mounted) Navigator.pop(context);
  }

  /// Checks the quota, then stores contact and history.
  /// False when the paywall blocked it.
  Future<bool> _saveDocument() async {
    if (!await SubscriptionService.canCreateDocument()) {
      if (mounted) showPaywallSheet(context);
      return false;
    }
    final faktur = _faktur;
    await ContactService.saveIfNotExists(
      nama: faktur.namaPembeli,
      npwp: faktur.npwpPembeli,
      alamat: faktur.alamatPembeli,
      telepon: faktur.teleponPembeli,
    );
    _reloadContacts();
    await HistoryService.add(HistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      docType: DocType.invoice,
      nomorDokumen: faktur.nomorFaktur,
      namaKlien: faktur.namaPembeli,
      totalAmount: faktur.totalTagihan,
      tanggalDokumen: faktur.tanggal,
      createdAt: DateTime.now(),
      items: faktur.items
          .map((i) => HistoryItem(
                nama: i.namaBarang,
                kuantitas: i.kuantitas,
                satuan: i.satuan,
                hargaSatuan: i.hargaSatuan,
                subtotal: i.jumlah,
              ))
          .toList(),
      catatan: faktur.catatan,
      namaPenjual: faktur.namaPenjual,
      alamatPembeli: faktur.alamatPembeli,
      npwpPembeli: faktur.npwpPembeli,
      teleponPembeli: faktur.teleponPembeli,
      totalDpp: faktur.totalDpp,
      totalPpn: faktur.totalPpn,
      jatuhTempo: faktur.jatuhTempo,
      taxRate: faktur.taxRate,
      currency: faktur.currency,
    ));
    await SubscriptionService.incrementDocCount();
    _isDirty = false;
    return true;
  }

  Future<void> _openCatalog() async {
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
    if (!_isDirty) setState(() => _isDirty = true);
    _items.value = [
      ..._items.value,
      ItemFaktur(
        namaBarang: selected.nama,
        deskripsi: selected.deskripsi,
        satuan: selected.satuan,
        hargaSatuan: selected.hargaSatuan,
      ),
    ];
  }

  Future<void> _saveAsTemplate() async {
    _syncToModel();
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('invoice.save_template')),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: tr('invoice.template_name'),
            hintText: tr('invoice.template_name_hint'),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('common.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text),
            child: Text(tr('common.save')),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    if (name == null || name.trim().isEmpty) return;

    final template = TemplateModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      namaPembeli: _namaPembeliCtrl.text,
      npwpPembeli: _npwpPembeliCtrl.text,
      alamatPembeli: _alamatPembeliCtrl.text,
      teleponPembeli: _teleponPembeliCtrl.text,
      catatan: _catatanCtrl.text,
      items: _faktur.items
          .map((i) => TemplateItem(
                nama: i.namaBarang,
                deskripsi: i.deskripsi,
                kuantitas: i.kuantitas,
                satuan: i.satuan,
                hargaSatuan: i.hargaSatuan,
              ))
          .toList(),
    );
    await TemplateService.save(template);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('invoice.template_saved').replaceAll('{name}', name)),
          backgroundColor: AppColors.successFor(Theme.of(context).brightness),
        ),
      );
    }
  }

  Future<void> _loadTemplate() async {
    final templates = await TemplateService.loadAll();
    if (!mounted) return;

    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('invoice.no_templates'))),
      );
      return;
    }

    final selected = await showModalBottomSheet<TemplateModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TemplatePickerSheet(templates: templates),
    );
    if (selected == null) return;

    setState(() {
      _namaPembeliCtrl.text = selected.namaPembeli;
      _npwpPembeliCtrl.text = selected.npwpPembeli;
      _alamatPembeliCtrl.text = selected.alamatPembeli;
      _teleponPembeliCtrl.text = selected.teleponPembeli;
      _catatanCtrl.text = selected.catatan;
      _faktur.catatan = selected.catatan;
      _isDirty = true;
    });
    _items.value = selected.items
        .map((i) => ItemFaktur(
              namaBarang: i.nama,
              deskripsi: i.deskripsi,
              kuantitas: i.kuantitas,
              satuan: i.satuan,
              hargaSatuan: i.hargaSatuan,
            ))
        .toList();
  }

  void _resetForm() {
    setState(() {
      _isDirty = false;
      _nomorCtrl.clear();
      _namaPembeliCtrl.clear();
      _npwpPembeliCtrl.clear();
      _alamatPembeliCtrl.clear();
      _teleponPembeliCtrl.clear();
      _catatanCtrl.clear();
      _faktur.tanggal = DateTime.now();
      _faktur.jatuhTempo = null;
      _faktur.catatan = '';
      _items.value = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width >= 600 ? ((width - 680) / 2).clamp(24.0, 9999.0) : 20.0;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'reset') _resetForm();
              if (val == 'save_template') _saveAsTemplate();
              if (val == 'load_template') _loadTemplate();
              if (val == 'catalog') _openCatalog();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'catalog',
                  child: ListTile(
                    leading: const Icon(Icons.inventory_2_outlined, size: 20),
                    title: Text(tr('invoice.catalog'),
                        style: const TextStyle(fontSize: 14)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
              PopupMenuItem(
                  value: 'load_template',
                  child: ListTile(
                    leading: const Icon(Icons.file_open_outlined, size: 20),
                    title: Text(tr('invoice.load_template'),
                        style: const TextStyle(fontSize: 14)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
              PopupMenuItem(
                  value: 'save_template',
                  child: ListTile(
                    leading: const Icon(Icons.save_outlined, size: 20),
                    title: Text(tr('invoice.save_template'),
                        style: const TextStyle(fontSize: 14)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
              PopupMenuItem(
                  value: 'reset',
                  child: ListTile(
                    leading: const Icon(Icons.refresh, size: 20),
                    title: Text(tr('invoice.reset_form'),
                        style: const TextStyle(fontSize: 14)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
        children: [
          _buildHeader(theme),
          if (_settings.isEmpty) ...[
            const SizedBox(height: 8),
            Text(tr('invoice.store_missing'), style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 24),
          _buildClientRow(theme),
          const Divider(height: 1),
          _buildDueRow(theme),
          const Divider(height: 1),
          const SizedBox(height: 24),
          _buildItems(theme),
          const Divider(height: 1),
          _buildExtrasRow(theme),
        ],
      ),
      bottomNavigationBar: TotalBar(
        total: _total,
        currency: _currency,
        actionLabel: tr('invoice.make_pdf'),
        busy: _isGenerating,
        onAction: _generatePdf,
      ),
    ),
    );
  }

  Widget _row(
    ThemeData theme, {
    String? label,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null) ...[
                    Text(label, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                  ],
                  Text(title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: titleColor)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
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

  Widget _buildHeader(ThemeData theme) {
    return InkWell(
      onTap: _editNumber,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('invoice.new_title'), style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(_nomorCtrl.text, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Future<void> _editNumber() async {
    var draft = _nomorCtrl.text;
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('invoice.number')),
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

  Widget _buildClientRow(ThemeData theme) {
    final name = _namaPembeliCtrl.text.trim();
    final details = [_teleponPembeliCtrl.text.trim(), _alamatPembeliCtrl.text.trim()]
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return _row(
      theme,
      label: tr('invoice.to'),
      title: name.isEmpty ? tr('invoice.choose_client') : name,
      titleColor: name.isEmpty ? theme.colorScheme.primary : null,
      subtitle: details.isEmpty ? null : details,
      onTap: _showClientSheet,
    );
  }

  Future<void> _showClientSheet() async {
    String snapshot() =>
        '${_namaPembeliCtrl.text}|${_teleponPembeliCtrl.text}|${_alamatPembeliCtrl.text}';
    final before = snapshot();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(tr('invoice.client'),
                          style: Theme.of(ctx).textTheme.titleMedium)),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showContactPicker();
                    },
                    icon: const Icon(Icons.contacts_outlined, size: 18),
                    label: Text(tr('invoice.from_contacts')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _namaPembeliCtrl,
                autofocus: _namaPembeliCtrl.text.isEmpty,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: tr('invoice.client_name')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _teleponPembeliCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: tr('invoice.client_phone')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _alamatPembeliCtrl,
                maxLines: 2,
                decoration:
                    InputDecoration(labelText: tr('invoice.client_address')),
              ),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(tr('common.done'))),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      if (snapshot() != before) _isDirty = true;
    });
  }

  Widget _buildDueRow(ThemeData theme) {
    final due = _faktur.jatuhTempo;
    final days = due == null
        ? null
        : DateUtils.dateOnly(due)
            .difference(DateUtils.dateOnly(_faktur.tanggal))
            .inDays;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _pickDate(true),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('invoice.due'), style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      due == null
                          ? tr('invoice.no_due')
                          : DateFormat('d MMM yyyy', _dateLocale).format(due),
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final d in const [7, 14, 30])
                ChoiceChip(
                  label:
                      Text(tr('invoice.days_short').replaceAll('{n}', '$d')),
                  selected: days == d,
                  showCheckmark: false,
                  onSelected: (_) => setState(() {
                    _faktur.jatuhTempo =
                        _faktur.tanggal.add(Duration(days: d));
                    _isDirty = true;
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItems(ThemeData theme) {
    return ValueListenableBuilder<List<ItemFaktur>>(
      valueListenable: _items,
      builder: (context, items, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('invoice.items'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child:
                  Text(tr('invoice.no_items'), style: theme.textTheme.bodySmall),
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
                onPressed: _openCatalog,
                child: Text(tr('invoice.from_catalog')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemRow(ThemeData theme, ItemFaktur item, int index) {
    final isDark = theme.brightness == Brightness.dark;
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.namaBarang, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmtQty(item.kuantitas)} ${item.satuan} × '
                      '${_currency.format(item.hargaSatuan)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(_currency.format(item.jumlah),
                  style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExtrasRow(ThemeData theme) {
    final note = _catatanCtrl.text.trim();
    return _row(
      theme,
      title: tr('invoice.extras').replaceAll('{tax}', _fmtQty(_faktur.taxRate)),
      subtitle: note.isEmpty ? null : note,
      onTap: _showExtrasSheet,
    );
  }

  Future<void> _showExtrasSheet() async {
    final before = _catatanCtrl.text;
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
                Text(tr('invoice.extras_title'),
                    style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('invoice.date')),
                  trailing: Text(DateFormat('d MMM yyyy', _dateLocale)
                      .format(_faktur.tanggal)),
                  onTap: () async {
                    await _pickDate(false);
                    setSheet(() {});
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('invoice.tax')),
                  subtitle: Text(tr('invoice.tax_hint')),
                  trailing: Text('${_fmtQty(_faktur.taxRate)}%'),
                ),
                const SizedBox(height: 8),
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
    setState(() {
      if (_catatanCtrl.text != before) _isDirty = true;
    });
  }
}

// ─── Contact Picker Bottom Sheet ─────────────────────────────────────────────

class _ContactPickerSheet extends StatefulWidget {
  final List<ContactModel> contacts;
  final Future<void> Function(String id) onDelete;

  const _ContactPickerSheet({
    required this.contacts,
    required this.onDelete,
  });

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  late List<ContactModel> _filtered;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.contacts;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.contacts;
      } else {
        final q = query.toLowerCase();
        _filtered = widget.contacts
            .where((c) =>
                c.nama.toLowerCase().contains(q) ||
                c.alamat.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  Future<void> _confirmDelete(ContactModel contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('invoice.delete_contact_title')),
        content: Text(tr('invoice.delete_contact_body')
            .replaceAll('{name}', contact.nama)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('common.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('common.delete'),
                style: TextStyle(
                    color: AppColors.errorFor(Theme.of(ctx).brightness))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.onDelete(contact.id);
      if (mounted) {
        setState(() {
          _filtered = List.from(_filtered)
            ..removeWhere((c) => c.id == contact.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar + header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.contacts_rounded,
                            color: theme.colorScheme.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          tr('invoice.pick_contact'),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          trN('invoice.contact_count', widget.contacts.length),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Search
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: tr('invoice.search_contact'),
                        hintStyle: GoogleFonts.inter(
                            fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_off_outlined,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text(
                              widget.contacts.isEmpty
                                  ? tr('invoice.no_contacts')
                                  : tr('contact.not_found'),
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
                            ),
                            if (widget.contacts.isEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                tr('invoice.contacts_auto_hint'),
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 4),
                        itemBuilder: (_, i) =>
                            _buildContactTile(_filtered[i], theme),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactTile(ContactModel contact, ThemeData theme) {
    final initials = contact.nama.isNotEmpty
        ? contact.nama
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context, contact),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.nama,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (contact.npwp.isNotEmpty)
                      Text(
                        'NPWP: ${contact.npwp}',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
                      ),
                    if (contact.alamat.isNotEmpty)
                      Text(
                        contact.alamat,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Delete
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                onPressed: () => _confirmDelete(contact),
                tooltip: tr('invoice.delete_contact'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Template Picker Bottom Sheet ────────────────────────────────────────────

class _TemplatePickerSheet extends StatelessWidget {
  final List<TemplateModel> templates;

  const _TemplatePickerSheet({required this.templates});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.file_copy_rounded,
                            color: theme.colorScheme.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          tr('invoice.pick_template'),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: templates.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final t = templates[i];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.description_outlined,
                            color: theme.colorScheme.primary, size: 20),
                      ),
                      title: Text(t.name,
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        t.namaPembeli.isNotEmpty
                            ? '${t.namaPembeli} - ${trN('invoice.item_count', t.items.length)}'
                            : trN('invoice.item_count', t.items.length),
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                        onPressed: () async {
                          await TemplateService.delete(t.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      onTap: () => Navigator.pop(context, t),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
