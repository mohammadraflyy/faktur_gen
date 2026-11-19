import 'package:flutter/material.dart';
import '../../models/settings_model.dart';
import '../../services/locale_service.dart';
import 'settings_sub_page_mixin.dart';

class ContactSubPage extends StatefulWidget {
  final SettingsModel settings;
  const ContactSubPage({super.key, required this.settings});

  @override
  State<ContactSubPage> createState() => _ContactSubPageState();
}

class _ContactSubPageState extends State<ContactSubPage>
    with SettingsSubPageMixin {
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
