import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/phone_utils.dart';

class WhatsAppService {
  /// Share invoice PDF via WhatsApp with pre-filled message.
  static Future<void> shareInvoice({
    required String clientName,
    required String clientPhone,
    required String invoiceNumber,
    required String amount,
    required Uint8List pdfBytes,
    required String filename,
  }) async {
    // Save PDF to temp file for sharing
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(pdfBytes);

    final message = 'Halo $clientName,\n\n'
        'Berikut invoice $invoiceNumber sebesar $amount.\n\n'
        'Terima kasih.';

    // Share PDF with message (lets user pick WhatsApp or other app)
    await Share.shareXFiles(
      [XFile(file.path)],
      text: message,
    );
  }

  /// Open WhatsApp chat with pre-filled message (no attachment).
  static Future<bool> sendMessage({
    required String phone,
    required String message,
  }) async {
    final normalized = normalizeIndonesianPhone(phone);
    final uri = Uri.parse(
        'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }
}
