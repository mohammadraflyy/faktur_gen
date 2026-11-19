import 'package:flutter/material.dart';
import '../../models/settings_model.dart';
import '../../services/locale_service.dart';
import 'settings_sub_page_mixin.dart';

class InvoiceSettingsSubPage extends StatefulWidget {
  final SettingsModel settings;
  const InvoiceSettingsSubPage({super.key, required this.settings});

  @override
  State<InvoiceSettingsSubPage> createState() =>
      _InvoiceSettingsSubPageState();
}

class _InvoiceSettingsSubPageState extends State<InvoiceSettingsSubPage>
    with SettingsSubPageMixin {
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
