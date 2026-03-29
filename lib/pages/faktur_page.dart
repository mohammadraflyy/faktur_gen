import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../services/pdf_service.dart';
import '../services/settings_service.dart';
import '../services/reminder_service.dart';
import '../services/template_service.dart';
import '../models/reminder_model.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _faktur = FakturModel();

  final _nomorCtrl = TextEditingController();
  final _namaPembeliCtrl = TextEditingController();
  final _npwpPembeliCtrl = TextEditingController();
  final _alamatPembeliCtrl = TextEditingController();
  final _teleponPembeliCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  final List<_ItemCtrls> _itemCtrls = [_ItemCtrls()];

  SettingsModel _settings = SettingsModel();
  List<ContactModel> _contacts = [];

  NumberFormat get _currency => NumberFormat.currency(
        locale: _settings.currencyLocale,
        symbol: _settings.currencySymbol,
        decimalDigits: 0,
      );

  bool _isLoading = true;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
          _faktur.items = entry.items
              .map((i) => ItemFaktur(
                    namaBarang: i.nama,
                    kuantitas: i.kuantitas,
                    satuan: i.satuan,
                    hargaSatuan: i.hargaSatuan,
                  ))
              .toList();
          if (_faktur.items.isEmpty) _faktur.items = [ItemFaktur()];
          for (final c in _itemCtrls) {
            c.dispose();
          }
          _itemCtrls.clear();
          for (final item in _faktur.items) {
            final c = _ItemCtrls();
            c.namaCtrl.text = item.namaBarang;
            c.deskripsiCtrl.text = item.deskripsi;
            c.qtyCtrl.text = _fmtQty(item.kuantitas);
            c.satuanCtrl.text = item.satuan;
            c.hargaCtrl.text =
                item.hargaSatuan > 0 ? item.hargaSatuan.toInt().toString() : '';
            _itemCtrls.add(c);
          }
        } else if (widget.reminderItems != null &&
            widget.reminderItems!.isNotEmpty) {
          _nomorCtrl.text = invNum;
          if (widget.reminderContactName != null) {
            _namaPembeliCtrl.text = widget.reminderContactName!;
          }
          _faktur.items = widget.reminderItems!
              .map((i) => ItemFaktur(
                    namaBarang: i.nama,
                    kuantitas: i.kuantitas,
                    satuan: i.satuan,
                    hargaSatuan: i.hargaSatuan,
                  ))
              .toList();
          for (final c in _itemCtrls) {
            c.dispose();
          }
          _itemCtrls.clear();
          for (final item in _faktur.items) {
            final c = _ItemCtrls();
            c.namaCtrl.text = item.namaBarang;
            c.qtyCtrl.text = _fmtQty(item.kuantitas);
            c.satuanCtrl.text = item.satuan;
            c.hargaCtrl.text =
                item.hargaSatuan > 0 ? item.hargaSatuan.toInt().toString() : '';
            _itemCtrls.add(c);
          }
        } else {
          _nomorCtrl.text = invNum;
        }
        _isLoading = false;
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
    for (final c in _itemCtrls) {
      c.dispose();
    }
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
        if (isJatuhTempo) {
          _faktur.jatuhTempo = picked;
        } else {
          _faktur.tanggal = picked;
        }
      });
    }
  }

  void _addItem() {
    setState(() {
      _isDirty = true;
      _faktur.items.add(ItemFaktur());
      _itemCtrls.add(_ItemCtrls());
    });
  }

  void _removeItem(int index) {
    if (_faktur.items.length <= 1) return;
    final removedItem = _faktur.items[index];
    final removedCtrl = _itemCtrls[index];
    setState(() {
      _faktur.items.removeAt(index);
      _itemCtrls.removeAt(index);
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Item "${removedItem.namaBarang.isNotEmpty ? removedItem.namaBarang : 'Item ${index + 1}'}" dihapus',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              final insertAt = index.clamp(0, _faktur.items.length);
              _faktur.items.insert(insertAt, removedItem);
              _itemCtrls.insert(insertAt, removedCtrl);
            });
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _generatePdf() async {
    if (!_formKey.currentState!.validate()) return;
    _syncToModel();
    if (!mounted) return;

    final faktur = _faktur;
    final logoBytes = _settings.logoBytes;
    final signatureBytes = _settings.signatureBytes;

    // Auto-save kontak baru
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

    _isDirty = false;
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewPage(
          title: 'Preview Invoice',
          filename: 'Invoice_${faktur.nomorFaktur.replaceAll('/', '-')}.pdf',
          buildPdf: (format) => PdfService.buildBytes(faktur, format,
              logoBytes: logoBytes,
              signatureBytes: signatureBytes,
              templateConfig: _settings.templateConfig),
        ),
      ),
    );
    if (!mounted) return;
    _showReminderDialog(faktur);
  }

  Future<void> _showReminderDialog(FakturModel faktur) async {
    if (faktur.namaPembeli.trim().isEmpty) return;
    final setReminder = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atur Pengingat?'),
        content: Text(
            'Ingin mengatur pengingat layanan untuk ${faktur.namaPembeli}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Atur'),
          ),
        ],
      ),
    );
    if (setReminder != true || !mounted) return;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (time == null) return;

    await ReminderService.add(ReminderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      contactName: faktur.namaPembeli,
      contactPhone: faktur.teleponPembeli,
      contactAddress: faktur.alamatPembeli,
      serviceName: faktur.items.isNotEmpty ? faktur.items.first.namaBarang : '',
      reminderDate: date,
      reminderHour: time.hour,
      reminderMinute: time.minute,
      docType: ReminderDocType.invoice,
      lastItems: faktur.items
          .map((i) => ReminderItem(
                nama: i.namaBarang,
                kuantitas: i.kuantitas,
                satuan: i.satuan,
                hargaSatuan: i.hargaSatuan,
              ))
          .toList(),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pengingat berhasil disimpan'),
          backgroundColor: AppColors.successFor(Theme.of(context).brightness),
        ),
      );
    }
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
      builder: (_) => _CatalogPickerSheet(
        items: items,
        currencySymbol: _settings.currencySymbol,
        currencyLocale: _settings.currencyLocale,
      ),
    );
    if (selected == null) return;
    setState(() {
      _isDirty = true;
      _faktur.items.add(ItemFaktur(
        namaBarang: selected.nama,
        deskripsi: selected.deskripsi,
        satuan: selected.satuan,
        hargaSatuan: selected.hargaSatuan,
      ));
      final c = _ItemCtrls();
      c.namaCtrl.text = selected.nama;
      c.deskripsiCtrl.text = selected.deskripsi;
      c.satuanCtrl.text = selected.satuan;
      c.hargaCtrl.text = selected.hargaSatuan > 0
          ? selected.hargaSatuan.toInt().toString()
          : '';
      _itemCtrls.add(c);
    });
  }

  Future<void> _saveAsTemplate() async {
    _syncToModel();
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simpan Template'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nama Template',
            hintText: 'cth: Invoice Bulanan PT ABC',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text),
            child: const Text('Simpan'),
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
          content: Text('Template "$name" tersimpan'),
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
        const SnackBar(content: Text('Belum ada template tersimpan')),
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
      _faktur.items = selected.items
          .map((i) => ItemFaktur(
                namaBarang: i.nama,
                deskripsi: i.deskripsi,
                kuantitas: i.kuantitas,
                satuan: i.satuan,
                hargaSatuan: i.hargaSatuan,
              ))
          .toList();
      if (_faktur.items.isEmpty) _faktur.items = [ItemFaktur()];
      for (final c in _itemCtrls) {
        c.dispose();
      }
      _itemCtrls.clear();
      for (final item in _faktur.items) {
        final c = _ItemCtrls();
        c.namaCtrl.text = item.namaBarang;
        c.deskripsiCtrl.text = item.deskripsi;
        c.qtyCtrl.text = _fmtQty(item.kuantitas);
        c.satuanCtrl.text = item.satuan;
        c.hargaCtrl.text =
            item.hargaSatuan > 0 ? item.hargaSatuan.toInt().toString() : '';
        _itemCtrls.add(c);
      }
      _isDirty = true;
    });
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
      _faktur.items = [ItemFaktur()];
      for (final c in _itemCtrls) {
        c.dispose();
      }
      _itemCtrls
        ..clear()
        ..add(_ItemCtrls());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 600;
    final hPad = isTablet ? ((width - 680) / 2).clamp(24.0, 9999.0) : 16.0;

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
            title: const Text('Keluar?'),
            content: const Text('Form belum disimpan. Yakin ingin keluar?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Keluar',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Buat Invoice'),
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
              const PopupMenuItem(
                  value: 'catalog',
                  child: ListTile(
                    leading: Icon(Icons.inventory_2_outlined, size: 20),
                    title: Text('Katalog Item', style: TextStyle(fontSize: 14)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
              const PopupMenuItem(
                  value: 'load_template',
                  child: ListTile(
                    leading: Icon(Icons.file_open_outlined, size: 20),
                    title: Text('Load Template', style: TextStyle(fontSize: 14)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
              const PopupMenuItem(
                  value: 'save_template',
                  child: ListTile(
                    leading: Icon(Icons.save_outlined, size: 20),
                    title:
                        Text('Simpan Template', style: TextStyle(fontSize: 14)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
              const PopupMenuItem(
                  value: 'reset',
                  child: ListTile(
                    leading: Icon(Icons.refresh, size: 20),
                    title: Text('Reset Form', style: TextStyle(fontSize: 14)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
            ],
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 24),
          children: [
            _buildPenjualBanner(theme),
            const SizedBox(height: 24),
            _buildInfoInvoice(theme),
            const SizedBox(height: 24),
            _buildPembeli(theme, isTablet: isTablet),
            const SizedBox(height: 24),
            _buildItemSection(theme),
            const SizedBox(height: 24),
            _buildTotalCard(theme),
            const SizedBox(height: 24),
            _buildCatatanCard(theme),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 8),
          child: _buildGenerateButton(theme, isTablet: isTablet),
        ),
      ),
    ),
    );
  }

  Widget _buildInfoInvoice(ThemeData theme) {
    return _card(
      theme,
      title: 'Informasi Invoice',
      icon: Icons.receipt_long_outlined,
      children: [
        _field(
          controller: _nomorCtrl,
          label: 'Nomor Invoice',
          hint: 'cth: INV-001',
          required: true,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _datePicker(
                label: 'Tanggal Invoice',
                date: _faktur.tanggal,
                onTap: () => _pickDate(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _datePicker(
                label: 'Jatuh Tempo',
                date: _faktur.jatuhTempo,
                onTap: () => _pickDate(true),
                optional: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    bool optional = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          date != null
              ? DateFormat('dd/MM/yyyy').format(date)
              : optional
                  ? 'Opsional'
                  : '-',
          style: TextStyle(
            fontSize: 14,
            color: date == null ? Colors.grey : null,
          ),
        ),
      ),
    );
  }

  Widget _buildPenjualBanner(ThemeData theme) {
    return Container(
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _settings.hasLogo
                  ? null
                  : theme.colorScheme.primary.withValues(alpha: 0.07),
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
                    color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _settings.namaToko.isEmpty
                      ? 'Nama toko belum diisi'
                      : _settings.namaToko,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (_settings.alamat.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(_settings.alamat,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.45)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          Icon(Icons.lock_outline,
              size: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
        ],
      ),
    );
  }

  Widget _buildPembeli(ThemeData theme, {bool isTablet = false}) {
    return _card(
      theme,
      title: 'Tagihan Kepada',
      icon: Icons.person_outline,
      trailing: TextButton.icon(
        onPressed: _showContactPicker,
        icon: const Icon(Icons.contacts_outlined, size: 18),
        label: Text(_contacts.isEmpty ? 'Kontak' : 'Pilih Kontak'),
      ),
      children: [
        _field(
          controller: _namaPembeliCtrl,
          label: 'Nama Perusahaan / Klien',
          required: true,
        ),
        const SizedBox(height: 14),
        _field(
          controller: _teleponPembeliCtrl,
          label: 'No. Telepon / WhatsApp',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),
        _field(
          controller: _alamatPembeliCtrl,
          label: 'Alamat',
          maxLines: 2,
        ),
      ],
    );
  }

  void _reorderItem(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _faktur.items.removeAt(oldIndex);
      _faktur.items.insert(newIndex, item);
      final ctrl = _itemCtrls.removeAt(oldIndex);
      _itemCtrls.insert(newIndex, ctrl);
      _isDirty = true;
    });
  }

  Widget _buildItemSection(ThemeData theme) {
    return _card(
      theme,
      title: 'Item / Layanan',
      icon: Icons.inventory_2_outlined,
      trailing: TextButton.icon(
        onPressed: _addItem,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Tambah Item'),
      ),
      children: [
        ...List.generate(_faktur.items.length, (i) => _buildItemRow(i, theme)),
      ],
    );
  }

  Widget _buildItemRow(int index, ThemeData theme) {
    final item = _faktur.items[index];
    final ctrls = _itemCtrls[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Item ${index + 1}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const Spacer(),
              if (_faktur.items.length > 1) ...[
                if (index > 0)
                  GestureDetector(
                    onTap: () => _reorderItem(index, index - 1),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.arrow_upward_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                    ),
                  ),
                if (index < _faktur.items.length - 1)
                  GestureDetector(
                    onTap: () => _reorderItem(index, index + 2),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.arrow_downward_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                    ),
                  ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _removeItem(index),
                  child: Icon(Icons.close_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: ctrls.namaCtrl,
            decoration: const InputDecoration(labelText: 'Nama Item / Layanan'),
            onChanged: (v) => item.namaBarang = v,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: ctrls.deskripsiCtrl,
            decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)', hintText: 'Detail tambahan...'),
            onChanged: (v) => item.deskripsi = v,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: ctrls.qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                  ],
                  onChanged: (v) {
                    setState(() {
                      item.kuantitas = double.tryParse(v) ?? item.kuantitas;
                    });
                  },
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: ctrls.satuanCtrl,
                  decoration: const InputDecoration(labelText: 'Satuan'),
                  onChanged: (v) => item.satuan = v,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: ctrls.hargaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Harga Satuan',
                    prefixText: _settings.currencySymbol,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) {
                    setState(() {
                      item.hargaSatuan = double.tryParse(v) ?? 0;
                    });
                  },
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _currency.format(item.jumlah),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(ThemeData theme) {
    final taxLabel = 'PPN (${_faktur.taxRate % 1 == 0 ? _faktur.taxRate.toInt() : _faktur.taxRate}%)';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          _totalRow('DPP', _faktur.totalDpp, theme),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
                height: 0.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
          ),
          _totalRow(taxLabel, _faktur.totalPpn, theme),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
                height: 0.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
          ),
          _totalRow('Total', _faktur.totalTagihan, theme, bold: true),
        ],
      ),
    );
  }

  Widget _buildCatatanCard(ThemeData theme) {
    return _card(
      theme,
      title: 'Catatan',
      icon: Icons.notes_outlined,
      children: [
        _field(
          controller: _catatanCtrl,
          label: 'Catatan / Syarat Pembayaran (opsional)',
          hint: 'cth: Pembayaran via transfer ke rekening BCA 1234567890',
          maxLines: 3,
          onChanged: (v) => _faktur.catatan = v,
        ),
      ],
    );
  }

  Widget _totalRow(String label, double value, ThemeData theme,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              fontSize: bold ? 16 : 14,
              color: bold
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.55),
            )),
        Text(_currency.format(value),
            style: GoogleFonts.inter(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              fontSize: bold ? 16 : 14,
              color: theme.colorScheme.onSurface,
            )),
      ],
    );
  }

  Widget _buildGenerateButton(ThemeData theme, {bool isTablet = false}) {
    final btn = SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _generatePdf,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text('Generate Invoice',
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
    if (isTablet) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: btn,
        ),
      );
    }
    return btn;
  }

  Widget _card(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing,
              ],
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: required
          ? (v) => (v == null || v.isEmpty) ? '$label wajib diisi' : null
          : null,
    );
  }
}

