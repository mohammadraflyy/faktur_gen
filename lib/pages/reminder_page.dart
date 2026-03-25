import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../models/contact_model.dart';
import '../models/reminder_model.dart';
import '../services/contact_service.dart';
import '../services/notification_service.dart';
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
    final list = await ReminderService.loadAll();
    if (mounted) setState(() { _reminders = list; _isLoading = false; });
  }

  List<ReminderModel> get _pending =>
      _reminders.where((r) => r.status == ReminderStatus.pending).toList();

  List<ReminderModel> get _completed =>
      _reminders.where((r) => r.status != ReminderStatus.pending).toList();

  Future<void> _addReminder() async {
    final result = await showModalBottomSheet<ReminderModel>(
      context: context,
      isScrollControlled: true,
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
    _load();
  }

  Future<void> _editReminder(ReminderModel r) async {
    final result = await showModalBottomSheet<ReminderModel>(
      context: context,
      isScrollControlled: true,
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

  Future<void> _deleteReminder(ReminderModel r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengingat?'),
        content: Text('Hapus pengingat "${r.serviceName}" untuk ${r.contactName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ReminderService.delete(r.id);
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
        const SnackBar(content: Text('Nomor telepon tidak tersedia')),
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
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
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
                  'Detail Pengingat',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _detailRow(theme, Icons.person_outlined, 'Pelanggan', r.contactName),
                if (r.contactPhone.isNotEmpty)
                  _detailRow(theme, Icons.phone_outlined, 'Telepon', r.contactPhone),
                if (r.contactAddress.isNotEmpty)
                  _detailRow(theme, Icons.location_on_outlined, 'Alamat', r.contactAddress),
                _detailRow(theme, Icons.build_outlined, 'Layanan', r.serviceName),
                _detailRow(
                  theme,
                  Icons.calendar_today,
                  'Tanggal',
                  '${_dateFormat.format(r.reminderDate)}, '
                      '${r.reminderHour.toString().padLeft(2, '0')}:'
                      '${r.reminderMinute.toString().padLeft(2, '0')}',
                ),
                if (r.isRepeating)
                  _detailRow(theme, Icons.repeat, 'Ulangi', r.repeatInterval.label),
                if (r.notes.isNotEmpty)
                  _detailRow(theme, Icons.notes_outlined, 'Catatan', r.notes),
                _detailRow(
                  theme,
                  Icons.info_outline,
                  'Status',
                  isOverdue
                      ? 'Terlewat'
                      : isDue
                          ? 'Jatuh tempo hari ini'
                          : r.status == ReminderStatus.pending
                              ? 'Menunggu'
                              : 'Selesai',
                ),
                const SizedBox(height: 16),
                // Edit button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editReminder(r);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Pengingat'),
                  ),
                ),
                const SizedBox(height: 8),
                // WhatsApp button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _sendWhatsApp(r);
                    },
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('Kirim WhatsApp'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (r.status == ReminderStatus.pending) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _reschedule(r);
                            },
                            icon: const Icon(Icons.event_repeat, size: 14),
                            label: const Text('Jadwal Ulang',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _markDone(r);
                            },
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text('Selesai',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengingat Layanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Test Notifikasi',
            onPressed: () async {
              await NotificationService.showTestNotification();
              final pending = await NotificationService.getPending();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Test notifikasi dikirim! (${pending.length} terjadwal)'),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(text: 'Aktif (${_pending.length})'),
            Tab(text: 'Selesai (${_completed.length})'),
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
      return Center(
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
                  ? 'Belum ada pengingat'
                  : 'Belum ada pengingat selesai',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            if (isPending) ...[
              const SizedBox(height: 8),
              Text(
                'Tap + untuk menambah pengingat',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildCard(theme, list[i], isPending: isPending),
    );
  }

  Widget _buildCard(ThemeData theme, ReminderModel r,
      {required bool isPending}) {
    final isOverdue = r.isOverdue;
    final isDue = r.isDue && !isOverdue;

    final errColor = AppColors.errorFor(theme.brightness);
    final warnColor = AppColors.warningFor(theme.brightness);

    Color borderColor;
    if (isOverdue) {
      borderColor = errColor.withValues(alpha: 0.4);
    } else if (isDue) {
      borderColor = warnColor.withValues(alpha: 0.4);
    } else {
      borderColor = theme.dividerTheme.color ?? Colors.grey.shade200;
    }

    return GestureDetector(
      onTap: () => _showDetail(r),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (isOverdue
                          ? errColor
                          : isDue
                              ? warnColor
                              : theme.colorScheme.primary)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  size: 18,
                  color: isOverdue
                      ? errColor
                      : isDue
                          ? warnColor
                          : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.contactName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (r.contactPhone.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        r.contactPhone,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      r.serviceName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isPending)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                  onSelected: (v) {
                    if (v == 'edit') _editReminder(r);
                    if (v == 'done') _markDone(r);
                    if (v == 'reschedule') _reschedule(r);
                    if (v == 'delete') _deleteReminder(r);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined, size: 20),
                        title: Text('Edit',
                            style: TextStyle(fontSize: 14)),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'done',
                      child: ListTile(
                        leading: Icon(Icons.check_circle_outline, size: 20),
                        title: Text('Tandai Selesai',
                            style: TextStyle(fontSize: 14)),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reschedule',
                      child: ListTile(
                        leading: Icon(Icons.event_repeat, size: 20),
                        title: Text('Jadwal Ulang',
                            style: TextStyle(fontSize: 14)),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading:
                            Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        title: Text('Hapus',
                            style: TextStyle(fontSize: 14, color: Colors.red)),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.grey),
                  onPressed: () => _deleteReminder(r),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 13,
                  color: isOverdue
                      ? errColor
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 6),
              Text(
                '${_dateFormat.format(r.reminderDate)}, ${r.reminderHour.toString().padLeft(2, '0')}:${r.reminderMinute.toString().padLeft(2, '0')}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isOverdue
                      ? errColor
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              if (isOverdue) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: errColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Terlewat',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: errColor,
                    ),
                  ),
                ),
              ] else if (isDue) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: warnColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Hari ini',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: warnColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (r.isRepeating) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.repeat, size: 13,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(
                  r.repeatInterval.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
          if (r.contactAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r.contactAddress,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (r.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              r.notes,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (isPending) ...[
            if (r.hasLastItems) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 34,
                child: OutlinedButton.icon(
                  onPressed: () => _createDocFromReminder(r),
                  icon: Icon(
                    r.docType == ReminderDocType.struk
                        ? Icons.receipt_outlined
                        : Icons.receipt_long_outlined,
                    size: 14,
                  ),
                  label: Text(
                    r.docType == ReminderDocType.struk
                        ? 'Buat Struk'
                        : 'Buat Invoice',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: r.docType == ReminderDocType.struk
                        ? const Color(0xFF059669)
                        : const Color(0xFF2563EB),
                    side: BorderSide(
                      color: r.docType == ReminderDocType.struk
                          ? const Color(0xFF059669)
                          : const Color(0xFF2563EB),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (r.contactPhone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: () => _sendWhatsApp(r),
                    icon: const Icon(Icons.message, size: 14),
                    label: const Text('Kirim WhatsApp',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(
                          color: Color(0xFF25D366), width: 0.8),
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: OutlinedButton.icon(
                      onPressed: () => _reschedule(r),
                      icon: const Icon(Icons.event_repeat, size: 14),
                      label: const Text('Jadwal Ulang',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: FilledButton.icon(
                      onPressed: () => _markDone(r),
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Selesai',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
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
            Text(
              _isEditing ? 'Edit Pengingat' : 'Tambah Pengingat',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _contactCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Pelanggan'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showContactPicker,
                  icon: const Icon(Icons.contacts_outlined),
                  tooltip: 'Pilih dari kontak',
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'No. Telepon / WhatsApp',
                hintText: 'cth: 08123456789',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Alamat (opsional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _serviceCtrl,
              decoration: const InputDecoration(
                labelText: 'Jenis Layanan',
                hintText: 'cth: Cuci AC, Service Mesin',
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
                      decoration: const InputDecoration(
                        labelText: 'Tanggal',
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
                      decoration: const InputDecoration(
                        labelText: 'Jam',
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
              decoration: const InputDecoration(
                labelText: 'Ulangi',
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
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'cth: Unit outdoor lantai 2',
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
                label: Text(_isEditing ? 'Simpan Perubahan' : 'Simpan Pengingat'),
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
        title: const Text('Hapus Kontak?'),
        content: Text('Hapus "${contact.nama}" dari daftar kontak?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
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
                        'Kontak',
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
                        label: const Text('Tambah', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau telepon...',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 13, color: const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
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
                              size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text(
                            _contacts.isEmpty
                                ? 'Belum ada kontak'
                                : 'Tidak ditemukan',
                            style: GoogleFonts.inter(
                                fontSize: 14, color: Colors.grey[400]),
                          ),
                          if (_contacts.isEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Tap "Tambah" untuk menambah kontak baru',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: Colors.grey[400]),
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
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined, size: 20),
                                  title: Text('Edit',
                                      style: TextStyle(fontSize: 14)),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline,
                                      size: 20, color: Colors.red),
                                  title: Text('Hapus',
                                      style: TextStyle(
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
                _isEditing ? 'Edit Kontak' : 'Tambah Kontak',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _teleponCtrl,
                decoration: const InputDecoration(
                  labelText: 'No. Telepon / WhatsApp',
                  hintText: 'cth: 08123456789',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _alamatCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alamat (opsional)',
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
                  label: Text(_isEditing ? 'Simpan' : 'Tambah Kontak'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
