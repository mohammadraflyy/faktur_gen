import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
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

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsModel _settings = SettingsModel();
  SubscriptionModel _sub = SubscriptionModel();
  bool _isLoading = true;
  // Nothing for the first 300ms, then a loading text, so a fast load
  // never flashes a spinner.
  bool _showLoadingText = false;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _loadingTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _isLoading) setState(() => _showLoadingText = true);
    });
    _load();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await SettingsService.load();
    final sub = await SubscriptionService.load();
    _loadingTimer?.cancel();
    if (mounted) setState(() { _settings = s; _sub = sub; _isLoading = false; });
  }

  Future<void> _push(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _load(); // refresh after returning
  }

  // Free users get the paywall instead of a Pro page.
  void _pushPro(Widget page) {
    if (!_sub.isPro) {
      showPaywallSheet(context);
      return;
    }
    _push(page);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('settings.title'))),
        body: Center(
          child: _showLoadingText
              ? Text(tr('dashboard.loading'), style: theme.textTheme.bodySmall)
              : const SizedBox.shrink(),
        ),
      );
    }

    final notSet = tr('settings.not_set');
    final isSet = tr('settings.already_set');
    // Written label instead of the old orange badge.
    final pro = _sub.isPro ? null : 'Pro';

    return Scaffold(
      appBar: AppBar(title: Text(tr('settings.title'))),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          SettingsHeader(
            settings: _settings,
            sub: _sub,
            onUpgrade: () => showPaywallSheet(context).then((_) => _load()),
          ),
          _group(theme, tr('settings.group_store'), [
            _row(
              theme,
              tr('settings.store_profile'),
              _settings.namaToko.isNotEmpty ? _settings.namaToko : notSet,
              () => _push(ProfileSubPage(settings: _settings)),
            ),
            _row(
              theme,
              tr('settings.contact'),
              _settings.telepon.isNotEmpty ? _settings.telepon : notSet,
              () => _push(ContactSubPage(settings: _settings)),
            ),
            _row(
              theme,
              tr('settings.payment_info'),
              _settings.bankAccounts.isNotEmpty &&
                      _settings.bankAccounts.first.namaBank.isNotEmpty
                  ? '${_settings.bankAccounts.length} ${tr('settings.accounts')}'
                  : notSet,
              () => _push(BankSubPage(settings: _settings)),
            ),
            _row(
              theme,
              tr('settings.qris'),
              pro ?? (_settings.qrisMerchantId.isNotEmpty ? isSet : notSet),
              () => _pushPro(QrisSubPage(settings: _settings)),
            ),
            _row(
              theme,
              tr('settings.signature'),
              _settings.hasSignature ? isSet : notSet,
              () => _push(SignatureSubPage(settings: _settings)),
            ),
          ]),
          _group(theme, tr('settings.documents'), [
            _row(
              theme,
              tr('template.title'),
              '${_settings.templateConfig.invoiceTemplate.label} · ${_settings.templateConfig.strukTemplate.label}',
              () => _push(TemplateSubPage(settings: _settings)),
            ),
            _row(
              theme,
              tr('settings.tax_doc'),
              'PPN ${_settings.taxRate}% · ${_settings.currency}',
              () => _push(InvoiceSettingsSubPage(settings: _settings)),
            ),
            _row(
              theme,
              tr('settings.receipt_settings'),
              _settings.footerStruk.isNotEmpty
                  ? _settings.footerStruk
                  : 'Default',
              () => _push(StrukSubPage(settings: _settings)),
            ),
            _row(theme, tr('recurring.title'), pro,
                () => _pushPro(const RecurringInvoicePage())),
          ]),
          _group(theme, tr('settings.app'), [
            _accountRow(theme),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeService.themeNotifier,
              builder: (_, mode, _) => _row(
                theme,
                tr('appearance.title'),
                switch (mode) {
                  ThemeMode.dark => tr('appearance.dark'),
                  ThemeMode.light => tr('appearance.light'),
                  ThemeMode.system => tr('appearance.system'),
                },
                () => _showThemePicker(theme),
              ),
            ),
            ValueListenableBuilder<AppLanguage>(
              valueListenable: LocaleService.languageNotifier,
              builder: (_, lang, _) => _row(theme, tr('settings.language'),
                  lang.label, () => _showLanguagePicker(theme)),
            ),
            _row(theme, tr('settings.backup'), null,
                () => _push(BackupSubPage())),
            if (kDebugMode)
              _row(theme, tr('sandbox.title'), null,
                  () => _push(const SandboxSubPage())),
            _row(theme, tr('about.title'), UpdaterService.currentAppVersion,
                () => _push(const AboutSubPage())),
            if (updaterSupported)
              _row(theme, tr('update.check'), null,
                  () => promptAppUpdate(context)),
          ]),
        ],
      ),
    );
  }

  Widget _group(ThemeData theme, String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 4),
          child: Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.bodySmall),
          ),
        ),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 20, endIndent: 20),
          rows[i],
        ],
      ],
    );
  }

  // Title on the left, current value on the right (mockup 05).
  Widget _row(
      ThemeData theme, String title, String? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
            if (value != null) ...[
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _accountRow(ThemeData theme) {
    final user = AuthService.currentUser;
    if (user != null) {
      return _row(
        theme,
        tr('auth.account'),
        user.email ?? user.displayName,
        () async {
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
    return _row(
      theme,
      tr('auth.sign_in'),
      tr('auth.not_signed_in'),
      () async {
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
                      child: Text(tr('settings.language'),
                          style: theme.textTheme.titleMedium),
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
                        style: theme.textTheme.bodyLarge?.copyWith(
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
                      child: Text(tr('appearance.title'),
                          style: theme.textTheme.titleMedium),
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
              : theme.colorScheme.onSurfaceVariant),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
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