class _ItemCtrls {
  final namaCtrl = TextEditingController();
  final deskripsiCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
  final satuanCtrl = TextEditingController(text: 'Unit');
  final hargaCtrl = TextEditingController();

  void dispose() {
    namaCtrl.dispose();
    deskripsiCtrl.dispose();
    qtyCtrl.dispose();
    satuanCtrl.dispose();
    hargaCtrl.dispose();
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
        title: const Text('Hapus Kontak?'),
        content: Text('Hapus "${contact.nama}" dari daftar kontak?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
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
                          'Pilih Kontak',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${widget.contacts.length} kontak',
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
                        hintText: 'Cari nama atau alamat...',
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
                                  ? 'Belum ada kontak tersimpan'
                                  : 'Tidak ditemukan',
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
                            ),
                            if (widget.contacts.isEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Kontak otomatis tersimpan saat buat invoice',
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
                tooltip: 'Hapus kontak',
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
                          'Pilih Template',
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
                            ? '${t.namaPembeli} - ${t.items.length} item'
                            : '${t.items.length} item',
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

// ─── Catalog Picker Bottom Sheet ─────────────────────────────────────────────

class _CatalogPickerSheet extends StatefulWidget {
  final List<CatalogItem> items;
  final String currencySymbol;
  final String currencyLocale;
  const _CatalogPickerSheet({
    required this.items,
    this.currencySymbol = 'Rp ',
    this.currencyLocale = 'id_ID',
  });

  @override
  State<_CatalogPickerSheet> createState() => _CatalogPickerSheetState();
}

class _CatalogPickerSheetState extends State<_CatalogPickerSheet> {
  late List<CatalogItem> _items;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = widget.items;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String q) {
    setState(() {
      if (q.isEmpty) {
        _items = widget.items;
      } else {
        final lq = q.toLowerCase();
        _items = widget.items
            .where((c) => c.nama.toLowerCase().contains(lq))
            .toList();
      }
    });
  }

  Future<void> _addNew() async {
    final namaCtrl = TextEditingController();
    final satuanCtrl = TextEditingController(text: 'Unit');
    final hargaCtrl = TextEditingController();

    final result = await showDialog<CatalogItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Item Katalog'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaCtrl,
              decoration: const InputDecoration(labelText: 'Nama Item'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: satuanCtrl,
                    decoration: const InputDecoration(labelText: 'Satuan'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: hargaCtrl,
                    decoration: const InputDecoration(labelText: 'Harga'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              if (namaCtrl.text.trim().isEmpty) return;
              final item = CatalogItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                nama: namaCtrl.text.trim(),
                satuan: satuanCtrl.text.trim(),
                hargaSatuan: double.tryParse(hargaCtrl.text) ?? 0,
              );
              Navigator.pop(ctx, item);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    namaCtrl.dispose();
    satuanCtrl.dispose();
    hargaCtrl.dispose();

    if (result != null) {
      await CatalogService.save(result);
      if (mounted) Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.85,
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
                        Icon(Icons.inventory_2_outlined,
                            color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Katalog Item',
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addNew,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Baru'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _filter,
                      decoration: const InputDecoration(
                        hintText: 'Cari item...',
                        prefixIcon: Icon(Icons.search, size: 18),
                      ),
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _items.isEmpty
                    ? Center(
                        child: Text(
                          widget.items.isEmpty
                              ? 'Katalog kosong. Tap "Baru" untuk menambah.'
                              : 'Tidak ditemukan',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final item = _items[i];
                          return ListTile(
                            title: Text(item.nama,
                                style: GoogleFonts.inter(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                            subtitle: Text(
                              '${item.satuan} - ${NumberFormat.currency(locale: widget.currencyLocale, symbol: widget.currencySymbol, decimalDigits: 0).format(item.hargaSatuan)}',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                              onPressed: () async {
                                await CatalogService.delete(item.id);
                                final refreshed =
                                    await CatalogService.loadAll();
                                setState(() {
                                  _items = refreshed;
                                });
                              },
                            ),
                            onTap: () => Navigator.pop(context, item),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
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
