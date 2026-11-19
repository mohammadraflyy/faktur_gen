import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/settings_model.dart';
import '../../services/locale_service.dart';
import '../../widgets/signature_pad.dart';
import 'settings_sub_page_mixin.dart';

class SignatureSubPage extends StatefulWidget {
  final SettingsModel settings;
  const SignatureSubPage({super.key, required this.settings});

  @override
  State<SignatureSubPage> createState() => _SignatureSubPageState();
}

class _SignatureSubPageState extends State<SignatureSubPage>
    with SettingsSubPageMixin {
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
              tooltip: tr('common.delete'),
              icon: Icon(Icons.delete_outline,
                  color: AppColors.errorFor(theme.brightness)),
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
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr('settings.sign_note'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 32),
          buildSaveButton(theme, () => saveSettings(_s)),
        ],
      ),
    );
  }
}
