import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../main.dart';
import '../models/reminder_model.dart';
import '../services/locale_service.dart';
import '../services/reminder_service.dart';
import '../services/whatsapp_service.dart';
import '../widgets/pdf_action_sheet.dart';
import 'pdf_preview_page.dart';

/// Shown once an invoice or receipt is saved: send it, set a reminder, or
/// finish. Viewing the PDF itself stays in [PdfPreviewPage].
class DocumentReadyPage extends StatefulWidget {
  final String title;
  final String summary;
  final String shareMessage;
  final PdfPreviewPage preview;
  final ReminderModel reminder;
  final String reminderLabel;

  const DocumentReadyPage({
    super.key,
    required this.title,
    required this.summary,
    required this.shareMessage,
    required this.preview,
    required this.reminder,
    required this.reminderLabel,
  });

  @override
  State<DocumentReadyPage> createState() => _DocumentReadyPageState();
}

class _DocumentReadyPageState extends State<DocumentReadyPage>
    with SingleTickerProviderStateMixin {
  late final _check = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200));
  late final _scale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _check, curve: Easing.emphasizedDecelerate));
  bool _busy = false;
  bool _remind = false;
  bool _savingReminder = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery is not readable in initState; start the check only once.
    if (_check.status != AnimationStatus.dismissed) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _check.value = 1;
    } else {
      _check.forward();
    }
  }

  @override
  void dispose() {
    _check.dispose();
    super.dispose();
  }

  Future<Uint8List> _bytes() async =>
      widget.preview.buildPdf(widget.preview.initialPageFormat);

  /// Keeps the share buttons disabled while the PDF is built and handed off.
  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendWhatsApp() => _run(() async => WhatsAppService.sharePdf(
        pdfBytes: await _bytes(),
        filename: widget.preview.filename,
        message: widget.shareMessage,
      ));

  Future<void> _showMore() async {
    final action =
        await showPdfActionSheet(context, docName: widget.preview.filename);
    if (!mounted) return;
    switch (action) {
      case PdfAction.print:
        await _run(() => Printing.layoutPdf(
            onLayout: widget.preview.buildPdf, name: widget.preview.filename));
      case PdfAction.download:
        await _run(() async => Printing.sharePdf(
            bytes: await _bytes(), filename: widget.preview.filename));
      case PdfAction.whatsapp:
      case null:
        break;
    }
  }

  Future<void> _toggleReminder(bool on) async {
    setState(() => _savingReminder = true);
    try {
      if (on) {
        await ReminderService.add(widget.reminder);
      } else {
        await ReminderService.delete(widget.reminder.id);
      }
      if (mounted) setState(() => _remind = on);
    } finally {
      if (mounted) setState(() => _savingReminder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.reminder;
    final remindAt = DateTime(r.reminderDate.year, r.reminderDate.month,
        r.reminderDate.day, r.reminderHour, r.reminderMinute);
    final dateLocale = LocaleService.isEn ? 'en_US' : 'id_ID';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Icon(Icons.check_circle_rounded,
                      size: 64, color: AppColors.successFor(theme.brightness)),
                ),
                const SizedBox(height: 16),
                Text(widget.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(widget.summary,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 32),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  onPressed: _busy ? null : _sendWhatsApp,
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(tr('done.whatsapp')),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : _showMore,
                  child: Text(tr('done.more')),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Text(tr('done.view_pdf')),
                  subtitle: Text(widget.preview.filename),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => widget.preview)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(widget.reminderLabel),
                  subtitle: Text(DateFormat('d MMM yyyy, HH:mm', dateLocale)
                      .format(remindAt)),
                  value: _remind,
                  onChanged: _savingReminder ? null : _toggleReminder,
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.pop(context),
            child: Text(tr('common.done')),
          ),
        ),
      ),
    );
  }
}
