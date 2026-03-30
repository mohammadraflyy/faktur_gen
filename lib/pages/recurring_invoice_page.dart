import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/contact_model.dart';
import '../models/recurring_invoice_model.dart';
import '../models/reminder_model.dart';
import '../services/contact_service.dart';
import '../services/locale_service.dart';
import '../services/recurring_invoice_service.dart';
import '../services/settings_service.dart';

class RecurringInvoicePage extends StatefulWidget {
  const RecurringInvoicePage({super.key});

  @override
  State<RecurringInvoicePage> createState() => _RecurringInvoicePageState();
}

class _RecurringInvoicePageState extends State<RecurringInvoicePage> {
  List<RecurringInvoiceModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await RecurringInvoiceService.loadAll();
    if (mounted) setState(() { _items = items; _isLoading = false; });
  }

  Future<void> _add() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _RecurringFormPage()),
    );
    if (result == true) _load();
  }

  Future<void> _edit(RecurringInvoiceModel item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _RecurringFormPage(existing: item)),
    );
    if (result == true) _load();
  }

  Future<void> _delete(RecurringInvoiceModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('recurring.delete_title')),
        content: Text('${item.contactName} — ${item.interval.label}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('common.cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('common.delete'),
              style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await RecurringInvoiceService.delete(item.id);
      _load();
    }
  }

  Future<void> _toggleActive(RecurringInvoiceModel item) async {
    item.isActive = !item.isActive;
    await RecurringInvoiceService.save(item);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('recurring.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _add,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.repeat_rounded, size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      Text(tr('recurring.empty'),
                        style: GoogleFonts.inter(fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                      const SizedBox(height: 4),
                      Text(tr('recurring.empty_sub'),
                        style: GoogleFonts.inter(fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.35))),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _buildCard(theme, _items[i]),
                ),
    );
  }

  Widget _buildCard(ThemeData theme, RecurringInvoiceModel item) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final total = RecurringInvoiceService.calculateTotal(item);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.contactName,
                    style: GoogleFonts.inter(fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.isActive ? tr('recurring.active') : tr('recurring.paused'),
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                      color: item.isActive ? Colors.green : Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('${item.interval.label} · ${tr('recurring.next')}: ${dateFormat.format(item.nextDate)}',
              style: GoogleFonts.inter(fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 4),
            Text('${item.items.length} item · Rp ${total.toStringAsFixed(0)}',
              style: GoogleFonts.inter(fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _toggleActive(item),
                  child: Text(item.isActive ? tr('recurring.pause') : tr('recurring.activate')),
                ),
                TextButton(onPressed: () => _edit(item),
                  child: Text(tr('common.edit'))),
                TextButton(onPressed: () => _delete(item),
                  child: Text(tr('common.delete'),
                    style: const TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Form page for adding/editing recurring invoices ─────────────────────────

class _RecurringFormPage extends StatefulWidget {
  final RecurringInvoiceModel? existing;
  const _RecurringFormPage({this.existing});

  @override
  State<_RecurringFormPage> createState() => _RecurringFormPageState();
}

class _RecurringFormPageState extends State<_RecurringFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _contactCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  final List<_ItemRow> _items = [];
  RepeatInterval _interval = RepeatInterval.monthly;
  DateTime _nextDate = DateTime.now().add(const Duration(days: 30));
  List<ContactModel> _contacts = [];
  String _contactId = '';
  String _contactPhone = '';
  String _contactAddress = '';
  String _contactNpwp = '';
  String _invoicePrefix = 'INV';
  double _taxRate = 11;
  String _currency = 'IDR';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    if (widget.existing != null) {
      final e = widget.existing!;
      _contactCtrl.text = e.contactName;
      _catatanCtrl.text = e.catatan;
      _interval = e.interval;
      _nextDate = e.nextDate;
      _contactId = e.contactId;
      _contactPhone = e.contactPhone;
      _contactAddress = e.contactAddress;
      _contactNpwp = e.contactNpwp;
      _invoicePrefix = e.invoicePrefix;
      _taxRate = e.taxRate;
      _currency = e.currency;
      for (final item in e.items) {
        _items.add(_ItemRow(
          namaCtrl: TextEditingController(text: item.nama),
          qtyCtrl: TextEditingController(text: item.kuantitas.toString()),
          priceCtrl: TextEditingController(text: item.hargaSatuan.toString()),
          satuanCtrl: TextEditingController(text: item.satuan),
        ));
      }
    }
    if (_items.isEmpty) _items.add(_ItemRow());
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.load();
    final contacts = await ContactService.loadAll();
    if (mounted) {
      setState(() {
        _contacts = contacts;
        if (widget.existing == null) {
          _invoicePrefix = settings.invoicePrefix;
          _taxRate = settings.taxRate;
          _currency = settings.currency;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final model = RecurringInvoiceModel(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      contactId: _contactId,
      contactName: _contactCtrl.text.trim(),
      contactPhone: _contactPhone,
      contactAddress: _contactAddress,
      contactNpwp: _contactNpwp,
      interval: _interval,
      nextDate: _nextDate,
      lastGenerated: widget.existing?.lastGenerated,
      isActive: widget.existing?.isActive ?? true,
      catatan: _catatanCtrl.text.trim(),
      invoicePrefix: _invoicePrefix,
      currency: _currency,
      taxRate: _taxRate,
      items: _items.map((r) => RecurringItem(
        nama: r.namaCtrl.text.trim(),
        kuantitas: double.tryParse(r.qtyCtrl.text) ?? 1,
        satuan: r.satuanCtrl.text.trim(),
        hargaSatuan: double.tryParse(r.priceCtrl.text) ?? 0,
      )).where((i) => i.nama.isNotEmpty).toList(),
      createdAt: widget.existing?.createdAt,
    );

    await RecurringInvoiceService.save(model);
    setState(() => _isSaving = false);
    if (mounted) Navigator.pop(context, true);
  }

  void _pickContact() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        itemCount: _contacts.length,
        itemBuilder: (_, i) {
          final c = _contacts[i];
          return ListTile(
            title: Text(c.nama),
            subtitle: c.telepon.isNotEmpty ? Text(c.telepon) : null,
            onTap: () {
              _contactCtrl.text = c.nama;
              _contactId = c.id;
              _contactPhone = c.telepon;
              _contactAddress = c.alamat;
              _contactNpwp = c.npwp;
              Navigator.pop(ctx);
              setState(() {});
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? tr('recurring.edit_title') : tr('recurring.add_title')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Contact
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _contactCtrl,
                    decoration: InputDecoration(
                      labelText: tr('recurring.client'),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? tr('recurring.client_required') : null,
                  ),
                ),
                if (_contacts.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.contacts_outlined),
                    onPressed: _pickContact,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Interval
            DropdownButtonFormField<RepeatInterval>(
              value: _interval,
              decoration: InputDecoration(labelText: tr('recurring.interval')),
              items: RepeatInterval.values
                  .where((r) => r != RepeatInterval.none)
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                  .toList(),
              onChanged: (v) => setState(() => _interval = v!),
            ),
            const SizedBox(height: 16),
            // Next date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr('recurring.next_date')),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_nextDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _nextDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                );
                if (date != null) setState(() => _nextDate = date);
              },
            ),
            const SizedBox(height: 16),
            // Items
            Text(tr('recurring.items'),
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...List.generate(_items.length, (i) => _buildItemRow(theme, i)),
            TextButton.icon(
              onPressed: () => setState(() => _items.add(_ItemRow())),
              icon: const Icon(Icons.add, size: 18),
              label: Text(tr('recurring.add_item')),
            ),
            const SizedBox(height: 16),
            // Notes
            TextFormField(
              controller: _catatanCtrl,
              decoration: InputDecoration(labelText: tr('recurring.notes')),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isEdit ? tr('recurring.save_edit') : tr('recurring.save'),
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(ThemeData theme, int index) {
    final item = _items[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: TextFormField(
            controller: item.namaCtrl,
            decoration: InputDecoration(labelText: tr('recurring.item_name'), isDense: true),
          )),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: TextFormField(
            controller: item.qtyCtrl,
            decoration: InputDecoration(labelText: tr('recurring.qty'), isDense: true),
            keyboardType: TextInputType.number,
          )),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: TextFormField(
            controller: item.priceCtrl,
            decoration: InputDecoration(labelText: tr('recurring.price'), isDense: true),
            keyboardType: TextInputType.number,
          )),
          if (_items.length > 1)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _items.removeAt(index)),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _contactCtrl.dispose();
    _catatanCtrl.dispose();
    for (final item in _items) {
      item.namaCtrl.dispose();
      item.qtyCtrl.dispose();
      item.priceCtrl.dispose();
      item.satuanCtrl.dispose();
    }
    super.dispose();
  }
}

class _ItemRow {
  final TextEditingController namaCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController satuanCtrl;

  _ItemRow({
    TextEditingController? namaCtrl,
    TextEditingController? qtyCtrl,
    TextEditingController? priceCtrl,
    TextEditingController? satuanCtrl,
  })  : namaCtrl = namaCtrl ?? TextEditingController(),
        qtyCtrl = qtyCtrl ?? TextEditingController(text: '1'),
        priceCtrl = priceCtrl ?? TextEditingController(text: '0'),
        satuanCtrl = satuanCtrl ?? TextEditingController(text: 'Unit');
}
