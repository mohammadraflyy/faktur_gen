import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../models/doc_template_config.dart';
import '../models/settings_model.dart';
import '../models/subscription_model.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../services/reminder_service.dart';
import '../services/locale_service.dart';
import '../services/settings_service.dart';
import '../services/subscription_service.dart';
import '../services/theme_service.dart';
import '../widgets/paywall_sheet.dart';
import '../widgets/signature_pad.dart';
import 'recurring_invoice_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Settings Hub — menu list that navigates to sub-pages
// ═══════════════════════════════════════════════════════════════════════════════

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsModel _settings = SettingsModel();
  SubscriptionModel _sub = SubscriptionModel();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SettingsService.load();
    final sub = await SubscriptionService.load();
    if (mounted) setState(() { _settings = s; _sub = sub; _isLoading = false; });
  }

  Future<void> _push(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _load(); // refresh after returning
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('settings.title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr('settings.title'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Subscription
          _buildSubscriptionCard(theme),
          const SizedBox(height: 16),
          // Profile header
          _buildProfileHeader(theme),
          const SizedBox(height: 16),
          _sectionLabel(theme, tr('settings.general')),
          _menuTile(
            theme,
            icon: Icons.storefront_outlined,
            title: tr('settings.store_profile'),
            subtitle: _settings.namaToko.isNotEmpty
                ? _settings.namaToko
                : tr('settings.not_set'),
            onTap: () => _push(_ProfileSubPage(settings: _settings)),
          ),
          _menuTile(
            theme,
            icon: Icons.contact_phone_outlined,
            title: tr('settings.contact'),
            subtitle: _settings.telepon.isNotEmpty
                ? _settings.telepon
                : tr('settings.not_set'),
            onTap: () => _push(_ContactSubPage(settings: _settings)),
          ),
          _menuTile(
            theme,
            icon: Icons.account_balance_outlined,
            title: tr('settings.payment_info'),
            subtitle: _settings.bankAccounts.isNotEmpty &&
                    _settings.bankAccounts.first.namaBank.isNotEmpty
                ? '${_settings.bankAccounts.length} ${tr('settings.accounts')}'
                : tr('settings.not_set'),
            onTap: () => _push(_BankSubPage(settings: _settings)),
          ),
          const SizedBox(height: 8),
          _sectionLabel(theme, tr('settings.documents')),
          _menuTile(
            theme,
            icon: Icons.style_outlined,
            title: tr('template.title'),
            subtitle:
                '${_settings.templateConfig.invoiceTemplate.label} · ${_settings.templateConfig.strukTemplate.label}',
            onTap: () => _push(_TemplateSubPage(settings: _settings)),
          ),
          _menuTile(
            theme,
            icon: Icons.tune_outlined,
            title: tr('settings.tax_doc'),
            subtitle:
                'PPN ${_settings.taxRate}% · ${_settings.currency}',
            onTap: () => _push(_InvoiceSettingsSubPage(settings: _settings)),
          ),
          _menuTile(
            theme,
            icon: Icons.receipt_outlined,
            title: tr('settings.receipt_settings'),
            subtitle: _settings.footerStruk.isNotEmpty
                ? _settings.footerStruk
                : 'Default',
            onTap: () => _push(_StrukSubPage(settings: _settings)),
          ),
          _menuTile(
            theme,
            icon: Icons.draw_outlined,
            title: tr('settings.signature'),
            subtitle: _settings.hasSignature ? tr('settings.already_set') : tr('settings.not_set'),
            onTap: () => _push(_SignatureSubPage(settings: _settings)),
          ),
          _menuTile(
            theme,
            icon: Icons.qr_code_2_rounded,
            title: tr('settings.qris'),
            subtitle: _settings.qrisMerchantId.isNotEmpty
                ? tr('settings.already_set')
                : tr('settings.not_set'),
            onTap: () {
              if (!_sub.isPro) { showPaywallSheet(context); return; }
              _push(_QrisSubPage(settings: _settings));
            },
            trailing: _sub.isPro ? null : _proBadge(theme),
          ),
          _menuTile(
            theme,
            icon: Icons.repeat_rounded,
            title: tr('recurring.title'),
            subtitle: tr('recurring.subtitle'),
            onTap: () {
              if (!_sub.isPro) { showPaywallSheet(context); return; }
              _push(const RecurringInvoicePage());
            },
            trailing: _sub.isPro ? null : _proBadge(theme),
          ),
          const SizedBox(height: 8),
          _sectionLabel(theme, tr('auth.account')),
          _buildAccountTile(theme),
          const SizedBox(height: 8),
          _sectionLabel(theme, tr('settings.app')),
          _buildThemeTile(theme),
          _buildLanguageTile(theme),
          _menuTile(
            theme,
            icon: Icons.backup_outlined,
            title: tr('settings.backup'),
            subtitle: tr('settings.backup_subtitle'),
            onTap: () => _push(_BackupSubPage()),
          ),
          _menuTile(
            theme,
            icon: Icons.science_outlined,
            title: tr('sandbox.title'),
            subtitle: tr('sandbox.subtitle'),
            onTap: () => _push(const _SandboxSubPage()),
          ),
          _menuTile(
            theme,
            icon: Icons.info_outline,
            title: tr('about.title'),
            subtitle: tr('about.subtitle'),
            onTap: () => _push(const _AboutSubPage()),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _settings.hasLogo
                  ? null
                  : theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
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
                    color: theme.colorScheme.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _settings.namaToko.isNotEmpty
                      ? _settings.namaToko
                      : 'Faktura',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (_settings.alamat.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _settings.alamat,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
    );
  }

  Widget _proBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA000).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('PRO',
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
          color: const Color(0xFFFFA000))),
    );
  }

  Widget _buildSubscriptionCard(ThemeData theme) {
    final isPro = _sub.isPro;
    final remaining = SubscriptionService.freeMonthlyLimit - _sub.monthlyDocCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: InkWell(
          onTap: isPro ? null : () => showPaywallSheet(context).then((_) => _load()),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: isPro
                        ? const Color(0xFFFFA000).withValues(alpha: 0.15)
                        : theme.colorScheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPro ? Icons.workspace_premium_rounded : Icons.star_outline_rounded,
                    color: isPro ? const Color(0xFFFFA000) : theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPro ? tr('sub.pro') : tr('sub.free'),
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPro
                            ? tr('sub.unlimited')
                            : '$remaining ${tr('sub.docs_remaining')}',
                        style: GoogleFonts.inter(fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                if (!isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA000),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(tr('sub.upgrade'),
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                        color: Colors.white)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTile(ThemeData theme) {
    final user = AuthService.currentUser;
    if (user != null) {
      return _menuTile(
        theme,
        icon: Icons.account_circle_outlined,
        title: user.displayName ?? user.email ?? tr('auth.account'),
        subtitle: user.email ?? '',
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(tr('auth.sign_out_confirm')),
              content: Text(tr('auth.sign_out_warn')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(tr('common.cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(tr('auth.sign_out')),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await AuthService.signOut();
            if (mounted) setState(() {});
          }
        },
      );
    }
    return _menuTile(
      theme,
      icon: Icons.login_rounded,
      title: tr('auth.sign_in'),
      subtitle: tr('auth.not_signed_in'),
      onTap: () async {
        try {
          await AuthService.signInWithGoogle();
          if (mounted) setState(() {});
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${tr('auth.sign_in_failed')}: $e')),
            );
          }
        }
      },
    );
  }

  Widget _buildLanguageTile(ThemeData theme) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LocaleService.languageNotifier,
      builder: (context, lang, _) {
        return _menuTile(
          theme,
          icon: Icons.language_rounded,
          title: tr('settings.language'),
          subtitle: lang.label,
          onTap: () => _showLanguagePicker(theme),
        );
      },
    );
  }

  void _showLanguagePicker(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: ValueListenableBuilder<AppLanguage>(
          valueListenable: LocaleService.languageNotifier,
          builder: (context, current, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        tr('settings.language'),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...AppLanguage.values.map((lang) {
                    final isSelected = lang == current;
                    return ListTile(
                      leading: Text(
                        lang == AppLanguage.id ? '🇮🇩' : '🇬🇧',
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(
                        lang.label,
                        style: GoogleFonts.inter(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_rounded,
                              color: theme.colorScheme.primary, size: 20)
                          : null,
                      onTap: () {
                        LocaleService.setLanguage(lang);
                        Navigator.pop(context);
                        // Rebuild settings page
                        setState(() {});
                      },
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildThemeTile(ThemeData theme) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, mode, _) {
        String subtitle;
        IconData icon;
        switch (mode) {
          case ThemeMode.dark:
            subtitle = tr('appearance.dark');
            icon = Icons.dark_mode_outlined;
          case ThemeMode.light:
            subtitle = tr('appearance.light');
            icon = Icons.light_mode_outlined;
          case ThemeMode.system:
            subtitle = tr('appearance.system');
            icon = Icons.contrast_outlined;
        }
        return _menuTile(
          theme,
          icon: icon,
          title: tr('appearance.title'),
          subtitle: subtitle,
          onTap: () => _showThemePicker(theme),
        );
      },
    );
  }

  void _showThemePicker(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.themeNotifier,
          builder: (context, current, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        tr('appearance.title'),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _themeOption(
                    context,
                    icon: Icons.light_mode_outlined,
                    label: tr('appearance.light'),
                    mode: ThemeMode.light,
                    current: current,
                  ),
                  _themeOption(
                    context,
                    icon: Icons.dark_mode_outlined,
                    label: tr('appearance.dark'),
                    mode: ThemeMode.dark,
                    current: current,
                  ),
                  _themeOption(
                    context,
                    icon: Icons.contrast_outlined,
                    label: tr('appearance.system'),
                    mode: ThemeMode.system,
                    current: current,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _themeOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required ThemeMode mode,
    required ThemeMode current,
  }) {
    final theme = Theme.of(context);
    final isSelected = mode == current;
    return ListTile(
      leading: Icon(icon,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: theme.colorScheme.primary, size: 20)
          : null,
      onTap: () {
        ThemeService.setMode(mode);
        Navigator.pop(context);
      },
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _menuTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.25)),
      onTap: onTap,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared helpers for sub-pages
// ═══════════════════════════════════════════════════════════════════════════════

mixin _SettingsSubPageMixin<T extends StatefulWidget> on State<T> {
  bool isSaving = false;

  Future<void> saveSettings(SettingsModel settings) async {
    setState(() => isSaving = true);
    await SettingsService.save(settings);
    setState(() => isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('settings.saved')),
          backgroundColor: AppColors.successFor(Theme.of(context).brightness),
          duration: const Duration(seconds: 1),
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget buildField({
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

  Widget buildSaveButton(ThemeData theme, VoidCallback onSave) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isSaving ? null : onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        child: isSaving
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Text(tr('common.save')),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-page: Profil Toko
// ═══════════════════════════════════════════════════════════════════════════════

class _ProfileSubPage extends StatefulWidget {
  final SettingsModel settings;
  const _ProfileSubPage({required this.settings});

  @override
  State<_ProfileSubPage> createState() => _ProfileSubPageState();
}

class _ProfileSubPageState extends State<_ProfileSubPage>
    with _SettingsSubPageMixin {
  final _formKey = GlobalKey<FormState>();
  late final SettingsModel _s;
  late final TextEditingController _namaCtrl;
  late final TextEditingController _alamatCtrl;
  late final TextEditingController _npwpCtrl;

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
    _namaCtrl = TextEditingController(text: _s.namaToko);
    _alamatCtrl = TextEditingController(text: _s.alamat);
    _npwpCtrl = TextEditingController(text: _s.npwp);
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _alamatCtrl.dispose();
    _npwpCtrl.dispose();
    super.dispose();
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
              title: Text(tr('settings.gallery')),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(tr('settings.camera')),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            if (_s.hasLogo)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(tr('settings.delete_logo'),
                    style: const TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() => _s.logoBytes = null);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _s.logoBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('settings.store_profile'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Logo
            Center(
              child: GestureDetector(
                onTap: _pickLogo,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: theme.colorScheme.outlineVariant, width: 0.8),
                        image: _s.hasLogo
                            ? DecorationImage(
                                image: MemoryImage(_s.logoBytes!),
                                fit: BoxFit.contain)
                            : null,
                      ),
                      child: _s.hasLogo
                          ? null
                          : Icon(Icons.add_photo_alternate_outlined,
                              size: 32,
                              color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            buildField(controller: _namaCtrl, label: tr('settings.store_name'), required: true),
            const SizedBox(height: 14),
            buildField(controller: _npwpCtrl, label: 'NPWP', hint: 'cth: 00.000.000.0-000.000', keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            buildField(controller: _alamatCtrl, label: tr('settings.address'), maxLines: 3),
            const SizedBox(height: 32),
            buildSaveButton(theme, () {
              if (!_formKey.currentState!.validate()) return;
              _s
                ..namaToko = _namaCtrl.text
                ..alamat = _alamatCtrl.text
                ..npwp = _npwpCtrl.text;
              saveSettings(_s);
            }),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-page: Kontak
// ═══════════════════════════════════════════════════════════════════════════════

class _ContactSubPage extends StatefulWidget {
  final SettingsModel settings;
  const _ContactSubPage({required this.settings});

  @override
  State<_ContactSubPage> createState() => _ContactSubPageState();
}

class _ContactSubPageState extends State<_ContactSubPage>
    with _SettingsSubPageMixin {
  late final SettingsModel _s;
  late final TextEditingController _teleponCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _websiteCtrl;

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
    _teleponCtrl = TextEditingController(text: _s.telepon);
    _emailCtrl = TextEditingController(text: _s.email);
    _websiteCtrl = TextEditingController(text: _s.website);
  }

  @override
  void dispose() {
    _teleponCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('settings.contact'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          buildField(controller: _teleponCtrl, label: tr('settings.phone'), keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          buildField(controller: _emailCtrl, label: 'Email', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          buildField(controller: _websiteCtrl, label: 'Website', hint: 'cth: www.tokosaya.com', keyboardType: TextInputType.url),
          const SizedBox(height: 32),
          buildSaveButton(theme, () {
            _s
              ..telepon = _teleponCtrl.text
              ..email = _emailCtrl.text
              ..website = _websiteCtrl.text;
            saveSettings(_s);
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-page: Pajak & Dokumen
// ═══════════════════════════════════════════════════════════════════════════════

class _InvoiceSettingsSubPage extends StatefulWidget {
  final SettingsModel settings;
  const _InvoiceSettingsSubPage({required this.settings});

  @override
  State<_InvoiceSettingsSubPage> createState() =>
      _InvoiceSettingsSubPageState();
}

class _InvoiceSettingsSubPageState extends State<_InvoiceSettingsSubPage>
    with _SettingsSubPageMixin {
  late final SettingsModel _s;
  late final TextEditingController _taxRateCtrl;
  late final TextEditingController _invPrefixCtrl;
  late final TextEditingController _strPrefixCtrl;

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
    _taxRateCtrl = TextEditingController(text: _s.taxRate.toString());
    _invPrefixCtrl = TextEditingController(text: _s.invoicePrefix);
    _strPrefixCtrl = TextEditingController(text: _s.strukPrefix);
  }

  @override
  void dispose() {
    _taxRateCtrl.dispose();
    _invPrefixCtrl.dispose();
    _strPrefixCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('settings.tax_doc'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: buildField(
                  controller: _taxRateCtrl,
                  label: 'Tarif Pajak (%)',
                  hint: '11',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _s.currency,
                  decoration: const InputDecoration(labelText: 'Mata Uang'),
                  items: const [
                    DropdownMenuItem(value: 'IDR', child: Text('IDR (Rp)')),
                    DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR (\u20AC)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _s.currency = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: buildField(controller: _invPrefixCtrl, label: 'Prefix Invoice', hint: 'INV')),
              const SizedBox(width: 12),
              Expanded(child: buildField(controller: _strPrefixCtrl, label: 'Prefix Struk', hint: 'STR')),
            ],
          ),
          const SizedBox(height: 32),
          buildSaveButton(theme, () {
            _s
              ..taxRate = double.tryParse(_taxRateCtrl.text) ?? 11
              ..invoicePrefix = _invPrefixCtrl.text.isNotEmpty ? _invPrefixCtrl.text : 'INV'
              ..strukPrefix = _strPrefixCtrl.text.isNotEmpty ? _strPrefixCtrl.text : 'STR';
            saveSettings(_s);
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-page: Pengaturan Struk
// ═══════════════════════════════════════════════════════════════════════════════

class _StrukSubPage extends StatefulWidget {
  final SettingsModel settings;
  const _StrukSubPage({required this.settings});

  @override
  State<_StrukSubPage> createState() => _StrukSubPageState();
}

class _StrukSubPageState extends State<_StrukSubPage>
    with _SettingsSubPageMixin {
  late final SettingsModel _s;
  late final TextEditingController _footerCtrl;

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
    _footerCtrl = TextEditingController(text: _s.footerStruk);
  }

  @override
  void dispose() {
    _footerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('settings.receipt_settings'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          buildField(
            controller: _footerCtrl,
            label: 'Pesan Footer Struk',
            hint: 'cth: Terima kasih atas kunjungan Anda!',
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          buildSaveButton(theme, () {
            _s.footerStruk = _footerCtrl.text;
            saveSettings(_s);
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-page: Template Dokumen
// ═══════════════════════════════════════════════════════════════════════════════

class _TemplateSubPage extends StatefulWidget {
  final SettingsModel settings;
  const _TemplateSubPage({required this.settings});

  @override
  State<_TemplateSubPage> createState() => _TemplateSubPageState();
}

class _TemplateSubPageState extends State<_TemplateSubPage>
    with _SettingsSubPageMixin {
  late final SettingsModel _s;
  late DocTemplateConfig _config;

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
    _config = _s.templateConfig;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('template.title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Invoice template
          Text(
            tr('template.invoice_design'),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ...InvoiceTemplate.values.map((t) => _templateOption(
                theme,
                label: t.label,
                description: t.description,
                isSelected: _config.invoiceTemplate == t,
                onTap: () => setState(() => _config.invoiceTemplate = t),
              )),

          const SizedBox(height: 24),

          // Struk template
          Text(
            tr('template.receipt_design'),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ...StrukTemplate.values.map((t) => _templateOption(
                theme,
                label: t.label,
                description: t.description,
                isSelected: _config.strukTemplate == t,
                onTap: () => setState(() => _config.strukTemplate = t),
              )),

          const SizedBox(height: 24),

          // Customization toggles
          Text(
            tr('template.customize'),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          _toggleTile(theme,
              icon: Icons.image_outlined,
              title: tr('template.show_logo'),
              value: _config.showLogo,
              onChanged: (v) => setState(() => _config.showLogo = v)),
          if (_config.showLogo)
            _toggleTile(theme,
                icon: Icons.format_align_center,
                title: tr('template.logo_center'),
                subtitle: tr('template.logo_center_off'),
                value: _config.logoCenter,
                onChanged: (v) => setState(() => _config.logoCenter = v)),
          _toggleTile(theme,
              icon: Icons.draw_outlined,
              title: tr('template.show_signature'),
              value: _config.showSignature,
              onChanged: (v) => setState(() => _config.showSignature = v)),
          _toggleTile(theme,
              icon: Icons.account_balance_outlined,
              title: tr('template.show_bank'),
              value: _config.showBankInfo,
              onChanged: (v) => setState(() => _config.showBankInfo = v)),
          _toggleTile(theme,
              icon: Icons.badge_outlined,
              title: tr('template.show_npwp'),
              value: _config.showNpwp,
              onChanged: (v) => setState(() => _config.showNpwp = v)),

          const SizedBox(height: 24),

          // Color picker
          Text(
            tr('template.primary_color'),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              0xFF2563EB, // Blue
              0xFF059669, // Green
              0xFF7C3AED, // Purple
              0xFFDC2626, // Red
              0xFFD97706, // Amber
              0xFF0891B2, // Cyan
              0xFF4F46E5, // Indigo
              0xFF374151, // Gray
            ].map((c) => _colorDot(theme, c)).toList(),
          ),

          const SizedBox(height: 32),
          buildSaveButton(theme, () {
            _s.templateConfig = _config;
            saveSettings(_s);
          }),
        ],
      ),
    );
  }

  Widget _templateOption(
    ThemeData theme, {
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(_config.primaryColorValue).withValues(alpha: 0.06)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Color(_config.primaryColorValue).withValues(alpha: 0.4)
                : theme.dividerTheme.color ?? Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Color(_config.primaryColorValue)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Color(_config.primaryColorValue)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      secondary: Icon(icon,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
      title: Text(title,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4)))
          : null,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _colorDot(ThemeData theme, int colorValue) {
    final isSelected = _config.primaryColorValue == colorValue;
    return GestureDetector(
      onTap: () => setState(() => _config.primaryColorValue = colorValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Color(colorValue),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.onSurface
                : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(colorValue).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-page: Tanda Tangan
// ═══════════════════════════════════════════════════════════════════════════════

class _SignatureSubPage extends StatefulWidget {
  final SettingsModel settings;
  const _SignatureSubPage({required this.settings});

  @override
  State<_SignatureSubPage> createState() => _SignatureSubPageState();
}

class _SignatureSubPageState extends State<_SignatureSubPage>
    with _SettingsSubPageMixin {
  late final SettingsModel _s;

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
  }

  Future<void> _openPad() async {
    final result = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => const SignaturePadPage()),
    );
    if (result != null) setState(() => _s.signatureBytes = result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('settings.signature')),
        actions: [
          if (_s.hasSignature)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => setState(() => _s.signatureBytes = null),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: _openPad,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: theme.colorScheme.outlineVariant, width: 0.8),
              ),
              child: _s.hasSignature
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.memory(_s.signatureBytes!, fit: BoxFit.contain),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.draw_outlined, size: 40,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text(tr('settings.sign_tap'),
                            style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr('settings.sign_note'),
            style: TextStyle(
                fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          buildSaveButton(theme, () => saveSettings(_s)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-page: Informasi Pembayaran (Bank)
// ═══════════════════════════════════════════════════════════════════════════════

class _BankSubPage extends StatefulWidget {
  final SettingsModel settings;
  const _BankSubPage({required this.settings});

  @override
  State<_BankSubPage> createState() => _BankSubPageState();
}

class _BankSubPageState extends State<_BankSubPage>
    with _SettingsSubPageMixin {
  late final SettingsModel _s;
  final List<_BankCtrls> _bankCtrls = [];

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
    final banks = _s.bankAccounts.isNotEmpty ? _s.bankAccounts : [BankAccount()];
    for (final b in banks) {
      _bankCtrls.add(_BankCtrls.from(b));
    }
  }

  @override
  void dispose() {
    for (final c in _bankCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('settings.payment_info')),
        actions: [
          if (_bankCtrls.length < 3)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => setState(() => _bankCtrls.add(_BankCtrls())),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ..._bankCtrls.asMap().entries.map((e) {
            final i = e.key;
            final c = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.colorScheme.outlineVariant, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${tr('settings.account_n')} ${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const Spacer(),
                      if (_bankCtrls.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => setState(() {
                            c.dispose();
                            _bankCtrls.removeAt(i);
                          }),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  buildField(controller: c.bankCtrl, label: tr('settings.bank_name'), hint: 'cth: BCA, Mandiri'),
                  const SizedBox(height: 10),
                  buildField(controller: c.nomorCtrl, label: tr('settings.account_number'), keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  buildField(controller: c.pemilikCtrl, label: tr('settings.account_holder')),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          buildSaveButton(theme, () {
            _s.bankAccounts = _bankCtrls
                .map((c) => BankAccount(
                      namaBank: c.bankCtrl.text.trim(),
                      nomorRekening: c.nomorCtrl.text.trim(),
                      namaPemilik: c.pemilikCtrl.text.trim(),
                    ))
                .toList();
            saveSettings(_s);
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-page: Backup & Restore
// ═══════════════════════════════════════════════════════════════════════════════

class _BackupSubPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('settings.backup'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _BackupTile(
            theme: theme,
            icon: Icons.upload_file_rounded,
            title: tr('settings.export_backup'),
            subtitle: tr('settings.export_backup_desc'),
            onTap: () async {
              try {
                await BackupService.export();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${tr('settings.export_failed')}: $e')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 12),
          _BackupTile(
            theme: theme,
            icon: Icons.download_rounded,
            title: tr('settings.import_backup'),
            subtitle: tr('settings.import_backup_desc'),
            onTap: () => _confirmImport(context),
          ),
          const SizedBox(height: 16),
          Text(
            tr('settings.backup_note'),
            style: TextStyle(
                fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmImport(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('settings.import_confirm')),
        content: Text(tr('settings.import_confirm_desc')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('common.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('settings.import'), style: const TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final success = await BackupService.import();
      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('settings.import_success')),
            backgroundColor: AppColors.successFor(Theme.of(context).brightness),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('settings.invalid_backup'))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('settings.import_failed')}: $e')),
        );
      }
    }
  }
}

class _BackupTile extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BackupTile({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-page: Sandbox (Testing & Debug)
// ═══════════════════════════════════════════════════════════════════════════════

class _SandboxSubPage extends StatefulWidget {
  const _SandboxSubPage();

  @override
  State<_SandboxSubPage> createState() => _SandboxSubPageState();
}

class _SandboxSubPageState extends State<_SandboxSubPage> {
  int _pendingNotifCount = 0;
  int _activeReminderCount = 0;
  String _lastBackup = '-';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final pending = await NotificationService.getPending();
    final reminders = await ReminderService.getUpcoming();
    final lastBackup = await BackupService.getLastAutoBackupTime();
    if (mounted) {
      setState(() {
        _pendingNotifCount = pending.length;
        _activeReminderCount = reminders.length;
        _lastBackup = lastBackup != null
            ? '${lastBackup.day}/${lastBackup.month}/${lastBackup.year}'
            : tr('sandbox.never');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('sandbox.title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info cards
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: theme.colorScheme.outlineVariant, width: 0.8),
            ),
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('sandbox.notif_status'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _infoRow(theme, tr('sandbox.active_reminders'),
                          '$_activeReminderCount'),
                      const SizedBox(height: 6),
                      _infoRow(theme, tr('sandbox.scheduled_notif'),
                          '$_pendingNotifCount'),
                      const SizedBox(height: 6),
                      _infoRow(theme, tr('sandbox.last_backup'),
                          _lastBackup),
                      const SizedBox(height: 4),
                      Text(
                        tr('sandbox.auto_backup_note'),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),

          // Test actions
          Text(
            tr('sandbox.test_actions'),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          _sandboxTile(
            theme,
            icon: Icons.notifications_active_outlined,
            title: tr('sandbox.test_notif'),
            subtitle: tr('sandbox.test_notif_desc'),
            onTap: () async {
              await NotificationService.showTestNotification();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr('sandbox.test_notif_sent')),
                  backgroundColor:
                      AppColors.successFor(theme.brightness),
                ),
              );
              _loadInfo();
            },
          ),
          const SizedBox(height: 10),
          _sandboxTile(
            theme,
            icon: Icons.refresh_rounded,
            title: tr('sandbox.reschedule_all'),
            subtitle: tr('sandbox.reschedule_all_desc'),
            onTap: () async {
              await ReminderService.rescheduleNotifications();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr('sandbox.reschedule_done')),
                  backgroundColor:
                      AppColors.successFor(theme.brightness),
                ),
              );
              _loadInfo();
            },
          ),
          const SizedBox(height: 10),
          _sandboxTile(
            theme,
            icon: Icons.cancel_outlined,
            title: tr('sandbox.cancel_all'),
            subtitle: tr('sandbox.cancel_all_desc'),
            color: Colors.red,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(tr('sandbox.cancel_all_confirm')),
                  content: Text(tr('sandbox.cancel_all_confirm_desc')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(tr('common.cancel')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(tr('sandbox.yes_delete'),
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm != true || !mounted) return;
              await NotificationService.cancelAll();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('sandbox.all_cancelled'))),
              );
              _loadInfo();
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _sandboxTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? theme.colorScheme.primary;
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
                  color: c.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: c, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-page: Tentang (About)
// ═══════════════════════════════════════════════════════════════════════════════

class _AboutSubPage extends StatelessWidget {
  const _AboutSubPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('about.title'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.receipt_long_rounded,
                  size: 40, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Faktura',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr('about.subtitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Versi 1.0.0',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 32),
          _infoTile(theme,
              icon: Icons.description_outlined,
              title: tr('about.features'),
              subtitle: tr('about.features_desc')),
          _infoTile(theme,
              icon: Icons.print_outlined,
              title: tr('about.print'),
              subtitle: tr('about.print_desc')),
          _infoTile(theme,
              icon: Icons.backup_outlined,
              title: tr('about.data'),
              subtitle: tr('about.data_desc')),
          _infoTile(theme,
              icon: Icons.palette_outlined,
              title: tr('about.theme'),
              subtitle: tr('about.theme_desc')),
          const SizedBox(height: 24),
          Text(
            tr('about.made_with'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(ThemeData theme,
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 18,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared bank controller helper
// ═══════════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════════
// QRIS Settings Sub-page
// ═══════════════════════════════════════════════════════════════════════════════

class _QrisSubPage extends StatefulWidget {
  final SettingsModel settings;
  const _QrisSubPage({required this.settings});

  @override
  State<_QrisSubPage> createState() => _QrisSubPageState();
}

class _QrisSubPageState extends State<_QrisSubPage> {
  late final TextEditingController _qrisCtrl;

  @override
  void initState() {
    super.initState();
    _qrisCtrl = TextEditingController(text: widget.settings.qrisMerchantId);
  }

  @override
  void dispose() {
    _qrisCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    widget.settings.qrisMerchantId = _qrisCtrl.text.trim();
    await SettingsService.save(widget.settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('settings.saved'))),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('settings.qris')),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(tr('settings.save')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            tr('settings.qris_desc'),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _qrisCtrl,
            decoration: InputDecoration(
              labelText: tr('settings.qris_id'),
              prefixIcon: const Icon(Icons.qr_code_2_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
