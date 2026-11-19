import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/faktur_model.dart';
import '../services/locale_service.dart';

/// Outcome of the item sheet: an edited item, or a delete request.
class ItemEditResult {
  final ItemFaktur? item;

  /// Per-item discount; stays 0 unless the sheet was opened with one.
  final double discount;
  const ItemEditResult.saved(ItemFaktur this.item, {this.discount = 0});
  const ItemEditResult.deleted()
      : item = null,
        discount = 0;

  bool get deleted => item == null;
}

Future<ItemEditResult?> showItemEditSheet(
  BuildContext context, {
  required ItemFaktur item,
  required NumberFormat currency,
  bool isNew = false,
  double? discount,
}) {
  return showModalBottomSheet<ItemEditResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ItemEditSheet(
        item: item, currency: currency, isNew: isNew, discount: discount),
  );
}

class ItemEditSheet extends StatefulWidget {
  final ItemFaktur item;
  final NumberFormat currency;
  final bool isNew;

  /// Receipts can discount a single item; null hides the field.
  final double? discount;

  const ItemEditSheet({
    super.key,
    required this.item,
    required this.currency,
    this.isNew = false,
    this.discount,
  });

  @override
  State<ItemEditSheet> createState() => _ItemEditSheetState();
}

class _ItemEditSheetState extends State<ItemEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.item.namaBarang);
  late final _deskripsi = TextEditingController(text: widget.item.deskripsi);
  late final _satuan = TextEditingController(text: widget.item.satuan);
  late final _harga = TextEditingController(
      text: widget.item.hargaSatuan > 0
          ? widget.item.hargaSatuan.round().toString()
          : '');
  late final _diskon = TextEditingController(
      text: (widget.discount ?? 0) > 0
          ? widget.discount!.round().toString()
          : '');
  late double _qty = widget.item.kuantitas;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  double get _price => double.tryParse(_harga.text) ?? 0;
  double get _discount => double.tryParse(_diskon.text) ?? 0;

  @override
  void dispose() {
    _nama.dispose();
    _deskripsi.dispose();
    _satuan.dispose();
    _harga.dispose();
    _diskon.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final satuan = _satuan.text.trim();
    Navigator.pop(
      context,
      ItemEditResult.saved(ItemFaktur(
        namaBarang: _nama.text.trim(),
        deskripsi: _deskripsi.text.trim(),
        kuantitas: _qty,
        satuan: satuan.isEmpty ? 'Unit' : satuan,
        hargaSatuan: _price,
      ), discount: _discount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.isNew ? tr('item.add_title') : tr('item.edit_title'),
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nama,
                autofocus: widget.isNew,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: tr('item.name')),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? tr('item.name_required')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deskripsi,
                decoration: InputDecoration(labelText: tr('item.description')),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: Text(tr('item.qty'),
                          style: theme.textTheme.bodyLarge)),
                  IconButton.filledTonal(
                    tooltip: tr('item.qty_less'),
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed:
                        _qty >= 2 ? () => setState(() => _qty -= 1) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(_fmt(_qty),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium),
                  ),
                  IconButton.filledTonal(
                    tooltip: tr('item.qty_more'),
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => setState(() => _qty += 1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _harga,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(labelText: tr('item.price')),
                      // Only this sheet rebuilds; the invoice page stays still.
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _satuan,
                      decoration: InputDecoration(labelText: tr('item.unit')),
                    ),
                  ),
                ],
              ),
              if (widget.discount != null) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _diskon,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: tr('item.discount')),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: Text(
                    '${tr('common.save')} · ${widget.currency.format(_qty * _price - _discount)}'),
              ),
              if (!widget.isNew)
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, const ItemEditResult.deleted()),
                  child: Text(tr('item.delete'),
                      style: TextStyle(
                          color: AppColors.errorFor(theme.brightness))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
