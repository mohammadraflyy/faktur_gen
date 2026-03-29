import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../models/contact_model.dart';
import '../models/reminder_model.dart';
import '../services/contact_service.dart';
import '../services/locale_service.dart';
import '../services/reminder_service.dart';
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
  late TabController _tabCtrl;

  final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await ReminderService.loadAll();
      if (mounted) setState(() { _reminders = list; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('[Reminder] load error: $e');
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
          content: Text('${r.serviceName} untuk ${r.contactName} ${tr('reminder.marked_done')}'),
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

    final message = 'Halo ${r.contactName}, ini pengingat untuk layanan '
        '*${r.serviceName}* yang dijadwalkan tanggal '
        '${_dateFormat.format(r.reminderDate)}.'
        '${r.notes.isNotEmpty ? '\n\nCatatan: ${r.notes}' : ''}'
        '\n\nTerima kasih 🙏';

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

  void _showDetail(ReminderModel r) {
    final theme = Theme.of(context);
    final isOverdue = r.isOverdue;
    final isDue = r.isDue && !isOverdue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  tr('reminder.detail_title'),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _detailRow(theme, Icons.person_outlined, tr('reminder.customer'), r.contactName),
                if (r.contactPhone.isNotEmpty)
                  _detailRow(theme, Icons.phone_outlined, tr('common.phone'), r.contactPhone),
                if (r.contactAddress.isNotEmpty)
                  _detailRow(theme, Icons.location_on_outlined, tr('common.address'), r.contactAddress),
                _detailRow(theme, Icons.build_outlined, tr('reminder.service'), r.serviceName),
                _detailRow(
                  theme,
                  Icons.calendar_today,
                  tr('reminder.date'),
                  '${_dateFormat.format(r.reminderDate)}, '
                      '${r.reminderHour.toString().padLeft(2, '0')}:'
                      '${r.reminderMinute.toString().padLeft(2, '0')}',
                ),
                if (r.isRepeating)
                  _detailRow(theme, Icons.repeat, tr('reminder.repeat'), r.repeatInterval.label),
                if (r.notes.isNotEmpty)
                  _detailRow(theme, Icons.notes_outlined, tr('reminder.notes'), r.notes),
                _detailRow(
                  theme,
                  Icons.info_outline,
                  tr('reminder.status'),
                  isOverdue
                      ? tr('reminder.overdue')
                      : isDue
                          ? tr('reminder.due_today')
                          : r.status == ReminderStatus.pending
                              ? tr('reminder.waiting')
                              : tr('reminder.done'),
                ),
                const SizedBox(height: 16),
                // Actions
                if (r.contactPhone.isNotEmpty)
                  _actionTile(
                    theme,
                    icon: Icons.message_rounded,
                    label: tr('reminder.send_wa'),
                    color: const Color(0xFF25D366),
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
                    color: r.docType == ReminderDocType.struk
                        ? const Color(0xFF059669)
                        : const Color(0xFF2563EB),
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
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _markDone(r);
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(tr('reminder.mark_done')),
                    ),
                  ),
                ],
                _actionTile(
                  theme,
                  icon: Icons.delete_outline,
                  label: tr('common.delete'),
                  color: Colors.red,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c.withValues(alpha: 0.7)),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: c,
              ),
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
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.5,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPending ? Icons.notifications_none : Icons.check_circle_outline,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPending
                          ? tr('reminder.empty_pending')
                          : tr('reminder.empty_done'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 8),
                      Text(
                        tr('reminder.add_hint'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 80),
        itemCount: list.length,
        itemBuilder: (_, i) => _buildCard(theme, list[i], isPending: isPending),
      ),
    );
  }

  Widget _buildCard(ThemeData theme, ReminderModel r,
      {required bool isPending}) {
    final isOverdue = r.isOverdue;
    final isDue = r.isDue && !isOverdue;

    final errColor = AppColors.errorFor(theme.brightness);
    final warnColor = AppColors.warningFor(theme.brightness);

    Color accentColor;
    if (isOverdue) {
      accentColor = errColor;
    } else if (isDue) {
      accentColor = warnColor;
    } else {
      accentColor = theme.colorScheme.primary;
    }

    final card = GestureDetector(
      onTap: () => _showDetail(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isOverdue || isDue)
                ? accentColor.withValues(alpha: 0.4)
                : theme.dividerTheme.color ?? Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            // Left accent icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.notifications_active_outlined,
                size: 20,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.contactName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOverdue || isDue)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOverdue ? tr('reminder.overdue') : tr('dashboard.today'),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    r.serviceName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.35)),
                      const SizedBox(width: 4),
                      Text(
                        '${_dateFormat.format(r.reminderDate)}, ${r.reminderHour.toString().padLeft(2, '0')}:${r.reminderMinute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      if (r.isRepeating) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.repeat,
                            size: 11,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.5)),
                        const SizedBox(width: 3),
                        Text(
                          r.repeatInterval.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Chevron hint
            Icon(Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );

    if (!isPending) {
      // Completed: swipe left to delete only
      return Dismissible(
        key: ValueKey(r.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDelete(r),
        background: _swipeBackground(
          alignment: Alignment.centerRight,
          color: errColor,
          icon: Icons.delete_outline,
        ),
        child: card,
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
      background: _swipeBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.successFor(theme.brightness),
        icon: Icons.check_rounded,
      ),
      secondaryBackground: _swipeBackground(
        alignment: Alignment.centerRight,
        color: errColor,
        icon: Icons.delete_outline,
      ),
      child: card,
    );
  }

  Future<bool> _confirmDelete(ReminderModel r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('reminder.delete_title')),
        content:
            Text('${tr('common.delete')} "${r.serviceName}" untuk ${r.contactName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('common.delete'), style: const TextStyle(color: Colors.red)),
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

  Widget _swipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(icon, color: color, size: 24),
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

  final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  final _presetServices = [
    'Cuci AC',
    'Service AC',
    'Ganti Filter AC',
    'Perawatan Rutin',
    'Service Mesin',
    'Pengecekan Berkala',
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                Expanded(
                  child: Text(
                    _isEditing ? tr('reminder.edit_title') : tr('reminder.add_title'),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
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
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showContactPicker,
                  icon: const Icon(Icons.contacts_outlined),
                  tooltip: tr('reminder.pick_contact'),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                  ),
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
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _presetServices.map((s) {
                return ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
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
                      child: Text(
                        _dateFormat.format(_reminderDate),
                        style: const TextStyle(fontSize: 14),
                      ),
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
                      child: Text(
                        _reminderTime.format(context),
                        style: const TextStyle(fontSize: 14),
                      ),
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
                _quickDateChip('1 Bulan', 30),
                _quickDateChip('2 Bulan', 60),
                _quickDateChip('3 Bulan', 90),
                _quickDateChip('6 Bulan', 180),
                _quickDateChip('1 Tahun', 365),
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
                  .map((r) =>
                      DropdownMenuItem(value: r, child: Text(r.label)))
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
      label: Text(label, style: const TextStyle(fontSize: 11)),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
            child: Text(tr('common.delete'), style: const TextStyle(color: Colors.red)),
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
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      expand: false,
      builder: (context, scrollController) {
        return Column(
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
                      Icon(Icons.contacts_rounded,
                          color: theme.colorScheme.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        tr('contact.title'),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addContact,
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: Text(tr('contact.add'), style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: tr('contact.search'),
                      hintStyle: GoogleFonts.inter(
                          fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_off_outlined,
                              size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
                          const SizedBox(height: 8),
                          Text(
                            _contacts.isEmpty
                                ? tr('contact.empty')
                                : tr('contact.not_found'),
                            style: GoogleFonts.inter(
                                fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
                          ),
                          if (_contacts.isEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Tap "Tambah" untuk menambah kontak baru',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
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
                            child: Text(initials,
                                style: const TextStyle(fontSize: 12)),
                          ),
                          title: Text(c.nama,
                              style: const TextStyle(fontSize: 14)),
                          subtitle: c.telepon.isNotEmpty
                              ? Text(c.telepon,
                                  style: const TextStyle(fontSize: 12))
                              : null,
                          dense: true,
                          onTap: () => Navigator.pop(context, c),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert,
                                size: 18,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4)),
                            onSelected: (v) {
                              if (v == 'edit') _editContact(c);
                              if (v == 'delete') _deleteContact(c);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: const Icon(Icons.edit_outlined, size: 20),
                                  title: Text(tr('common.edit'),
                                      style: const TextStyle(fontSize: 14)),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: const Icon(Icons.delete_outline,
                                      size: 20, color: Colors.red),
                                  title: Text(tr('common.delete'),
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.red)),
                                  dense: true,
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
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(
                _isEditing ? tr('contact.edit_title') : tr('contact.add_title'),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _namaCtrl,
                decoration: InputDecoration(labelText: tr('contact.name')),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
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
