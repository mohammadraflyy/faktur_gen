import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/history_model.dart';

class ExportService {
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  static Future<void> exportCsv(List<HistoryEntry> entries) async {
    final buf = StringBuffer();
    buf.writeln('No,Tipe,Nomor Dokumen,Tanggal,Klien,Total');
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final type = e.docType == DocType.invoice ? 'Invoice' : 'Struk';
      final klien = e.namaKlien.replaceAll('"', '""');
      final nomor = e.nomorDokumen.replaceAll('"', '""');
      buf.writeln(
          '${i + 1},$type,"$nomor",${_dateFmt.format(e.tanggalDokumen)},"$klien",${e.totalAmount.toInt()}');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/riwayat_dokumen.csv');
    await file.writeAsString(buf.toString());
    await Share.shareXFiles([XFile(file.path)], subject: 'Riwayat Dokumen');
  }
}
