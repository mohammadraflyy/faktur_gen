import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/struk_model.dart';

class StrukPdfService {
  static late NumberFormat _currency;

  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');

  // Lebar struk thermal 80mm
  static const _receiptWidth = 226.77; // 80mm in points

  static String _filename(StrukModel struk) =>
      'Struk_${struk.nomorStruk.replaceAll('/', '-')}.pdf';

  static void _initCurrency({String currencySymbol = 'Rp ', String currencyLocale = 'id_ID'}) {
    _currency = NumberFormat.currency(
      locale: currencyLocale,
      symbol: currencySymbol,
      decimalDigits: 0,
    );
  }

  /// Callback untuk PdfPreview.build — format diabaikan, struk selalu 80mm.
  // ignore: avoid_unused_parameters
  static Future<Uint8List> buildBytes(
    StrukModel struk,
    PdfPageFormat format, {
    Uint8List? logoBytes,
    String currencySymbol = 'Rp ',
    String currencyLocale = 'id_ID',
  }) async {
    _initCurrency(currencySymbol: currencySymbol, currencyLocale: currencyLocale);
    return _buildDocument(struk, logoBytes: logoBytes).save();
  }

  static pw.Document _buildDocument(StrukModel struk,
      {Uint8List? logoBytes}) {
    final pdf = pw.Document();
    final pageFormat = PdfPageFormat(
      _receiptWidth,
      double.infinity,
      marginAll: 12,
    );
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            _buildHeader(struk, logoBytes: logoBytes),
            _dashedLine(),
            _buildInfoStruk(struk),
            _dashedLine(),
            _buildItems(struk),
            _solidLine(),
            _buildSubtotal(struk),
            if (struk.diskon > 0) _buildDiskon(struk),
            _solidLine(),
            _buildTotal(struk),
            _dashedLine(),
            _buildPembayaran(struk),
            if (struk.catatan.isNotEmpty) ...[
              _dashedLine(),
              _buildCatatan(struk),
            ],
          ],
        ),
      ),
    );
    return pdf;
  }

  static Future<void> print(StrukModel struk, {
    Uint8List? logoBytes,
    String currencySymbol = 'Rp ',
    String currencyLocale = 'id_ID',
  }) async {
    _initCurrency(currencySymbol: currencySymbol, currencyLocale: currencyLocale);
    final doc = _buildDocument(struk, logoBytes: logoBytes);
    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: _filename(struk),
    );
  }

  static Future<void> download(StrukModel struk, {
    Uint8List? logoBytes,
    String currencySymbol = 'Rp ',
    String currencyLocale = 'id_ID',
  }) async {
    _initCurrency(currencySymbol: currencySymbol, currencyLocale: currencyLocale);
    final doc = _buildDocument(struk, logoBytes: logoBytes);
    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: _filename(struk));
  }

  static pw.Widget _buildHeader(StrukModel struk, {Uint8List? logoBytes}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logoBytes != null) ...[
          pw.Center(
            child: pw.Image(pw.MemoryImage(logoBytes), width: 50, height: 50),
          ),
          pw.SizedBox(height: 4),
        ],
        pw.Text(
          struk.namaToko.isEmpty ? 'NAMA TOKO' : struk.namaToko.toUpperCase(),
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        if (struk.alamatToko.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            struk.alamatToko,
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ],
        if (struk.teleponToko.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            'Telp: ${struk.teleponToko}',
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ],
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _buildInfoStruk(StrukModel struk) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 4),
        _infoLine('No. Struk', struk.nomorStruk),
        _infoLine('Tanggal', _dateFormat.format(struk.tanggal)),
        if (struk.namaKasir.isNotEmpty)
          _infoLine('Kasir', struk.namaKasir),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _infoLine(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  static pw.Widget _buildItems(StrukModel struk) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 4),
        ...struk.items.map((item) => _buildItemRow(item)),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _buildItemRow(ItemStruk item) {
    final qtyStr = item.kuantitas == item.kuantitas.truncateToDouble()
        ? item.kuantitas.toInt().toString()
        : item.kuantitas.toString();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          item.nama.isEmpty ? '(item)' : item.nama,
          style: const pw.TextStyle(fontSize: 9),
        ),
        if (item.deskripsi.isNotEmpty)
          pw.Text(
            '  ${item.deskripsi}',
            style: const pw.TextStyle(fontSize: 7),
          ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '  $qtyStr ${item.satuan} x ${_currency.format(item.hargaSatuan)}',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              _currency.format(item.subtotal + item.diskon),
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        if (item.diskon > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('  Diskon', style: const pw.TextStyle(fontSize: 7)),
              pw.Text('- ${_currency.format(item.diskon)}',
                  style: const pw.TextStyle(fontSize: 7)),
            ],
          ),
        pw.SizedBox(height: 2),
      ],
    );
  }

  static pw.Widget _buildSubtotal(StrukModel struk) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 9)),
          pw.Text(_currency.format(struk.subtotal),
              style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _buildDiskon(StrukModel struk) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Diskon', style: const pw.TextStyle(fontSize: 9)),
          pw.Text('- ${_currency.format(struk.diskon)}',
              style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _buildTotal(StrukModel struk) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('TOTAL',
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Text(_currency.format(struk.total),
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildPembayaran(StrukModel struk) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 4),
        _infoLine('Metode Bayar', struk.metodeBayar.label),
        if (struk.metodeBayar == MetodeBayar.tunai && struk.jumlahBayar > 0) ...[
          _infoLine('Bayar', _currency.format(struk.jumlahBayar)),
          _infoLine('Kembali', _currency.format(struk.kembalian)),
        ],
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _buildCatatan(StrukModel struk) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Catatan:', style: const pw.TextStyle(fontSize: 8)),
          pw.Text(struk.catatan, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  static pw.Widget _dashedLine() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Text(
        '- ' * 25,
        style: const pw.TextStyle(fontSize: 7),
        maxLines: 1,
      ),
    );
  }

  static pw.Widget _solidLine() {
    return pw.Divider(height: 6, thickness: 0.5);
  }
}
