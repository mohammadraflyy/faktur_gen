import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../models/contact_model.dart';
import '../models/reminder_model.dart';
import '../services/contact_service.dart';
import '../services/locale_service.dart';
import '../services/reminder_service.dart';
import '../widgets/status_label.dart';
import 'faktur_page.dart';
import 'struk_page.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage>
    with SingleTickerProviderStateMixin {
  List<ReminderModel> _reminders = [];
  bool _isLoading = true;
  bool _showLoadingText = false;
  Timer? _loadingTimer;
  late TabController _tabCtrl;

  DateFormat get _dateFormat =>
      DateFormat('dd MMM yyyy', LocaleService.isEn ? 'en_US' : 'id_ID');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _loadingTimer?.cancel();
    // A fast load should not flash a loading message.
    _loadingTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _isLoading) setState(() => _showLoadingText = true);
    });
    try {
      final list = await ReminderService.loadAll();
      if (mounted) setState(() { _reminders = list; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('[Reminder] load error: $e');
    } finally {
      _loadingTimer?.cancel();
    }
  }

  List<ReminderModel> get _pending =>
      _reminders.where((r) => r.status == ReminderStatus.pending).toList();

  List<ReminderModel> get _completed =>
      _reminders.where((r) => r.status != ReminderStatus.pending).toList();

  Future<void> _addReminder() async {
    final result = await showModalBottomSheet<ReminderModel>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddReminderSheet(),
    );
    if (result != null) {
      await ReminderService.add(result);
      _load();
    }
  }

  Future<void> _markDone(ReminderModel r) async {
    await ReminderService.updateStatus(r.id, ReminderStatus.done);
    await _load();
    // Pindah ke tab Selesai agar user melihat item yang baru ditandai
    _tabCtrl.animateTo(1);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('reminder.marked_done_msg')
              .replaceAll('{service}', r.serviceName)
              .replaceAll('{name}', r.contactName)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _editReminder(ReminderModel r) async {
    final result = await showModalBottomSheet<ReminderModel>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddReminderSheet(reminder: r),
    );
    if (result != null) {
      await ReminderService.update(result);
      _load();
    }
  }


  void _createDocFromReminder(ReminderModel r) {
    if (r.docType == ReminderDocType.struk) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StrukPage(
            reminderItems: r.lastItems,
            reminderContactName: r.contactName,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FakturPage(
            reminderItems: r.lastItems,
            reminderContactName: r.contactName,
          ),
        ),
      );
    }
  }

  Future<void> _reschedule(ReminderModel r) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: r.reminderDate.isBefore(DateTime.now())
          ? DateTime.now().add(const Duration(days: 1))
          : r.reminderDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      r.reminderDate = picked;
      r.status = ReminderStatus.pending;
      await ReminderService.update(r);
      _load();
    }
  }

  Future<void> _sendWhatsApp(ReminderModel r) async {
    if (r.contactPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('reminder.no_phone'))),
      );
      return;
    }
    // Normalize phone: remove spaces/dashes, convert leading 0 to 62
    var phone = r.contactPhone.replaceAll(RegExp(r'[\s\-()]+'), '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    } else if (!phone.startsWith('+') && !phone.startsWith('62')) {
      phone = '62$phone';
    }
    phone = phone.replaceAll('+', '');

    final notes = r.notes.isEmpty
        ? ''
        : tr('reminder.wa_notes').replaceAll('{notes}', r.notes);
    // {notes} last, so placeholders typed inside the notes stay literal.
    final message = tr('reminder.wa_message')
        .replaceAll('{name}', r.contactName)
        .replaceAll('{service}', r.serviceName)
        .replaceAll('{date}', _dateFormat.format(r.reminderDate))
        .replaceAll('{notes}', notes);

    final uri = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('reminder.wa_fail'))),
        );
      }
    }
  }

  String _when(ReminderModel r) =>
      '${_dateFormat.format(r.reminderDate)}, '
      '${r.reminderHour.toString().padLeft(2, '0')}:'
      '${r.reminderMinute.toString().padLeft(2, '0')}';

  String _repeatLabel(ReminderModel r) =>
      tr('reminder.repeat_${r.repeatInterval.name}');

  void _showDetail(ReminderModel r) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          // Scrolls instead of overflowing at large text sizes.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('reminder.detail_title'),
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                _detailRow(theme, Icons.person_outlined, tr('reminder.customer'), r.contactName),
                if (r.contactPhone.isNotEmpty)
                  _detailRow(theme, Icons.phone_outlined, tr('common.phone'), r.contactPhone),
                if (r.contactAddress.isNotEmpty)
                  _detailRow(theme, Icons.location_on_outlined, tr('common.address'), r.contactAddress),
                _detailRow(theme, Icons.build_outlined, tr('reminder.service'), r.serviceName),
                _detailRow(theme, Icons.calendar_today, tr('reminder.date'), _when(r)),
                if (r.isRepeating)
                  _detailRow(theme, Icons.repeat, tr('reminder.repeat'), _repeatLabel(r)),
                if (r.notes.isNotEmpty)
                  _detailRow(theme, Icons.notes_outlined, tr('reminder.notes'), r.notes),
                _detailRow(
                  theme,
                  Icons.info_outline,
                  tr('reminder.status'),
                  r.isOverdue
                      ? tr('reminder.overdue')
                      : r.isDue
                          ? tr('reminder.due_today')
                          : r.status == ReminderStatus.pending
                              ? tr('reminder.waiting')
                              : tr('reminder.done'),
                ),
                const SizedBox(height: 4),
                const Divider(height: 1),
                if (r.contactPhone.isNotEmpty)
                  _actionTile(
                    theme,
                    icon: Icons.message_outlined,
                    label: tr('reminder.send_wa'),
                    onTap: () {
                      Navigator.pop(context);
                      _sendWhatsApp(r);
                    },
                  ),
                if (r.hasLastItems)
                  _actionTile(
                    theme,
                    icon: r.docType == ReminderDocType.struk
                        ? Icons.receipt_outlined
                        : Icons.receipt_long_outlined,
                    label: r.docType == ReminderDocType.struk
                        ? tr('reminder.create_receipt')
                        : tr('reminder.create_invoice'),
                    onTap: () {
                      Navigator.pop(context);
                      _createDocFromReminder(r);
                    },
                  ),
                _actionTile(
                  theme,
                  icon: Icons.edit_outlined,
                  label: tr('reminder.edit_title'),
                  onTap: () {
                    Navigator.pop(context);
                    _editReminder(r);
                  },
                ),
                if (r.status == ReminderStatus.pending) ...[
                  _actionTile(
                    theme,
                    icon: Icons.event_repeat_rounded,
                    label: tr('reminder.reschedule'),
                    onTap: () {
                      Navigator.pop(context);
                      _reschedule(r);
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _markDone(r);
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(tr('reminder.mark_done')),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _actionTile(
                  theme,
                  icon: Icons.delete_outline,
                  label: tr('common.delete'),
                  color: AppColors.errorFor(theme.brightness),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(r);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(ThemeData theme, IconData icon, String label, String value) {
    final muted = theme.textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: muted?.color),
          const SizedBox(width: 12),
          // Label above the value, so long labels survive 200% text.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: muted),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: theme.textTheme.bodyLarge?.copyWith(color: c)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('reminder.title')),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(text: '${tr('reminder.active')} (${_pending.length})'),
            Tab(text: '${tr('reminder.done')} (${_completed.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        tooltip: tr('reminder.add_title'),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? Center(
              child: _showLoadingText
                  ? Text(tr('dashboard.loading'),
                      style: theme.textTheme.bodySmall)
                  : const SizedBox.shrink(),
            )
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(theme, _pending, isPending: true),
                _buildList(theme, _completed, isPending: false),
              ],
            ),
    );
  }

  Widget _buildList(ThemeData theme, List<ReminderModel> list,
      {required bool isPending}) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
          children: [
            Text(
              isPending
                  ? tr('reminder.empty_pending')
                  : tr('reminder.empty_done'),
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (isPending) ...[
              const SizedBox(height: 4),
              Text(tr('reminder.add_hint'),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        // Bottom room so the FAB never covers the last row.
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.paddingOf(context).bottom + 80),
        itemCount: list.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) => _buildRow(theme, list[i], isPending: isPending),
      ),
    );
  }

  Widget _buildRow(ThemeData theme, ReminderModel r,
      {required bool isPending}) {
    final error = AppColors.errorFor(theme.brightness);
    final repeat = r.isRepeating ? ' · ${_repeatLabel(r)}' : '';

    final row = InkWell(
      onTap: () => _showDetail(r),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.contactName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (r.serviceName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(r.serviceName,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 2),
                  Text('${_when(r)}$repeat', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (r.isOverdue) ...[
              const SizedBox(width: 12),
              StatusLabel(text: tr('reminder.overdue'), color: error),
            ] else if (r.isDue) ...[
              const SizedBox(width: 12),
              StatusLabel(
                  text: tr('dashboard.today'),
                  color: AppColors.warningFor(theme.brightness)),
            ],
          ],
        ),
      ),
    );

    final deleteBg = _swipeBackground(theme,
        alignment: Alignment.centerRight,
        color: error,
        icon: Icons.delete_outline,
        label: tr('common.delete'));

    if (!isPending) {
      // Completed: swipe left to delete only
      return Dismissible(
        key: ValueKey(r.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDelete(r),
        background: deleteBg,
        child: row,
      );
    }

    // Pending: swipe right=done, left=delete
    return Dismissible(
      key: ValueKey(r.id),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          _markDone(r);
          return false; // don't remove, _markDone reloads
        } else {
          return _confirmDelete(r);
        }
      },
      background: _swipeBackground(theme,
          alignment: Alignment.centerLeft,
          color: AppColors.successFor(theme.brightness),
          icon: Icons.check_rounded,
          label: tr('reminder.mark_done')),
      secondaryBackground: deleteBg,
      child: row,
    );
  }

  Future<bool> _confirmDelete(ReminderModel r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('reminder.delete_title')),
        content: Text(tr('reminder.delete_body')
            .replaceAll('{service}', r.serviceName)
            .replaceAll('{name}', r.contactName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('common.delete'),
                style: TextStyle(
                    color: AppColors.errorFor(Theme.of(ctx).brightness))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ReminderService.delete(r.id);
      _load();
      return true;
    }
    return false;
  }

  Widget _swipeBackground(
    ThemeData theme, {
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon,
          // White on the light colors, #0F1117 on the dark-mode ones; all >= 5.48:1.
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF0F1117)
              : Colors.white,
          semanticLabel: label),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Reminder Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddReminderSheet extends StatefulWidget {
  final ReminderModel? reminder;

  const _AddReminderSheet({this.reminder});

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _contactCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _serviceCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _reminderDate;
  late TimeOfDay _reminderTime;
  late RepeatInterval _repeatInterval;
  List<ContactModel> _contacts = [];

  bool get _isEditing => widget.reminder != null;

  DateFormat get _dateFormat =>
      DateFormat('dd MMM yyyy', LocaleService.isEn ? 'en_US' : 'id_ID');

  static const _presetServiceKeys = [
    'reminder.preset_ac_wash',
    'reminder.preset_ac_service',
    'reminder.preset_ac_filter',
    'reminder.preset_routine',
    'reminder.preset_engine',
    'reminder.preset_check',
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _contactCtrl = TextEditingController(text: r?.contactName ?? '');
    _phoneCtrl = TextEditingController(text: r?.contactPhone ?? '');
    _addressCtrl = TextEditingController(text: r?.contactAddress ?? '');
    _serviceCtrl = TextEditingController(text: r?.serviceName ?? '');
    _notesCtrl = TextEditingController(text: r?.notes ?? '');
    _reminderDate = r?.reminderDate ?? DateTime.now().add(const Duration(days: 30));
    _reminderTime = r != null
        ? TimeOfDay(hour: r.reminderHour, minute: r.reminderMinute)
        : const TimeOfDay(hour: 8, minute: 0);
    _repeatInterval = r?.repeatInterval ?? RepeatInterval.none;
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await ContactService.loadAll();
    if (mounted) setState(() => _contacts = contacts);
  }

  @override
  void dispose() {
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _serviceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _selectContact(ContactModel c) {
    setState(() {
      _contactCtrl.text = c.nama;
      _phoneCtrl.text = c.telepon;
      _addressCtrl.text = c.alamat;
    });
  }

  Future<void> _showContactPicker() async {
    final selected = await showModalBottomSheet<ContactModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ContactManagerSheet(
        contacts: _contacts,
        onChanged: () => _loadContacts(),
      ),
    );
    if (selected != null) _selectContact(selected);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _reminderDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _contactCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();

    // Auto-save kontak
    await ContactService.saveIfNotExists(
      nama: name,
      npwp: '',
      alamat: address,
      telepon: phone,
    );

    final reminder = ReminderModel(
      id: widget.reminder?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      contactName: name,
      contactPhone: phone,
      contactAddress: address,
      serviceName: _serviceCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      reminderDate: _reminderDate,
      reminderHour: _reminderTime.hour,
      reminderMinute: _reminderTime.minute,
      repeatInterval: _repeatInterval,
      docType: widget.reminder?.docType,
      lastItems: widget.reminder?.lastItems ?? const [],
      createdAt: widget.reminder?.createdAt,
    );
    if (mounted) Navigator.pop(context, reminder);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? tr('reminder.edit_title') : tr('reminder.add_title'),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: tr('common.close'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _contactCtrl,
                    decoration: InputDecoration(labelText: tr('reminder.customer_name')),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? tr('common.required') : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showContactPicker,
                  icon: const Icon(Icons.contacts_outlined),
                  tooltip: tr('reminder.pick_contact'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              decoration: InputDecoration(
                labelText: tr('reminder.phone'),
                hintText: tr('reminder.phone_hint'),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressCtrl,
              decoration: InputDecoration(
                labelText: tr('reminder.address'),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _serviceCtrl,
              decoration: InputDecoration(
                labelText: tr('reminder.service_type'),
                hintText: tr('reminder.service_hint'),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? tr('common.required') : null,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _presetServiceKeys.map((key) {
                final s = tr(key);
                return ActionChip(
                  label: Text(s),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _serviceCtrl.text = s),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: tr('reminder.date'),
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(_dateFormat.format(_reminderDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: tr('reminder.time'),
                        suffixIcon: Icon(Icons.access_time, size: 18),
                      ),
                      child: Text(_reminderTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _quickDateChip(trN('reminder.months', 1), 30),
                _quickDateChip(trN('reminder.months', 2), 60),
                _quickDateChip(trN('reminder.months', 3), 90),
                _quickDateChip(trN('reminder.months', 6), 180),
                _quickDateChip(tr('reminder.one_year'), 365),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<RepeatInterval>(
              initialValue: _repeatInterval,
              decoration: InputDecoration(
                labelText: tr('reminder.repeat'),
                prefixIcon: Icon(Icons.repeat, size: 20),
              ),
              items: RepeatInterval.values
                  .map((r) => DropdownMenuItem(
                      value: r, child: Text(tr('reminder.repeat_${r.name}'))))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _repeatInterval = v);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: tr('reminder.notes_optional'),
                hintText: tr('reminder.notes_hint'),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: Icon(_isEditing ? Icons.save : Icons.alarm_add),
                label: Text(_isEditing ? tr('reminder.save_edit') : tr('reminder.save')),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickDateChip(String label, int days) {
    return ActionChip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      onPressed: () =>
          setState(() => _reminderDate = DateTime.now().add(Duration(days: days))),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact Manager Sheet (pick, add, edit, delete)
// ─────────────────────────────────────────────────────────────────────────────

class _ContactManagerSheet extends StatefulWidget {
  final List<ContactModel> contacts;
  final VoidCallback onChanged;

  const _ContactManagerSheet({
    required this.contacts,
    required this.onChanged,
  });

  @override
  State<_ContactManagerSheet> createState() => _ContactManagerSheetState();
}

class _ContactManagerSheetState extends State<_ContactManagerSheet> {
  late List<ContactModel> _contacts;
  List<ContactModel> _filtered = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _contacts = List.from(widget.contacts);
    _filtered = _contacts;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _contacts;
      } else {
        final q = query.toLowerCase();
        _filtered = _contacts
            .where((c) =>
                c.nama.toLowerCase().contains(q) ||
                c.telepon.contains(q))
            .toList();
      }
    });
  }

  Future<void> _reload() async {
    final contacts = await ContactService.loadAll();
    widget.onChanged();
    if (mounted) {
      setState(() {
        _contacts = contacts;
        _onSearch(_searchCtrl.text);
      });
    }
  }

  Future<void> _addContact() async {
    final result = await showModalBottomSheet<ContactModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ContactFormSheet(),
    );
    if (result != null) {
      await ContactService.save(result);
      await _reload();
    }
  }

  Future<void> _editContact(ContactModel contact) async {
    final result = await showModalBottomSheet<ContactModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ContactFormSheet(contact: contact),
    );
    if (result != null) {
      await ContactService.save(result);
      await _reload();
    }
  }

  Future<void> _deleteContact(ContactModel contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('contact.delete_title')),
        content: Text('${tr('common.delete')} "${contact.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('common.delete'),
                style: TextStyle(
                    color: AppColors.errorFor(Theme.of(ctx).brightness))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ContactService.delete(contact.id);
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = AppColors.errorFor(theme.brightness);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(tr('contact.title'),
                            style: theme.textTheme.titleMedium),
                      ),
                      TextButton.icon(
                        onPressed: _addContact,
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: Text(tr('contact.add')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: tr('contact.search'),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _contacts.isEmpty
                                  ? tr('contact.empty')
                                  : tr('contact.not_found'),
                              style: theme.textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            if (_contacts.isEmpty) ...[
                              const SizedBox(height: 4),
                              Text(tr('contact.empty_hint'),
                                  style: theme.textTheme.bodySmall,
                                  textAlign: TextAlign.center),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 24),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (_, i) {
                        final c = _filtered[i];
                        final initials = c.nama.isNotEmpty
                            ? c.nama
                                .split(' ')
                                .take(2)
                                .map((w) =>
                                    w.isNotEmpty ? w[0].toUpperCase() : '')
                                .join()
                            : '?';
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            child: Text(initials),
                          ),
                          title: Text(c.nama,
                              style: theme.textTheme.titleSmall),
                          subtitle: c.telepon.isNotEmpty
                              ? Text(c.telepon,
                                  style: theme.textTheme.bodySmall)
                              : null,
                          onTap: () => Navigator.pop(context, c),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (v) {
                              if (v == 'edit') _editContact(c);
                              if (v == 'delete') _deleteContact(c);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: const Icon(Icons.edit_outlined),
                                  title: Text(tr('common.edit')),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline,
                                      color: error),
                                  title: Text(tr('common.delete'),
                                      style: TextStyle(color: error)),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact Form Sheet (add / edit)
// ─────────────────────────────────────────────────────────────────────────────

class _ContactFormSheet extends StatefulWidget {
  final ContactModel? contact;

  const _ContactFormSheet({this.contact});

  @override
  State<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<_ContactFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _teleponCtrl;
  late final TextEditingController _alamatCtrl;

  bool get _isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.contact?.nama ?? '');
    _teleponCtrl = TextEditingController(text: widget.contact?.telepon ?? '');
    _alamatCtrl = TextEditingController(text: widget.contact?.alamat ?? '');
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _teleponCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final contact = ContactModel(
      id: widget.contact?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      nama: _namaCtrl.text.trim(),
      npwp: widget.contact?.npwp ?? '',
      telepon: _teleponCtrl.text.trim(),
      alamat: _alamatCtrl.text.trim(),
    );
    Navigator.pop(context, contact);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? tr('contact.edit_title') : tr('contact.add_title'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _namaCtrl,
                decoration: InputDecoration(labelText: tr('contact.name')),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? tr('common.required') : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _teleponCtrl,
                decoration: InputDecoration(
                  labelText: tr('reminder.phone'),
                  hintText: tr('reminder.phone_hint'),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _alamatCtrl,
                decoration: InputDecoration(
                  labelText: tr('reminder.address'),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: Icon(_isEditing ? Icons.save : Icons.person_add),
                  label: Text(_isEditing ? tr('common.save') : tr('contact.add_title')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
