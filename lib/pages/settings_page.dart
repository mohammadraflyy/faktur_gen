import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/settings_model.dart';
import '../services/backup_service.dart';
import '../services/settings_service.dart';
import '../services/theme_service.dart';
import '../widgets/signature_pad.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late SettingsModel _settings;

  final _namaCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _teleponCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _npwpCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  final _taxRateCtrl = TextEditingController();
  final _invPrefixCtrl = TextEditingController();
  final _strPrefixCtrl = TextEditingController();

  final List<_BankCtrls> _bankCtrls = [_BankCtrls()];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SettingsService.load();
    setState(() {
      _settings = s;
      _namaCtrl.text = s.namaToko;
      _alamatCtrl.text = s.alamat;
      _teleponCtrl.text = s.telepon;
      _emailCtrl.text = s.email;
      _websiteCtrl.text = s.website;
      _npwpCtrl.text = s.npwp;
      _footerCtrl.text = s.footerStruk;
      _taxRateCtrl.text = s.taxRate.toString();
      _invPrefixCtrl.text = s.invoicePrefix;
      _strPrefixCtrl.text = s.strukPrefix;
      for (final c in _bankCtrls) {
        c.dispose();
      }
      _bankCtrls.clear();
      final banks = s.bankAccounts.isNotEmpty ? s.bankAccounts : [BankAccount()];
      for (final b in banks) {
        _bankCtrls.add(_BankCtrls.from(b));
      }
      _isLoading = false;
    });
  }

  Future<void> _pickLogo() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() => _settings.logoBytes = bytes);
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Pilih Sumber Gambar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri Foto'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            if (_settings.hasLogo)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Hapus Logo',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() => _settings.logoBytes = null);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openSignaturePad() async {
    final result = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const SignaturePadPage(),
      ),
    );
    if (result != null) {
      setState(() => _settings.signatureBytes = result);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    _settings
      ..namaToko = _namaCtrl.text
      ..alamat = _alamatCtrl.text
      ..telepon = _teleponCtrl.text
      ..email = _emailCtrl.text
      ..website = _websiteCtrl.text
      ..npwp = _npwpCtrl.text
      ..footerStruk = _footerCtrl.text
      ..taxRate = double.tryParse(_taxRateCtrl.text) ?? 11
      ..invoicePrefix = _invPrefixCtrl.text.isNotEmpty ? _invPrefixCtrl.text : 'INV'
      ..strukPrefix = _strPrefixCtrl.text.isNotEmpty ? _strPrefixCtrl.text : 'STR'
      ..bankAccounts = _bankCtrls
          .map((c) => BankAccount(
                namaBank: c.bankCtrl.text.trim(),
                nomorRekening: c.nomorCtrl.text.trim(),
                namaPemilik: c.pemilikCtrl.text.trim(),
              ))
          .toList();

    await SettingsService.save(_settings);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan berhasil disimpan'),
          backgroundColor: Color(0xFF065F46),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _alamatCtrl.dispose();
    _teleponCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _npwpCtrl.dispose();
    _footerCtrl.dispose();
    _taxRateCtrl.dispose();
    _invPrefixCtrl.dispose();
    _strPrefixCtrl.dispose();
    for (final c in _bankCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 600;
    final hPad = isTablet ? ((width - 680) / 2).clamp(24.0, 9999.0) : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
          children: [
            _buildLogoPicker(theme),
            const SizedBox(height: 24),
            _buildIdentitasSection(theme, isTablet: isTablet),
            const SizedBox(height: 24),
            _buildKontakSection(theme, isTablet: isTablet),
            const SizedBox(height: 24),
            _buildInvoiceSettingsSection(theme, isTablet: isTablet),
            const SizedBox(height: 24),
            _card(
              theme,
              title: 'Pengaturan Struk',
              icon: Icons.receipt,
              children: [
                _field(
                  controller: _footerCtrl,
                  label: 'Pesan Footer Struk',
                  hint: 'cth: Terima kasih atas kunjungan Anda!',
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSignatureSection(theme),
            const SizedBox(height: 24),
            _buildBankSection(theme, isTablet: isTablet),
            const SizedBox(height: 24),
            _buildAppearanceSection(theme),
            const SizedBox(height: 24),
            _buildBackupSection(theme),
            const SizedBox(height: 32),
            if (isTablet)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: _saveButton(theme),
                ),
              )
            else
              _saveButton(theme),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _saveButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _save,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Pengaturan'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLogoPicker(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickLogo,
            child: Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant, width: 0.8),
                    image: _settings.hasLogo
                        ? DecorationImage(
                            image: MemoryImage(_settings.logoBytes!),
                            fit: BoxFit.contain,
                          )
                        : null,
                  ),
                  child: _settings.hasLogo
                      ? null
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 36,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 4),
                            Text(
                              'Tambah Logo',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.edit, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap untuk ganti logo',
            style: TextStyle(
                fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitasSection(ThemeData theme, {bool isTablet = false}) {
    return _card(
      theme,
      title: 'Identitas Toko / Perusahaan',
      icon: Icons.storefront,
      children: [
        _field(
          controller: _namaCtrl,
          label: 'Nama Toko / Perusahaan',
          required: true,
        ),
        const SizedBox(height: 14),
        if (isTablet)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field(
                  controller: _npwpCtrl,
                  label: 'NPWP',
                  hint: 'cth: 00.000.000.0-000.000',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  controller: _alamatCtrl,
                  label: 'Alamat Lengkap',
                  maxLines: 3,
                ),
              ),
            ],
          )
        else ...[
          _field(
            controller: _npwpCtrl,
            label: 'NPWP',
            hint: 'cth: 00.000.000.0-000.000',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          _field(
            controller: _alamatCtrl,
            label: 'Alamat Lengkap',
            maxLines: 3,
          ),
        ],
      ],
    );
  }

  Widget _buildKontakSection(ThemeData theme, {bool isTablet = false}) {
    return _card(
      theme,
      title: 'Kontak',
      icon: Icons.contact_phone,
      children: [
        _field(
          controller: _teleponCtrl,
          label: 'No. Telepon / WhatsApp',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),
        if (isTablet)
          Row(
            children: [
              Expanded(
                child: _field(
                  controller: _emailCtrl,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  controller: _websiteCtrl,
                  label: 'Website',
                  hint: 'cth: www.tokosaya.com',
                  keyboardType: TextInputType.url,
                ),
              ),
            ],
          )
        else ...[
          _field(
            controller: _emailCtrl,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _field(
            controller: _websiteCtrl,
            label: 'Website',
            hint: 'cth: www.tokosaya.com',
            keyboardType: TextInputType.url,
          ),
        ],
      ],
    );
  }

  Widget _buildSignatureSection(ThemeData theme) {
    return _card(
      theme,
      title: 'Tanda Tangan',
      icon: Icons.draw_rounded,
      trailing: _settings.hasSignature
          ? GestureDetector(
              onTap: () => setState(() => _settings.signatureBytes = null),
              child: Text('Hapus',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500)),
            )
          : null,
      children: [
        GestureDetector(
          onTap: _openSignaturePad,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: theme.colorScheme.outlineVariant, width: 0.8),
            ),
            child: _settings.hasSignature
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.memory(
                      _settings.signatureBytes!,
                      fit: BoxFit.contain,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.draw_outlined,
                          size: 32,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 6),
                      Text(
                        'Tap untuk membuat tanda tangan',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tanda tangan akan ditampilkan pada invoice',
          style: TextStyle(
              fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildBankSection(ThemeData theme, {bool isTablet = false}) {
    return _card(
      theme,
      title: 'Informasi Pembayaran',
      icon: Icons.account_balance,
      trailing: _bankCtrls.length < 3
          ? GestureDetector(
              onTap: () => setState(() => _bankCtrls.add(_BankCtrls())),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 2),
                  Text('Tambah',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : null,
      children: [
        ..._bankCtrls.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: theme.colorScheme.outlineVariant, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Rekening ${i + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    if (_bankCtrls.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () => setState(() {
                          c.dispose();
                          _bankCtrls.removeAt(i);
                        }),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _field(
                  controller: c.bankCtrl,
                  label: 'Nama Bank',
                  hint: 'cth: BCA, Mandiri, BNI',
                ),
                const SizedBox(height: 8),
                if (isTablet)
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: c.nomorCtrl,
                          label: 'Nomor Rekening',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _field(
                          controller: c.pemilikCtrl,
                          label: 'Nama Pemilik Rekening',
                        ),
                      ),
                    ],
                  )
                else ...[
                  _field(
                    controller: c.nomorCtrl,
                    label: 'Nomor Rekening',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  _field(
                    controller: c.pemilikCtrl,
                    label: 'Nama Pemilik Rekening',
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInvoiceSettingsSection(ThemeData theme,
      {bool isTablet = false}) {
    return _card(
      theme,
      title: 'Pajak & Dokumen',
      icon: Icons.tune,
      children: [
        Row(
          children: [
            Expanded(
              child: _field(
                controller: _taxRateCtrl,
                label: 'Tarif Pajak (%)',
                hint: '11',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _settings.currency,
                decoration: const InputDecoration(
                  labelText: 'Mata Uang',
                ),
                items: const [
                  DropdownMenuItem(value: 'IDR', child: Text('IDR (Rp)')),
                  DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR (\u20AC)')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _settings.currency = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(
                controller: _invPrefixCtrl,
                label: 'Prefix Invoice',
                hint: 'INV',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                controller: _strPrefixCtrl,
                label: 'Prefix Struk',
                hint: 'STR',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(ThemeData theme) {
    return _card(
      theme,
      title: 'Tampilan',
      icon: Icons.palette_outlined,
      children: [
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.themeNotifier,
          builder: (context, mode, _) {
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark Mode'),
              subtitle: Text(
                mode == ThemeMode.dark
                    ? 'Mode gelap aktif'
                    : 'Mode terang aktif',
                style: const TextStyle(fontSize: 12),
              ),
              secondary: Icon(
                mode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: theme.colorScheme.primary,
              ),
              value: mode == ThemeMode.dark,
              onChanged: (_) => ThemeService.toggle(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBackupSection(ThemeData theme) {
    return _card(
      theme,
      title: 'Backup & Restore',
      icon: Icons.backup_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exportBackup,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Export Backup'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _importBackup,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Import Backup'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Export semua data (settings, kontak, history) ke file JSON',
          style: TextStyle(
              fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Future<void> _exportBackup() async {
    try {
      await BackupService.export();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export: $e')),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Backup?'),
        content: const Text(
            'Data saat ini akan ditimpa dengan data dari backup. Lanjutkan?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Import', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final success = await BackupService.import();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup berhasil di-import! Restart aplikasi.'),
              backgroundColor: Color(0xFF065F46),
            ),
          );
          await _load();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File backup tidak valid')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal import: $e')),
        );
      }
    }
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

class _BankCtrls {
  final bankCtrl = TextEditingController();
  final nomorCtrl = TextEditingController();
  final pemilikCtrl = TextEditingController();

  _BankCtrls();

  factory _BankCtrls.from(BankAccount b) {
    final c = _BankCtrls();
    c.bankCtrl.text = b.namaBank;
    c.nomorCtrl.text = b.nomorRekening;
    c.pemilikCtrl.text = b.namaPemilik;
    return c;
  }

  void dispose() {
    bankCtrl.dispose();
    nomorCtrl.dispose();
    pemilikCtrl.dispose();
  }
}
