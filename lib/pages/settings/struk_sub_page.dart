import 'package:flutter/material.dart';
import '../../models/settings_model.dart';
import '../../services/locale_service.dart';
import 'settings_sub_page_mixin.dart';

class StrukSubPage extends StatefulWidget {
  final SettingsModel settings;
  const StrukSubPage({super.key, required this.settings});

  @override
  State<StrukSubPage> createState() => _StrukSubPageState();
}

class _StrukSubPageState extends State<StrukSubPage>
    with SettingsSubPageMixin {
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
            label: tr('settings.footer_receipt'),
            hint: tr('settings.footer_hint'),
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
