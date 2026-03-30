import 'package:flutter/material.dart';

enum PdfAction { print, download, whatsapp }

/// Tampilkan bottom sheet pilihan Print / Download / WhatsApp.
/// Mengembalikan [PdfAction] yang dipilih, atau null jika dibatalkan.
Future<PdfAction?> showPdfActionSheet(
  BuildContext context, {
  required String docName,
  bool showWhatsApp = false,
}) {
  return showModalBottomSheet<PdfAction>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              docName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih aksi yang ingin dilakukan',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.print,
                    label: 'Print',
                    sublabel: 'Cetak via printer',
                    color: theme.colorScheme.primary,
                    onTap: () => Navigator.pop(context, PdfAction.print),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.download,
                    label: 'Download',
                    sublabel: 'Simpan / bagikan PDF',
                    color: const Color(0xFF2E7D32),
                    onTap: () => Navigator.pop(context, PdfAction.download),
                  ),
                ),
                if (showWhatsApp) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.chat,
                      label: 'WhatsApp',
                      sublabel: 'Kirim ke klien',
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
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
