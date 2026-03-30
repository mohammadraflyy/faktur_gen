import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/doc_template_config.dart';
import '../models/faktur_model.dart';
import '../models/settings_model.dart';

class PdfService {
  static NumberFormat _currencyOf(FakturModel f) {
    String symbol;
    String locale;
    switch (f.currency) {
      case 'USD':
        symbol = '\$ ';
        locale = 'en_US';
      case 'EUR':
        symbol = '\u20AC ';
        locale = 'de_DE';
      default:
        symbol = 'Rp ';
        locale = 'id_ID';
    }
    return NumberFormat.currency(locale: locale, symbol: symbol, decimalDigits: 0);
  }

  static final _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
  static final _numFormat = NumberFormat('#,##0.##', 'id_ID');

  static const _textDark = PdfColor.fromInt(0xFF1A1A1A);
  static const _textGrey = PdfColor.fromInt(0xFF757575);

  // Template-aware colors
  static PdfColor _primary(DocTemplateConfig? tpl) =>
      PdfColor.fromInt(tpl?.primaryColorValue ?? 0xFF1565C0);
  static PdfColor _primaryLight(DocTemplateConfig? tpl) {
    final c = tpl?.primaryColorValue ?? 0xFF1565C0;
    // Lighten: mix with white at ~90%
    final r = ((c >> 16) & 0xFF);
    final g = ((c >> 8) & 0xFF);
    final b = (c & 0xFF);
    return PdfColor(
      (r + (255 - r) * 0.88) / 255,
      (g + (255 - g) * 0.88) / 255,
      (b + (255 - b) * 0.88) / 255,
    );
  }

  static String _filename(FakturModel f) =>
      'Invoice_${f.nomorFaktur.replaceAll('/', '-')}.pdf';

  static Future<Uint8List> buildBytes(
    FakturModel faktur,
    PdfPageFormat format, {
    Uint8List? logoBytes,
    Uint8List? signatureBytes,
    bool isPaid = false,
    bool showQr = false,
    DocTemplateConfig? templateConfig,
    bool showWatermark = false,
    String? qrisMerchantId,
  }) async =>
      _buildDocument(faktur,
              format: format,
              logoBytes: logoBytes,
              signatureBytes: signatureBytes,
              isPaid: isPaid,
              showQr: showQr,
              tpl: templateConfig,
              showWatermark: showWatermark,
              qrisMerchantId: qrisMerchantId)
          .save();

  static Future<void> print(FakturModel faktur, {Uint8List? logoBytes}) async {
    final doc = _buildDocument(faktur, logoBytes: logoBytes);
    await Printing.layoutPdf(
        onLayout: (f) async => doc.save(), name: _filename(faktur));
  }

  static Future<void> download(FakturModel faktur,
      {Uint8List? logoBytes}) async {
    final doc = _buildDocument(faktur, logoBytes: logoBytes);
    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: _filename(faktur));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Document builder
  // ─────────────────────────────────────────────────────────────────────────

