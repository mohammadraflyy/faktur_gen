import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';
import '../widgets/app_logo.dart';

/// Key to track if onboarding has been completed.
const _kOnboardingDone = 's_onboarding_done';

/// Check whether onboarding should be shown.
Future<bool> shouldShowOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_kOnboardingDone) ?? false);
}

/// Mark onboarding as completed.
Future<void> _markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDone, true);
}

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  // Step 1: Profil
  final _namaCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _teleponCtrl = TextEditingController();

  // Step 2: Logo
  final _settings = SettingsModel();

  bool _isSaving = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _namaCtrl.dispose();
    _alamatCtrl.dispose();
    _teleponCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage == 0 && _namaCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama toko wajib diisi')),
      );
      return;
    }
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _back() {
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);
    _settings
      ..namaToko = _namaCtrl.text.trim()
      ..alamat = _alamatCtrl.text.trim()
      ..telepon = _teleponCtrl.text.trim();
    await SettingsService.save(_settings);
    await _markOnboardingDone();
    setState(() => _isSaving = false);
    widget.onComplete();
  }

  Future<void> _skip() async {
    await _markOnboardingDone();
    widget.onComplete();
  }

  Future<void> _pickLogo() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _settings.logoBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Lewati',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            ),
            // Page indicator
            _buildIndicator(theme),
            const SizedBox(height: 8),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildStepProfile(theme),
                  _buildStepLogo(theme),
                  _buildStepDone(theme),
                ],
              ),
            ),
            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : _currentPage == 2
                          ? _finish
                          : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _currentPage == 2 ? 'Mulai Sekarang' : 'Lanjut',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          if (_currentPage > 0)
            GestureDetector(
              onTap: _back,
              child: Icon(Icons.arrow_back_rounded,
                  size: 22,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            )
          else
            const SizedBox(width: 22),
          const Spacer(),
          ...List.generate(3, (i) {
            final isActive = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
          const Spacer(),
          const SizedBox(width: 22),
        ],
      ),
    );
  }

  // ─── Step 1: Profil Toko ───────────────────────────────────────────────────

  Widget _buildStepProfile(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        const SizedBox(height: 16),
        Center(child: AppLogo(size: 64)),
        const SizedBox(height: 24),
        Text(
          'Atur Profil Toko',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Informasi ini akan muncul di invoice dan struk',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _namaCtrl,
          decoration: const InputDecoration(
            labelText: 'Nama Toko / Perusahaan *',
            prefixIcon: Icon(Icons.storefront_outlined, size: 20),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _alamatCtrl,
          decoration: const InputDecoration(
            labelText: 'Alamat (opsional)',
            prefixIcon: Icon(Icons.location_on_outlined, size: 20),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _teleponCtrl,
          decoration: const InputDecoration(
            labelText: 'No. Telepon (opsional)',
            prefixIcon: Icon(Icons.phone_outlined, size: 20),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  // ─── Step 2: Logo ──────────────────────────────────────────────────────────

  Widget _buildStepLogo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          const Spacer(flex: 1),
          Text(
            'Tambahkan Logo',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Logo akan tampil di header dokumen\nBisa ditambahkan nanti di Pengaturan',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _pickLogo,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _settings.hasLogo
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : theme.colorScheme.outlineVariant,
                  width: _settings.hasLogo ? 2 : 1,
                ),
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
                        const SizedBox(height: 6),
                        Text(
                          'Pilih Logo',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (_settings.hasLogo)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextButton.icon(
                onPressed: () => setState(() => _settings.logoBytes = null),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Hapus'),
              ),
            ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  // ─── Step 3: Selesai ───────────────────────────────────────────────────────

  Widget _buildStepDone(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded,
                size: 40, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Siap Digunakan!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kamu bisa langsung buat invoice atau struk.\nSemua pengaturan bisa diubah nanti.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Preview card
          Container(
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
                            fit: BoxFit.contain,
                          )
                        : null,
                  ),
                  child: _settings.hasLogo
                      ? null
                      : Icon(Icons.storefront_outlined,
                          color: theme.colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _namaCtrl.text.isNotEmpty
                            ? _namaCtrl.text
                            : 'Toko Anda',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (_alamatCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _alamatCtrl.text,
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
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
