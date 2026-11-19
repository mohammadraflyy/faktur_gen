import 'package:flutter/material.dart';
import '../main.dart';
import '../services/locale_service.dart';

enum PdfAction { print, download, whatsapp }

/// Bottom sheet with Print / Save and, optionally, WhatsApp.
/// Returns the chosen [PdfAction], or null when dismissed.
Future<PdfAction?> showPdfActionSheet(
  BuildContext context, {
  required String docName,
  bool showWhatsApp = false,
}) {
  return showModalBottomSheet<PdfAction>(
    context: context,
    showDragHandle: true,
    builder: (_) => _PdfActionSheet(docName: docName, showWhatsApp: showWhatsApp),
  );
}

class _PdfActionSheet extends StatelessWidget {
  final String docName;
  final bool showWhatsApp;
  const _PdfActionSheet({required this.docName, this.showWhatsApp = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(docName,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(tr('pdf.choose_action'), style: theme.textTheme.bodySmall),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.print,
                    label: tr('pdf.print'),
                    sublabel: tr('pdf.print_hint'),
                    color: theme.colorScheme.primary,
                    onTap: () => Navigator.pop(context, PdfAction.print),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.download,
                    label: tr('common.save'),
                    sublabel: tr('pdf.save_hint'),
                    color: AppColors.successFor(theme.brightness),
                    onTap: () => Navigator.pop(context, PdfAction.download),
                  ),
                ),
                if (showWhatsApp) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.chat,
                      label: 'WhatsApp',
                      sublabel: tr('pdf.whatsapp_hint'),
                      color: const Color(0xFF25D366),
                      onTap: () => Navigator.pop(context, PdfAction.whatsapp),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              // The label carries the meaning; the tinted icon is decoration.
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 10),
              Text(label,
                  style: theme.textTheme.titleSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text(sublabel,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
