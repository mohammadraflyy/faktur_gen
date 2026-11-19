import 'package:flutter/material.dart';
import '../../models/settings_model.dart';
import '../../services/locale_service.dart';
import '../../services/settings_service.dart';

class QrisSubPage extends StatefulWidget {
  final SettingsModel settings;
  const QrisSubPage({super.key, required this.settings});

  @override
  State<QrisSubPage> createState() => _QrisSubPageState();
}

class _QrisSubPageState extends State<QrisSubPage> {
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
            style: theme.textTheme.bodySmall,
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