  static pw.Document _buildDocument(
    FakturModel faktur, {
    PdfPageFormat format = PdfPageFormat.a4,
    Uint8List? logoBytes,
    Uint8List? signatureBytes,
    bool isPaid = false,
    bool showQr = false,
    DocTemplateConfig? tpl,
    bool showWatermark = false,
    String? qrisMerchantId,
  }) {
    final showLogo = tpl?.showLogo ?? true;
    final showSig = tpl?.showSignature ?? true;
    final showBank = tpl?.showBankInfo ?? true;
    final showNpwp = tpl?.showNpwp ?? true;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) {
          final cur = _currencyOf(faktur);
          return [
          _header(faktur, showLogo ? logoBytes : null, tpl),
          pw.SizedBox(height: 20),
          _billTo(faktur, tpl, showNpwp: showNpwp),
          pw.SizedBox(height: 20),
          _itemTable(faktur, cur, tpl),
          pw.SizedBox(height: 12),
          _totals(faktur, cur, tpl),
          if (isPaid) ...[
            pw.SizedBox(height: 12),
            _paidStamp(),
          ],
          pw.SizedBox(height: 24),
          if (showBank && faktur.bankAccounts.isNotEmpty) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: _paymentInfo(faktur.bankAccounts, tpl)),
                if (showQr && faktur.bankAccounts.isNotEmpty) ...[
                  pw.SizedBox(width: 16),
                  _qrCode(faktur.bankAccounts.first),
                ],
              ],
            ),
            pw.SizedBox(height: 24),
          ],
          _footer(faktur, signatureBytes: showSig ? signatureBytes : null, tpl: tpl),
          if (qrisMerchantId != null && qrisMerchantId.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Scan QRIS', style: const pw.TextStyle(fontSize: 8, color: _textGrey)),
                    pw.SizedBox(height: 4),
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: qrisMerchantId,
                      width: 80,
                      height: 80,
                    ),
                  ],
                ),
              ],
            ),
          ],
          if (showWatermark) ...[
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text(
                'Made with Faktura',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
              ),
            ),
          ],
        ];
        },
      ),
    );
    return pdf;
  }

  static pw.Widget _paidStamp() {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(
            color: const PdfColor.fromInt(0xFF16A34A),
            width: 2,
          ),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(
          'LUNAS',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF16A34A),
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }

  static pw.Widget _qrCode(BankAccount bank) {
    final data = '${bank.namaBank}\n${bank.nomorRekening}\na.n. ${bank.namaPemilik}';
    return pw.BarcodeWidget(
      barcode: pw.Barcode.qrCode(),
      data: data,
      width: 80,
      height: 80,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header: logo + company (kiri) | INVOICE + nomor/tanggal (kanan)
  // ─────────────────────────────────────────────────────────────────────────

  static pw.Widget _header(FakturModel f, Uint8List? logoBytes, DocTemplateConfig? tpl) {
    final color = _primary(tpl);
    final style = tpl?.invoiceTemplate ?? InvoiceTemplate.modern;
    final isMinimal = style == InvoiceTemplate.minimal;
    final isClassic = style == InvoiceTemplate.classic;
    final logoCenter = tpl?.logoCenter ?? false;

    final companyInfo = pw.Column(
      crossAxisAlignment: logoCenter
          ? pw.CrossAxisAlignment.center
          : pw.CrossAxisAlignment.start,
      children: [
        if (logoBytes != null) ...[
          pw.Image(pw.MemoryImage(logoBytes), width: 60, height: 60),
          pw.SizedBox(height: 8),
        ],
        pw.Text(
          f.namaPenjual.isEmpty ? 'Nama Perusahaan' : f.namaPenjual,
          style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _textDark),
        ),
        if (f.alamatPenjual.isNotEmpty)
          pw.Text(f.alamatPenjual,
              style: const pw.TextStyle(fontSize: 9, color: _textGrey)),
        if (f.teleponPenjual.isNotEmpty)
          pw.Text(f.teleponPenjual,
              style: const pw.TextStyle(fontSize: 9, color: _textGrey)),
        if (f.emailPenjual.isNotEmpty)
          pw.Text(f.emailPenjual,
              style: const pw.TextStyle(fontSize: 9, color: _textGrey)),
        if (f.npwpPenjual.isNotEmpty)
          pw.Text('NPWP: ${f.npwpPenjual}',
              style: const pw.TextStyle(fontSize: 9, color: _textGrey)),
      ],
    );

    final invoiceTitle = isMinimal
        ? pw.Text('INVOICE',
            style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: _textDark,
                letterSpacing: 2))
        : isClassic
            ? pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: color, width: 2),
                ),
                child: pw.Text('INVOICE',
                    style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: color)),
              )
            : pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: pw.BoxDecoration(color: color),
                child: pw.Text('INVOICE',
                    style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
              );

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: companyInfo),
        pw.SizedBox(width: 24),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            invoiceTitle,
            pw.SizedBox(height: 10),
            _detailRow('No. Invoice', f.nomorFaktur.isEmpty ? '-' : f.nomorFaktur),
            pw.SizedBox(height: 4),
            _detailRow('Tanggal', _dateFormat.format(f.tanggal)),
            if (f.jatuhTempo != null) ...[
              pw.SizedBox(height: 4),
              _detailRow('Jatuh Tempo', _dateFormat.format(f.jatuhTempo!)),
            ],
          ],
        ),
      ],
    );
  }

  static pw.Widget _detailRow(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$label  ',
            style: const pw.TextStyle(fontSize: 9, color: _textGrey)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _textDark)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bill To
  // ─────────────────────────────────────────────────────────────────────────

  static pw.Widget _billTo(FakturModel f, DocTemplateConfig? tpl, {bool showNpwp = true}) {
    final color = _primary(tpl);
    final light = _primaryLight(tpl);
    final style = tpl?.invoiceTemplate ?? InvoiceTemplate.modern;
    final isMinimal = style == InvoiceTemplate.minimal;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: isMinimal
          ? pw.BoxDecoration(
              border: pw.Border(
                  top: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  bottom: const pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            )
          : pw.BoxDecoration(
              color: light,
              border: pw.Border(left: pw.BorderSide(color: color, width: 3)),
            ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('TAGIHAN KEPADA',
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: isMinimal ? _textGrey : color,
                  letterSpacing: 1)),
          pw.SizedBox(height: 6),
          pw.Text(
            f.namaPembeli.isEmpty ? '-' : f.namaPembeli,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _textDark),
          ),
          if (showNpwp && f.npwpPembeli.isNotEmpty)
            pw.Text('NPWP: ${f.npwpPembeli}',
                style: const pw.TextStyle(fontSize: 9, color: _textGrey)),
          if (f.alamatPembeli.isNotEmpty)
            pw.Text(f.alamatPembeli,
                style: const pw.TextStyle(fontSize: 9, color: _textGrey)),
          if (f.teleponPembeli.isNotEmpty)
            pw.Text('Telp: ${f.teleponPembeli}',
                style: const pw.TextStyle(fontSize: 9, color: _textGrey)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Items table
  // ─────────────────────────────────────────────────────────────────────────

  static pw.Widget _itemTable(FakturModel f, NumberFormat cur, DocTemplateConfig? tpl) {
    final color = _primary(tpl);
    final style = tpl?.invoiceTemplate ?? InvoiceTemplate.modern;
    final isMinimal = style == InvoiceTemplate.minimal;
    final isClassic = style == InvoiceTemplate.classic;

    const headers = ['No', 'Deskripsi', 'Qty', 'Satuan', 'Harga Satuan', 'Jumlah'];
    const widths = {
      0: pw.FlexColumnWidth(0.5),
      1: pw.FlexColumnWidth(3.5),
      2: pw.FlexColumnWidth(0.8),
      3: pw.FlexColumnWidth(0.8),
      4: pw.FlexColumnWidth(1.5),
      5: pw.FlexColumnWidth(1.5),
    };

    final headerBg = isMinimal
        ? PdfColors.white
        : isClassic
            ? PdfColors.grey200
            : color;
    final headerTextColor = isMinimal
        ? _textDark
        : isClassic
            ? _textDark
            : PdfColors.white;

    return pw.Table(
      columnWidths: widths,
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: isMinimal ? PdfColors.grey400 : color, width: 0.5),
        horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        top: isClassic ? const pw.BorderSide(color: PdfColors.grey400, width: 1) : pw.BorderSide.none,
      ),
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerBg),
          children: headers.map((h) {
            final isRight = ['Qty', 'Harga Satuan', 'Jumlah'].contains(h);
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              child: pw.Text(h,
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: headerTextColor),
                  textAlign:
                      isRight ? pw.TextAlign.right : pw.TextAlign.left),
            );
          }).toList(),
        ),
        // Data rows
        ...f.items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final isEven = i.isEven;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: isEven ? PdfColors.white : PdfColors.grey50),
            children: [
              _tc('${i + 1}', center: true),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.namaBarang.isEmpty ? '-' : item.namaBarang,
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    if (item.deskripsi.isNotEmpty)
                      pw.Text(item.deskripsi,
                          style: const pw.TextStyle(
                              fontSize: 8, color: _textGrey)),
                  ],
                ),
              ),
              _tc(_numFormat.format(item.kuantitas), right: true),
              _tc(item.satuan, center: true),
              _tc(cur.format(item.hargaSatuan), right: true),
              _tc(cur.format(item.jumlah), right: true),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tc(String text,
      {bool right = false, bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(text,
          style: const pw.TextStyle(fontSize: 9),
          textAlign: right
              ? pw.TextAlign.right
              : center
                  ? pw.TextAlign.center
                  : pw.TextAlign.left),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Totals (kanan bawah)
  // ─────────────────────────────────────────────────────────────────────────

  static pw.Widget _totals(FakturModel f, NumberFormat cur, DocTemplateConfig? tpl) {
    final color = _primary(tpl);
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 220,
        child: pw.Column(
          children: [
            _totalLine('DPP', f.totalDpp, cur),
            pw.Divider(color: PdfColors.grey300, height: 8),
            _totalLine('PPN (${f.taxRate % 1 == 0 ? f.taxRate.toInt() : f.taxRate}%)', f.totalPpn, cur),
            pw.Divider(color: color, height: 10, thickness: 1),
            _totalLine('TOTAL', f.totalTagihan, cur, bold: true, large: true, color: color),
          ],
        ),
      ),
    );
  }

  static pw.Widget _totalLine(String label, double value, NumberFormat cur,
      {bool bold = false, bool large = false, PdfColor? color}) {
    final sz = large ? 11.0 : 9.0;
    final fw = bold ? pw.FontWeight.bold : pw.FontWeight.normal;
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(fontSize: sz, fontWeight: fw, color: _textDark)),
        pw.Text(cur.format(value),
            style: pw.TextStyle(
                fontSize: sz,
                fontWeight: fw,
                color: bold ? (color ?? _textDark) : _textDark)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Payment info: bank account(s)
  // ─────────────────────────────────────────────────────────────────────────

  static pw.Widget _paymentInfo(List<BankAccount> banks, DocTemplateConfig? tpl) {
    final color = _primary(tpl);
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMASI PEMBAYARAN',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: banks.map((b) {
              return pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      b.namaBank,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    pw.Text(
                      b.nomorRekening,
                      style: const pw.TextStyle(fontSize: 9, color: _textDark),
                    ),
                    pw.Text(
                      'a.n. ${b.namaPemilik}',
                      style: const pw.TextStyle(fontSize: 8, color: _textGrey),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Footer: catatan (kiri) + tanda tangan (kanan)
  // ─────────────────────────────────────────────────────────────────────────

  static pw.Widget _footer(FakturModel f, {Uint8List? signatureBytes, DocTemplateConfig? tpl}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // Catatan
        pw.Expanded(
          child: f.catatan.isNotEmpty
              ? pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Catatan:',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: _textGrey)),
                    pw.SizedBox(height: 4),
                    pw.Text(f.catatan,
                        style:
                            const pw.TextStyle(fontSize: 9, color: _textGrey)),
                  ],
                )
              : pw.SizedBox(),
        ),
        pw.SizedBox(width: 40),
        // TTD
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Hormat kami,',
                style: const pw.TextStyle(fontSize: 9, color: _textGrey)),
            if (signatureBytes != null) ...[
              pw.SizedBox(height: 4),
              pw.Image(
                pw.MemoryImage(signatureBytes),
                width: 120,
                height: 50,
                fit: pw.BoxFit.contain,
              ),
              pw.SizedBox(height: 4),
            ] else
              pw.SizedBox(height: 36),
            pw.Container(
              width: 120,
              decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      top: pw.BorderSide(color: _textGrey, width: 0.5))),
              child: pw.Center(
                child: pw.Text(
                  f.namaPenjual.isEmpty ? '( ............. )' : f.namaPenjual,
                  style: const pw.TextStyle(fontSize: 8, color: _textDark),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
