import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../services/locale_service.dart';

class PdfPreviewPage extends StatelessWidget {
  final String title;
  final String filename;
  final LayoutCallback buildPdf;

  /// Set ke false untuk dokumen dengan format tetap seperti struk 80mm.
  final bool canChangePageFormat;

  /// Format awal halaman. A4 untuk faktur, custom untuk struk.
  final PdfPageFormat initialPageFormat;

  const PdfPreviewPage({
    super.key,
    required this.title,
    required this.filename,
    required this.buildPdf,
    this.canChangePageFormat = true,
    this.initialPageFormat = PdfPageFormat.a4,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton.icon(
            // Caller decides what to close next; popping twice here also
            // closed MainNavigation when opened from History.
            onPressed: () => Navigator.of(context).pop(true),
            icon: Icon(Icons.check_rounded,
                color: theme.colorScheme.primary, size: 20),
            label: Text(tr('common.done'),
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: PdfPreview(
            build: buildPdf,
            pdfFileName: filename,
            initialPageFormat: initialPageFormat,
            canChangePageFormat: canChangePageFormat,
            canChangeOrientation: canChangePageFormat,
            canDebug: false,
            allowPrinting: true,
            allowSharing: true,
            dynamicLayout: true,
          ),
        ),
      ),
    );
  }
}
