import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/catalog_model.dart';
import '../services/catalog_service.dart';
import '../services/locale_service.dart';

/// Catalog search sheet shared by the invoice and receipt forms. Pops with
/// the picked or newly created [CatalogItem].
class CatalogPickerSheet extends StatefulWidget {
  final List<CatalogItem> items;
  final String currencySymbol;
  final String currencyLocale;
  const CatalogPickerSheet({
    super.key,
    required this.items,
    this.currencySymbol = 'Rp ',
    this.currencyLocale = 'id_ID',
  });

  @override
  State<CatalogPickerSheet> createState() => _CatalogPickerSheetState();
}

class _CatalogPickerSheetState extends State<CatalogPickerSheet> {
  late List<CatalogItem> _items;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = widget.items;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String q) {
    setState(() {
      if (q.isEmpty) {
        _items = widget.items;
      } else {
        final lq = q.toLowerCase();
        _items = widget.items
            .where((c) => c.nama.toLowerCase().contains(lq))
            .toList();
      }
    });
  }

  Future<void> _addNew() async {
    final namaCtrl = TextEditingController();
    final satuanCtrl = TextEditingController(text: 'Unit');
    final hargaCtrl = TextEditingController();

    final result = await showDialog<CatalogItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('invoice.add_catalog_item')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaCtrl,
              decoration: InputDecoration(labelText: tr('invoice.item_name')),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: satuanCtrl,
                    decoration: InputDecoration(labelText: tr('item.unit')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: hargaCtrl,
                    decoration: InputDecoration(labelText: tr('invoice.price')),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('common.cancel'))),
          TextButton(
            onPressed: () {
              if (namaCtrl.text.trim().isEmpty) return;
              final item = CatalogItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                nama: namaCtrl.text.trim(),
                satuan: satuanCtrl.text.trim(),
                hargaSatuan: double.tryParse(hargaCtrl.text) ?? 0,
              );
              Navigator.pop(ctx, item);
            },
            child: Text(tr('common.save')),
          ),
        ],
      ),
    );
    namaCtrl.dispose();
    satuanCtrl.dispose();
    hargaCtrl.dispose();

    if (result != null) {
      await CatalogService.save(result);
      if (mounted) Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(tr('invoice.catalog'),
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addNew,
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(tr('invoice.catalog_new')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _filter,
                      decoration: InputDecoration(
                        hintText: tr('invoice.search_item'),
                        prefixIcon: const Icon(Icons.search, size: 18),
                      ),
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _items.isEmpty
                    ? Center(
                        child: Text(
                          widget.items.isEmpty
                              ? tr('invoice.catalog_empty')
                              : tr('contact.not_found'),
                          style: GoogleFonts.inter(
                              fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final item = _items[i];
                          return ListTile(
                            title: Text(item.nama,
                                style: GoogleFonts.inter(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                            subtitle: Text(
                              '${item.satuan} - ${NumberFormat.currency(locale: widget.currencyLocale, symbol: widget.currencySymbol, decimalDigits: 0).format(item.hargaSatuan)}',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                              onPressed: () async {
                                await CatalogService.delete(item.id);
                                final refreshed =
                                    await CatalogService.loadAll();
                                setState(() {
                                  _items = refreshed;
                                });
                              },
                            ),
                            onTap: () => Navigator.pop(context, item),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
