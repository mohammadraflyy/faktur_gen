import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/settings_model.dart';
import '../models/subscription_model.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/settings_service.dart';
import '../services/subscription_service.dart';
import '../services/theme_service.dart';
import '../services/updater_service.dart';
import '../widgets/paywall_sheet.dart';
import 'recurring_invoice_page.dart';
import 'settings/about_sub_page.dart';
import 'settings/backup_sub_page.dart';
import 'settings/bank_sub_page.dart';
import 'settings/contact_sub_page.dart';
import 'settings/invoice_settings_sub_page.dart';
import 'settings/profile_sub_page.dart';
import 'settings/qris_sub_page.dart';
import 'settings/sandbox_sub_page.dart';
import 'settings/signature_sub_page.dart';
import 'settings/struk_sub_page.dart';
import 'settings/template_sub_page.dart';

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
            onTap: () => _push(ProfileSubPage(settings: _settings)),
          ),
          _menuTile(
            theme,
            icon: Icons.contact_phone_outlined,
            title: tr('settings.contact'),
            subtitle: _settings.telepon.isNotEmpty
                ? _settings.telepon
                : tr('settings.not_set'),
            onTap: () => _push(ContactSubPage(settings: _settings)),
          ),
          _menuTile(
            theme,
            icon: Icons.account_balance_outlined,
            title: tr('settings.payment_info'),
            subtitle: _settings.bankAccounts.isNotEmpty &&
                    _settings.bankAccounts.first.namaBank.isNotEmpty
                ? '${_settings.bankAccounts.length} ${tr('settings.accounts')}'
                : tr('settings.not_set'),
            onTap: () => _push(BankSubPage(settings: _settings)),
          ),
          const SizedBox(height: 8),
          _sectionLabel(theme, tr('settings.documents')),
          _menuTile(
            theme,
            icon: Icons.style_outlined,
            title: tr('template.title'),
            subtitle:
                '${_settings.templateConfig.invoiceTemplate.label} · ${_settings.templateConfig.strukTemplate.label}',
            onTap: () => _push(TemplateSubPage(settings: _settings)),
          ),
          _menuTile(
            theme,
            icon: Icons.tune_outlined,
            title: tr('settings.tax_doc'),
            subtitle:
                'PPN ${_settings.taxRate}% · ${_settings.currency}',
            onTap: () => _push(InvoiceSettingsSubPage(settings: _settings)),
          ),
          _menuTile(
            theme,
            icon: Icons.receipt_outlined,
            title: tr('settings.receipt_settings'),
            subtitle: _settings.footerStruk.isNotEmpty
                ? _settings.footerStruk
                : 'Default',
            onTap: () => _push(StrukSubPage(settings: _settings)),
          ),
          _menuTile(
            theme,
            icon: Icons.draw_outlined,
            title: tr('settings.signature'),
            subtitle: _settings.hasSignature ? tr('settings.already_set') : tr('settings.not_set'),
            onTap: () => _push(SignatureSubPage(settings: _settings)),
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
              _push(QrisSubPage(settings: _settings));
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
            onTap: () => _push(BackupSubPage()),
          ),
          _menuTile(
            theme,
            icon: Icons.science_outlined,
            title: tr('sandbox.title'),
            subtitle: tr('sandbox.subtitle'),
            onTap: () => _push(const SandboxSubPage()),
          ),
          _menuTile(
            theme,
            icon: Icons.info_outline,
            title: tr('about.title'),
            subtitle: tr('about.subtitle'),
            onTap: () => _push(const AboutSubPage()),
          ),
          if (updaterSupported)
            _menuTile(
              theme,
              icon: Icons.system_update_outlined,
              title: tr('update.check'),
              subtitle: tr('update.check_sub'),
              onTap: () => promptAppUpdate(context),
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

/// Top of Pengaturan: store avatar and name, plan, monthly quota as a thin
/// bar, and the Pro link for free users.
class SettingsHeader extends StatelessWidget {
  final SettingsModel settings;
  final SubscriptionModel sub;
  final VoidCallback onUpgrade;

  const SettingsHeader({
    super.key,
    required this.settings,
    required this.sub,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const limit = SubscriptionService.freeMonthlyLimit;
    final used = sub.monthlyDocCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              image: settings.hasLogo
                  ? DecorationImage(
                      image: MemoryImage(settings.logoBytes!),
                      fit: BoxFit.contain,
                    )
                  : null,
            ),
            child: settings.hasLogo
                ? null
                : Icon(Icons.storefront_outlined,
                    color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.namaToko.isNotEmpty ? settings.namaToko : 'Faktura',
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sub.isPro
                      ? tr('settings.plan_pro')
                      : tr('settings.plan_free')
                          .replaceAll('{n}', '$used')
                          .replaceAll('{max}', '$limit'),
                  style: theme.textTheme.bodySmall,
                ),
                if (!sub.isPro) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    // The count can pass the limit; the bar just stays full.
                    value: used >= limit ? 1 : used / limit,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ],
              ],
            ),
          ),
          if (!sub.isPro)
            TextButton(
              onPressed: onUpgrade,
              // "Pro" alone says little to TalkBack.
              child: Text('Pro', semanticsLabel: tr('sub.unlock_all')),
            ),
        ],
      ),
    );
  }
}
