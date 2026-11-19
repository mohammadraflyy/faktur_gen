import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/doc_template_config.dart';
import '../../models/settings_model.dart';
import '../../services/locale_service.dart';
import 'settings_sub_page_mixin.dart';

class TemplateSubPage extends StatefulWidget {
  final SettingsModel settings;
  const TemplateSubPage({super.key, required this.settings});

  @override
  State<TemplateSubPage> createState() => _TemplateSubPageState();
}

class _TemplateSubPageState extends State<TemplateSubPage>
    with SettingsSubPageMixin {
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
          if (_config.showSignature)
            _toggleTile(theme,
                icon: Icons.verified_outlined,
                title: tr('template.show_stamp'),
                subtitle: tr('template.show_stamp_note'),
                value: _config.showStamp,
                onChanged: (v) => setState(() => _config.showStamp = v)),
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
