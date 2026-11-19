import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/settings_model.dart';
import '../../services/locale_service.dart';
import 'settings_sub_page_mixin.dart';

class BankSubPage extends StatefulWidget {
  final SettingsModel settings;
  const BankSubPage({super.key, required this.settings});

  @override
  State<BankSubPage> createState() => _BankSubPageState();
}

class _BankSubPageState extends State<BankSubPage>
    with SettingsSubPageMixin {
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
              tooltip: tr('settings.add_account'),
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
                          style: theme.textTheme.titleSmall),
                      const Spacer(),
                      if (_bankCtrls.length > 1)
                        IconButton(
                          tooltip: tr('common.delete'),
                          icon: Icon(Icons.delete_outline,
                              color: AppColors.errorFor(theme.brightness),
                              size: 20),
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
                  buildField(controller: c.bankCtrl, label: tr('settings.bank_name'), hint: tr('settings.bank_hint')),
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
