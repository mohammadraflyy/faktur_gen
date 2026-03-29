import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import '../main.dart';
import '../models/catalog_model.dart';
import '../models/history_model.dart';
import '../models/settings_model.dart';
import '../models/struk_model.dart';
import '../models/reminder_model.dart';
import '../services/catalog_service.dart';
import '../services/history_service.dart';
import '../services/reminder_service.dart';
import '../services/settings_service.dart';
import '../services/struk_pdf_service.dart';
import 'pdf_preview_page.dart';

class StrukPage extends StatefulWidget {
  final HistoryEntry? initialEntry;
  final List<ReminderItem>? reminderItems;
  final String? reminderContactName;
  const StrukPage({
    super.key,
    this.initialEntry,
    this.reminderItems,
    this.reminderContactName,
  });

  @override
  State<StrukPage> createState() => _StrukPageState();
}

class _StrukPageState extends State<StrukPage> {
  final _formKey = GlobalKey<FormState>();
  final _struk = StrukModel();

  SettingsModel _settings = SettingsModel();

  final _nomorStrukCtrl = TextEditingController();
  final List<_ItemCtrls> _itemCtrls = [];
  final _kasirCtrl = TextEditingController();
  final _diskonCtrl = TextEditingController();
  final _bayarCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();

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
    if (mounted) {
      setState(() {
        _settings = s;
        _struk.namaToko = s.namaToko;
        _struk.alamatToko = s.alamat;
        _struk.teleponToko = s.telepon;

        final entry = widget.initialEntry;
        if (entry != null) {
          _nomorStrukCtrl.text = nomorStruk;
          _kasirCtrl.text = entry.namaKasir ?? '';
          _diskonCtrl.text =
              entry.diskon != null && entry.diskon! > 0
                  ? entry.diskon!.toInt().toString()
                  : '';
          _bayarCtrl.text =
              entry.jumlahBayar != null && entry.jumlahBayar! > 0
                  ? entry.jumlahBayar!.toInt().toString()
                  : '';
          _catatanCtrl.text = entry.catatan;
          _struk.catatan = entry.catatan;
          _struk.diskon = entry.diskon ?? 0;
          _struk.metodeBayar = _parseMetodeBayar(entry.metodeBayar);
          _struk.jumlahBayar = entry.jumlahBayar ?? 0;
          _struk.items = entry.items
              .map((i) => ItemStruk(
                    nama: i.nama,
                    kuantitas: i.kuantitas,
                    satuan: i.satuan,
                    hargaSatuan: i.hargaSatuan,
                    diskon: i.diskon,
                  ))
              .toList();
          if (_struk.items.isEmpty) _struk.items = [];
          for (final c in _itemCtrls) {
            c.dispose();
          }
          _itemCtrls.clear();
          for (final item in _struk.items) {
            final c = _ItemCtrls();
            c.namaCtrl.text = item.nama;
            c.deskripsiCtrl.text = item.deskripsi;
            c.qtyCtrl.text = _fmtQty(item.kuantitas);
            c.satuanCtrl.text = item.satuan;
            c.hargaCtrl.text =
                item.hargaSatuan > 0 ? item.hargaSatuan.toInt().toString() : '';
            c.diskonCtrl.text =
                item.diskon > 0 ? item.diskon.toInt().toString() : '';
            _itemCtrls.add(c);
          }
        } else if (widget.reminderItems != null &&
            widget.reminderItems!.isNotEmpty) {
          _nomorStrukCtrl.text = nomorStruk;
          _struk.catatan = s.footerStruk;
          _catatanCtrl.text = s.footerStruk;
          if (widget.reminderContactName != null) {
            _kasirCtrl.text = widget.reminderContactName!;
          }
          _struk.items = widget.reminderItems!
              .map((i) => ItemStruk(
                    nama: i.nama,
                    kuantitas: i.kuantitas,
                    satuan: i.satuan,
                    hargaSatuan: i.hargaSatuan,
                  ))
              .toList();
          for (final c in _itemCtrls) {
            c.dispose();
          }
          _itemCtrls.clear();
          for (final item in _struk.items) {
            final c = _ItemCtrls();
            c.namaCtrl.text = item.nama;
            c.qtyCtrl.text = _fmtQty(item.kuantitas);
            c.satuanCtrl.text = item.satuan;
            c.hargaCtrl.text =
                item.hargaSatuan > 0 ? item.hargaSatuan.toInt().toString() : '';
            _itemCtrls.add(c);
          }
        } else {
          _struk.catatan = s.footerStruk;
          _catatanCtrl.text = s.footerStruk;
          _nomorStrukCtrl.text = nomorStruk;
          _struk.items = [];
          for (final c in _itemCtrls) {
            c.dispose();
          }
          _itemCtrls.clear();
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nomorStrukCtrl.dispose();
    _kasirCtrl.dispose();
    _diskonCtrl.dispose();
    _bayarCtrl.dispose();
    _catatanCtrl.dispose();
    for (final c in _itemCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncToModel() {
    _isDirty = true;
    _struk.namaToko = _settings.namaToko;
    _struk.alamatToko = _settings.alamat;
    _struk.teleponToko = _settings.telepon;
    _struk.nomorStruk = _nomorStrukCtrl.text;
    _struk.namaKasir = _kasirCtrl.text;
    _struk.diskon = double.tryParse(_diskonCtrl.text) ?? 0;
    _struk.jumlahBayar = double.tryParse(_bayarCtrl.text) ?? 0;
    _struk.catatan = _catatanCtrl.text;
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
    if (pickedTime == null) return;

    setState(() {
      _struk.tanggal = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _addItemFromCatalog() async {
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
      final item = ItemStruk(
        nama: selected.nama,
        kuantitas: 1,
        satuan: selected.satuan,
        hargaSatuan: selected.hargaSatuan,
      );
      _struk.items.add(item);
      final c = _ItemCtrls();
      c.namaCtrl.text = selected.nama;
      c.deskripsiCtrl.text = selected.deskripsi;
      c.qtyCtrl.text = '1';
      c.satuanCtrl.text = selected.satuan;
      c.hargaCtrl.text =
          selected.hargaSatuan > 0 ? selected.hargaSatuan.toInt().toString() : '';
      _itemCtrls.add(c);
    });
  }

  void _reorderItem(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _struk.items.removeAt(oldIndex);
      _struk.items.insert(newIndex, item);
      final ctrl = _itemCtrls.removeAt(oldIndex);
      _itemCtrls.insert(newIndex, ctrl);
      _isDirty = true;
    });
  }

  void _removeItem(int index) {
    if (_struk.items.isEmpty) return;
    final removedItem = _struk.items[index];
    final removedCtrl = _itemCtrls[index];
    setState(() {
      _struk.items.removeAt(index);
      _itemCtrls.removeAt(index);
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${removedItem.nama.isNotEmpty ? removedItem.nama : 'Item ${index + 1}'}" dihapus',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              final insertAt = index.clamp(0, _struk.items.length);
              _struk.items.insert(insertAt, removedItem);
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

    // Validate items exist
    if (_struk.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tambahkan minimal 1 barang dari katalog')),
      );
      return;
    }
    if (!mounted) return;

    final struk = _struk;
    final logoBytes = _settings.logoBytes;
    const struklFormat = PdfPageFormat(226.77, double.infinity, marginAll: 12);

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

    _isDirty = false;
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewPage(
          title: 'Preview Struk',
          filename: 'Struk_${struk.nomorStruk.replaceAll('/', '-')}.pdf',
          buildPdf: (format) =>
              StrukPdfService.buildBytes(struk, format,
                  logoBytes: logoBytes,
                  currencySymbol: _settings.currencySymbol,
                  currencyLocale: _settings.currencyLocale,
                  templateConfig: _settings.templateConfig),
          initialPageFormat: struklFormat,
          canChangePageFormat: false,
        ),
      ),
    );
    if (!mounted) return;
    _showReminderDialog(struk);
  }

  Future<void> _showReminderDialog(StrukModel struk) async {
    final customerName = struk.namaKasir.isNotEmpty ? struk.namaKasir : '';
    final setReminder = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atur Pengingat?'),
        content: Text(customerName.isNotEmpty
            ? 'Ingin mengatur pengingat layanan untuk $customerName?'
            : 'Ingin mengatur pengingat untuk layanan ini?'),
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
      contactName: customerName.isNotEmpty ? customerName : 'Pelanggan',
      serviceName: struk.items.isNotEmpty ? struk.items.first.nama : '',
      reminderDate: date,
      reminderHour: time.hour,
      reminderMinute: time.minute,
      docType: ReminderDocType.struk,
      lastItems: struk.items
          .map((i) => ReminderItem(
                nama: i.nama,
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

  void _resetForm() {
    setState(() {
      _isDirty = false;
      _nomorStrukCtrl.clear();
      _kasirCtrl.clear();
      _diskonCtrl.clear();
      _bayarCtrl.clear();
      _catatanCtrl.clear();
      _struk.tanggal = DateTime.now();
      _struk.items = [];
      _struk.metodeBayar = MetodeBayar.tunai;
      _struk.diskon = 0;
      _struk.jumlahBayar = 0;
      for (final c in _itemCtrls) {
        c.dispose();
      }
      _itemCtrls.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 600;
    final hPad = isTablet ? ((width - 680) / 2).clamp(24.0, 9999.0) : 16.0;

    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: theme.brightness == Brightness.dark
              ? AppColors.strukGreenSoft
              : AppColors.strukGreen,
          secondary: theme.brightness == Brightness.dark
              ? AppColors.strukGreenSoft
              : AppColors.strukGreen,
        ),
      ),
      child: Builder(builder: (context) {
        final t = Theme.of(context);
        if (_isLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return PopScope(
          canPop: !_isDirty,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final leave = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Keluar?'),
                content:
                    const Text('Form belum disimpan. Yakin ingin keluar?'),
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
            title: const Text('Buat Struk'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset Form',
                onPressed: _resetForm,
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 24),
              children: [
                _buildTokoBanner(t),
                const SizedBox(height: 24),
                _buildInfoStruk(t),
                const SizedBox(height: 24),
                _buildItemSection(t),
                const SizedBox(height: 24),
                _buildPembayaran(t, isTablet: isTablet),
                const SizedBox(height: 24),
                _buildRingkasan(t),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 8),
              child: _buildGenerateButton(t, isTablet: isTablet),
            ),
          ),
        ),
        );
      }),
    );
  }

  Widget _buildTokoBanner(ThemeData theme) {
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
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (_settings.alamat.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(_settings.alamat,
                      style: TextStyle(
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

  Widget _buildInfoStruk(ThemeData theme) {
    return _card(
      theme,
      title: 'Info Struk',
      icon: Icons.receipt,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _field(
                controller: _nomorStrukCtrl,
                label: 'Nomor Struk',
                hint: 'cth: STR-001',
                required: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal & Waktu',
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yy HH:mm').format(_struk.tanggal),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _field(
          controller: _kasirCtrl,
          label: 'Nama Kasir (opsional)',
        ),
      ],
    );
  }

  Widget _buildItemSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              Icon(Icons.shopping_cart, size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
              const SizedBox(width: 6),
              Text(
                'Daftar Barang',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              if (_struk.items.isNotEmpty)
                Text(
                  '${_struk.items.length} item',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
        ),

        // Item list
        if (_struk.items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerTheme.color ?? Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.shopping_bag_outlined,
                    size: 36,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
                const SizedBox(height: 10),
                Text(
                  'Belum ada barang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tambahkan dari katalog',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(
              _struk.items.length, (i) => _buildItemRow(i, theme)),

        const SizedBox(height: 12),

        // Add item button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _addItemFromCatalog,
            icon: const Icon(Icons.add_shopping_cart, size: 18),
            label: const Text('Tambah Barang dari Katalog'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(int index, ThemeData theme) {
    final item = _struk.items[index];
    final ctrls = _itemCtrls[index];

    return Dismissible(
      key: ObjectKey(item),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.errorFor(theme.brightness),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 20),
      ),
      confirmDismiss: (_) async {
        _removeItem(index);
        return false; // we already removed it via setState
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
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
            // Top row: name + price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nama,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (ctrls.deskripsiCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          ctrls.deskripsiCtrl.text,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        '${_currency.format(item.hargaSatuan)} / ${item.satuan}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_struk.items.length > 1) ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index > 0)
                        GestureDetector(
                          onTap: () => _reorderItem(index, index - 1),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.arrow_upward_rounded,
                                size: 14,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.25)),
                          ),
                        ),
                      if (index < _struk.items.length - 1)
                        GestureDetector(
                          onTap: () => _reorderItem(index, index + 2),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.arrow_downward_rounded,
                                size: 14,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.25)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  _currency.format(item.subtotal),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Bottom row: qty controls + diskon
            Row(
              children: [
                // Qty stepper
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.dividerTheme.color ?? Colors.grey.shade200,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _qtyBtn(Icons.remove, () {
                        if (item.kuantitas > 1) {
                          setState(() {
                            item.kuantitas--;
                            ctrls.qtyCtrl.text = _fmtQty(item.kuantitas);
                          });
                        }
                      }, theme),
                      Container(
                        constraints: const BoxConstraints(minWidth: 40),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          _fmtQty(item.kuantitas),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _qtyBtn(Icons.add, () {
                        setState(() {
                          item.kuantitas++;
                          ctrls.qtyCtrl.text = _fmtQty(item.kuantitas);
                        });
                      }, theme),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Diskon inline
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextFormField(
                      controller: ctrls.diskonCtrl,
                      decoration: InputDecoration(
                        labelText: 'Diskon',
                        prefixText: _settings.currencySymbol,
                        hintText: '0',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      onChanged: (v) {
                        setState(() {
                          item.diskon = double.tryParse(v) ?? 0;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, ThemeData theme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
    );
  }

  Widget _buildPembayaran(ThemeData theme, {bool isTablet = false}) {
    final diskonField = TextFormField(
      controller: _diskonCtrl,
      decoration: InputDecoration(
        labelText: 'Diskon (${_settings.currencySymbol.trim()})',
        prefixText: _settings.currencySymbol,
        hintText: '0',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (v) {
        setState(() => _struk.diskon = double.tryParse(v) ?? 0);
      },
    );

    final metodeBayarField = DropdownButtonFormField<MetodeBayar>(
      initialValue: _struk.metodeBayar,
      decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
      items: MetodeBayar.values
          .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _struk.metodeBayar = v);
      },
    );

    return _card(
      theme,
      title: 'Pembayaran',
      icon: Icons.payments,
      children: [
        if (isTablet)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: diskonField),
              const SizedBox(width: 12),
              Expanded(child: metodeBayarField),
            ],
          )
        else ...[
          diskonField,
          const SizedBox(height: 12),
          metodeBayarField,
        ],
        if (_struk.metodeBayar == MetodeBayar.tunai) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _bayarCtrl,
            decoration: InputDecoration(
              labelText: 'Jumlah Bayar (${_settings.currencySymbol.trim()})',
              prefixText: _settings.currencySymbol,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {
              setState(() => _struk.jumlahBayar = double.tryParse(v) ?? 0);
            },
          ),
        ],
        const SizedBox(height: 12),
        _field(
          controller: _catatanCtrl,
          label: 'Catatan (opsional)',
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildRingkasan(ThemeData theme) {
    final isKembalianVisible =
        _struk.metodeBayar == MetodeBayar.tunai && _struk.jumlahBayar > 0;

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
          _totalRow('Subtotal', _struk.subtotal, theme),
          if (_struk.diskon > 0) ...[
            const Divider(height: 12),
            _totalRow('Diskon', -_struk.diskon, theme, isDiskon: true),
          ],
          const Divider(height: 12),
          _totalRow('Total', _struk.total, theme, bold: true),
          if (isKembalianVisible) ...[
            const Divider(height: 12),
            _totalRow('Bayar', _struk.jumlahBayar, theme),
            const Divider(height: 12),
            _totalRow('Kembalian', _struk.kembalian, theme, bold: true),
          ],
        ],
      ),
    );
  }

  Widget _totalRow(String label, double value, ThemeData theme,
      {bool bold = false, bool isDiskon = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
      color: isDiskon
          ? AppColors.errorFor(theme.brightness)
          : theme.colorScheme.primary,
    );
    final display = isDiskon
        ? '- ${_currency.format(value.abs())}'
        : _currency.format(value);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(display, style: style),
      ],
    );
  }

  Widget _buildGenerateButton(ThemeData theme, {bool isTablet = false}) {
    final btn = SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _generatePdf,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Generate Struk',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                style: TextStyle(
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
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
      maxLines: maxLines,
      keyboardType: keyboardType,
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
  final satuanCtrl = TextEditingController(text: 'pcs');
  final hargaCtrl = TextEditingController();
  final diskonCtrl = TextEditingController();

  void dispose() {
    namaCtrl.dispose();
    deskripsiCtrl.dispose();
    qtyCtrl.dispose();
    satuanCtrl.dispose();
    hargaCtrl.dispose();
    diskonCtrl.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Catalog Picker Bottom Sheet (with create-new ability)
// ─────────────────────────────────────────────────────────────────────────────

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
  late List<CatalogItem> _all;
  late List<CatalogItem> _filtered;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _all = widget.items;
    _filtered = _all;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String q) {
    setState(() {
      if (q.isEmpty) {
        _filtered = _all;
      } else {
        final lq = q.toLowerCase();
        _filtered =
            _all.where((c) => c.nama.toLowerCase().contains(lq)).toList();
      }
    });
  }

  Future<void> _refresh() async {
    final items = await CatalogService.loadAll();
    setState(() {
      _all = items;
      _filter(_searchCtrl.text);
    });
  }

  Future<void> _addNew() async {
    final namaCtrl = TextEditingController();
    final deskripsiCtrl = TextEditingController();
    final satuanCtrl = TextEditingController(text: 'pcs');
    final hargaCtrl = TextEditingController();

    final result = await showDialog<CatalogItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Barang Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama Barang'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: deskripsiCtrl,
                decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)'),
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
                deskripsi: deskripsiCtrl.text.trim(),
                satuan: satuanCtrl.text.trim(),
                hargaSatuan: double.tryParse(hargaCtrl.text) ?? 0,
              );
              Navigator.pop(ctx, item);
            },
            child: const Text('Simpan & Pilih'),
          ),
        ],
      ),
    );
    namaCtrl.dispose();
    deskripsiCtrl.dispose();
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
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.15),
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
                        Text('Pilih Barang',
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addNew,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Buat Baru'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _filter,
                      decoration: const InputDecoration(
                        hintText: 'Cari barang...',
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
                child: _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 48,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.15)),
                            const SizedBox(height: 12),
                            Text(
                              _all.isEmpty
                                  ? 'Belum ada barang'
                                  : 'Tidak ditemukan',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            if (_all.isEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Tap "Buat Baru" untuk menambah barang',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final item = _filtered[i];
                          final currency = NumberFormat.currency(
                            locale: widget.currencyLocale,
                            symbol: widget.currencySymbol,
                            decimalDigits: 0,
                          );
                          return ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.shopping_bag_outlined,
                                  size: 18, color: theme.colorScheme.primary),
                            ),
                            title: Text(item.nama,
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            subtitle: Text(
                              '${item.satuan} — ${currency.format(item.hargaSatuan)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 16,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3)),
                              onPressed: () async {
                                await CatalogService.delete(item.id);
                                await _refresh();
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
